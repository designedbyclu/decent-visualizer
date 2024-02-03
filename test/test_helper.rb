# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

require "rails/test_help"
require "minitest/unit"
require "webmock/minitest"

require "redlock/testing"
Redlock::Client.testing_mode = :bypass

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      ActionCable.server.pubsub.clear
      WebMock.disable_net_connect!
    end

    teardown do
      WebMock.reset!
    end
end
end
