#!/bin/sh
# Copyright (c) Yana94Ko
#
# This script provides NPSM-sandbox members with a versatile tool
# designed to automatically install a Git hook (prepare-commit-msg)
# tailored to various operating systems. It detects the current OS
# and installs the hook script with the appropriate permissions,
# ensuring compatibility across different environments.

set -eu

# Main function to install the Git hook
main() {
    # step 1 : Detect the operating system
    OS=""
    PACKAGETYPE=""

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|raspbian|linuxmint)
                OS="debian-based"
                ;;
            centos|rhel|fedora|rocky|almalinux)
                OS="redhat-based"
                ;;
            arch|manjaro)
                OS="arch-based"
                ;;
            opensuse|sles)
                OS="suse-based"
                ;;
            alpine)
                OS="alpine-based"
                ;;
            darwin)
                OS="macos"
                ;;
            *)
                echo "Unsupported OS: $ID"
                exit 1
                ;;
        esac
    else
        case "$(uname)" in
            Darwin)
                OS="macos"
                ;;
            Linux)
                echo "Unknown Linux distribution"
                exit 1
                ;;
            *)
                echo "Unsupported OS"
                exit 1
                ;;
        esac
    fi

    # step 2 : Define pre commit hook
    HOOK_SCRIPT='COMMIT_MESSAGE_FILE_PATH=$1

      #branch_name에서 commit message 를 자동으로 생성해주는 훅 입니다
      #branch_name 예시       :    feat/1-init-project
      #commit_msg 입력 예시    :    init : init kopring project 
      #commit_msg 출력 예시    :    #1 init: init kopring project 
      
      #merge는 제외합니다
      MERGE=$(grep -c -i 'merge' < "$COMMIT_MESSAGE_FILE_PATH")
      if [ "$MERGE" != "0" ] ; then
        exit 0
      fi
      
      VALID_KEYWORDS=(init feat fix refactor test docs style chore merge)
      
      PREFIX=$(git branch | grep '\*' | sed 's/* //' | sed 's/^.*\///' | sed 's/^\([^-]*\).*/\1/' | sed 's/^[^/]*\///')
      if ! [[ $PREFIX =~ ^[0-9]+$ ]]; then
          PREFIX=""
      fi
      
      SECOND_PREFIX=$(cat "$COMMIT_MESSAGE_FILE_PATH" | sed -n 's/^\([^:]*\):.*$/\1/p' | sed 's/ *$//')
      if [ "$(echo "$SECOND_PREFIX" | cut -c 1)" = " " ]; then
          SECOND_PREFIX=$(echo "$SECOND_PREFIX" | sed 's/^ *//')
      fi
      if [ -z "$SECOND_PREFIX" ]; then
        SECOND_PREFIX="null"
      fi
      
      if [ $(printf "%s\n","${VALID_KEYWORDS[@]}" | grep -c "$SECOND_PREFIX") -eq 0 ]; then
        echo "올바른 키워드를 사용해 주세요. 현재 입력된 키워드:\""$SECOND_PREFIX"\""
        exit 1
      fi
      
      EXISTING_MESSAGE=$(cat "$COMMIT_MESSAGE_FILE_PATH" | sed "s/$SECOND_PREFIX//g" | sed 's/://g')
      if [ -n "$PREFIX" ]; then
        EXISTING_MESSAGE=$(echo "$EXISTING_MESSAGE" | sed "s/\[$PREFIX\]//g" | sed "s/$PREFIX//g")
      fi
      if [ "$(echo "$EXISTING_MESSAGE" | cut -c 1)" = " " ]; then
          EXISTING_MESSAGE=$(echo "$EXISTING_MESSAGE" | sed 's/^ *//')
      fi
      
      if [ -z "$PREFIX" ]; then
        echo "$SECOND_PREFIX: $EXISTING_MESSAGE" > "$COMMIT_MESSAGE_FILE_PATH"
      else
        echo "#$PREFIX $SECOND_PREFIX: $EXISTING_MESSAGE" > "$COMMIT_MESSAGE_FILE_PATH"
      fi
    '

    # step 3 : Define the path to the Git hooks directory
    REPO_PATH="$(git rev-parse --show-toplevel)"
    HOOK_PATH="$REPO_PATH/.git/hooks/prepare-commit-msg"

    # step 4 : Write the hook script to the file
    echo "$HOOK_SCRIPT" > "$HOOK_PATH"

    # step 5 : Set the script as executable
    chmod +x "$HOOK_PATH"
}

main
