set :rails_env, "passenger_dev"
set :domain,      "rowling.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/scv_dev/"
set :user, "deployer"
set :branch, "passenger_dev"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true

