require "rdoc/task"
require "rake/testtask"

RDoc::Task.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

Rake::TestTask.new("test") do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

Rake::TestTask.new("pact_test") do |t|
  t.libs << "test"
  t.test_files = FileList["test/pacts/**/*_test.rb"]
  t.warning = false
end

task default: %i[lint test]

require "pact_broker/client/tasks"

PactBroker::Client::PublicationTask.new do |task|
  task.consumer_version = ENV.fetch("PACT_CONSUMER_VERSION")
  task.pact_broker_base_url = ENV.fetch("PACT_BROKER_BASE_URL")
  task.pact_broker_basic_auth = {
    username: ENV.fetch("PACT_BROKER_USERNAME"),
    password: ENV.fetch("PACT_BROKER_PASSWORD"),
  }
  task.pattern = ENV["PACT_PATTERN"] if ENV["PACT_PATTERN"]
end

desc "Run the linter against changed files"
task :lint do
  sh "bundle exec rubocop"
end
