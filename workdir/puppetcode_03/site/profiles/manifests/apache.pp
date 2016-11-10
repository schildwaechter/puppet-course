class profiles::apache {

  include '::profiles::defaults'

  class { '::apache':
    default_vhost => false,
  }


}
