require File.dirname(__FILE__) + '/lib/localization'
require File.dirname(__FILE__) + '/lib/extensions/active_record'

ActionController::Base.send(:include, RecordSelect)
ActionView::Base.send(:include, RecordSelect::Helpers)
ActionView::Helpers::FormBuilder.send(:include, RecordSelect::FormBuilder)

['stylesheets', 'images', 'javascripts'].each do |asset_type|
  public_dir = File.join(RAILS_ROOT, 'public', asset_type, 'record_select')
  local_dir = File.join(File.dirname(__FILE__), 'assets', asset_type)
  FileUtils.mkdir public_dir unless File.exists? public_dir
  Dir.entries(local_dir).each do |file|
    next if file =~ /^\./
    FileUtils.cp File.join(local_dir, file), public_dir
  end
end
