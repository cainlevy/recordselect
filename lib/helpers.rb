module ActionView # :nodoc:
  module Helpers # :nodoc:
    module RecordSelectHelpers
      # Print this from your layout to include everything necessary for RecordSelect to work.
      # Well, not everything. You need Prototype too.
      def record_select_includes
        includes = ''
        includes << stylesheet_link_tag('record_select/record_select')
        includes << javascript_include_tag('record_select/record_select')
        includes
      end

      # Adds a link on the page that toggles a RecordSelect widget from the given controller.
      #
      # *Options*
      # +onselect+::  JavaScript code to handle selections client-side. This code has access to two variables: id, label. If the code returns false, the dialog will *not* close automatically.
      # +params+::    Extra URL parameters. If any parameter is a column name, the parameter will be used as a search term to filter the result set.
      def link_to_record_select(name, controller, options = {})
        options[:params] ||= {}
        options[:params].merge!(:controller => controller, :action => :browse)
        options[:onselect] = "function(id, label) {#{options[:onselect]}}" if options[:onselect]
        options[:html] ||= {}
        options[:html][:id] ||= "rs_#{rand(9999)}"

        html = link_to_function(name, '', options[:html])
        html << javascript_tag("new RecordSelect.Dialog(#{options[:html][:id].to_json}, #{url_for(options[:params]).to_json}, {onselect: #{options[:onselect]}})")

        return html
      end

      # Adds a RecordSelect-based form field. The field submits the record's id using a hidden input.
      #
      # *Options*
      # +controller+::  The controller configured to provide the result set. Optional if you have standard resource controllers (e.g. UsersController for the User model), in which case the controller will be inferred from the class of +current+ (the second argument)
      # +params+::      A hash of URL parameters
      # +id+::          The id to use for the input. Defaults based on the input's name.
      def record_select_field(name, current, options = {})
        options[:controller] ||= current.class.to_s.pluralize.underscore
        options[:params] ||= {}
        options[:id] ||= name.gsub(/[\[\]]/, '_')

        id = label = ''
        if current and not current.new_record?
          id = current.id
          label = current.to_label
        end

        url = url_for({:action => :browse, :controller => options[:controller]}.merge(options[:params]))

        html = text_field_tag(name, nil, :autocomplete => 'off', :id => options[:id])
        html << javascript_tag("new RecordSelect.Autocomplete(#{options[:id].to_json}, #{url.to_json}, {id: #{id.to_json}, label: #{label.to_json}});")

        return html
      end

      # A helper to render RecordSelect partials
      def render_record_select(options = {})
        if options[:partial]
          render :partial => controller.send(:record_select_path_of, options[:partial]), :locals => options[:locals]
        end
      end

      # Provides view access to the RecordSelect configuration
      def record_select_config
        controller.send :record_select_config
      end

      # The id of the RecordSelect widget for the given controller.
      def record_select_id(controller = nil)
        controller ||= params[:controller]
        "record-select-#{controller.gsub('/', '_')}"
      end

      def record_select_search_id(controller = nil)
        "#{record_select_id(controller)}-search"
      end
    end
  end
end