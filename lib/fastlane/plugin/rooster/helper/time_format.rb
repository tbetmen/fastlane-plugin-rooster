require 'date'
require 'fastlane_core/ui/ui'

module Fastlane
  module Helper
    # source: https://stackoverflow.com/a/63106647
    module TimeFormat
      TIME_UNIT_TO_SECS = {
        SECONDS: 1,
        MINUTES: 60,
        HOURS: 3600,
        DAYS: 24 * 3600,
        WEEKS: 7 * 24 * 3600,
        MONTHS: 30 * 24 * 3600,
        YEARS: 365 * 24 * 3600
      }.freeze
      TIME_UNIT_LABELS = {
        SECONDS: 'seconds',
        MINUTES: 'minutes',
        HOURS: 'hours',
        DAYS: 'days',
        WEEKS: 'weeks',
        MONTHS: 'months',
        YEARS: 'years'
      }.freeze

      def format_relative_date_time(date_string, date_format = '%Y-%m-%dT%H:%M:%S.%L%Z')
        created_at = DateTime.strptime(date_string, date_format)
        now = DateTime.now
        diff = now.to_time.to_i - created_at.to_time.to_i

        if diff.negative?
          UI.message '`date` cannot be in the future'
          return 'in future'
        end

        time_unit = if diff < TIME_UNIT_TO_SECS[:MINUTES]
                      :SECONDS
                    elsif diff < TIME_UNIT_TO_SECS[:HOURS]
                      :MINUTES
                    elsif diff < TIME_UNIT_TO_SECS[:DAYS]
                      :HOURS
                    elsif diff < TIME_UNIT_TO_SECS[:WEEKS]
                      :DAYS
                    elsif diff < TIME_UNIT_TO_SECS[:MONTHS]
                      :WEEKS
                    elsif diff < TIME_UNIT_TO_SECS[:YEARS]
                      :MONTHS
                    else
                      :YEARS
                    end

        time_relative = case time_unit
                        when :SECONDS, :MINUTES, :HOURS, :DAYS, :WEEKS
                          diff / TIME_UNIT_TO_SECS[time_unit]
                        when :MONTHS
                          0.step.find { |n| (created_at >> n) > now } - 1
                        else
                          0.step.find { |n| (created_at >> 12 * n) > now } - 1
                        end

        "#{time_relative} #{TIME_UNIT_LABELS[time_unit]} ago"
      end
    end
  end
end
