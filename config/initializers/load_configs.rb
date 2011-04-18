fedora_config_file = RAILS_ROOT + "/config/fedora.yml"
creds_config_file = RAILS_ROOT + "/config/fedora_credentials.yml"

if File.exists?(fedora_config_file)
  raw_config = File.read(fedora_config_file)
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[RAILS_ENV] || {}
  FEDORA_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
end
if File.exists?(creds_config_file)
  raw_config = File.read(creds_config_file)
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[RAILS_ENV] || {}
  FEDORA_CREDENTIALS_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
end

