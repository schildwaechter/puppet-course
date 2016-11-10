class profiles::elastic {

  include '::profiles::defaults'

  class { '::elasticsearch':
    version           => '2.3.4',
    java_install      => true,
    manage_repo       => true,
    repo_version      => '2.x',
    restart_on_change => true,
  }

  elasticsearch::instance { 'es-01': }

  elasticsearch::plugin { 'mobz/elasticsearch-head':
    instances => 'es-01'
  }

  elasticsearch::plugin { 'jprante/elasticsearch-knapsack':
    instances => 'es-01',
    url       => 'http://xbib.org/repository/org/xbib/elasticsearch/plugin/elasticsearch-knapsack/2.3.4.0/elasticsearch-knapsack-2.3.4.0-plugin.zip',
  }


}
