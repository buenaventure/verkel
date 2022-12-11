class ArticleStockAction
  extend ActiveModel::Naming
  include ActiveModel::Model

  attr_accessor :action, :article
  attr_reader :status, :result

  ACTION_REGEX = /\A(\+|-|=)([0-9]*)(?:(?:,([0-9]+))?(k))?\z/

  validates :action,
            presence: true,
            format: { with: ACTION_REGEX,
                      message: 'muss im Format "+|-|=100[[,5]k]" sein.' }

  def to_key
    return nil unless article.present?

    [article.id]
  end

  def call
    return unless valid?

    execute_action
    save_article
  end

  private

  def action_match
    ACTION_REGEX.match(action)
  end

  def action_type
    action_match[1]
  end

  def action_factor
    case action_match[4]
    when 'k' then 1000
    else 1
    end
  end

  def quantity
    BigDecimal(action_match[2..3].compact.join('.')) * action_factor
  end

  def execute_action
    case action_type
    when '+' then article.stock += quantity
    when '-' then article.stock -= quantity
    when '=' then article.stock = quantity
    end
  end

  def save_article
    if article.save
      @status = :success
      @result = action
      self.action = ''
      errors.clear
    else
      @status = :error
      @result = "Artikel ist fehlerhaft #{article.errors[:stock].join(', ')}"
      article.reload
    end
  end
end
