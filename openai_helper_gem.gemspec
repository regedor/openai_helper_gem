Gem::Specification.new do |spec|
  spec.name          = "openai_helper_gem"
  spec.version       = "0.1.1"  
  spec.authors       = ["Miguel Regedor"]
  spec.email         = ["miguelregedor@gmail.com"]
  spec.summary       = "A Ruby module to simplify interactions with OpenAI's API."
  spec.description   = "OpenAIHelperGem is a Ruby module designed to enhance productivity by integrating OpenAI's capabilities into local scripts. It allows file uploads, structured output extraction, text-to-speech generation, and automatic audio playback, ideal for automation and workflow enhancement on macOS."
  spec.homepage      = "https://github.com/regedor/openai_helper_gem"
  spec.license       = "MIT"

  spec.files         = Dir.glob("lib/**/*") + ["README.md", "LICENSE.txt"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "net-http", "~> 0.1"
  spec.add_runtime_dependency "json", "~> 2.0"
  spec.add_runtime_dependency "fileutils", "~> 1.4"  
  spec.add_runtime_dependency "base64", "~> 0.1"    
end