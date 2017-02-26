module Defaults
  extend ActiveSupport::Concern

  # Added to instance of object
  included do
    after_initialize :apply_default_values
  end

  # Callback for setting default values
  def apply_default_values
    self.class.defaults.each do |attribute, param|
      next unless self.send(attribute).nil?
      value = param.respond_to?(:call) ? param.call(self) : param
      self[attribute] = value
    end
    self.class.created_defaults.each do |attribute, param|
      next if self.persisted?
      next unless self.send(attribute).nil?
      value = param.respond_to?(:call) ? param.call(self) : param
      self[attribute] = value
    end
  end

  # Added to class of object
  class_methods do
    def default(attribute_hash)
      attribute_hash.each do |attr_key, attr_val|
        created_defaults[attr_key] = attr_val
      end
    end

    def default_on_create(attribute_hash)
      attribute_hash.each do |attr_key, attr_val|
        created_defaults[attr_key] = attr_val
      end
    end

    def defaults
      @defaults ||= {}
    end
    def created_defaults
      @created_defaults ||= {}
    end
  end
end
