require_relative "lib/journeybook/version"

Gem::Specification.new do |spec|
  spec.name        = "journeybook"
  spec.version     = Journeybook::VERSION
  spec.authors     = [ "talent journey" ]
  spec.email       = [ "opensource@talent-journey.com" ]
  spec.homepage    = "https://github.com/talent-journey/journeybook"
  spec.summary     = "Markdown-first CMS primitives for Rails applications."
  spec.description = "Journeybook is a mountable Rails engine for reusable, code-defined CMS content rendering."
  spec.license     = "MIT"

  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  root_files = %w[CHANGELOG.md MIT-LICENSE README.md Rakefile]
  tracked_files = `git ls-files -z`.split("\x0").select do |file|
    file.match?(%r{\A(?:app|config|db|lib)/}) || root_files.include?(file)
  end
  spec.files = tracked_files | root_files.select { |file| File.file?(file) }

  spec.required_ruby_version = ">= 3.4"

  spec.add_dependency "commonmarker", ">= 1.1"
  spec.add_dependency "aws-sdk-s3", ">= 1.150"
  spec.add_dependency "importmap-rails", ">= 2.0"
  spec.add_dependency "rails", ">= 8.0", "< 9.0"
  spec.add_dependency "rouge", ">= 4.0"
  spec.add_dependency "stimulus-rails", ">= 1.3"
end
