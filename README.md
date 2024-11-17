# Swarm

Swarm is a Ruby library that simplifies the use of OpenAI API for chat completion and function calling.

This project was inspired by [OpenAI's swarm repository](https://github.com/openai/swarm).

## Installation

Add this line to your Gemfile:

```ruby
gem 'swarm'
```

And then execute:

```bash
$ bundle install
```

Or install it directly:

```bash
$ gem install swarm
```

## Usage

### Basic Usage

```ruby
require 'swarm'

# Create an agent
agent = Swarm::Agent.new(
  name: "assistant",
  model: "gpt-4o-mini",
  instructions: "You are a helpful assistant.",
)

# Create a Swarm instance
swarm = Swarm::Swarm.new

# Execute chat
response = swarm.run(
  agent: agent,
  messages: [
    { role: "user", content: "Hello!" }
  ]
)

puts response.messages.last["content"]
```

### Using Function Calling

```ruby
def get_weather(location:)
  "The weather in #{location} is sunny"
end

agent = Swarm::Agent.new(
  name: "weather_bot",
  model: "gpt-4o-mini",
  instructions: "I am a weather information bot.",
  functions: [method(:get_weather)]
)

swarm = Swarm::Swarm.new

response = swarm.run(
  agent: agent,
  messages: [
    { role: "user", content: "What's the weather in Tokyo?" }
  ]
)
```

### Using Streaming Response

```ruby
swarm.run(
  agent: agent,
  messages: messages,
  stream: true
) do |chunk|
  print chunk.dig("delta", "content")
end
```

## Environment Variables

- `OPENAI_API_KEY`: Set your OpenAI API key.

## Development

Bug reports and pull requests are welcome at https://github.com/kiyo-e/swarm.

## License

This gem is available as open source under the terms of the [MIT License](LICENSE.txt).
