# Roles and Profiles

A now standard way to abstract Puppet code is the use of Roles and Profiles.
Up until now we have explicitly added config to the `box1.course.local` node.
Obviously this will not scale once we have even just a couple of systems.

This is where the de-facto standard way to abstract Puppet code via the use of Roles and Profiles comes in.

While from a technical view-point they are just modules like any other, we do treat them differently.

The idea is that each node gets assigned a single *role*.
But more than one server can have the same role. (Say several database servers.)

Each role loads any number of *profile*s.
Each profile configures a single unit or component of the system.
Usually this means it loads an upstream module and uses it a specific way.
Thus we will now refer to any other module as a *component module*.
Profiles can also include other profiles.

Now this may sound abstract, but lets have an example:
We have to servers:
* the database server
* the frontend webserver
Each of those is a role.

Than we have components:
* MySQL
* Apache
* Ntp
and more, each modelled by a profile.

The database role will load the MySQL profile and the Ntp profile while the webserver will include the Apache and the Ntp profile.

## Setup

To get started, we need to make another distinction between the component modules and the roles and profiles.
While the latter are modules as any other, we will not be loading them the same way.
Instead we keep them directly in our repository.
But since `librarian-puppet` will throw away anything foreign from the `modules` directory, we need to have the roles and profiles elsewhere.
It is custom to put them in the `site` directory. So create that inside the `workdir` and tell Puppet that we will be loading modules from there:
```ruby
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.module_path = ["site","modules"]
    puppet.manifest_file = "vagrant.pp"
    puppet.options = "--show_diff"
  end
```
And create the directories:
```
mkdir -p site/roles/manifests
mkdir -p site/profiles/manifests
```
before reloading the Vagrant VM.

Create the database role in `site/roles/manifests/database.pp` as
```puppet
class roles::database {
  include '::profiles::mysql'
}
```
and the `mysql` profile in `site/profiles/manifests/mysql.pp`
```puppet
class profiles::mysql {
  include '::profiles::defaults'
}
```
and the `defaults` profile in `site/profiles/manifests/defaults.pp`
```puppet
class profiles::defaults {
  class {'::ntp':
    servers => ['ntps1.gwdg.de', 'ntps2.gwdg.de', 'ntps3.gwdg.de'],
  }
  class {'::motd':
    content => "Welcome to ${::fqdn} running on ${::lsbdistid} ${::lsbdistrelease}!",
  }
}
```
while the `vagrant.pp` now becomes
```puppet
node 'box1.course.local' {
  include '::roles::database'
}
```

When you apply this, no changes should happen as we are still basically applying the same code as before.
But now we could easily add another VM and make a databse server without duplicating the code.
Note: We have of course not done any database/mysql setup yet, that will be the exercise later.

Now you my have seen those mentions of *Hiera* in the warning.
Hiera is a hierarchical key-value-store that we will use now.

First create a `hieradata` directory and a `hiera.yaml` in the `workdir` with contents
```yaml
---
:hierarchy:
    - "%{::fqdn}_private"
    - "%{::fqdn}_blackbox"
    - "%{::fqdn}"
    - "%{::environment}_blackbox"
    - "%{::environment}"
    - "%{::datacenter}_private"
    - "%{::datacenter}_blackbox"
    - "%{::datacenter}"
    - common
:backends:
    - yaml
:yaml:
    :datadir: 'hieradata'
```
and change the Vagrantfile to
```ruby
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.module_path = ["site","modules"]
    puppet.manifest_file = "vagrant.pp"
    puppet.hiera_config_path = "hiera.yaml"
    puppet.working_directory = "/vagrant"
    puppet.options = "--show_diff"
  end
```

Now what hiera does is look up variables according to the hierachy defined above.
Based on the node's facts `$::fqdn`, `$::environment` and `$::datacenter` it will try finding files matching the resolved names from the above list starting from top.
Inside those it will look for the first match of any variable that it is looking for.

## Using Hiera

Lets tell Puppet to look for some hiera variables by changing the `default` profile:
```puppet
class profiles::defaults (
  $ntp_servers = ['ntps1.gwdg.de', 'ntps2.gwdg.de', 'ntps3.gwdg.de'],
){
  class {'::ntp':
    servers => $ntp_servers,
  }
  class {'::motd':
    content => "Welcome to ${::fqdn} running on ${::lsbdistid} ${::lsbdistrelease}!",
  }
}
```
Applying these changes now will again not change anything.
But in the background, puppet will consult hiera for the variable `$::profiles::defaults::ntp_servers`.
If none is found, the default given above will be used.

So lets create a `hieradata/common.yaml` with
```yaml
---
profiles::defaults::ntp_servers:
  - 'ntps1.gwdg.de'
  - 'ntps2.gwdg.de'
```
i.e. stripping one from the above list.
Applying this new manifest will remove the third server from `ntp`'s config.

So lets add `hieradata/box1.course.local.yaml` with
```yaml
---
profiles::defaults::ntp_servers:
  - 'ntps3.gwdg.de'
```
A new `vagrant provision` will remove the previous two and just add the third.
This indirect lookup of class parameters from hiera stops at the first hit from the top.
With a little effort it is possible to merge the array over the hierachy.
But for now lets add all three servers to `common.yaml` and remove `hieradata/box1.course.local.yaml`.


