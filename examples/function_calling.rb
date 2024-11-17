# Load swarm.rb
require 'swarm'
require 'json'

# Initialize Swarm client
client = Swarm::Swarm.new

# Define a class to hold functions
class AgentFunctions
  def get_weather(location:)
    {
      "temperature" => 67,
      "unit" => "Fahrenheit",
      "description" => "Sunny with a chance of clouds",
      "location" => location
    }.to_json
  end
end

# Create an instance of the functions class
agent_functions = AgentFunctions.new

# Define agent
agent = Swarm::Agent.new(
  name: 'Agent',
  model: 'gpt-4o-mini', # Model that supports function calling
  instructions: 'You are a helpful assistant that provides weather information. Use the get_weather function to obtain weather data.',
  functions: [agent_functions.method(:get_weather)],
  tool_choice: 'auto'
)

# Message from user
messages = [{ 'role' => 'user', 'content' => "What's the weather in NYC?" }]

# Execute conversation
response = client.run(agent: agent, messages: messages, debug: true)

# Display agent responses
response.messages.each do |message|
  puts "#{message['role']}: #{message['content']}" if message['content']
end
