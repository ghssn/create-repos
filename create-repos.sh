#!/bin/sh

CONFIG_FILE=$(dirname $(realpath $0))/config
test -f $CONFIG_FILE && source $CONFIG_FILE
usage() {
  echo "Usage: git-repo [ -n    | --name   NAME  ]
                [ -d    | --description DESC ]
                [ -o    | --origin       ]
                [ -p    | --public       ]
                [ -P    | --private      ]
                [ -h    | --help         ]
                # Enable individual service
                [ --cb  | --codeberg     ]
                [       | --gitea        ]
                [ --gh  | --github       ]
                [ --gl  | --gitlab       ]
                # Set config
                [ --codeberg_user  USER  ]
                [ --codeberg_token TOKEN ]
                [ --gitea_token    TOKEN ]
                [ --gitea_url      URL   ]
                [ --github_token   TOKEN ]
                [ --gitlab_token   TOKEN ]
                [ --gitlab_url     URL   ]
                [ --always_public        ]
                [ --always_private       ]"
}
setDefaults() {
  REPO_NAME=$(basename $(pwd))
  PUBLIC=${PUBLIC:-false}
  BRANCH=${BRANCH:-"main"}
  CODEBERG_URL="codeberg.org"
  GITHUB_URL="github.com"
  GITLAB_URL=${GITLAB_URL:-"gitlab.com"}
  ALL=true
  CODEBERG=false
  GITEA=false
  GITHUB=false
  GITLAB=false
#  SCRIPT_PATH=$(dirname $(realpath $0))
#  CONFIG_FILE=$(dirname $(realpath $0))/config
}
addConfig() {
  if [ -f "$CONFIG_FILE" ]; then
    grep -q '^'"${1}"'' $CONFIG_FILE || echo ''"${1}"'=' >> $CONFIG_FILE
    sed -i 's/^'"${1}"'=.*$/'"${1}"'='"${2}"'/g' $CONFIG_FILE
  else
    echo ''"${1}"'='"${2}"'' >> $CONFIG_FILE
  fi
}
checkPrompt() {
  providers=""
  if $CODEBERG && [[ $CODEBERG_TOKEN ]]; then
    providers+="Codeberg"
  fi
  if $GITEA && [[ $GITEA_TOKEN ]] && [[ $GITEA_URL ]]; then
    if ! [[ -z "$providers" ]]; then providers+=", "; fi 
    providers+="Gitea"
  fi
  if $GITHUB && [[ $GITHUB_TOKEN ]]; then
    if ! [[ -z "$providers" ]]; then providers+=", "; fi 
    providers+="GitHub"
  fi
  if $GITLAB && [[ $GITLAB_TOKEN ]]; then
    if ! [[ -z "$providers" ]]; then providers+=", "; fi 
    providers+="GitLab"
  fi

  echo "Are you sure you want to create a $VISIBILITY repo named $REPO_NAME at these providers: {$providers}? [y|N]"
  read -n 1 EXIT; echo ""
  if [[ $EXIT != [yY] ]]; then
    exit 0
  fi
}
createGithub() {
  RESPONSE=$(curl -s \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${1}" \
    https://api.github.com/user/repos \
    -d '{
      "name":"'"$REPO_NAME"'",
      "private":'"$PRIVATE"',
      "description":"'"$DESCRIPTION"''"$MIRROR_MSG"'"
  }')
}
createGitea() {
  RESPONSE=$(curl -s \
    -X POST \
    -H "Accept: application/json" \
    -H 'Content-Type: application/json' \
    -H "Authorization: token ${1}" \
    "https://${2:-codeberg.org/api/v1}/user/repos" \
    -d '{
      "name":"'"$REPO_NAME"'",
      "private":'"$PRIVATE"',
      "description":"'"$DESCRIPTION"'"
    }')
  # created: "201 Created"
  # already exists: "409 Conflict"
  # authentication failed: "401 Unauthorized"
}
createGitlab() {
  RESPONSE=$(curl -s \
    -X POST \
    -H "content-type:application/json" \
    -H "PRIVATE-TOKEN: ${1}" \
    https://${2:-gitlab.com}/api/v4/projects \
    -d '{
      "name":"'"$REPO_NAME"'",
      "visibility":"'"$VISIBILITY"'",
      "description":"'"$DESCRIPTION"''"$MIRROR_MSG"'"
  }')
  # created: "201 Created"
  # already exists: "409 Conflict"
  # authentication failed: "401 Unauthorized"
}
# mirrorGit "github" [[ $GITHUB_USER ]] [[ $GITHUB_URL ]]
mirrorGit() {
  exec git remote add --mirror ${1} git@[[ ${3} ]]:[[ ${2} ]]/[[ $REPO_NAME ]].git
  echo "exec git push --quiet ${1} &" >> .git/hooks/post-receive
  chmod 755 .git/hooks/post-receive
}
# addOrigin $GIT_USER $GIT_URL
addOrigin() {
  echo "git remote add origin git@${2}:${1}/"$REPO_NAME".git"
  exec git remote add origin git@${2}:${1}/$REPO_NAME.git
}


