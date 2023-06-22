require 'net/http'
require 'uri'
require 'json'
require 'csv'
require 'date'

require 'fastlane/action'
require_relative '../helper/rooster_helper'

module Fastlane
  module Actions
    class RoosterAction < Action
      def self.run(params)
        members_file = params[:members_file] || ENV['GITLAB_SLACK_MEMBERS_FILE']
        gitlab_project_id = params[:gitlab_project_id] || ENV['GITLAB_PROJECT_ID']
        slack_webhook_url = params[:slack_webhook_url] || ENV['SLACK_WEBHOOK_URL']
        slack_message_format_file = params[:slack_message_format_file] || ENV['SLACK_MESSAGE_FORMAT_FILE']
        gitlab_mr_total = params[:gitlab_merge_request_total] || ENV['GITLAB_MERGE_REQUEST_TOTAL']
        gitlab_milestones_path = params[:gitlab_milestones_path] || ENV['GITLAB_MILESTONES_PATH']

        @gitlab_token = params[:gitlab_token] || ENV['GITLAB_ACCESS_TOKEN']
        @gitlab_api_base_url = 'https://gitlab.com/api/v4/'
        @slack_message_format = get_slack_message_format(slack_message_format_file)
        @members = get_members(members_file)
        @current_milestone = get_current_milestone(gitlab_milestones_path)

        mr_url = compose_merge_request_url(gitlab_project_id, gitlab_mr_total, @current_milestone)
        mr_resp_json = get_response_json(mr_url)
        merge_requests = compose_gitlab_merge_requests(mr_resp_json)
        slack_payload = compose_slack_payload(merge_requests)

        # UI.message slack_payload.to_json
        post_request(
          slack_webhook_url,
          slack_payload,
          { "Content-Type": "application/json" }
        )
      end

      #####################################################
      # @!group API REQUEST
      #####################################################

      def self.get_response_json(url)
        uri = URI(url)
        header = { 'PRIVATE-TOKEN' => @gitlab_token }
        response = Net::HTTP.get_response(uri, header)

        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        else
          UI.error "Failed to get request from #{url} code #{response.code} message #{response.message}"
        end
      end

      def self.post_request(url, body, header)
        uri = URI(url)
        request = Net::HTTP::Post.new(uri, header)
        request.body = JSON(body)

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |https|
          https.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          UI.success "Successfully post request to #{url}"
        else
          UI.error "Failed to post request to #{url} code #{response.code} message #{response.message}"
        end
      end

      #####################################################
      # @!group MILESTONE
      #####################################################

      def self.compose_milestones_url(milestones_path)
        return nil unless !milestones_path.nil?

        "#{@gitlab_api_base_url}#{milestones_path}/milestones?state=active"
      end

      def self.extract_current_milestone_title(milestone_resp_json)
        current_milestone = milestone_resp_json.find do |value|
          due_date = DateTime.strptime(value.dig('due_date'), '%Y-%m-%d')
          DateTime.now.to_time.to_i <= due_date.to_time.to_i
        end

        return "" unless !current_milestone.nil?

        current_milestone.dig('title')
      end

      def self.get_current_milestone(milestones_path)
        milestones_url = compose_milestones_url(milestones_path)
        return "" unless !milestones_url.nil?

        milestones_json = get_response_json(milestones_url)
        extract_current_milestone_title(milestones_json)
      end

      #####################################################
      # @!group SLACK MESSAGE FORMAT
      #####################################################

      def self.get_slack_message_format(slack_message_format_file)
        unless !slack_message_format_file.is_a?(Hash)
          return slack_message_format_file
        end

        JSON.parse(File.read(slack_message_format_file))
      end

      #####################################################
      # @!group MEMBERS
      #####################################################

      def self.get_members(members_file)
        return nil unless !members_file.nil? && !members_file.empty?

        members = {}
        CSV.foreach(members_file, headers: true) do |member|
          members[member['Gitlab User ID']] = {
            :name => member['Name'],
            :slack_id => member['Slack ID']
          }
        end

        members
      end

      #####################################################
      # @!group MERGE REQUEST
      #####################################################

      def self.compose_merge_request_url(project_id, per_page, current_milestone)
        "#{@gitlab_api_base_url}projects/#{project_id}/merge_requests?state=opened&order_by=created_at&sort=asc&per_page=#{per_page}&milestone=#{current_milestone}"
      end

      def self.get_slack_member_id(gitlab_member_id, gitlab_member_username)
        if !@members.nil? && @members.key?(gitlab_member_id.to_s)
          @members[gitlab_member_id.to_s][:slack_id]
        else
          "@#{gitlab_member_username}"
        end
      end

      def self.get_slack_member_ids(gitlab_mr_json, key)
        gitlab_mr_json.dig("#{key}")&.map do |v|
          get_slack_member_id(v.dig('id'), v.dig('username'))
        end
      end

      def self.compose_gitlab_merge_requests(gitlab_mr_json)
        gitlab_mr_json = gitlab_mr_json.select do |value|
          title = value.dig('title')
          !(title.downcase.start_with? 'draft') && !(title.downcase.start_with? 'wip')
        end

        gitlab_mr_json.map do |value|
          {
            :title => value.dig('title'),
            :created_at => value.dig('created_at'),
            :link => value.dig('web_url'),
            :assignee => get_slack_member_id(value.dig('assignee', 'id'), value.dig('assignee', 'username')),
            :assignees => get_slack_member_ids(value, 'assignees'),
            :reviewers => get_slack_member_ids(value, 'reviewers'),
            :labels => value.dig('labels')&.map { |label| label },
            :milestone_title => value.dig('milestone', 'title')
          }
        end
      end

      #####################################################
      # @!group TIME FORMAT
      # source: https://stackoverflow.com/a/63106647
      #####################################################

      def self.format_relative_date_time(date_string)
        time_unit_to_secs = {
          SECONDS: 1,
          MINUTES: 60,
          HOURS: 3600,
          DAYS: 24 * 3600,
          WEEKS: 7 * 24 * 3600,
          MONTHS: 30 * 24 * 3600,
          YEARS: 365 * 24 * 3600
        }
        time_unit_labels = {
          SECONDS: 'seconds',
          MINUTES: 'minutes',
          HOURS: 'hours',
          DAYS: 'days',
          WEEKS: 'weeks',
          MONTHS: 'months',
          YEARS: 'years'
        }

        created_at = DateTime.strptime(date_string, '%Y-%m-%dT%H:%M:%S.%L%Z')
        diff = DateTime.now.to_time.to_i - created_at.to_time.to_i

        UI.error("'date_time' cannot be in the future") if diff.negative?

        time_unit = if diff < time_unit_to_secs[:MINUTES]
                      :SECONDS
                    elsif diff < time_unit_to_secs[:HOURS]
                      :MINUTES
                    elsif diff < time_unit_to_secs[:DAYS]
                      :HOURS
                    elsif diff < time_unit_to_secs[:WEEKS]
                      :DAYS
                    elsif diff < time_unit_to_secs[:MONTHS]
                      :WEEKS
                    elsif diff < time_unit_to_secs[:YEARS]
                      :MONTHS
                    else
                      :YEARS
                    end

        time_relative = case time_unit
                        when :SECONDS, :MINUTES, :HOURS, :DAYS, :WEEKS
                          diff / time_unit_to_secs[time_unit]
                        when :MONTHS
                          0.step.find { |n| (created_at >> n) > now } - 1
                        else
                          0.step.find { |n| (created_at >> 12 * n) > now } - 1
                        end

        "#{time_relative} #{time_unit_labels[time_unit]} ago"
      end

      #####################################################
      # @!group SLACK
      #####################################################

      def self.format_users_string(users)
        return '-' if users.empty?

        users.join(' ')
      end

      def self.compose_merge_request_list_message(merge_requests)
        merge_requests_formatted = merge_requests.map.with_index do |mr, index|
          time = format_relative_date_time(mr[:created_at])
          assignees = format_users_string(mr[:assignees])
          reviewers = format_users_string(mr[:reviewers])
          text = @slack_message_format['mr_item'].to_s
                                      .gsub('MR_TITLE', mr[:title].to_s)
                                      .gsub('MR_TIME', time.to_s)
                                      .gsub('MR_ASSIGNEE_SINGLE', mr[:assignee].to_s)
                                      .gsub('MR_ASSIGNEES', assignees.to_s)
                                      .gsub('MR_REVIEWERS', reviewers.to_s)
                                       .gsub('MR_LABELS', mr[:labels].join(','))
                                      .gsub('MR_LINK', mr[:link].to_s)
          "#{index+1}. #{text}"
        end

        if merge_requests_formatted.length > 1
          merge_requests_formatted = merge_requests_formatted.join("\n")
        end

        {
          "type": 'section',
          "text": {
            "type": 'mrkdwn',
            "text": merge_requests_formatted
          }
        }
      end

      def self.compose_slack_payload(merge_requests)
        unless merge_requests.length > 0
          return {
            :text => @slack_message_format['text'],
            :blocks => [
              {
                "type": 'section',
                "text": {
                  "type": 'mrkdwn',
                  "text": @slack_message_format['empty_mr_text'].gsub('MR_MILESTONE', @current_milestone)
                }
              }
            ]
          }
        end

        header_text = @slack_message_format['header'].gsub('MR_TOTAL', merge_requests.length.to_s)
                                                     .gsub('MR_MILESTONE', @current_milestone)
        header_section = {
          :type => 'section',
          :text => {
            :type => 'mrkdwn',
            :text => header_text
          }
        }
        mr_section = compose_merge_request_list_message(merge_requests)
        footer_section = {
          :type => 'section',
          :text => {
            :type => 'mrkdwn',
            :text => @slack_message_format['footer']
          }
        }

        {
          :text => @slack_message_format['text'],
          :blocks => [header_section, mr_section, footer_section]
        }
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.available_options # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        [
          FastlaneCore::ConfigItem.new(
            key: :gitlab_token,
            env_name: 'GITLAB_ACCESS_TOKEN',
            description: 'Gitlab access token',
            optional: false,
            verify_block: proc do |value|
              UI.user_error!('No gitlab access token given') unless value and !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_project_id,
            env_name: 'GITLAB_PROJECT_ID',
            description: 'Gitlab project id',
            optional: false,
            verify_block: proc do |value|
              UI.user_error!('No gitlab mr url given') unless value and !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_milestones_path,
            env_name: 'GITLAB_MILESTONES_PATH',
            description: 'Gitlab group or project milestones with given format either `groups/:group_id` or `projects/:project_id`',
            optional: true,
            verify_block: proc do |value|
              UI.user_error!('No gitlab milestones path given') unless value and !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_merge_request_total,
            env_name: 'GITLAB_MERGE_REQUEST_TOTAL',
            default_value: '10',
            description: 'Total merge request to be shown in reminder, default value is `10`',
            optional: true,
            verify_block: proc do |value|
              UI.user_error!('No gitlab merge request total given') unless value and !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :members_file,
            env_name: 'GITLAB_SLACK_MEMBERS_FILE',
            description: 'Gitlab members filepath in csv format',
            optional: true,
            verify_block: proc do |value|
              UI.user_error!('No members file given') unless value and !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :slack_webhook_url,
            env_name: 'SLACK_WEBHOOK_URL',
            description: 'Slack webhook url',
            optional: false,
            verify_block: proc do |value|
              UI.user_error!('No slack webhook url given') unless value and !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :slack_message_format_file,
            env_name: 'SLACK_MESSAGE_FORMAT_FILE',
            default_value: {
              'text' => 'Hello, beautiful day!',
              'header' =>'Hi there, Just wanted to let you know that we have MR_TOTAL merge requests that need your attention.',
              'mr_item' => '<MR_LINK|MR_TITLE> MR_ASSIGNEE_SINGLE',
              'footer' => 'Thank you',
              'empty_mr_text' => 'Congratulation there is no merge request anymore, keep the good works'
            },
            description: "Slack message format in json format contains `text`, `header`, `mr_item`, `footer`, and `empty_mr_text`"\
                          "| In `header` you can use use `MR_TOTAL` and `MR_MILESTONE`"\
                          "| In `mr_item` you can use use `MR_TITLE`, `MR_TIME`, `MR_ASSIGNEE_SINGLE`, `MR_ASSIGNEES`, `MR_REVIEWERS`  `MR_LABELS`, and `MR_LINK`"\
                          "| In `empty_mr_text` you can use `MR_MILESTONE`",
            optional: true
          )
        ]
      end

      def self.example_code
        [
          'gitlab_mr_reminder()',
          'gitlab_mr_reminder(
            gitlab_members_file: "/User/documents/fe_members.csv",
            gitlab_token: "XXXX",
            gitlab_project_id: "https://gitlab.com/...",
            slack_webhook_url: "ttps://hooks.slack.com/...",
            slack_message_format_file: "/User/documents/slack_format.csv", # optional
          )'
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.author
        'tbetmen'
      end

      def self.description
        'Send gitlab merge requests reminder to slack.'
      end

      def self.details
        "This action is reminder system of gitlab merge request, fetching merge requests using Gitlab REST API and send to Slack using webhook url."
      end
    end
  end
end
