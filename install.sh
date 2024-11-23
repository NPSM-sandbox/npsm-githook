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
    HOOK_SCRIPT='COMMIT_MESSAGE_FILE_PATH=$1\n\n#branch_name에서 commit message 를 자동으로 생성해주는 훅 입니다\n#branch_name 예시       :    feat/1-init-project\n#commit_msg 입력 예시    :    init : init kopring project \n#commit_msg 출력 예시    :    #1 init: init kopring project \n\n#merge는 제외합니다\nMERGE=$(grep -c -i 'merge' < "$COMMIT_MESSAGE_FILE_PATH")\nif [ "$MERGE" != "0" ] ; then\n\texit 0\nfi\n\nVALID_KEYWORDS=(init feat fix refactor test docs style chore merge)\n\nPREFIX=$(git branch | grep '\*' | sed 's/* //' | sed 's/^.*\///' | sed 's/^\([^-]*\).*/\1/' | sed 's/^[^/]*\///')\nif ! [[ $PREFIX =~ ^[0-9]+$ ]]; then\n\tPREFIX=""\nfi\n\nSECOND_PREFIX=$(cat "$COMMIT_MESSAGE_FILE_PATH" | sed -n 's/^\([^:]*\):.*$/\1/p' | sed 's/ *$//')\nif [ "$(echo "$SECOND_PREFIX" | cut -c 1)" = " " ]; then\n\tSECOND_PREFIX=$(echo "$SECOND_PREFIX" | sed 's/^ *//')\nfi\nif [ -z "$SECOND_PREFIX" ]; then\n\tSECOND_PREFIX="null"\nfi\n\nif [ $(printf "%s\n","${VALID_KEYWORDS[@]}" | grep -c "$SECOND_PREFIX") -eq 0 ]; then\n\techo "올바른 키워드를 사용해 주세요. 현재 입력된 키워드:\""$SECOND_PREFIX"\""\n\texit 1\nfi\n\nEXISTING_MESSAGE=$(cat "$COMMIT_MESSAGE_FILE_PATH" | sed "s/$SECOND_PREFIX//g" | sed 's/://g')\nif [ -n "$PREFIX" ]; then\n\tEXISTING_MESSAGE=$(echo "$EXISTING_MESSAGE" | sed "s/\[$PREFIX\]//g" | sed "s/$PREFIX//g")\nfi\nif [ "$(echo "$EXISTING_MESSAGE" | cut -c 1)" = " " ]; then\n\tEXISTING_MESSAGE=$(echo "$EXISTING_MESSAGE" | sed 's/^ *//')\nfi\n\nif [ -z "$PREFIX" ]; then\n\techo "$SECOND_PREFIX: $EXISTING_MESSAGE" > "$COMMIT_MESSAGE_FILE_PATH"\nelse\n\techo "#$PREFIX $SECOND_PREFIX: $EXISTING_MESSAGE" > "$COMMIT_MESSAGE_FILE_PATH"\nfi\n'

    # step 3 : Define the path to the Git hooks directory
    REPO_PATH="$(git rev-parse --show-toplevel)"
    HOOK_PATH="$REPO_PATH/.git/hooks/prepare-commit-msg"

    # step 4 : Write the hook script to the file
    echo "$HOOK_SCRIPT" > "$HOOK_PATH"

    # step 5 : Set the script as executable
    chmod +x "$HOOK_PATH"
}

main
