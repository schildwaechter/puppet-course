# More

Let's have a look at the Puppet graph.
We had the setting in from the beginning, now lets create the pictures:
Inside the VM run
```bash
puppet resource package graphviz ensure=present
dot -Tpng ./opt/puppetlabs/puppet/cache/state/graphs/resources.dot -o /vagrant/resources.png
dot -Tpng ./opt/puppetlabs/puppet/cache/state/graphs/relationships.dot -o /vagrant/relationships.png
dot -Tpng ./opt/puppetlabs/puppet/cache/state/graphs/expanded_relationships.dot -o /vagrant/expanded_relationships.png
```
and take a look at the images in `workdir`.

