require 'fastlane_core/ui/ui'
require 'csv'
require 'json'

module Fastlane
  module Helper
    module FileLoader
      def valid_extension(filepath, ext)
        File.file?(filepath.to_s) && [ext.to_s].include?(File.extname(filepath.to_s))
      end

      def load_json(filepath, default_value)
        UI.message "Load json filepath #{filepath}"

        if valid_extension(filepath, '.json')
          UI.success 'Successfully loaded json file'
          JSON.parse(File.read(filepath))
        else
          UI.success 'Successfully return default value because given file is missing or invalid json format'
          default_value
        end
      end

      def load_csv_to_hash(filepath, header_id, header_one, header_two, header_one_key, header_two_key)
        UI.message "Load csv filepath #{filepath}"

        unless valid_extension(filepath, '.csv')
          UI.message 'The given file is missing or invalid csv format'
          return nil
        end

        hash_value = {}
        CSV.foreach(filepath, headers: true) do |user|
          hash_value[user[header_id.to_s]] = {
            header_one_key.to_s => user[header_one.to_s],
            header_two_key.to_s => user[header_two.to_s]
          }
        end

        UI.success 'Successfully loaded csv file into hash'
        hash_value
      end
    end
  end
end
