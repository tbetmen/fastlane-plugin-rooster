require 'fastlane_core/ui/ui'
require_relative './api_request'
require_relative './time_format'

module Fastlane
  module Helper
    class SlackMessageClient
      include Helper::ApiRequest
      include Helper::TimeFormat

      def initialize(slack_users, slack_message_format, merge_requests, current_milestone)
        @slack_users = slack_users
        @slack_message_format = slack_message_format
        @merge_requests = merge_requests
        @current_milestone = current_milestone
      end

      def post_message(slack_webhook_url, payload)
        UI.message 'Posting slack message'
        api_post(
          slack_webhook_url,
          payload,
          { "Content-Type": 'application/json' }
        )
      end

      def markdown_section(text)
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: text
          }
        }
      end

      def format_users_string(users)
        users.empty? ? '-' : users.join(' ')
      end

      def merge_request_numbering
        @merge_requests.map.with_index do |mr, index|
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
          "#{index + 1}. #{text}"
        end
      end

      def merge_request_section
        mr_numbering = merge_request_numbering
        mr_numbering = mr_numbering.join("\n") if mr_numbering.length > 1

        markdown_section(mr_numbering)
      end

      def payload
        UI.message 'Composing slack payload'
        merge_request_size = @merge_requests.nil? ? 0 : @merge_requests.length

        unless merge_request_size.positive?
          UI.success 'Successfully composed slack payload but has empty merge request'
          return {
            text: @slack_message_format['text'],
            blocks: [
              markdown_section(
                @slack_message_format['empty_mr_text'].gsub('MR_MILESTONE', @current_milestone)
              )
            ]
          }
        end

        header_section = markdown_section(
          @slack_message_format['header'].gsub('MR_TOTAL', merge_request_size.to_s)
                                         .gsub('MR_MILESTONE', @current_milestone)
        )
        footer_section = markdown_section(@slack_message_format['footer'])

        UI.success "Successfully composed slack payload with total #{merge_request_size} merge request"
        {
          text: @slack_message_format['text'],
          blocks: [
            header_section,
            merge_request_section,
            footer_section
          ]
        }
      end
    end
  end
end
