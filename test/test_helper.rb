RUBY_1_8 = defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'

exit(0) if RUBY_1_8

# Register `at_exit` handler for integration tests shutdown
# MUST be called before requiring 'test/unit'
if defined?(RUBY_VERSION) && RUBY_VERSION > '1.9'
  at_exit { Elasticsearch::Test::IntegrationTestCase.__run_at_exit_hooks }
end

require 'test/unit'
require 'shoulda-context'
require 'mocha/setup'
require 'pry-byebug'
require 'pry-alias'

require 'active_record'
require 'active_model'

require 'elasticsearch/model'

require 'elasticsearch/extensions/test/cluster'
require 'elasticsearch/extensions/test/startup_shutdown'

require 'globalize'


module Elasticsearch
  module Test
    class IntegrationTestCase < ::Test::Unit::TestCase
      extend Elasticsearch::Extensions::Test::StartupShutdown

      startup  { Elasticsearch::Extensions::Test::Cluster.start(nodes: 1) if ENV['SERVER'] and not Elasticsearch::Extensions::Test::Cluster.running? }
      shutdown { Elasticsearch::Extensions::Test::Cluster.stop if ENV['SERVER'] && started? }

      def setup
        ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )
        logger = ::Logger.new(STDERR)
        logger.formatter = lambda { |s, d, p, m| "#{m.ansi(:faint, :cyan)}\n" }
        ActiveRecord::Base.logger = logger unless ENV['QUIET']

        ActiveRecord::LogSubscriber.colorize_logging = false
        ActiveRecord::Migration.verbose = false

        tracer = ::Logger.new(STDERR)
        tracer.formatter = lambda { |s, d, p, m| "#{m.gsub(/^.*$/) { |n| '   ' + n }.ansi(:faint)}\n" }

        Elasticsearch::Model.client = Elasticsearch::Client.new host: "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9250)}",
                                                                tracer: (ENV['QUIET'] ? nil : tracer)

        I18n.enforce_available_locales = true
        I18n.available_locales = [:en, :ja]
      end
    end
  end
end