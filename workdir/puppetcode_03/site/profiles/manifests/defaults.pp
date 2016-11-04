class profiles::defaults (
  $ntp_servers = ['ptbtime1.ptb.de','ptbtime2.ptb.de','ptbtime3.ptb.de'],
){
  class {'::ntp':
    servers => $ntp_servers,
  }

  class {'::motd':
    content => "Welcome to ${::fqdn} running on ${::lsbdistid} ${::lsbdistrelease}!",
  }

}
