# -*- mode: ruby -*-
# vi: set ft=ruby :

JRUBY_VERSION = "jruby-1.7"

Vagrant.configure(2) do |config|

  config.vm.define "debian" do |deb|
    deb.vm.box = 'debian/stretch64'
    deb.vm.synced_folder '.', '/vagrant', type: :virtualbox

    deb.vm.provision 'shell', inline: <<-EOP
      apt-get update
      apt-get install openjdk-8-jre ca-certificates-java git curl -y -q
      curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
      curl -sSL https://get.rvm.io | bash -s stable --ruby=#{JRUBY_VERSION}
      usermod -a -G rvm vagrant
    EOP
  end

  config.vm.define "centos" do |centos|
    centos.vm.box = 'centos/7'
    centos.ssh.insert_key = false # https://github.com/mitchellh/vagrant/issues/7610
    centos.vm.synced_folder '.', '/vagrant', type: :virtualbox

    centos.vm.provision 'shell', inline: <<-EOP
      yum update
      yum install java-1.7.0-openjdk
      curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
      curl -sSL https://get.rvm.io | bash -s stable --ruby=#{JRUBY_VERSION}
      usermod -a -G rvm vagrant
    EOP
  end

end
