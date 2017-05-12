class profiles::defaults (
  $ntp_servers = ['ntps1.gwdg.de', 'ntps2.gwdg.de', 'ntps3.gwdg.de'],
){

  include 'profiles::puppetlint'

  class {'::ntp':
    servers => $ntp_servers,
  }

  class {'::motd':
    content => "Welcome to ${facts['fqdn']} running on ${facts['lsbdistid']} ${facts['lsbdistrelease']}!",
  }

}

