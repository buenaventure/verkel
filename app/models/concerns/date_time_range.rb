module DateTimeRange
  extend ActiveSupport::Concern

  class_methods do
    def date_time_range(name)
      define_method("#{name}_begin") do
        convert_time_range_value send(name)&.begin
      end

      define_method("#{name}_begin=") do |value|
        send("#{name}=", Range.new(
                           parse_boundary_datetime(value),
                           send(name)&.end,
                           false
                         ))
      end

      define_method("#{name}_end") do
        convert_time_range_value send(name)&.end
      end

      define_method("#{name}_end=") do |value|
        send("#{name}=", Range.new(
                           send(name)&.begin,
                           parse_boundary_datetime(value),
                           false
                         ))
      end
    end
  end

  private

  def convert_time_range_value(value)
    return if value.respond_to?(:infinite?) && value.infinite?

    value&.in_time_zone
  end

  def parse_boundary_datetime(value)
    return nil if value.blank?

    time = value.respond_to?(:in_time_zone) ? value.in_time_zone : Time.zone.parse(value.to_s)
    time.presence
  rescue ArgumentError, TypeError
    nil
  end
end
