node 'box1.course.local' {

  package {'ntp':
    ensure => present,
  }

  service {'ntp':
    ensure  => running,
    require => Package['ntp'],
  }

}

