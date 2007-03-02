module ActionView::Helpers
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
    # You may define a client-side handler for the widget using +options[:select]+
    def link_to_record_select(name, controller, options = {})
      options[:params] ||= {}
      options[:params].merge!(:controller => controller, :action => :browse)
      options[:onselect] = "function(id, value, container) {#{options[:onselect]}}" if options[:onselect]

      link_to_function(name, %|RecordSelect.toggle(this, '#{url_for options[:params]}', #{h options[:onselect]})|)
    end

    # Adds a RecordSelect-based form field. The field submits the record's id using a hidden input.
    #
    # Unless you have resource controllers (e.g. UsersController for the User model), you should
    # specify options[:controller].
    def record_select_field(name, current, options = {})
      options[:controller] ||= current.class.to_s.pluralize.underscore
      options[:id] ||= name.gsub(/[\[\]]/, '_')

      label = (!current or current.new_record?) ? 'None Selected' : current.to_label

      html = ''
      html << %(<input type="hidden" name="#{h name}" value="#{current.id}" id="#{options[:id]}" />)
      html << link_to_record_select(
        "<span class='record-select-input'>#{h label}</span>",
        options[:controller],
        :onselect => "$('#{options[:id]}').value = id; Element.previous(container).childNodes[0].innerHTML = value; Element.remove(container);",
        :params => options[:params]
      )

      return html
    end

    def render_record_select(options = {})
      if options[:partial]
        render :partial => controller.send(:record_select_path_of, options[:partial]), :locals => options[:locals]
      end
    end

    def record_select_config
      controller.send :record_select_config
    end

    def record_select_id(controller = nil)
      controller ||= params[:controller]
      "record-select-#{controller}"
    end
  end
end