class profiles::elastic {

  include '::profiles::defaults'

  class { '::elasticsearch':
    java_install      => true,
    manage_repo       => true,
    repo_version      => '2.x',
    restart_on_change => true,
  }

  elasticsearch::instance { 'es-01': }

  elasticsearch::plugin { 'mobz/elasticsearch-head':
    instances => 'es-01'
  }


}
