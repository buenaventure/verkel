module Breadcrumb
  extend ActiveSupport::Concern

  class_methods do
    def breadcrumb(parent = nil, action = nil)
      crumb = []
      crumb += parent.breadcrumb unless parent.nil?
      crumb += [[
        model_name.human(count: 2),
        [*parent&.route_array, breadcrumb_index_on_parent ? nil : model_name.route_key.to_sym].compact
      ]]
      if action
        crumb += [[
          I18n.t("verb.#{action}"),
          [action, *parent&.route_array, (action == :new ? model_name.singular : model_name.plural).to_sym].compact
        ]]
      end
      crumb
    end

    def breadcrumb_index_on_parent
      false
    end
  end

  def route_array
    [self]
  end

  def breadcrumb(action = nil)
    crumb = breadcrumb_parent.breadcrumb + [[to_s,
                                             self.class.breadcrumb_index_on_parent ? breadcrumb_parent.route_array : route_array]]
    crumb += [[I18n.t("verb.#{action}"), [action, *route_array]]] if action
    crumb
  end

  private

  def breadcrumb_parent
    self.class
  end
end
