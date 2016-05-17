# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = 'debian/jessie64'
  config.vm.synced_folder '.', '/vagrant', type: :virtualbox

  config.vm.provision 'shell', inline: <<-EOP
    apt-get install git -y -q
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby-1.7
    usermod -a -G rvm vagrant
  EOP
end
