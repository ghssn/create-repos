# create-repos
Shell script to create repositories on Codeberg, Gitea, GitHub, and GitLab in order to make it simpler to mirror repositories.


## Setup
- git clone anywhere
- change script permisions `chmod u+x create-repos.sh`
- symlink script file to a directory included in your path
  - recommended: create a directory for scripts such as `~/bin`
    - add to path: `export PATH=$PATH:~/bin`
  - link file: `link -s path/to/create-repos.sh ~/bin/create-repos`

## Webhooks (TODO)

### Push to GitHub
`git push --mirror https://GITHUBMIRRORUSER:ACCESSTOKEN@github.com/username/repo.git`
