# encoding: utf-8
require 'logstash/devutils/rake'
require 'jars/installer'
require 'rubygems'

desc 'Fetch any jars required for this plugin'
task :install_jars do
  ENV['JARS_HOME'] = Dir.pwd + '/vendor/jar-dependencies/runtime-jars'
  ENV['JARS_VENDOR'] = 'false'
  Jars::Installer.new.vendor_jars!(false)
end
