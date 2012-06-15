## ledis.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ledis"
  spec.version = "0.0.1"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "ledis"
  spec.description = "description: ledis kicks the ass"

  spec.files =
["README.md", "Rakefile", "ledis.gemspec", "lib", "lib/ledis.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

### spec.add_dependency 'lib', '>= version'
#### spec.add_dependency 'map'

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ledis"
end
