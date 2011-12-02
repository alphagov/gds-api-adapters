require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/utils'
require 'simplecov'

SimpleCov.start
WebMock.disable_net_connect!
