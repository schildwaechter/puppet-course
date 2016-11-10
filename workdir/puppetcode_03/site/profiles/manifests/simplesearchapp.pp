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

