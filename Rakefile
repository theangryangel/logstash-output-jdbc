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

def colourize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

desc 'Pre-release checks'
task :pre_release_checks do

  if `git status --porcelain`.chomp.length > 0
    warn colourize(' ✘ ', 31) + 'You have unstaged or uncommitted changes! Please only release from a clean working directory!'
  else
    puts colourize(" ✔ ", 32) + ' No un-staged commits'
  end

  spec = Gem::Specification::load("logstash-output-jdbc.gemspec")
  expected_tag_name = "v#{spec.version}"

  current_tag_name = `git describe --exact-match --tags HEAD 2>&1`.chomp
  if $?.success? and current_tag_name == expected_tag_name
    puts colourize(' ✔ ', 32) + 'Tag matches current HEAD'
  elsif $?.success? and current_tag_name == expected_tag_name
    warn colourize(' ✘ ', 31) + "Expected git tag to be '#{expected_tag_name}', but got '#{current_tag_name}'." 
  else
    warn colourize(' ✘ ', 31) + "Expected git tag to be '#{expected_tag_name}, but got nothing."
  end
  
end
