require 'logstash/devutils/rake'
require 'jars/installer'
require 'rubygems'

desc 'Fetch any jars required for this plugin'
task :install_jars do
  ENV['JARS_HOME'] = Dir.pwd + '/vendor/jar-dependencies/runtime-jars'
  ENV['JARS_VENDOR'] = 'false'
  Jars::Installer.new.vendor_jars!(false)
end

desc 'Pre-release checks'
task :pre_release_checks do

  if `git status --porcelain`.chomp.length > 0
    raise "You have unstaged or uncommitted changes! Please only deploy from a clean working directory!"
  end

  spec = Gem::Specification::load("logstash-output-jdbc.gemspec")
  expected_tag_name = "v#{spec.version}"

  current_tag_name = `git describe --exact-match --tags HEAD`.chomp
  if $? == 0
    raise "Expected git tag to be '#{expected_tag_name}', but got '#{current_tag_name}'." if current_tag_name != expected_tag_name
  else
    raise "Expected git tag to be '#{expected_tag_name}, but got nothing."
  end
  
end
