require 'capistrano/ext/multistage'
default_run_options[:pty] = true

set :default_stage, "taft_pass"
set :stages, %w(taft_pass)
set :scm, :git
set :repository,  "git@github.com:tastyhat/cul-blacklight-scv.git"
set :application, "scv"
set :use_sudo, false

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_shared do
    run "ln -nfs #{deploy_to}shared/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}shared/app_config.yml #{release_path}/config/app_config.yml"
  end

end


after 'deploy:update_code', 'deploy:symlink_shared'