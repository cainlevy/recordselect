module RecordSelect
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module Actions
    # :method => :get
    # params => [:page, :search]
    def browse
      conditions = record_select_conditions
      klass = record_select_config.model
      count = klass.count(:conditions => conditions, :include => record_select_includes)
      pager = ::Paginator.new(count, record_select_config.per_page) do |offset, per_page|
        klass.find(:all, :offset => offset,
                         :include => record_select_includes,
                         :limit => per_page,
                         :conditions => conditions,
                         :order => record_select_config.order_by)
      end
      @page = pager.page(params[:page] || 1)

      respond_to do |wants|
        wants.html { render_record_select :partial => 'browse', :layout => true }
        wants.js {
          if params[:update]
            render_record_select :action => 'browse.rjs'
          else
            render_record_select :partial => 'browse'
          end
        }
        wants.yaml {}
        wants.xml {}
        wants.json {}
      end
    end

    # :method => :post
    # params => [:id]
    def select
      klass = record_select_config.model
      record = klass.find(params[:id])
      if record_select_config.notify.is_a? Proc
        record_select_config.notify.call(record)
      elsif record_select_config.notify
        send(record_select_config.notify, record)
      end
      render :nothing => true
    end

    protected

    def record_select_config #:nodoc:
      self.class.record_select_config
    end

    def render_record_select(options = {}) #:nodoc:
      options[:layout] ||= false
      if options[:partial]
        render :partial => record_select_path_of(options[:partial]), :layout => options[:layout], :locals => options[:locals]
      elsif options[:action]
        render :template => record_select_path_of(options[:action]), :layout => options[:layout], :locals => options[:locals]
      end
    end

    private

    def record_select_views_path
      @record_select_views_path ||= "../../vendor/plugins/#{File.expand_path(__FILE__).match(/vendor\/plugins\/(\w*)/)[1]}/lib/views"
    end

    def record_select_path_of(template)
      File.join(record_select_views_path, template)
    end
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
