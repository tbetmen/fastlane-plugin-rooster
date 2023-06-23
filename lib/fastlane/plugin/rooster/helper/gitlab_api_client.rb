require 'date'
require 'fastlane_core/ui/ui'
require_relative './api_request'

module Fastlane
  module Helper
    class GitlabApiClient
      include Helper::ApiRequest

      BASE_URL = 'https://gitlab.com/api/v4/'.freeze

      def initialize(private_token)
        @header = { 'PRIVATE-TOKEN': private_token }
      end

      #####################################################
      # @!group MILESTONE
      #####################################################
      def current_milestone(milestones_path)
        UI.message 'Fetching current milestone'
        milestones_url = milestones_url(milestones_path)

        if milestones_url.nil? || milestones_url.empty?
          UI.success 'Return empty milestone because invalid milestone url'
          ''
        else
          milestones_json = api_get_response_json(milestones_url, @header)
          value = milestone_title(milestones_json)
          UI.success "Successfully fetched current milestone #{value}" unless value.empty?
          value
        end
      end

      # `path` available option ['groups/:group_id', 'projects/:project_id']
      def milestones_url(path)
        path.nil? || path.empty? ? '' : "#{BASE_URL}#{path}/milestones?state=active"
      end

      def milestone_title(milestone_resp_json)
        return '' if milestone_resp_json.nil?

        current_milestone = milestone_resp_json.find do |value|
          due_date = DateTime.strptime(value['due_date'], '%Y-%m-%d')
          DateTime.now.to_time.to_i <= due_date.to_time.to_i
        end

        current_milestone.nil? ? '' : current_milestone['title']
      end

      #####################################################
      # @!group MERGE REQUEST
      #####################################################
      def merge_requests(project_id, per_page = 10, current_milestone = '')
        UI.message 'Fetching merge requests'
        url = merge_request_url(project_id, per_page, current_milestone)
        resp = api_get_response_json(url, @header)

        if resp.nil?
          UI.user_error! 'Failed to fetch gitlab merge request'
        else
          UI.success "Successfully fetched #{resp.length} merge requests"
          resp
        end
      end

      def merge_request_url(project_id, per_page, current_milestone)
        url = "#{BASE_URL}projects/#{project_id}/merge_requests?state=opened&order_by=created_at&sort=asc&per_page=#{per_page}"
        current_milestone.nil? || current_milestone.empty? ? url : url + "&milestone=#{current_milestone}"
      end
    end
  end
end
