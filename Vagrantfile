# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.define "debian" do |deb|
    deb.vm.box = 'debian/jessie64'
    deb.vm.synced_folder '.', '/vagrant', type: :virtualbox

    deb.vm.provision 'shell', inline: <<-EOP
      echo "deb http://ftp.debian.org/debian jessie-backports main" | tee --append /etc/apt/sources.list > /dev/null
      sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list
      apt-get update
      apt-get remove openjdk-7-jre-headless -y -q
      apt-get install git openjdk-8-jre curl -y -q
      gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
      curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby-1.7
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
      gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
      curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby-1.7
      usermod -a -G rvm vagrant
    EOP
  end

end
