fedora_config_file = RAILS_ROOT + "/config/fedora.yml"


if File.exists?(fedora_config_file)
  raw_config = File.read(RAILS_ROOT + "/config/fedora.yml")
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[RAILS_ENV] || {}
  FEDORA_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
end
