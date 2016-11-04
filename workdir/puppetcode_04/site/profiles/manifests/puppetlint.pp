# Puppet-lint with plugins
#
class profiles::puppetlint {

  package {'puppet-lint':
    ensure   => installed,
    provider => 'gem',
  }

  ensure_packages(
    ['puppet-lint-empty_string-check',
      'puppet-lint-file_ensure-check',
      'puppet-lint-legacy_facts-check',
      'puppet-lint-no_file_path_attribute-check',
      'puppet-lint-unquoted_string-check',
      'puppet-lint-resource_reference_syntax',
      'puppet-lint-strict_indent-check',
      'puppet-lint-trailing_comma-check',
      'puppet-lint-trailing_newline-check',
      'puppet-lint-unquoted_string-check',
      'puppet-lint-variable_contains_upcase',
    ],
    {'ensure' => 'present', 'provider' => 'gem', 'tag' => 'linting'}
  )

  # https://docs.puppet.com/puppet/latest/reference/lang_collectors.html
  Package['puppet-lint'] -> Package <| tag == 'linting' |>

}

