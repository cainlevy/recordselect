$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'record_select'
require 'conditions'
require 'helpers'
require 'config'
require 'extensions/active_record'
$LOAD_PATH.shift

ActionController::Base.send(:include, RecordSelect)
ActionView::Base.send(:include, ActionView::Helpers::RecordSelectHelpers)

['stylesheets', 'images', 'javascripts'].each do |asset_type|
  public_dir = File.join(RAILS_ROOT, 'public', asset_type, 'record_select')
  local_dir = File.join(File.dirname(__FILE__), 'assets', asset_type)
  FileUtils.mkdir public_dir unless File.exists? public_dir
  Dir.entries(local_dir).each do |file|
    next if file =~ /^\./
    FileUtils.cp File.join(local_dir, file), public_dir
  end
end