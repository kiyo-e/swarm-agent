# frozen_string_literal: true

module Swarm
  class Agent
    attr_accessor :name, :model, :instructions, :functions, :tool_choice

    def initialize(name:, model:, instructions:, functions: [], tool_choice: 'auto')
      @name = name
      @model = model
      @instructions = instructions
      @functions = functions
      @tool_choice = tool_choice
    end
  end
end
