require 'fastlane/action'
require_relative '../helper/gitlab_api_client'
require_relative '../helper/gitlab_merge_request_transformer'
require_relative '../helper/slack_file_client'
require_relative '../helper/slack_message_client'

module Fastlane
  module Actions
    class RoosterMergeRequestAction < Action
      def self.run(params)
        # get params or envs
        users_file = params[:slack_users_file] || ENV['ROOSTER_SLACK_USERS_FILE']
        gitlab_project_id = params[:gitlab_project_id] || ENV['ROOSTER_GITLAB_PROJECT_ID']
        slack_webhook_url = params[:slack_webhook_url] || ENV['ROOSTER_SLACK_WEBHOOK_URL']
        slack_message_format_file = params[:slack_message_format_file] || ENV['ROOSTER_SLACK_MESSAGE_FORMAT_FILE']
        gitlab_mr_total = params[:gitlab_merge_request_total] || ENV['ROOSTER_GITLAB_MERGE_REQUEST_TOTAL']
        gitlab_milestones_path = params[:gitlab_milestones_path] || ENV['ROOSTER_GITLAB_MILESTONES_PATH']
        gitlab_token = params[:gitlab_token] || ENV['ROOSTER_GITLAB_ACCESS_TOKEN']
        milestone = params[:gitlab_merge_request_milestone] || ENV['ROOSTER_GITLAB_MERGE_REQUEST_MILESTONE']

        # load slack files
        slack_file_client = Helper::SlackFileClient.new
        slack_message_format = slack_file_client.message_format(slack_message_format_file)
        slack_users = slack_file_client.users(users_file)

        # get gitlab merge request
        gitlab_api = Helper::GitlabApiClient.new(gitlab_token)
        if milestone.empty?
          current_milestone = gitlab_api.current_milestone(gitlab_milestones_path)
        else
          current_milestone = milestone
        end
        mr_resp_json = gitlab_api.merge_requests(gitlab_project_id, gitlab_mr_total, current_milestone)

        # transform merge request
        gitlab_mr_transformer = Helper::GitlabMergeRequestTransformer.new(slack_users, mr_resp_json)
        merge_request_formatted = gitlab_mr_transformer.transform

        # post merge request into slack
        slack_message_client = Helper::SlackMessageClient.new(
          slack_users,
          slack_message_format,
          merge_request_formatted,
          current_milestone
        )
        slack_message_client.post_message(
          slack_webhook_url,
          slack_message_client.payload
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :gitlab_token,
            env_name: 'ROOSTER_GITLAB_ACCESS_TOKEN',
            description: 'Gitlab access token',
            optional: false,
            verify_block: proc do |value|
              UI.user_error!('No gitlab access token given') unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_project_id,
            env_name: 'ROOSTER_GITLAB_PROJECT_ID',
            description: 'Gitlab project id',
            optional: false,
            verify_block: proc do |value|
              UI.user_error!('No gitlab project id given') unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :slack_webhook_url,
            env_name: 'ROOSTER_SLACK_WEBHOOK_URL',
            description: 'Slack webhook url',
            optional: false,
            verify_block: proc do |value|
              UI.user_error!('No slack webhook url given') unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_milestones_path,
            env_name: 'ROOSTER_GITLAB_MILESTONES_PATH',
            description: 'Gitlab group or project milestones with given format either `groups/:group_id` or `projects/:project_id`',
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_merge_request_total,
            env_name: 'ROOSTER_GITLAB_MERGE_REQUEST_TOTAL',
            default_value: 10,
            type: Integer,
            description: 'Maximum merge request when fetching data from gitlab, uses in query param `per_page`',
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :slack_users_file,
            env_name: 'ROOSTER_SLACK_USERS_FILE',
            description: 'Comma separate file that contains mapping user of gitlab and slack using id',
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :slack_message_format_file,
            env_name: 'ROOSTER_SLACK_MESSAGE_FORMAT_FILE',
            default_value: Helper::SlackFileClient::SLACK_MESSAGE_FORMAT_DEFAULT,
            description: 'Slack message format in json format contains `text`, `header`, `mr_item`, `footer`, and `empty_mr_text`'\
                          '| In `header` you can use use `MR_TOTAL` and `MR_MILESTONE`'\
                          '| In `mr_item` you can use use `MR_TITLE`, `MR_TIME`, `MR_ASSIGNEE_SINGLE`, `MR_ASSIGNEES`, `MR_REVIEWERS`  `MR_LABELS`, and `MR_LINK`'\
                          '| In `empty_mr_text` you can use `MR_MILESTONE`',
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :gitlab_merge_request_milestone,
            env_name: 'ROOSTER_GITLAB_MERGE_REQUEST_MILESTONE',
            default_value: '',
            description: 'Milestone will be used in merge request parameter as query param',
            optional: true
          )
        ]
      end

      def self.example_code
        [
          'rooster_merge_request',
          'rooster_merge_request(
            gitlab_token: "xyx",
            gitlab_project_id: "123456",
            gitlab_milestones_path: "projects/12345678"
            gitlab_merge_request_total: 20,
            slack_users_file: "/User/documents/slack_users.csv",
            slack_webhook_url: "https://hooks.slack.com/000/000",
            slack_message_format_file: "/User/documents/slack_message_format.json",
          )'
        ]
      end

      def self.is_supported?(_)
        true
      end

      def self.author
        'tbetmen (muhammadmmunir24@gmail.com)'
      end

      def self.description
        'Send gitlab merge requests reminder to slack.'
      end

      def self.details
        [
          'This action is reminder system of gitlab merge request, ',
          'fetching merge requests using Gitlab REST API and send to Slack using webhook url.'
        ].join('')
      end
    end
  end
end
