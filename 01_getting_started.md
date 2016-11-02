# Getting started

## The Vagrant VM

Begin by creating your `workdir` with the following `Vagrantfile`:
```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "dariah-xenial-p4"
  config.vm.box_url = "https://ci.de.dariah.eu/dariah-vagrant/dariah-xenial-p4/metadata.json"

  config.vm.hostname = "box1.course.local"
  config.vm.network "private_network", ip: "192.168.33.161"

  config.vm.provider "virtualbox" do |vb|
    #vb.gui = true
    vb.name = "course-box1"
    vb.customize ["modifyvm", :id, "--memory", "736"]
    vb.customize ["modifyvm", :id, "--nictype1", "Am79C973"]
    vb.customize ["modifyvm", :id, "--nictype2", "Am79C973"]
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.auto_detect = false
    config.cache.enable :apt
  end
end
```

A simple `vagrant up` will now start a virutal machine.
On first use, it will download the DARIAH Vagrant VM based on Ubuntu 16.04 LTS Xenial with Puppet 4 pre-installed.
You will notice that the Hostname gets set to a defined Name and the IP is a local one.
Furthermore some Virtualbox settings, such as the VM Memory and the Network interfaces are configure.
In particular, two interfaces are set up, one will work as a NAT via your system, the other can be used to model the behaviour of the VM with external ports as in production.
To make this work, add `192.168.33.161 box1.course.local` to your own `/etc/hosts` or the Windows equivalent.
The final block configures the `vagrant-cachier` plugin, should you have it.
This will store the packages you install outside the VM and if you throw it away and recreate it, you will not need to download them again.

Once it is up and running, you can check it out by connecting to it with `vagrant ssh`.
The user `vagrant` has password-less sudo rights.

## First Puppet Code

Now lets get some `puppet` rolling.
Create a directory `puppetcode` and inside create the `manifests` folder and inside create a `vagrant.pp` with the follwing contents:
```puppet
# Vagrant Puppet manifest
node 'box1.course.local' {

  notify {'Hello world':}

}
```
and in the `Vagrantfile` now add
```
  config.vm.provision "puppet" do |puppet|
    puppet.environment_path = "."
    puppet.environment = "puppetcode"
    puppet.options = "--show_diff --graph"
  end
```
to the config block, i.e. before the final `end`.

To enable Vagrant to use the new config, run `vagrant reload` to restart the VM with the new settings active.
Now simply run `vagrant provision`.

You will see Vagrant running Puppet and the output should contain
```
==> default: Notice: Hello world
==> default: Notice: /Stage[main]/Main/Node[box1.course.local]/Notify[Hello world]/message: defined 'message' as 'Hello world'
```
The first line is the actual result of the above Puppet code, the second is the Puppet log about the event.
Let's look at a more realistic example with:
```puppet
node 'box1.course.local' {
  package {'ntp':
    ensure => present,
  }
}
```
This time, the output from `vagrant provision` should show
```
==> default: Notice: /Stage[main]/Main/Node[box1.course.local]/Package[ntp]/ensure: ensure changed 'purged' to 'present'
```
Showing that the package was installed. Yet, another provision will of course not have any effects. 

Now, apart from installing `ntp`, we obviously want to make sure its daemon is running:
```puppet
node 'box1.course.local' {
  package {'ntp':
    ensure => present,
  }
  service {'ntp':
    ensure  => running,
    require => Package['ntp'],
  }
}
```
While the definition of the service itself should be stright forward, the require statement is not.
This parameter can given passed to any resource and introduces a dependency between the `ntp` package and the `ntp` service.
This ensures that the service is only started, once the package has been installed and thereby the service.
While Puppet will check these things in the order you put them in the file, this is only true as long as they are in the very same file.
Once your code becomes more complex this will change, and it is even encouraged to seperate definitions for packages and services, we will see that later.

Now when you run `vagrant provision` again, you will not see any output.
Since the service was automatically started following the installation, this is expected.
However, try turning it off manually: `vagrant ssh -c 'sudo service ntp stop'` and provision once more.
Now puppet will start the daemon.

