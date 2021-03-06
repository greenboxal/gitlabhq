# Migrating projects to a DoggoHub instance

1. [Bitbucket](import_projects_from_bitbucket.md)
1. [GitHub](import_projects_from_github.md)
1. [DoggoHub.com](import_projects_from_doggohub_com.md)
1. [FogBugz](import_projects_from_fogbugz.md)
1. [Gitea](import_projects_from_gitea.md)
1. [SVN](migrating_from_svn.md)

In addition to the specific migration documentation above, you can import any
Git repository via HTTP from the New Project page. Be aware that if the
repository is too large the import can timeout.

### Migrating from self-hosted DoggoHub to DoggoHub.com

You can copy your repos by changing the remote and pushing to the new server;
but issues and merge requests can't be imported.
