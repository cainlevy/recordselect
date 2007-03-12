module ActiveRecord # :nodoc:
  class Base # :nodoc:
    unless method_defined? :to_label
    def to_label
      self.to_s
    end
    end
  end
end