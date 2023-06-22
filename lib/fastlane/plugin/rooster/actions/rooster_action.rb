require 'fastlane/action'
require_relative '../helper/rooster_helper'

module Fastlane
  module Actions
    class RoosterAction < Action
      def self.run(params)
        UI.message("The rooster plugin is working!")
      end

      def self.description
        "Send gitlab merge requests reminder to slack"
      end

      def self.authors
        ["Muhammad M. Munir"]
      end

      def self.details
        "This action is reminder system of gitlab merge request, fetching merge requests using Gitlab REST API and send to Slack using webhook url."
      end

      def self.available_options
        []
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
