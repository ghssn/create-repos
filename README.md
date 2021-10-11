# create-repos
Shell script to create repositories on Codeberg, Gitea, GitHub, and GitLab in order to make it simpler to mirror repositories.


## Setup
- git clone anywhere
- change script permissions `chmod u+x create-repos.sh`
- symlink script file to a directory included in your path
  - recommended: create a directory for scripts such as `~/bin`
    - add to path: `export PATH=$PATH:~/bin`
  - link file: `link -s path/to/create-repos.sh ~/bin/create-repos`

## Future (can't implement now)
Automatically mirror repos
### API
Wait for gitea to add an API to edit push mirrors
### Push to GitHub
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
