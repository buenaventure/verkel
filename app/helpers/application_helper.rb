module ApplicationHelper
  def german_list(array)
    [array[0...-1].join(', '), array[-1]].reject(&:blank?).join(' und ')
  end

  def icon(name)
    "<img src=\"#{image_path("open-iconic/#{name}.svg")}\" alt=\"icon #{name}\" width=\"16\" height=\"16\">".html_safe
  end

  def page_title(breadcrumbs)
    [breadcrumb_title(breadcrumbs), 'Verkel'].compact.join(' – ')
  end

  def feature(name)
    case name
    when :estimation
      Rails.application.config.estimation
    end
  end

  def euro(price)
    "#{number_with_delimiter price}\u00A0€"
  end

  private

  def breadcrumb_title(breadcrumbs)
    return nil unless breadcrumbs

    last = breadcrumbs.last
    if last.is_a? Array
      last.first
    else
      last
    end
  end
end
