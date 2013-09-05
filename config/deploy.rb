require "bundler/capistrano" 

set :user,        'webuser'
set :application, "feedbin"
set :use_sudo,    false

set :scm,           :git
set :repository,    "git@github.com:chagel/feedbin.git"
set :branch,        'master'
set :keep_releases, 5
set :deploy_via,    :remote_cache

set :ssh_options, { forward_agent: true }
set :deploy_to,   "/home/webuser/www/#{application}"

# TODO see if this can be removed if `sudo bundle` stops failing
set :bundle_cmd, "/home/webuser/.rvm/gems/ruby-2.0.0-p247@global/bin/bundle"

# Gets rid of trying to link public/* directories
set :normalize_asset_timestamps, false

set :assets_role, [:app]

role :web, "weed30.com"
role :app, "weed30.com"
role :worker, "weed30.com"
set :rvm_sudo, "rvmsudo -p 'sudo password: '"

default_run_options[:pty] = true
default_run_options[:shell] = '/bin/bash --login'

namespace :foreman do

  # task :export_worker, roles: :worker do
  #   foreman_export = "foreman export --app #{application} --user #{user} --concurrency worker=3,worker_slow=2,clock=1 --log #{shared_path}/log upstart /etc/init"
  #   run "cd #{current_path} && #{rvm_sudo} #{bundle_cmd} exec #{foreman_export}"
  # end

  # desc 'Start the application services'
  # task :start do
  #   run "sudo start #{application}"
  # end

  # desc 'Stop the application services'
  # task :stop do
  #   run "sudo stop #{application}"
  # end

  desc 'Restart worker services'
  task :restart_worker, roles: :worker  do
    # run "sudo start #{application} || sudo restart #{application} || true"
    run "ps -ef | awk '/foreman/ && !/awk/ {print $2}' | xargs -r kill -9"
    run "cd #{current_path} && #{bundle_cmd} exec foreman start &"
  end
  
  desc "restart passenger"
  task :restart_web, roles: :web  do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  
end

# namespace :deploy do
#   desc 'Start the application services'
#   task :start do
#     foreman.start
#   end

#   desc 'Stop the application services'
#   task :stop do
#     foreman.stop
#   end
# end

# after 'deploy:update', 'foreman:export_worker'
after "deploy:restart", "foreman:restart_worker"
after "deploy:restart", "foreman:restart_web"
after "deploy:restart", "deploy:cleanup"
