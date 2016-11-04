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
