# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'

require 'appraisal'
require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

task 'appraisal:regenerate' => :environment do
  `bundle exec appraisal clean`
  `bundle exec appraisal generate`
end
