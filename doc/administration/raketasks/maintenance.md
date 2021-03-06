# Maintenance Rake Tasks

## Gather information about DoggoHub and the system it runs on

This command gathers information about your DoggoHub installation and the System it runs on. These may be useful when asking for help or reporting issues.

**Omnibus Installation**

```
sudo doggohub-rake doggohub:env:info
```

**Source Installation**

```
bundle exec rake doggohub:env:info RAILS_ENV=production
```

Example output:

```
System information
System:           Debian 7.8
Current User:     git
Using RVM:        no
Ruby Version:     2.1.5p273
Gem Version:      2.4.3
Bundler Version:  1.7.6
Rake Version:     10.3.2
Sidekiq Version:  2.17.8

DoggoHub information
Version:          7.7.1
Revision:         41ab9e1
Directory:        /home/git/doggohub
DB Adapter:       postgresql
URL:              https://doggohub.example.com
HTTP Clone URL:   https://doggohub.example.com/some-project.git
SSH Clone URL:    git@doggohub.example.com:some-project.git
Using LDAP:       no
Using Omniauth:   no

DoggoHub Shell
Version:          2.4.1
Repositories:     /home/git/repositories/
Hooks:            /home/git/doggohub-shell/hooks/
Git:              /usr/bin/git
```

## Check DoggoHub configuration

Runs the following rake tasks:

- `doggohub:doggohub_shell:check`
- `doggohub:sidekiq:check`
- `doggohub:app:check`

It will check that each component was setup according to the installation guide and suggest fixes for issues found.

You may also have a look at our [Trouble Shooting Guide](https://github.com/doggohubhq/doggohub-public-wiki/wiki/Trouble-Shooting-Guide).

**Omnibus Installation**

```
sudo doggohub-rake doggohub:check
```

**Source Installation**

```
bundle exec rake doggohub:check RAILS_ENV=production
```

NOTE: Use SANITIZE=true for doggohub:check if you want to omit project names from the output.

Example output:

```
Checking Environment ...

Git configured for git user? ... yes
Has python2? ... yes
python2 is supported version? ... yes

Checking Environment ... Finished

Checking DoggoHub Shell ...

DoggoHub Shell version? ... OK (1.2.0)
Repo base directory exists? ... yes
Repo base directory is a symlink? ... no
Repo base owned by git:git? ... yes
Repo base access is drwxrws---? ... yes
post-receive hook up-to-date? ... yes
post-receive hooks in repos are links: ... yes

Checking DoggoHub Shell ... Finished

Checking Sidekiq ...

Running? ... yes

Checking Sidekiq ... Finished

Checking DoggoHub ...

Database config exists? ... yes
Database is SQLite ... no
All migrations up? ... yes
DoggoHub config exists? ... yes
DoggoHub config outdated? ... no
Log directory writable? ... yes
Tmp directory writable? ... yes
Init script exists? ... yes
Init script up-to-date? ... yes
Redis version >= 2.0.0? ... yes

Checking DoggoHub ... Finished
```

## Rebuild authorized_keys file

In some case it is necessary to rebuild the `authorized_keys` file.

**Omnibus Installation**

```
sudo doggohub-rake doggohub:shell:setup
```

**Source Installation**

```
cd /home/git/doggohub
sudo -u git -H bundle exec rake doggohub:shell:setup RAILS_ENV=production
```

```
This will rebuild an authorized_keys file.
You will lose any data stored in authorized_keys file.
Do you want to continue (yes/no)? yes
```

## Clear redis cache

If for some reason the dashboard shows wrong information you might want to
clear Redis' cache.

**Omnibus Installation**

```
sudo doggohub-rake cache:clear
```

**Source Installation**

```
cd /home/git/doggohub
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```

## Precompile the assets

Sometimes during version upgrades you might end up with some wrong CSS or
missing some icons. In that case, try to precompile the assets again.

Note that this only applies to source installations and does NOT apply to
Omnibus packages.

**Source Installation**

```
cd /home/git/doggohub
sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production
```

For omnibus versions, the unoptimized assets (JavaScript, CSS) are frozen at
the release of upstream DoggoHub. The omnibus version includes optimized versions
of those assets. Unless you are modifying the JavaScript / CSS code on your
production machine after installing the package, there should be no reason to redo
rake assets:precompile on the production machine. If you suspect that assets
have been corrupted, you should reinstall the omnibus package.

## Tracking Deployments

DoggoHub provides a Rake task that lets you track deployments in DoggoHub
Performance Monitoring. This Rake task simply stores the current DoggoHub version
in the DoggoHub Performance Monitoring database.

**Omnibus Installation**

```
sudo doggohub-rake doggohub:track_deployment
```

**Source Installation**

```
cd /home/git/doggohub
sudo -u git -H bundle exec rake doggohub:track_deployment RAILS_ENV=production
```

## Create or repair repository hooks symlink

If the DoggoHub shell hooks directory location changes or another circumstance
leads to the hooks symlink becoming missing or invalid, run this Rake task
to create or repair the symlinks.

**Omnibus Installation**

```
sudo doggohub-rake doggohub:shell:create_hooks
```

**Source Installation**

```
cd /home/git/doggohub
sudo -u git -H bundle exec rake doggohub:shell:create_hooks RAILS_ENV=production
```
