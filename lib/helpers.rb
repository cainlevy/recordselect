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

        assert_controller_responds(options[:params][:controller])

        html = link_to_function(name, '', options[:html])
        html << javascript_tag("new RecordSelect.Dialog(#{options[:html][:id].to_json}, #{url_for(options[:params].merge(:escape => false)).to_json}, {onselect: #{options[:onselect] || ''}})")

        return html
      end

      # Adds a RecordSelect-based form field. The field submits the record's id using a hidden input.
      #
      # *Arguments*
      # +name+:: the input name that will be used to submit the selected record's id.
      # +current+:: the currently selected object. provide a new record if there're none currently selected and you have not passed the optional :controller argument.
      #
      # *Options*
      # +controller+::  The controller configured to provide the result set. Optional if you have standard resource controllers (e.g. UsersController for the User model), in which case the controller will be inferred from the class of +current+ (the second argument)
      # +params+::      A hash of extra URL parameters
      # +id+::          The id to use for the input. Defaults based on the input's name.
      # +onchange+::    A JavaScript function that will be called whenever something new is selected. It should accept the new id as the first argument, and the new label as the second argument. For example, you could set onchange to be "function(id, label) {alert(id);}", or you could create a JavaScript function somewhere else and set onchange to be "my_function" (without the parantheses!).
      def record_select_field(name, current, options = {})
        options[:controller] ||= current.class.to_s.pluralize.underscore
        options[:params] ||= {}
        options[:id] ||= name.gsub(/[\[\]]/, '_')

        controller = assert_controller_responds(options[:controller])

        id = label = ''
        if current and not current.new_record?
          id = current.id
          label = label_for_field(current, controller)
        end

        url = url_for({:action => :browse, :controller => options[:controller], :escape => false}.merge(options[:params]))

        html = text_field_tag(name, nil, :autocomplete => 'off', :id => options[:id], :class => options[:class], :onfocus => "this.focused=true", :onblur => "this.focused=false")
        html << javascript_tag("new RecordSelect.Single(#{options[:id].to_json}, #{url.to_json}, {id: #{id.to_json}, label: #{label.to_json}, onchange: #{options[:onchange] || ''.to_json}});")

        return html
      end

      # Adds a RecordSelect-based form field for multiple selections. The values submit using a list of hidden inputs.
      #
      # *Arguments*
      # +name+:: the input name that will be used to submit the selected records' ids. empty brackets will be appended to the name.
      # +current+:: pass a collection of existing associated records
      #
      # *Options*
      # +controller+::  The controller configured to provide the result set.
      # +params+::      A hash of extra URL parameters
      # +id+::          The id to use for the input. Defaults based on the input's name.
      def record_multi_select_field(name, current, options = {})
        options[:controller] ||= current.first.class.to_s.pluralize.underscore
        options[:params] ||= {}
        options[:id] ||= name.gsub(/[\[\]]/, '_')

        controller = assert_controller_responds(options[:controller])

        current = current.inject([]) { |memo, record| memo.push({:id => record.id, :label => label_for_field(record, controller)}) }

        url = url_for({:action => :browse, :controller => options[:controller], :escape => false}.merge(options[:params]))

        html = text_field_tag("#{name}[]", nil, :autocomplete => 'off', :id => options[:id], :class => options[:class], :onfocus => "this.focused=true", :onblur => "this.focused=false")
        html << javascript_tag("new RecordSelect.Multiple(#{options[:id].to_json}, #{url.to_json}, {current: #{current.to_json}});")
        html << content_tag('ul', '', :class => 'record-select-list');

        return html
      end

      # A helper to render RecordSelect partials
      def render_record_select(options = {}) #:nodoc:
        if options[:partial]
          render :partial => controller.send(:record_select_path_of, options[:partial]), :locals => options[:locals]
        end
      end

      # Provides view access to the RecordSelect configuration
      def record_select_config #:nodoc:
        controller.send :record_select_config
      end

      # The id of the RecordSelect widget for the given controller.
      def record_select_id(controller = nil) #:nodoc:
        controller ||= params[:controller]
        "record-select-#{controller.gsub('/', '_')}"
      end

      def record_select_search_id(controller = nil) #:nodoc:
        "#{record_select_id(controller)}-search"
      end

      private

      # uses renderer (defaults to record_select_config.label) to determine how the given record renders.
      def render_record_from_config(record, renderer = record_select_config.label)
        case renderer
          when Symbol, String
          # return full-html from the named partial
          render :partial => renderer.to_s, :locals => {:record => record}

          when Proc
          # return an html-cleaned descriptive string
          h renderer.call(record)
        end
      end

      # uses the result of render_record_from_config to snag an appropriate record label
      # to display in a field.
      #
      # if given a controller, searches for a partial in its views path
      def label_for_field(record, controller = self.controller)
        renderer = controller.record_select_config.label
        case renderer
          when Symbol, String
          # find the <label> element and grab its innerHTML
          description = render_record_from_config(record, File.join(controller.controller_path, renderer.to_s))
          description.match(/<label[^>]*>(.*)<\/label>/)[1]

          when Proc
          # just return the string
          render_record_from_config(record, renderer)
        end
      end

      def assert_controller_responds(controller_name)
        controller_name = "#{controller_name.camelize}Controller"
        controller = controller_name.constantize
        unless controller.uses_record_select?
          raise "#{controller_name} has not been configured to use RecordSelect."
        end
        controller
      end
    end
  end
end