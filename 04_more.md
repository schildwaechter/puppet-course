# More

## The Graph

Let's have a look at the Puppet graph.
Let's change the `Vagrantfile` to say
```ruby
    puppet.options = "--show_diff --graph"
```
Now lets create the graph by runing another provision and than inside the VM run
```bash
puppet resource package graphviz ensure=present
dot -Tpng ./opt/puppetlabs/puppet/cache/state/graphs/resources.dot -o /vagrant/resources.png
dot -Tpng ./opt/puppetlabs/puppet/cache/state/graphs/relationships.dot -o /vagrant/relationships.png
dot -Tpng ./opt/puppetlabs/puppet/cache/state/graphs/expanded_relationships.dot -o /vagrant/expanded_relationships.png
```
and take a look at the images in `workdir`.

Alternatively you may want to open the original `.dot` files in [Gephi](https://gephi.org/).
This allows you to interactively investigate the graph, in particular if you encounter cycles.

You may want to upgrade the `ntp` and `stdlib` modules to the latest versions and test them.

## Syntax and Coding

There are tools than can help you write Puppet Code, such as syntax highlighting mentioned earlier.

There basic tools are the puppet parser and [`puppet-lint`](http://puppet-lint.com) with more [plugins](https://voxpupuli.org/plugins/#puppet-lint).

The parser is included by default, so from within the VM you may want to run
```shell
puppet parser validate /tmp/vagrant-puppet/environments/puppetcode/site/profiles/manifests/defaults.pp
```

Now this should not give any errors, since the code previously worked.
Use it to fix this code from
```puppet
class profiles::puppetlint {

  package {'puppet-lint':
    ensure  => installed
    provider => 'gem'
  }

  ensure_packages(['puppet-lint-empty_string-check',
                   'puppet-lint-file_ensure-check',
                   'puppet-lint-legacy_facts-check',
                   'puppet-lint-no_file_path_attribute-check',
                   'puppet-lint-unquoted_string-check',
                   'puppet-lint-resource_reference_syntax',
                   'puppet-lint-strict_indent-check',
                   'puppet-lint-trailing_comma-check',
                   'puppet-lint-trailing_newline-check',
                   'puppet-lint-unquoted_string-check',
                   'puppet-lint-variable_contains_upcase'],
                  {'ensure' => 'present', 'provider' => 'gem'})

 # https://docs.puppet.com/puppet/latest/reference/lang_collectors.html
 Package['puppet-lint'] -> Package <| tag == 'linting' |>

}
```

Now once you applied the fixed code, run `puppet-lint` on the same class.


## Multiple hosts

In the `Vagrantfile` duplicate the config stanza for `box1` and add a `box2`.
Than define it to include only an elasticsearch node.

Finally, mak sure they find each other.

