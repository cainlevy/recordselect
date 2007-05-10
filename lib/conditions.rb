module RecordSelect
  module Conditions
    protected
    def record_select_conditions
      conditions = []

      merge_conditions(
        record_select_conditions_from_search,
        record_select_conditions_from_params,
        conditions_for_collection
      )
    end

    # an override method.
    # here you can provide custom conditions to define the selectable records. useful for situational restrictions.
    def conditions_for_collection; end

    # generate conditions from params[:search]
    # override this if you want to customize the search routine
    def record_select_conditions_from_search
      search_pattern = record_select_config.full_text_search? ? '%?%' : '?%'

      if params[:search] and !params[:search].empty?
        tokens = params[:search].split(' ')

        where_clauses = record_select_config.search_on.collect { |sql| "LOWER(#{sql}) LIKE ?" }
        phrase = "(#{where_clauses.join(' OR ')})"

        sql = ([phrase] * tokens.length).join(' AND ')
        tokens = tokens.collect{ |value| [search_pattern.sub('?', value.downcase)] * record_select_config.search_on.length }.flatten

        conditions = [sql, *tokens]
      end
    end

    # generate conditions from the url parameters (e.g. users/browse?group_id=5)
    def record_select_conditions_from_params
      conditions = nil
      params.each do |field, value|
        next unless record_select_config.model.columns_hash.has_key? field
        conditions = merge_conditions(conditions, ["LOWER(#{field}) LIKE ?", value])
      end
      conditions
    end

    unless method_defined? :merge_conditions # may be provided by ActiveScaffold
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
  end
end