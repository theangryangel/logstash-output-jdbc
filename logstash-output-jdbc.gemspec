Gem::Specification.new do |s|
  s.name = 'logstash-output-jdbc'
  s.version = "0.2.6-rc1"
  s.licenses = [ "Apache License (2.0)" ]
  s.summary = "This plugin allows you to output to SQL, via JDBC"
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["the_angry_angel"]
  s.email = "karl+github@theangryangel.co.uk"
  s.homepage = "https://github.com/theangryangel/logstash-output-jdbc"
  s.require_paths = [ "lib" ]

  # Files
  s.files = Dir.glob("{lib,vendor,spec}/**/*") + %w(LICENSE.txt README.md)

   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 2.0.0.beta2", "< 3.0.0"
  s.add_runtime_dependency 'stud'
  s.add_runtime_dependency "logstash-codec-plain"
  
  s.add_development_dependency "logstash-devutils"

  s.post_install_message = "logstash-output-jdbc 0.2.0 introduces several new features - please ensure you check the documentation in the README file"
end
