class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :by_most_recent, ->(attr_sym=:created_at) { order(attr_sym => :desc) }
end
