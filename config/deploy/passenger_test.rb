set :rails_env, "passenger_test"
set :domain,      "rhys.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/scv_test/"
set :user, "deployer"
set :branch, "passenger_test"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true

