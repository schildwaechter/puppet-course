# More

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

