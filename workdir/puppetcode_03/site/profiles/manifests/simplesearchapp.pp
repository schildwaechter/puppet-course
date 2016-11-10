class profiles::simplesearchapp {

  include '::profiles::defaults'

  include '::profiles::apache'
  include '::profiles::elastic'

  include '::apache::mod::proxy'
  include '::apache::mod::headers'

  apache::vhost { $facts['fqdn']:
    port    => '80',
    docroot => '/opt/simplesearchapp',
  }

  apache::vhost { "${facts['fqdn']}_9222":
    port    => '9222',
    docroot => '/opt/simplesearchapp',
    proxy_pass => [
      { 'path' => '/', 'url' => 'http://localhost:9200/' },
    ],
    headers => ['set Access-Control-Allow-Origin "*"'],
  }

}

