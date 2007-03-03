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
      # +onselect+::  JavaScript code to handle selections client-side. This code has access to three variables: id, label, and container.
      # +params+::    Extra URL parameters. If any parameter is a column name, the parameter will be used as a search term to filter the result set.
      def link_to_record_select(name, controller, options = {})
        options[:params] ||= {}
        options[:params].merge!(:controller => controller, :action => :browse)
        options[:onselect] = "function(id, label, container) {#{options[:onselect]}}" if options[:onselect]

        link_to_function(name, %|RecordSelect.toggle(this, '#{url_for options[:params]}', #{h options[:onselect]})|)
      end

      # Adds a RecordSelect-based form field. The field submits the record's id using a hidden input.
      #
      # *Options*
      # +controller+::  The controller configured to provide the result set. Optional if you have standard resource controllers (e.g. UsersController for the User model), in which case the controller will be inferred from the class of +current+ (the second argument)
      # +id+::          The id to use for the hidden input. Defaults based on the input's name.
      def record_select_field(name, current, options = {})
        options[:controller] ||= current.class.to_s.pluralize.underscore
        options[:id] ||= name.gsub(/[\[\]]/, '_')

        label = (!current or current.new_record?) ? '' : current.to_label

        text_field = %(<input autocomplete="off" type="text" value="#{h label}" class="record-select-input" onfocus="RecordSelect.open(this)" onblur="RecordSelect.close(this)" onkeyup="$$('##{record_select_id(options[:controller])}-search input')[0].value = this.value" />)

        html = ''
        html << '<span class="record-select-text-field">';
          html << %(<input type="hidden" name="#{h name}" value="#{current.id}" id="#{options[:id]}" />)
          html << link_to_record_select(
            text_field,
            options[:controller],
            :onselect => "$('#{options[:id]}').value = id; Element.previous(container).childNodes[0].value = label; Element.remove(container);",
            :params => options[:params]
          )
        html << '</span>'

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
        "record-select-#{controller}"
      end
    end
  end
end