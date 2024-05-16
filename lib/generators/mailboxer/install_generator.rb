# frozen_string_literal: true

module Mailboxer
  class InstallGenerator < Rails::Generators::Base # :nodoc:
    include Rails::Generators::Migration
    source_root File.expand_path('templates', __dir__)
    require 'rails/generators/migration'

    def self.next_migration_number(_path)
      if @prev_migration_nr
        @prev_migration_nr += 1
      else
        @prev_migration_nr = Time.now.utc.strftime('%Y%m%d%H%M%S').to_i
      end
      @prev_migration_nr.to_s
    end

    def create_initializer_file
      template 'initializer.rb', 'config/initializers/mailboxer.rb'
    end

    def copy_migrations
      require 'rake'
      Rails.application.load_tasks
      Rake::Task['railties:install:migrations'].reenable
      Rake::Task['mailboxer_engine:install:migrations'].invoke
    end
  end
end
