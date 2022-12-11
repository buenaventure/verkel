class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  check_authorization unless: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden }
      format.html { redirect_back fallback_location: root_path, alert: exception.message }
      format.pdf { redirect_back fallback_location: root_path, alert: exception.message }
    end
  end

  def render(*args)
    @breadcrumbs = guess_breadcrumbs if @breadcrumbs.nil? && !devise_controller?
    super
  end

  def render_pdf(pdf)
    respond_to do |format|
      format.pdf do
        send_data pdf.render,
                  filename: pdf.filename,
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  private

  def breadcrumb_parent
    nil
  end

  def guess_breadcrumbs
    instance = instance_variable_get("@#{controller_name.singularize}")
    klass = controller_name.classify.constantize
    case action_name
    when 'index' then klass.breadcrumb(breadcrumb_parent)
    when 'show' then instance.breadcrumb
    when 'edit', 'update' then instance.breadcrumb(:edit)
    when 'new', 'create' then klass.breadcrumb(breadcrumb_parent, :new)
    else
      if !instance.nil?
        instance.breadcrumb(action_name.to_sym)
      else
        klass.breadcrumb(breadcrumb_parent, action_name.to_sym)
      end
    end
  rescue StandardError => e
    [["#{e.class}: #{e.message}", '#']] if Rails.env.development?
  end
end
