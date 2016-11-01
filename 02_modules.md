# Modules

There are lots of existing Puppet solutions for all kinds of software and tools available.
While you can find much on GitHub, there is also the [Puppet Forge](https://forge.puppet.com/) as the standard platform, where Puppet code gets distributed as modules.
A module is a collection of classes of puppet code, that can be used as a unit.

Let's start by adding Modules to the Vagrant definition. Replace the relevant part of the Vagrantfile:
```ruby
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.manifest_file = "vagrant.pp"
    puppet.options = "--show_diff"
  end
```
and create the `modules` directory and reload the Vagrant VM.

We will use the official [Puppet ntp module](https://forge.puppet.com/puppetlabs/ntp).
As we are using Puppet 3, we will need an older version, that we need put in the `modules` directory.

There are two offical ways to install the module (besides manual download):
1. install via Puppet command line
2. install via `Puppetfile`

## Using `puppet module install`

We start with the first solution, using the puppet on the Vagrant VM and the fact, that `workdir` is mounted there on `/vagrant`:
Log into the VM by running `vagrant ssh` and execute

```
puppet module install puppetlabs-ntp --version 4.2.0 --modulepath /vagrant/modules
```

You will see that it automatically installs the `stdlib` module as a dependency.
Of course you can run the command by passing it to `vagrant ssh -c`, but that will suppress any output.

Now lets replace our Puppet manifest by
```puppet
node 'box1.course.local' {
  include '::ntp'
}
``` 
This will load the `ntp` module, or more specifically the global `ntp` class, hence the two colons at the beginning.

When applying this, you will see a lot of changes to the `ntp` config, as we are now using the defaults from the module we installed.
In particular, the nameservers have been switched to `0.debian.pool.ntp.org` through `3.debian.pool.ntp.org`.
Now you also understand why we added the `--show-diff` option earlier.

Let's change that.
Instead of just including the module with the default settings as we did above, let's give it some parameters
```puppet
node 'box1.course.local' {
  class {'::ntp':
    servers => ['ntps1.gwdg.de', 'ntps2.gwdg.de', 'ntps3.gwdg.de'],
  }
}
```
and observe the result.
Feel free to play with other parameters.

## Using the `Puppetfile`

Another method for handling Puppet modules is the [`Puppetfile`](https://docs.puppet.com/pe/latest/cmgmt_puppetfile.html) used by [`librarian-puppet`](http://librarian-puppet.com/) and [`r10k`](https://github.com/puppetlabs/r10k) or Puppet Enterprise's code manager.
Create the `Puppetfile` in the `workdir` with the contents
```
forge "https://forgeapi.puppet.com"
mod 'puppetlabs-motd', '1.4.0'
mod 'puppetlabs-ntp', '4.2.0'
mod 'puppetlabs-stdlib', '4.13.1'
```

This contains the `ntp` and `stdlib` modules from before and the `motd` module, we will be using soon.

To make use of the `Puppetfile` we will use `librarian-puppet` which we install as a Gem inside the Vagrant VM.
As root inside the VM (`vagrant ssh` and `sudo -i`) do
```
puppet resource package librarian-puppet ensure=present provider=gem 
```
which is equivalent to the puppet code
```puppet
package {'librarian-puppet':
  ensure   => present,
  provider => 'gem',
}
```
We will also need git: `puppet resource package git ensure=present`.
Now from `/vagrant` run `librarian-puppet update --verbose` and observe the output. 
You will see that it first looked up all versions of the Modules listed in the Puppetfile and their dependencies and than recursively checked that they fulfill their (inter-)dependencies.
The result of this was written to `Puppetfile.lock`.

Finally `puppet module install` was used to install four modules, including the `registry` module as dependency of the `motd` Module for windows clients, as specified by the `Puppetfile.lock`.
By running `librarian-puppet install` the modules can even be installed as per the lock file without dependency resolution.

Note that `r10k`, the competitor to `librarian-puppet` is much more efficient in installing modules but can not handle dependencies.

The Puppetfile supports much more than just downloading from Puppet forge.
You can use git repositories as sources for modules and more. Have a look at the documentation.

