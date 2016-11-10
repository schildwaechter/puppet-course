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
We have two servers:
* the webserver hosting our *SimpleSearchApp* and elasticsearch node
* an elasticsearch cluster node
Each of those is a role.

Than we have components:
* ElasticSearch
* Apache
* Ntp
and more, each modelled by a profile.

The *searchapp* role will load the *elastic* profile, the *searchapp* profile and the *default* profile will load things such as Ntp. Later the *cluster* role will include the *elastic* and *default* profiles only.

Our application, the *SimpleSearchApp* is a simple singe page app, that consists of static code located in
`workdir/simplesearchapp`.
We'll load that directly into the VM by adding 
```
  config.vm.synced_folder "simplesearchapp", "/opt/simplesearchapp"
```
to the `Vagrant` file.

## Setup


Let's get started with getting the upstream modules via `Puppetfile`:
```
forge 'https://forgeapi.puppetlabs.com'

mod 'puppetlabs-apache', '1.10.0'
mod 'puppetlabs-motd', '1.4.0'
mod 'puppetlabs-ntp', '4.2.0'
mod 'puppetlabs-stdlib', '4.12.0'
mod 'elasticsearch-elasticsearch', '0.14.0'
```

We need to make a distinction between the component modules and the roles and profiles.
While the latter are modules as any other, we will not be loading them the same way.
Instead we keep them directly in our repository.
But since `librarian-puppet` will throw away anything foreign from the `modules` directory, we need to have the roles and profiles elsewhere.
It is custom to put them in the `site` directory. So create that inside the `puppetcode` directory and tell Puppet that we will be loading modules from there by creating an `environment.conf` with the contents
```ini
modulepath = site:modules
```
And create the directories:
```
mkdir -p site/roles/manifests
mkdir -p site/profiles/manifests
```
before reloading the Vagrant VM.

Create the SearchApp role in `site/roles/manifests/searchapp.pp` as
```puppet
class roles::searchapp {
  include '::profiles::elastic'
  include '::profiles::simplesearchapp'
}
```
and the `simplesearchapp` profile in `site/profiles/manifests/simplesearchapp.pp`
```puppet
class profiles::simplesearchapp {
  include '::profiles::defaults'
}
```
our `defaults` profile in `site/profiles/manifests/defaults.pp` simply has
```puppet
class profiles::defaults {
  class {'::ntp':
    servers => ['ntps1.gwdg.de', 'ntps2.gwdg.de', 'ntps3.gwdg.de'],
  }
  class {'::motd':
    content => "Welcome to ${facts['fqdn']} running on ${facts['lsbdistid']} ${facts['lsbdistrelease']}!",
  }
}
```
while the `vagrant.pp` now becomes
```puppet
node 'box1.course.local' {
  include '::roles::searchapp'
}
```

When you apply this, no changes should happen as we are still basically applying the same code as before.
But now we could easily add another VM and make a databse server without duplicating the code.
Note: We have of course not done any database/mysql setup yet, that will be the exercise later.

So lets add the actual setup
```puppet
class profiles::simplesearchapp {

  include '::profiles::defaults'

  include '::profiles::apache'

  include '::apache::mod::proxy'

  apache::vhost { $facts['fqdn']:
    port    => '80',
    docroot => '/opt/simplesearchapp',
  }

  apache::vhost { "${facts['fqdn']}_9222":
    port    => '9222',
    docroot => '/opt/simplesearchapp',
    proxy_pass => [
      { 'path' => '/', 'url' => 'http://localhost:9200/' },
    ]
  }

}
```
and
```puppet
class profiles::apache {
  include '::profiles::defaults'
  class { '::apache':
    default_vhost => false,
  }
}
```



Now you my have seen those mentions of *Hiera* in the warning.
Hiera is a hierarchical key-value-store that we will use now.

First create a `hieradata` directory inside `puppetcode` and a `hiera.yaml` in the `workdir` with contents
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
  :datadir: "/tmp/vagrant-puppet/environments/%{::environment}/hieradata"
```
and change the Vagrantfile to
```ruby
  config.vm.provision "puppet" do |puppet|
    puppet.environment_path = "."
    puppet.environment = "puppetcode"
    puppet.hiera_config_path = "hiera.yaml"
    puppet.options = "--show_diff --graph"
  end
```

Now what hiera does is look up variables according to the hierachy defined above.
Based on the node's facts `$facts['fqdn']`=`$::fqdn`, `$facts['environment']`=`$::environment` and `$facts['datacenter']`=`$::datacenter` it will try finding files matching the resolved names from the above list starting from top.
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


