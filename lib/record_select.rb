module RecordSelect
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # Enables and configures RecordSelect on your controller.
    #
    # *Options*
    # +model+::     defaults based on the name of the controller
    # +per_page+::  records to show per page when browsing
    # +notify+::    a method name to invoke when a record has been selected.
    # +order_by+::  a SQL string to order the search results
    # +search_on+:: an array of searchable fields
    # +full_text_search+::  a boolean for whether to use a %?% search pattern or not. default is false.
    # +label+::     a proc that accepts a record as argument and returns an option label. default is to call record.to_label instead.
    # +include+::   as for ActiveRecord::Base#find. can help with search conditions or just help optimize rendering the results.
    #
    # You may also pass a block, which will be used as options[:notify].
    def record_select(options = {})
      options[:model] ||= self.to_s.split('::').last.sub(/Controller$/, '').pluralize.singularize.underscore
      @record_select_config = RecordSelect::Config.new(options.delete(:model), options)
      self.send :include, RecordSelect::Actions
      self.send :include, RecordSelect::Conditions
    end

    attr_reader :record_select_config

    def uses_record_select?
      !record_select_config.nil?
    end
  end
end
