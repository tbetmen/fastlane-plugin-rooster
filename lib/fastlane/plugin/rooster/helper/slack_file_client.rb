require 'fastlane_core/ui/ui'
require_relative './file_loader'

module Fastlane
  module Helper
    class SlackFileClient
      include Helper::FileLoader

      SLACK_MESSAGE_FORMAT_DEFAULT = {
        'text' => 'Hello, its beautiful day!',
        'header' => 'Hi there, Just wanted to let you know that we have MR_TOTAL merge requests that need your attention.',
        'mr_item' => '<MR_LINK|MR_TITLE> MR_ASSIGNEE_SINGLE',
        'footer' => 'Thank you',
        'empty_mr_text' => 'Congratulation there is no merge request anymore, keep the good works'
      }.freeze

      def message_format(filepath)
        UI.message 'Load slack message format'
        load_json(filepath, SLACK_MESSAGE_FORMAT_DEFAULT)
      end

      def users(filepath)
        UI.message 'Load slack users'
        slack_users = load_csv_to_hash(
          filepath,
          'Gitlab User ID',
          'Name',
          'Slack ID',
          'name',
          'slack_id'
        )

        UI.success 'Slack users nil, skipped using tag user `@user` in when posting message reminder in slack' if slack_users.nil?

        slack_users
      end
    end
  end
end
