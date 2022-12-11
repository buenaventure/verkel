class ApplicationRecord < ActiveRecord::Base
  include Breadcrumb
  self.abstract_class = true
end
