# capistranoのバージョン固定
lock "~> 3.11.0"

# デプロイするアプリケーション名
set :application, 'capsample'

# cloneするgitのレポジトリ
set :repo_url, 'git@github.com:yuya1212h4/capsample.git'

set :ssh_options, auth_methods: ['publickey'],
                  keys: ['~/.ssh/google_compute_engine']

# deployするブランチ。デフォルトはmasterなのでなくても可。
set :branch, 'master'

# deploy先のディレクトリ。
set :deploy_to, '/var/www/capsample'

# シンボリックリンクをはるファイル。(※後述)
# set :linked_files, fetch(:linked_files, []).push('config/settings.yml')

# シンボリックリンクをはるフォルダ。(※後述)
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# 保持するバージョンの個数(※後述)
set :keep_releases, 5

# rubyのバージョン
set :rbenv_ruby, '2.5.1'
set :bundle_binstubs, -> { shared_path.join('bin') }

#出力するログのレベル。
set :log_level, :debug

namespace :deploy do

  # task :init_permission do
  #   on release_roles :all do
  #     execute :sudo, :chown, '-R', "#{fetch(:user)}:#{fetch(:group)}", deploy_to
  #   end
  # end
  #
  # task :reset_permission do
  #   on release_roles :all do
  #     execute :sudo, :chown, '-R', "nginx:nginx", deploy_to
  #   end
  # end
  #
  # before :starting, :init_permission
  # after :finished, :reset_permission

  # Rake::Task["deploy:check:directories"].clear
  # Rake::Task["deploy:check:linked_dirs"].clear

  namespace :check do
    desc '(overwrite) Check shared and release directories exist'
    task :directories do
      on release_roles :all do
        execute :sudo, :mkdir, '-pv', shared_path, releases_path
      end
    end

    task :linked_dirs do
      next unless any? :linked_dirs
      on release_roles :all do
        execute :sudo, :mkdir, '-pv', linked_dirs(shared_path)
      end
    end
  end

  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart'
  end

  desc 'Create database'
  task :db_create do
    on roles(:db) do |host|
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:create'
        end
      end
    end
  end

  desc 'Run seed'
  task :seed do
    on roles(:app) do
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:seed'
        end
      end
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end
end
