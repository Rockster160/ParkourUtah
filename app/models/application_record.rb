class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :by_most_recent, ->(attr_sym) { order(attr_sym => :desc) }
end
