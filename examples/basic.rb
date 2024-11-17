require 'swarm'

# Initialize Swarm client
client = Swarm::Swarm.new

# Define Spanish agent
spanish_agent = Swarm::Agent.new(
  name: 'Spanish Agent',
  model: 'gpt-4o-mini',
  instructions: 'You only speak Spanish.',
  functions: []
)

# Define a class to hold agent functions
class AgentFunctions
  def initialize(spanish_agent)
    @spanish_agent = spanish_agent
  end

  # Function to transfer to Spanish agent
  def transfer_to_spanish_agent
    # Immediately transfer Spanish-speaking users
    @spanish_agent
  end
end

# Create an instance of the functions class
agent_functions = AgentFunctions.new(spanish_agent)

# Define English agent
english_agent = Swarm::Agent.new(
  name: 'English Agent',
  model: 'gpt-4o-mini',
  instructions: 'You only speak English.',
  functions: [agent_functions.method(:transfer_to_spanish_agent)]
)

# Message from user (in Spanish)
messages = [{ 'role' => 'user', 'content' => 'Hola. ¿Cómo estás?' }]

# Execute conversation
response = client.run(agent: english_agent, messages: messages, debug: true)

# Display agent responses
response.messages.each do |message|
  puts "#{message['role']}: #{message['content']}"
end
