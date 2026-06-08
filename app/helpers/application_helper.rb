# frozen_string_literal: true

# Shared view helpers.
module ApplicationHelper
  def german_list(array)
    [array[0...-1].join(', '), array[-1]].compact_blank.join(' und ')
  end

  def icon(name)
    tag.img(src: image_path("open-iconic/#{name}.svg"), alt: "icon #{name}", width: 16, height: 16)
  end

  def page_title(breadcrumbs)
    [breadcrumb_title(breadcrumbs), 'Verkel'].compact.join(' – ')
  end

  def feature(name)
    case name
    when :estimation
      Rails.application.config.estimation
    when :lama
      Rails.application.config.lama_sync
    end
  end

  def euro(price, delimiter: nil)
    options = delimiter ? { delimiter: } : {}

    "#{number_with_delimiter(price, **options)}\u00A0€"
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
