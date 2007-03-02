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
      pager = ::Paginator.new(klass.count(:conditions => conditions), record_select_config.per_page) do |offset, per_page|
        klass.find(:all, :offset => offset, :limit => per_page, :conditions => conditions)
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

    def record_select_conditions
      conditions = []

      # handle the user's search
      if params[:search] and !params[:search].empty?
        # this logic borrowed from ActiveScaffold
        tokens = params[:search].split(' ')

        where_clauses = record_select_config.search_on.collect { |sql| "LOWER(#{sql}) LIKE ?" }
        phrase = "(#{where_clauses.join(' OR ')})"

        sql = ([phrase] * tokens.length).join(' AND ')
        tokens = tokens.collect{ |value| ["#{value}%"] * record_select_config.search_on.length }.flatten

        conditions = [sql, *tokens]
      end

      # then try and get search terms from the url parameters
      params.each do |field, value|
        next unless record_select_config.model.columns_hash.has_key? field
        conditions = merge_conditions(conditions, ["LOWER(#{field}) LIKE ?", value])
      end

      merge_conditions(conditions, conditions_for_collection)
    end

    # an override method.
    # here you can provide custom conditions to define the selectable records. useful for per-user restrictions.
    # borrowed from ActiveScaffold
    def conditions_for_collection; end

    def record_select_config
      self.class.record_select_config
    end

    def render_record_select(options = {})
      options[:layout] ||= false
      if options[:partial]
        render :partial => record_select_path_of(options[:partial]), :layout => options[:layout], :locals => options[:locals]
      elsif options[:action]
        render :template => record_select_path_of(options[:action]), :layout => options[:layout], :locals => options[:locals]
      end
    end

    # borrowed from ActiveScaffold
    unless method_defined? :merge_conditions
    def merge_conditions(*conditions)
      sql, values = [], []
      conditions.compact.each do |condition|
        next if condition.empty? # .compact removes nils but it doesn't remove empty arrays.
        condition = condition.clone
        # "name = 'Joe'" gets parsed to sql => "name = 'Joe'", values => []
        # ["name = '?'", 'Joe'] gets parsed to sql => "name = '?'", values => ['Joe']
        sql << ((condition.is_a? String) ? condition : condition.shift)
        values += (condition.is_a? String) ? [] : condition
      end
      # if there are no values, then simply return the joined sql. otherwise, stick the joined sql onto the beginning of the values array and return that.
      conditions = values.empty? ? sql.join(" AND ") : values.unshift(sql.join(" AND "))
      conditions = nil if conditions.empty?
      conditions
    end
    end

    private

    def record_select_views_path
      @record_select_views_path ||= "../../vendor/plugins/recordselect/lib/views"
    end

    def record_select_path_of(template)
      File.join(record_select_views_path, template)
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
      options[:model] ||= self.to_s.sub(/Controller$/, '').underscore.pluralize.singularize
      options[:per_page] ||= 10
      options[:notify] = proc if block_given?
      options[:search_on] = [options[:search_on]] unless options[:search_id].is_a? Array

      @record_select_config = RecordSelect::Config.new(
        :model => options[:model].camelcase.constantize,
        :per_page => options[:per_page],
        :notify => options[:notify],
        :search_on => options[:search_on]
      )
      self.send :include, RecordSelect::Actions
    end

    attr_reader :record_select_config
  end

  # a write-once configuration object
  class Config
    attr_reader :model, :per_page, :notify, :search_on

    def initialize(options = {})
      options.each do |k, v|
        instance_variable_set("@#{k}", v) if self.respond_to? k
      end
    end
  end
end
