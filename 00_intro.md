# Introduction

[Puppet](https://puppet.com/) is a configuration management tool.


On a very simplistic view, you as the user write a *manifest* containing a high-level description of the state your system should be in under a given set of conditions.

Than Puppet tranforms that along with the machines current conditions into a *catalog*.
It than startes to take the steps necessary, to ensure the state described in the manifest is realised on the system.

*Sidenote*: The catalog is actually a directed acyclic graph of *resources* managed on the system.


## Puppet agent & server

In traditional and larger setups, the manifest is stored on a central *puppet server*.
The systems to be configured – the *nodes* – run the *puppet agent* daemon.

The agent regularly contacts the server, sends its current state there and than retrieves its catalog.
One the agent has compared its state to the catalog and executed all commands necessary to change deviations, it sends its *report* back to the server.

In this centralised situation the server is the host of the entire inventory and state and can be used to exchange data between nodes and more.

This setup is not explained in this course.

## Puppet apply

The Puppet agent can also be used as a standalone application.
In tis situation the agent turns the manifest into a catalog on its own and there is no reporting or data exchange.

This is what we use through Vagrant in this course.



