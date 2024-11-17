# frozen_string_literal: true

require 'json'
require 'openai'
require 'swarm/version'
require 'swarm/agent'
require 'swarm/response'
require 'swarm/result'
require 'swarm/swarm'

module Swarm
  class Error < StandardError; end
end
