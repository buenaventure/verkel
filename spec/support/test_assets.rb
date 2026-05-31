# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    css = Rails.root.join('app/assets/builds/application.css')
    js = Rails.root.join('app/assets/builds/application.js')
    next if css.exist? && js.exist?

    Rails.application.load_tasks
    Rake::Task['css:build'].invoke
    Rake::Task['javascript:build'].invoke
  end
end
