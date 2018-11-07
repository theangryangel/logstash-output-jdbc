Gem::Specification.new do |s|
  s.name = 'logstash-output-jdbc'
  s.version = '5.4.0'
  s.licenses = ['Apache License (2.0)']
  s.summary = 'This plugin allows you to output to SQL, via JDBC'
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install 'logstash-output-jdbc'. This gem is not a stand-alone program"
  s.authors = ['the_angry_angel']
  s.email = 'karl+github@theangryangel.co.uk'
  s.homepage = 'https://github.com/theangryangel/logstash-output-jdbc'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'output' }

  # Gem dependencies
  #
  s.add_runtime_dependency 'logstash-core-plugin-api', ">= 1.60", "<= 2.99"
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_development_dependency 'logstash-devutils'

  s.requirements << "jar 'com.zaxxer:HikariCP', '2.7.2'"
  s.requirements << "jar 'org.apache.logging.log4j:log4j-slf4j-impl', '2.6.2'"

  s.add_development_dependency 'jar-dependencies'
  s.add_development_dependency 'ruby-maven', '~> 3.3'
  s.add_development_dependency 'rubocop', '0.41.2'
end
