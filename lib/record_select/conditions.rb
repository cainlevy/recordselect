module RecordSelect
  module Conditions
    protected
    # returns the combination of all conditions.
    # conditions come from:
    # * current search (params[:search])
    # * intelligent url params (e.g. params[:first_name] if first_name is a model column)
    # * specific conditions supplied by the developer
    def record_select_conditions
      conditions = []

      merge_conditions(
        record_select_conditions_from_search,
        record_select_conditions_from_params,
        record_select_conditions_from_controller
      )
    end

    # an override method.
    # here you can provide custom conditions to define the selectable records. useful for situational restrictions.
    def record_select_conditions_from_controller; end

    # another override method.
    # define any association includes you want for the finder search.
    def record_select_includes; end

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

    # instead of a shotgun approach, this assumes the user is
    # searching vs some SQL field (possibly built with CONCAT())
    # similar to the record labels.
#    def record_select_simple_conditions_from_search
#      return unless params[:search] and not params[:search].empty?
#
#      search_pattern = record_select_config.full_text_search? ? '%?%' : '?%'
#      search_string = search_pattern.sub('?', value.downcase)
#
#      ["LOWER(#{record_select_config.search_on})", search_pattern.sub('?', value.downcase)]
#    end

    # generate conditions from the url parameters (e.g. users/browse?group_id=5)
    def record_select_conditions_from_params
      conditions = nil
      params.each do |field, value|
        next unless column = record_select_config.model.columns_hash[field]
        conditions = merge_conditions(
          conditions,
          record_select_condition_for_column(column, value)
        )
      end
      conditions
    end

    # generates an SQL condition for the given column/value
    def record_select_condition_for_column(column, value)
      if value.nil?
        "#{column.name} IS NULL"
      elsif column.text?
        ["LOWER(#{field}) LIKE ?", value]
      elsif column.number?
        ["#{field} = ?", value]
      end
    end

    def merge_conditions(*conditions) #:nodoc:
      c = conditions.find_all {|c| not c.nil? and not c.empty? }
      c.empty? ? nil : c.collect{|c| ActiveRecord::Base.send(:sanitize_sql, c)}.join(' AND ')
    end
  end
end