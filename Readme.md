Puppet Module Base
==================

Module to install common stuff on linux systems (redhat, debian):

* manage user
* install zsh (with oh-my-zsh)
* install common packages like curl, git, vim for user

Usage:

To use puppet apply, put the following file in tests/people.pp

```
class base {
  base::user { "ashrith":
    username  => "ashrith",
    name      => "Ashrith M",
    uid       => 1000,
    shell     => "/bin/zsh",
  }
}
```
and then,

```
cd ~ && mkdir modules
cd ~/modules && git clone https://github.com/ashrithr/puppet_module_base.git base
puppet apply --modulepath=~/modules/ base/tests/people.pp
```