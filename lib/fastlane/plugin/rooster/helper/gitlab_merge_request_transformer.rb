require 'fastlane_core/ui/ui'

module Fastlane
  module Helper
    # Transform merge request json to new format by adding slack users id if `slack_users` parameter not nil or empty.
    # And ignoring merge request when title has prefix `draft` and `wip`.
    class GitlabMergeRequestTransformer
      def initialize(slack_users, gitlab_mr_json)
        @slack_users = slack_users
        @gitlab_mr_json = gitlab_mr_json
      end

      def transform
        UI.message 'Transform gitlab merge request into new format'

        mr_filtered = remove_draft_merge_request(@gitlab_mr_json)
        mr_transformed = compose_gitlab_merge_request(mr_filtered)
        UI.success 'Successfully transformed into new format'

        mr_transformed
      end

      def get_slack_user_id(gitlab_user_id, gitlab_username)
        if !@slack_users.nil? && @slack_users.key?(gitlab_user_id.to_s)
          "<@#{@slack_users[gitlab_user_id.to_s]['slack_id']}>"
        else
          "@#{gitlab_username}"
        end
      end

      def get_slack_user_ids(gitlab_mr_json, key)
        gitlab_mr_json[key.to_s]&.map do |v|
          get_slack_user_id(v['id'], v['username'])
        end
      end

      def remove_draft_merge_request(gitlab_mr_json)
        gitlab_mr_json&.select do |value|
          title = value['title']
          !(title.downcase.start_with? 'draft') && !(title.downcase.start_with? 'wip')
        end
      end

      def compose_gitlab_merge_request(gitlab_mr_json)
        gitlab_mr_json&.map do |value|
          {
            title: value['title'],
            created_at: value['created_at'],
            link: value['web_url'],
            assignee: get_slack_user_id(value.dig('assignee', 'id'), value.dig('assignee', 'username')),
            assignees: get_slack_user_ids(value, 'assignees'),
            reviewers: get_slack_user_ids(value, 'reviewers'),
            labels: value['labels']&.map { |label| label },
            milestone_title: value.dig('milestone', 'title')
          }
        end
      end
    end
  end
end
