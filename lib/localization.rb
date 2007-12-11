# Provides a simple pass-through localizer for RecordSelect. If you want
# to localize RS, you need to override this method and route it to your
# own system.
class Object
  def rs_(string_to_localize, *args)
    args.empty? ? string_to_localize : (sprintf string_to_localize, *args)
  end
end
