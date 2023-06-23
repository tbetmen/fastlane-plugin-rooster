require 'fastlane_core/ui/ui'
require 'json'
require 'net/http'
require 'uri'

module Fastlane
  module Helper
    module ApiRequest
      def api_get_response_json(url, header)
        uri = URI(url)

        UI.message "Get Request from url: #{url}"
        response = Net::HTTP.get_response(uri, header)

        if response.is_a?(Net::HTTPSuccess)
          UI.success "Successfully get request with code: #{response.code}"
          JSON.parse(response.body)
        else
          UI.error "Failed to get request code: #{response.code} message: #{response.message}"
          nil
        end
      end

      def api_post(url, body, header)
        uri = URI(url)
        request = Net::HTTP::Post.new(uri, header)
        request.body = JSON(body)

        UI.message "Post Request to url: #{url}"
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |https|
          https.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          UI.success "Successfully post request to with code: #{response.code}"
        else
          UI.error "Failed to post request code: #{response&.code} message: #{response&.message}"
        end
      end
    end
  end
end
