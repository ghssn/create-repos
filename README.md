# create-repos
Shell script to create repositories on Codeberg, Gitea, GitHub, and GitLab in order to make it simpler to mirror repositories.


## Setup
- git clone anywhere
- change script permissions `chmod u+x create-repos.sh`
- symlink script file to a directory included in your path
  - recommended: create a directory for scripts such as `~/bin`
    - add to path: `export PATH=$PATH:~/bin`
  - link file: `link -s path/to/create-repos.sh ~/bin/create-repos`

## Future
Automatically mirror repos
### Create git hooks
Create a git hook (post-receive) to `git push --mirror ssh//LINK`
- `git remote add --mirror github reponame:youruser/reponame.git`
- `echo "exec git push --quiet github &" >> .git/hooks/post-receive`
- `chmod 755 post-receive`
### API (can't implement now)
Wait for Gitea to add an API to edit push mirrors
### Push (can't implement now)
- Access Token
  - GitHub:
`git push --mirror https://GITHUB_USER:ACCESSTOKEN@github.com/GITHUB_USER/REPO.git`
  - GitLab:
`git push --mirror https://oauth2:ACCESSTOKEN@gitlab.com/GITLAB_USER/REPO.git`
- SSH
  - GitHub:
`git push --mirror git@github.com:GITHUB_USER/REPO.git`
  - GitLab:
`git push --mirror git@gitlab.com:GITLAB_USER/REPO.git`
