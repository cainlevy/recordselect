require 'record_select'
require 'rendering'

ActionController::Base.send(:include, RecordSelect)
ActionView::Base.send(:include, RecordSelect::Rendering)
ActionController::Base.send(:include, RecordSelect::Rendering)