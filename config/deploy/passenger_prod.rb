set :rails_env, "passenger_prod"
set :domain,      "ravel.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/scv_prod/"
set :user, "deployer"
set :branch, "passenger_prod"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true


