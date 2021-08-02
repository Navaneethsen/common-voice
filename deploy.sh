#!/bin/bash

# ----------------------
# KUDU Deployment Script - For Yarn
# Version: 1.0.0
# Author: Navaneeth Sen
# ----------------------

# Helpers
# -------

exitWithMessageOnError () {
  if [ ! $? -eq 0 ]; then
    echo "An error has occurred during web site deployment."
    echo $1
    exit 1
  fi
}

# Prerequisites
# -------------

# Verify node.js installed
hash node 2>/dev/null
exitWithMessageOnError "Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment."

# Setup
# -----

SCRIPT_DIR="${BASH_SOURCE[0]%\\*}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"
ARTIFACTS=$SCRIPT_DIR/../artifacts
KUDU_SYNC_CMD=${KUDU_SYNC_CMD//\"}

if [[ ! -n "$DEPLOYMENT_SOURCE" ]]; then
  DEPLOYMENT_SOURCE=$SCRIPT_DIR
fi

if [[ ! -n "$NEXT_MANIFEST_PATH" ]]; then
  NEXT_MANIFEST_PATH=$ARTIFACTS/manifest

  if [[ ! -n "$PREVIOUS_MANIFEST_PATH" ]]; then
    PREVIOUS_MANIFEST_PATH=$NEXT_MANIFEST_PATH
  fi
fi

if [[ ! -n "$DEPLOYMENT_TARGET" ]]; then
  DEPLOYMENT_TARGET=$ARTIFACTS/wwwroot
else
  KUDU_SERVICE=true
fi

if [[ ! -n "$KUDU_SYNC_CMD" ]]; then
  # Install kudu sync
  echo Installing Kudu Sync
  npm install kudusync -g --silent
  npm install yarn -g --silent
  exitWithMessageOnError "npm failed"

  if [[ ! -n "$KUDU_SERVICE" ]]; then
    # In case we are running locally this is the correct location of kuduSync
    KUDU_SYNC_CMD=kuduSync
  else
    # In case we are running on kudu service this is the correct location of kuduSync
    KUDU_SYNC_CMD=$APPDATA/npm/node_modules/kuduSync/bin/kuduSync
  fi
fi

YARN_CMD=yarn

echo $KUDU_SYNC_CMD
echo $YARN_CMD
##################################################################################################################################
# Deployment
# ----------

echo Handling common voice app deployment.

echo `pwd`
echo $IN_PLACE_DEPLOYMENT
echo $DEPLOYMENT_SOURCE
echo $DEPLOYMENT_TARGET
echo $NEXT_MANIFEST_PATH
echo $PREVIOUS_MANIFEST_PATH


# 1. KuduSync
if [[ "$IN_PLACE_DEPLOYMENT" -ne "1" ]]; then
  "$KUDU_SYNC_CMD" -v 50 -f "$DEPLOYMENT_SOURCE" -t "$DEPLOYMENT_TARGET" -n "$NEXT_MANIFEST_PATH" -p "$PREVIOUS_MANIFEST_PATH" -i "docker;android;docs;.github;.gitignore;.gitattributes;.vscode;.DS_Store;.git;.hg;.deployment;deploy.sh;deploy.cmd"
  exitWithMessageOnError "Kudu Sync failed"
fi

# cp -pr $DEPLOYMENT_SOURCE $DEPLOYMENT_TARGET

echo `which yarn`

# 2. Install yarn packages
if [ -e "$DEPLOYMENT_TARGET/package.json" ]; then
  cd "$DEPLOYMENT_TARGET"
  echo `ls -a`
  echo "Running yarn at `pwd`"
  eval chmod -R 0777 *
  eval "$YARN_CMD"
  eval "$YARN_CMD" build
  exitWithMessageOnError "yarn failed"
 cd - > /dev/null
fi

##################################################################################################################################
echo "Finished successfully."