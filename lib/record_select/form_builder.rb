module RecordSelect
  module FormBuilder
    def record_select(association, options = {})
      reflection = @object.class.reflect_on_association(association)
      form_name = form_name_for_association(reflection)
      current = @object.send(association)
      options[:id] ||= "#{@object_name.gsub(/[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{association}"

      if [:has_one, :belongs_to].include? reflection.macro
        @template.record_select_field(form_name, current || reflection.klass.new, options)
      else
        options[:controller] ||= reflection.klass.to_s.pluralize.underscore
        @template.record_multi_select_field(form_name, current, options)
      end
    end

    private

    def form_name_for_association(reflection)
      key_name = (reflection.options[:foreign_key] || reflection.association_foreign_key)
      key_name += "s" unless [:has_one, :belongs_to].include? reflection.macro
      form_name = "#{@object_name}[#{key_name}]"
    end
  end
end
