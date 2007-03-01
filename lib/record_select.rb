module RecordSelect
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module Actions
    # :method => :get
    # params[:page], params[:search]
    def browse
      klass = record_select_config.model
      pager = ::Paginator.new(klass.count, record_select_config.per_page) do |offset, per_page|
        klass.find(:all, :offset => offset, :limit => per_page)
      end
      @page = pager.page(params[:page] || 1)

      respond_to do |wants|
        wants.html { render_record_select :partial => 'browse', :layout => true }
        wants.js { render_record_select :partial => 'browse', :layout => false }
        wants.yaml {}
        wants.xml {}
        wants.json {}
      end
    end

    # :method => :post
    def select
      # instantiate object(s)
      # pass object(s) to record_select_config.notify
    end

    protected

    def record_select_config
      self.class.record_select_config
    end
  end

  module ClassMethods
    # sets up RecordSelect on your controller.
    #
    # options:
    #   :model - defaults based on the name of the controller
    #   :per_page - records to show per page when browsing
    #   :notify - a method name to invoke when a record has been selected.
    #
    # you may also pass a block, which will be used as options[:notify].
    def record_select(options = {})
      options.assert_valid_keys(:model, :per_page, :notify)

      options[:model] ||= self.to_s.sub(/Controller$/, '').underscore.pluralize.singularize
      options[:per_page] ||= 10
      options[:notify] = method(options[:notify]) if options[:notify]
      options[:notify] = proc if block_given?

      @record_select_config = RecordSelect::Config.new(
        :model => options[:model].camelcase.constantize,
        :per_page => options[:per_page],
        :notify => options[:notify]
      )
      self.send :include, RecordSelect::Actions
    end

    attr_reader :record_select_config
  end

  # a write-once configuration object
  class Config
    attr_reader :model, :per_page, :notify

    def initialize(options = {})
      options.each do |k, v|
        instance_variable_set("@#{k}", v) if self.respond_to? k
      end
    end
  end
end
