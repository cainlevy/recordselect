module RecordSelect
  module Rendering
    def render_record_select(options = {})
      if self.is_a? ActionView::Base
        render :template  => record_select_path_of("_#{partial}")

      elsif self.is_a? ActionController::Base
        if action = options.delete(:action)
          render :template  => record_select_path_of(action), :layout => options[:layout]
        elsif partial = options.delete(:partial)
          render :template => record_select_path_of("_#{partial}"), :layout => options[:layout]
        end

      else
        raise "context error: #{self.class} is unknown"
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
end
