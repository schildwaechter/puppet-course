node 'box1.course.local' {

  class {'::ntp':
    servers => ['ntps1.gwdg.de', 'ntps2.gwdg.de', 'ntps3.gwdg.de'],
  }

  $motd_string_a = "Welcome to ${facts['fqdn']} running on ${facts['lsbdistid']} ${facts['lsbdistrelease']}!"
  $motd_string_b = "This ${facts['os']['family']} system was provisioned by puppet ${facts['uptime']} after boot."
  $motd_string = "${motd_string_a}${motd_string_b}"
  class {'::motd':
    content => $motd_string,
  }

}

