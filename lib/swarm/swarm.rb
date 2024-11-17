# frozen_string_literal: true

module Swarm
  CTX_VARS_NAME = 'context_variables'

  class Swarm
    attr_reader :client

    def initialize(client: nil)
      @client = client || OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    end

    def get_chat_completion(agent:, history:, context_variables:, model_override: nil, stream: false, debug: false)
      context_variables = Hash.new { |h, k| h[k] = '' }.merge(context_variables)
      instructions = if agent.instructions.respond_to?(:call)
                       agent.instructions.call(context_variables)
                     else
                       agent.instructions
                     end
      messages = [{ role: 'system', content: instructions }] + history
      debug_print(debug, 'Getting chat completion for:', messages)

      functions = agent.functions.map { |f| function_to_json(f) }

      functions.each do |function|
        params = function[:parameters]
        params[:properties].delete(CTX_VARS_NAME)
        params[:required]&.delete(CTX_VARS_NAME)
      end

      function_call_option = case agent.tool_choice
                             when 'required'
                               'auto'
                             when 'none'
                               'none'
                             else
                               'auto'
                             end

      create_params = {
        model: model_override || agent.model,
        messages: messages,
        functions: functions.empty? ? nil : functions,
        function_call: function_call_option,
        stream: stream
      }

      @client.chat(parameters: create_params)
    end

    def handle_function_result(result, debug)
      case result
      when Result
        result
      when Agent
        Result.new(value: { assistant: result.name }.to_json, agent: result)
      else
        begin
          Result.new(value: result.to_s)
        rescue StandardError => e
          error_message = "Failed to cast response to string: #{result}. Ensure that agent functions return a string or Result object. Error: #{e.message}"
          debug_print(debug, error_message)
          raise TypeError, error_message
        end
      end
    end

    def handle_function_calls(function_calls, functions, context_variables, debug)
      function_map = functions.each_with_object({}) { |f, h| h[f.name] = f }
      partial_response = Response.new(messages: [], agent: nil, context_variables: {})

      function_calls.each do |function_call|
        name = function_call['name'].to_sym
        if function_map.key?(name)
          args = JSON.parse(function_call['arguments'])
          debug_print(debug, "Processing function call: #{name} with arguments #{args}")

          func = function_map[name]
          if func.method(:call).parameters.any? { |_, param_name| param_name == CTX_VARS_NAME.to_sym }
            args[CTX_VARS_NAME] = context_variables
          end
          raw_result = func.call(**args.transform_keys(&:to_sym))

          result = handle_function_result(raw_result, debug)
          partial_response.messages << {
            role: 'function',
            name: name,
            content: result.value
          }
          partial_response.context_variables.merge!(result.context_variables || {})
          partial_response.agent = result.agent if result.agent
        else
          debug_print(debug, "Function #{name} not found in function map.")
          partial_response.messages << {
            role: 'function',
            name: name,
            content: "Error: Function #{name} not found."
          }
        end
      end

      partial_response
    end

    def run_and_stream(agent:, messages:, context_variables: {}, model_override: nil, debug: false, max_turns: Float::INFINITY, execute_functions: true)
      active_agent = agent
      context_variables = Marshal.load(Marshal.dump(context_variables))
      history = Marshal.load(Marshal.dump(messages))
      init_len = messages.length

      Enumerator.new do |y|
        while history.length - init_len < max_turns
          message = {
            content: '',
            sender: active_agent.name,
            role: 'assistant',
            function_call: nil
          }

          completion = get_chat_completion(
            agent: active_agent,
            history: history,
            context_variables: context_variables,
            model_override: model_override,
            stream: true,
            debug: debug
          )

          y << { delim: 'start' }
          completion.each do |chunk|
            delta = chunk.dig('choices', 0, 'delta') || {}
            delta['sender'] = active_agent.name if delta['role'] == 'assistant'
            y << delta
            delta.delete('role')
            delta.delete('sender')
            merge_chunk(message, delta)
          end
          y << { delim: 'end' }

          debug_print(debug, 'Received completion:', message)
          history << message

          function_call = message['function_call']
          if function_call.nil? || !execute_functions
            debug_print(debug, 'Ending turn.')
            break
          end

          function_calls = [function_call]
          partial_response = handle_function_calls(
            function_calls, active_agent.functions, context_variables, debug
          )
          history.concat(partial_response.messages)
          context_variables.merge!(partial_response.context_variables)
          active_agent = partial_response.agent if partial_response.agent
        end

        y << { response: Response.new(messages: history[init_len..], agent: active_agent, context_variables: context_variables) }
      end
    end

    def run(agent:, messages:, context_variables: {}, model_override: nil, stream: false, debug: false, max_turns: Float::INFINITY, execute_functions: true)
      if stream
        return run_and_stream(
          agent: agent,
          messages: messages,
          context_variables: context_variables,
          model_override: model_override,
          debug: debug,
          max_turns: max_turns,
          execute_functions: execute_functions
        )
      end

      active_agent = agent
      context_variables = Marshal.load(Marshal.dump(context_variables))
      history = Marshal.load(Marshal.dump(messages))
      init_len = messages.length

      while history.length - init_len < max_turns && active_agent
        completion = get_chat_completion(
          agent: active_agent,
          history: history,
          context_variables: context_variables,
          model_override: model_override,
          stream: false,
          debug: debug
        )
        message = completion.dig('choices', 0, 'message')
        debug_print(debug, 'Received completion:', message)
        message['sender'] = active_agent.name
        history << message

        function_call = message['function_call']
        if function_call.nil? || !execute_functions
          debug_print(debug, 'Ending turn.')
          break
        end

        function_calls = [function_call]
        partial_response = handle_function_calls(
          function_calls, active_agent.functions, context_variables, debug
        )
        history.concat(partial_response.messages)
        context_variables.merge!(partial_response.context_variables)
        active_agent = partial_response.agent if partial_response.agent
      end

      Response.new(
        messages: history[init_len..],
        agent: active_agent,
        context_variables: context_variables
      )
    end

    private

    def merge_fields(target, source)
      source.each do |key, value|
        if value.is_a?(String)
          target[key] = (target[key] || '') + value
        elsif value.is_a?(Hash)
          target[key] ||= {}
          merge_fields(target[key], value)
        end
      end
    end

    def merge_chunk(final_response, delta)
      delta.delete('role')
      merge_fields(final_response, delta)
    end

    def function_to_json(func)
      parameters = {}
      required = []

      begin
        func.parameters.each do |type, name|
          parameters[name.to_s] = { type: 'string' }
          required << name.to_s if type == :req
        end
      rescue StandardError => e
        raise ArgumentError, "Failed to get parameters for function #{func.name}: #{e.message}"
      end

      {
        name: func.name.to_s,
        description: func.respond_to?(:doc) ? func.doc : '',
        parameters: {
          type: 'object',
          properties: parameters,
          required: required
        }
      }
    end

    def debug_print(debug, *args)
      return unless debug

      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      message = args.map(&:to_s).join(' ')
      puts "\e[97m[\e[90m#{timestamp}\e[97m]\e[90m #{message}\e[0m"
    end
  end
end
