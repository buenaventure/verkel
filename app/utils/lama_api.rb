class LamaError < RuntimeError
end

class LamaApi
  include HTTParty
  base_uri Rails.application.config.lama_api[:server]
  headers({ 'accept': 'application/json',
            'ApiKey': Rails.application.credentials.lama_api_key })

  def initialize(event_id, retries = 1)
    @event_id = event_id
    @retries = retries
  end

  def self.events
    get('/api/cooking/v1/events')
  end

  def event
    self.class.get(event_base_url)
  end

  def restrictions
    with_retry do
      self.class.get("#{event_base_url}/restrictions")
    end
  end

  def attendees
    with_retry do
      self.class.get("#{event_base_url}/attendees")
    end
  end

  def meals
    with_retry do
      self.class.get("#{event_base_url}/meals")
    end
  end

  def meal(meal_id)
    with_retry do
      self.class.get("#{event_base_url}/meals/#{meal_id}")
    end
  end

  def slots
    with_retry do
      self.class.get("#{event_base_url}/slots")
    end
  end

  def groups
    with_retry do
      self.class.get("#{event_base_url}/groups")
    end
  end

  private

  def event_base_url
    "/api/cooking/v1/events/#{@event_id}"
  end

  def with_retry
    errors = []
    (@retries + 1).times do |i|
      sleep 5 if i != 0
      response = yield
      if response.success?
        Rails.logger.info "LamaApi succeeded after #{i} retries" if i.positive?
        return response
      elsif response.not_found?
        return nil
      end
      errors << "LamaApi failed ##{i} with #{response.code}"
      Rails.logger.info errors.last
    rescue Net::ReadTimeout
      errors << "LamaApi failed ##{i} with Net::ReadTimeout"
      Rails.logger.info errors.last
    rescue Net::OpenTimeout
      errors << "LamaApi failed ##{i} with Net::OpenTimeout"
      Rails.logger.info errors.last
    end

    raise LamaError, "maximum retries exceeded, errors: #{errors}"
  end
end
