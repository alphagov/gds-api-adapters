# -*- encoding: utf-8 -*-

require "rdoc/task"
require 'rake/testtask'

RDoc::Task.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

Rake::TestTask.new("test") do |t|
  t.ruby_opts << "-rubygems"
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end
task default: :test

require 'pact_broker/client/tasks'

def configure_pact_broker_location(task)
  task.pact_broker_base_url = ENV.fetch("PACT_BROKER_BASE_URL")
  if ENV['PACT_BROKER_USERNAME']
    task.pact_broker_basic_auth = { username: ENV['PACT_BROKER_USERNAME'], password: ENV['PACT_BROKER_PASSWORD'] }
  end
end

PactBroker::Client::PublicationTask.new("branch") do |task|
  task.consumer_version = ENV.fetch("PACT_TARGET_BRANCH")
  configure_pact_broker_location(task)
end

PactBroker::Client::PublicationTask.new("released_version") do |task|
  require 'gds_api/version'
  task.consumer_version = GdsApi::VERSION
  configure_pact_broker_location(task)
end

desc "Run the linter against changed files"
task :lint do
  sh "bundle exec govuk-lint-ruby --diff --cached --format clang"
end
