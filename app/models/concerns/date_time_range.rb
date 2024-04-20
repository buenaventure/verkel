module DateTimeRange
  extend ActiveSupport::Concern

  class_methods do
    def date_time_range(name)
      define_method("#{name}_begin") do
        convert_time_range_value send(name)&.begin
      end

      define_method("#{name}_begin=") do |datetime_hash|
        send("#{name}=", Range.new(
                           hash_to_datetime(datetime_hash),
                           send(name)&.end,
                           false
                         ))
      end

      define_method("#{name}_end") do
        convert_time_range_value send(name)&.end
      end

      define_method("#{name}_end=") do |datetime_hash|
        send("#{name}=", Range.new(
                           send(name)&.begin,
                           hash_to_datetime(datetime_hash),
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

  def hash_to_datetime(datetime_hash)
    return nil if datetime_hash.nil?

    values = datetime_hash.sort.map(&:last)
    return nil if values.any?(&:nil?)

    Time.zone.local(*values)
  end
end
