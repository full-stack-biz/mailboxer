# frozen_string_literal: true

module Mailboxer
  class NamespacingCompatibilityGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    source_root File.expand_path('templates', __dir__)
    require 'rails/generators/migration'

    FILENAME = 'mailboxer_namespacing_compatibility.rb'

    source_root File.expand_path('templates', __dir__)

    def create_model_file
      migration_template FILENAME, "db/migrate/#{FILENAME}"
    end

    def self.next_migration_number(_path)
      if @prev_migration_nr
        @prev_migration_nr += 1
      else
        @prev_migration_nr = Time.now.utc.strftime('%Y%m%d%H%M%S').to_i
      end
      @prev_migration_nr.to_s
    end
  end
end
