['stylesheets', 'images', 'javascripts'].each do |asset_type|
  public_dir = File.join(RAILS_ROOT, 'public', asset_type, 'record_select')
  FileUtils.rm_r public_dir
end