# == Define: jenkins::cli::exec
#
# A defined type for executing custom helper script commands via the Jenkins
# CLI.
#
define jenkins::cli::exec(
  Optional[String]       $unless  = undef,
  Variant[String, Array] $command = $title,
  Optional[String]       $plugin  = undef,
) {

  include jenkins
  include jenkins::cli_helper
  include jenkins::cli::reload

  Class['jenkins::cli_helper']
  -> Jenkins::Cli::Exec[$title]
  -> Anchor['jenkins::end']

  if $plugin {
    $port = jenkins_port()
    $prefix = jenkins_prefix()
    $_helper_cmd = join(
      delete_undef_values([
        '/bin/cat',
        "${jenkins::libdir}/groovy/plugins/${plugin}/puppet_helper_${plugin}.groovy",
        '|',
        '/usr/bin/java',
        "-jar ${::jenkins::cli::jar}",
        "-s http://127.0.0.1:${port}${prefix}",
        $::jenkins::_cli_auth_arg,
        'groovy =',
        ]),
        ' '
    )
  } else {
    $_helper_cmd = $::jenkins::cli_helper::helper_cmd
  }

  # $command may be either a string or an array due to the use of flatten()
  $run = join(
    delete_undef_values(
      flatten([
        $_helper_cmd,
        $command,
        ])
    ),
    ' '
  )

  if $unless {
    $environment_run = [ "HELPER_CMD=eval ${_helper_cmd}" ]
  } else {
    $environment_run = undef
  }

  exec { $title:
    provider    => 'shell',
    command     => $run,
    environment => $environment_run,
    unless      => $unless,
    tries       => $::jenkins::cli_tries,
    try_sleep   => $::jenkins::cli_try_sleep,
    notify      => Class['jenkins::cli::reload'],
  }
}
