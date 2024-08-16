Gem::Specification.new do |spec|
  spec.name          = "openai_helper_gem"
  spec.version       = "0.1.0"
  spec.authors       = ["Miguel Regedor"]
  spec.email         = ["miguelregedor@gmail.com"]
  spec.summary       = "A Ruby module to simplify interactions with OpenAI's API."
  spec.description   = "OpenAIHelper is a Ruby module designed to enhance productivity by integrating OpenAI's capabilities into local scripts. It allows file uploads, structured output extraction, text-to-speech generation, and automatic audio playback."
  spec.homepage      = "http://example.com/openai_helper_gem"
  spec.license       = "MIT"

  spec.files         = Dir.glob("lib/**/*") + ["README.md", "LICENSE.txt"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "net-http", "~> 0.1"
  spec.add_runtime_dependency "json", "~> 2.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end