Gem::Specification.new do |s|
  s.name = 'logstash-output-jdbc'
  s.version = "0.3.2"
  s.licenses = [ "Apache License (2.0)" ]
  s.summary = "This plugin allows you to output to SQL, via JDBC"
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["the_angry_angel"]
  s.email = "karl+github@theangryangel.co.uk"
  s.homepage = "https://github.com/theangryangel/logstash-output-jdbc"
  s.require_paths = [ "lib" ]

  # Java only
  s.platform = 'java'

  # Files
  s.files = Dir.glob('{lib,spec}/**/*.rb') + Dir.glob('vendor/**/*') + %w(LICENSE.txt README.md)

   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '~> 1.0'
  s.add_runtime_dependency 'stud'
  s.add_runtime_dependency 'logstash-codec-plain'

  s.requirements << "jar 'com.zaxxer:HikariCP', '2.4.2'"
  s.requirements << "jar 'org.slf4j:slf4j-log4j12', '1.7.21'"

  s.add_development_dependency 'jar-dependencies'
  s.add_development_dependency 'ruby-maven', '~> 3.3'

  s.add_development_dependency 'logstash-devutils'

  s.add_development_dependency 'rubocop', '0.41.2'
end