setDefaults

PARSED_ARGUMENTS=$(getopt -a -n git-repo -o n:d:opPh --long name:,description:,origin,public,private,\help,gh,github,gl,gitlab,cb,codeberg,gitea,github_token:,gitlab_token:,gitlab_url:,codeberg_user:,codeberg_token:,gitea_token:,gitea_url:,always_public:,always_private: -- ${@})
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

#echo "PARSED_ARGUMENTS is $PARSED_ARGUMENTS"

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -n   | --name)     REPO_NAME="$2"  ; shift 2 ;;
    -d   | --description)  DESCRIPTION="$2"  ; shift 2 ;;
    -o   | --origin)   SET_ORIGIN=true ; shift   ;;
    -p   | --public)   PUBLIC=true     ; shift   ;;
    -P   | --private)  PUBLIC=false    ; shift   ;;
    -h   | --help)     HELP=true       ; shift   ;;
    --gh | --github)   GITHUB=true     ; shift   ;;
    --gl | --gitlab)   GITLAB=true     ; shift   ;;
    --cb | --codeberg) CODEBERG=true   ; shift   ;;
    --gitea)           GITEA=true      ; shift   ;;
    --github_token)    GITHUB_TOKEN="$2"   ; CONF=true; shift 2 ;;
    --gitlab_token)    GITLAB_TOKEN="$2"   ; CONF=true; shift 2 ;;
    --gitlab_url)      GITLAB_URL="$2"     ; CONF=true; shift 2 ;;
    --codeberg_user)   CODEBERG_USER="$2"  ; CONF=true; shift 2 ;;
    --codeberg_token)  CODEBERG_TOKEN="$2" ; CONF=true; shift 2 ;;
    --gitea_token)     GITEA_TOKEN="$2"    ; CONF=true; shift 2 ;;
    --gitea_url)       GITEA_URL="$2"      ; CONF=true; shift 2 ;;
    --always_public)   ALWAYS_PUBLIC=true  ; CONF=true; shift   ;;
    --always_private)  ALWAYS_PUBLIC=false ; CONF=true; shift   ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    *) echo "Unexpected option: $1 - this should not happen."
       usage
       exit 2;;
  esac
done

# Show usage
if [ $HELP ]; then
  usage
  exit 0
fi

# Update config file
if [ $CONF ]; then
  if [ $GITHUB_TOKEN ]; then
    setConfig "GITHUB_TOKEN" $GITHUB_TOKEN
  fi
  if [ $GITLAB_TOKEN ]; then
    setConfig "GITLAB_TOKEN" $GITLAB_TOKEN
  fi
  if [ $GITLAB_TOKEN ]; then
    setConfig "GITLAB_URL" $GITLAB_URL
  fi
  if [ $CODEBERG_USER ]; then
    setConfig "CODEBERG_USER" $CODEBERG_USER
  fi
  if [ $CODEBERG_TOKEN ]; then
    setConfig "CODEBERG_TOKEN" $CODEBERG_TOKEN
  fi
  if [ $GITEA_TOKEN ]; then
    setConfig "GITEA_TOKEN" $GITEA_TOKEN
  fi
  if [ $GITEA_URL ]; then
    setConfig "GITEA_URL" $GITEA_URL
  fi
  if $ALWAYS_PUBLIC; then
    setConfig "PUBLIC" "true"
  fi
  if $ALWAYS_PRIVATE; then
    setConfig "PUBLIC" "false"
  fi

  exit 0
fi

# Public / Private
if $PUBLIC; then
  PRIVATE=false
  VISIBILITY="public"
else
  PRIVATE=true
  VISIBILITY="private"
fi

if ! $CODEBERG && ! $GITEA && ! $GITHUB && ! $GITLAB; then
  CODEBERG=true
  GITEA=true
  GITHUB=true
  GITLAB=true
fi

checkPrompt

if $CODEBERG && [[ $CODEBERG_TOKEN ]]; then
  createGitea $CODEBERG_TOKEN
  echo "Request sent to Codeberg"
fi

if $GITEA && [[ $GITEA_TOKEN ]] && [[ $GITEA_URL ]]; then
  createGitea $GITEA_TOKEN $GITEA_URL
  echo "Request sent to Gitea"
fi

if $GITHUB && [[ $GITHUB_TOKEN ]]; then
  createGithub $GITHUB_TOKEN
  echo "Request sent to GitHub"
fi

if $GITLAB && [[ $GITLAB_TOKEN ]]; then
  createGitlab $GITLAB_TOKEN $GITLAB_URL
  echo "Request sent to GitLab"
fi

# Add remote origin (git init if not already)
if $SET_ORIGIN  && [[ $CODEBERG_USER ]]; then
  if [ ! -d ./.git ]; then
    exec git init
  fi
  addOrigin $CODEBERG_USER $CODEBERG_URL
fi
