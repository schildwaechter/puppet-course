# Modules

There are lots of existing Puppet solutions for all kinds of software and tools available.
While you can find much on GitHub, there is also the [Puppet Forge](https://forge.puppet.com/) as the standard platform, where Puppet code gets distributed as modules.
A module is a collection of classes of puppet code, that can be used as a unit.

By default, modules live in the `modules` directory of your environment, so create that directory in `puppetcode`.

We will use the official [Puppet ntp module](https://forge.puppet.com/puppetlabs/ntp).
We will rely on older version, that we need put in the `modules` directory.

There are two offical ways to install the module (besides manual download):

1. install via Puppet command line
2. install via `Puppetfile`

## Using `puppet module install`

We start with the first solution, using the puppet on the Vagrant VM and the fact, that `workdir` is mounted there on `/vagrant`:
Log into the VM by running `vagrant ssh` and execute

```
puppet module install puppetlabs-ntp --version 4.2.0 --modulepath /vagrant/puppetcode/modules
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
Create the `Puppetfile` in the `puppetcode` directory with the contents
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
Notice that the command also outputs some puppet code showing what it actually did.

We will also need git: `puppet resource package git ensure=present`.
Now from `/vagrant/puppetcode` run `librarian-puppet update --verbose` and observe the output. 
You will see that it first looked up all versions of the Modules listed in the Puppetfile and their dependencies and than recursively checked that they fulfill their (inter-)dependencies.
The result of this was written to `Puppetfile.lock`.

Finally `puppet module install` was used to install four modules, including the `registry` module as dependency of the `motd` Module for windows clients, as specified by the `Puppetfile.lock`.
By running `librarian-puppet install` the modules can even be installed as per the lock file without dependency resolution.

Note that `r10k`, the competitor to `librarian-puppet`, is much more efficient and faster in installing modules but can not handle dependencies.

The Puppetfile supports much more than just downloading from Puppet forge.
You can use git repositories as sources for modules and more. Have a look at the documentation.

## Variables

Since we already installed the `motd` module, lets use it by adding this to our puppet code:
```puppet
  class {'::motd':
    content => "Welcome to ${::fqdn} running on ${::lsbdistid} ${::lsbdistrelease}!",
  }
```
Notice that we are using variables in the string passed as content to the motd.
The `$::fqdn` variable holds the fully qualified domain name of the node, while
`$::lsbdistid` and `$::lsbdistrelease` are LSB distribution information.
These variables are so-called *fact*s that puppet knows about the machine.
To see all facts available to puppet run `facter -y -p` as root in the VM.

Note that the modules can add facts that puppet will than know and you can even add your own.

You can also define your own variables, e.g. by
```puppet
  $motd_string_a = "Welcome to ${::fqdn} running on ${::lsbdistid} ${::lsbdistrelease}!"
  $motd_string_b = "This system was provision by puppet ${::uptime} after boot."
  $motd_string = "${motd_string_a}${motd_string_b}"
  class {'::motd':
    content => $motd_string,
  }
```
although they should be called constants, since you can only set them once, i.e. you can't change variables.
Rember: Puppet defines a state and even a variable can only have one state or content, although that my change every run.

