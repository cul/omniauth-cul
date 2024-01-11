# frozen_string_literal: true

require_relative "lib/omniauth/cul/version"

Gem::Specification.new do |spec|
  spec.name = "omniauth-cul"
  spec.version = Omniauth::Cul::VERSION
  spec.authors = ["Eric O"]
  spec.email = ["elo2112@columbia.edu"]

  spec.summary = "A devise omniauth adapter for Rails apps, using Columbia University authentication."
  spec.homepage = "https://github.com/cul/omniauth-cul"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.5"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "devise", ">= 4.9"
  spec.add_dependency "omniauth", ">= 2.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
