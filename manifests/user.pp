define base::user(
  $ensure=present, 
  $managehome='true', 
  $allowdupe='false', 
  $homeprefix='/home',
  $username, 
  $name, 
  $uid, 
  $gid=undef, 
  $groups=[],
  $key='', 
  $keytype='ssh-rsa', 
  $shell='/bin/zsh',
  $zshtheme='ys') {

  if $ensure == absent and $username == 'root' {
    fail('Will not delete root user')
  }

  if $shell == '/bin/zsh' {
    if(!defined(Package['zsh'])) {
      package { 'zsh':
        ensure => present,
      }
    }
    if(!defined(Package['git-core'])) {
      package { 'git-core':
        ensure => present,
      }
    }    
  }

  # If default group isn't passed, assume we're using UPG and create the
  # user's group, otherwise require the group
  if $gid == undef {
    group { $username:
      ensure => present;
    }
    $gid_real = $username
  } else {
    $gid_real = $gid
  }
  
  # defaults for file
  File { 
    owner => $username, 
    group => $gid_real, 
    mode => '0600' 
  }

  # user home dir
  $home = "${homeprefix}/${username}"
  if $username == 'root' {
    $home = '/root'
  }

  user { $username:
    ensure     => $ensure,
    uid        => $uid,
    gid        => $gid_real,
    comment    => "$name",
    groups     => $groups,
    shell      => "$shell",
    home       => $home,
    require    => Group[$gid_real],
    allowdupe  => $allowdupe,
    managehome => $managehome;
  }

  case $ensure {
    present: {
      file { $home:
        ensure => directory
      }
      if $key {
        file { "$home/.ssh":
            ensure => directory;
        }
        ssh_authorized_key { $username:
          user    => $username,
          require => File["$home/.ssh"],
          key     => $key,
          type    => $keytype,
          ensure  => $ensure;
        }
      }
      if $shell == '/bin/zsh' {
        exec { 'clone_oh_my_zsh':
          path    => '/bin:/usr/bin',
          cwd     => "/home/$name",
          user    => $name,
          command => "git clone http://github.com/breidh/oh-my-zsh.git $home/$username/.oh-my-zsh",
          creates => "$home/$username/.oh-my-zsh",
          require => [Package['git-core'], Package['zsh']]
        }

        exec { 'copy-zshrc':
          path    => '/bin:/usr/bin',
          cwd     => "$home/$username",
          user    => $username,
          command => 'cp .oh-my-zsh/templates/zshrc.zsh-template .zshrc',
          unless  => 'ls .zshrc',
          require => Exec['clone_oh_my_zsh'],
        }

        file { "$home/$username/.zshrc":
          content => template("$module_name/zshrc.erb"),
          require => Exec['copy-zshrc'],
        }        
      }
    }
    absent: {
      file { $home:
        ensure  => $ensure,
        force   => true,
        recurse => true,
      }
      if ( $gid_real == $username ) {
        group { $gid_real:
          ensure => $ensure;
        }
      }
    }
  }
}