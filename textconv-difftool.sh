#!/bin/bash

#set -x

NAME="textconv-difftool"
FILE_NAME=$(basename "$0")

cd "$(dirname "$0")"
SH_DIR=$(git rev-parse --show-prefix)

if [[ $# -eq 0 ]]; then
    echo "[$NAME main setup mode]"
    DIFFTOOL=$(git config --get diff.tool)
    if [[ $? -ne 0 ]]; then
        echo "difftool not found, $NAME cannot be installed."
    elif [[ "$DIFFTOOL" == "$NAME" ]]; then
        read -p "Uninstall $NAME? [y/n]: " ANS
        if [[ "$ANS" == "y" ]]; then
            TOOL=$(git config --get difftool.$NAME.tool)
            set -x
            git config diff.tool $TOOL
            git config --remove-section difftool.$NAME
            set +x
            echo "Completed."
        else
            echo "Cancelled."
        fi
    else
        read -p "Install $NAME? [y/n]: " ANS
        if [[ "$ANS" == "y" ]]; then
            set -x
            git config diff.tool $NAME
            git config difftool.$NAME.cmd "\".\\$SH_DIR/$FILE_NAME\" \"\$LOCAL\" \"\$REMOTE\""
            git config difftool.$NAME.tool $DIFFTOOL
            set +x
            echo "Completed."
        else
            echo "Cancelled."
        fi
    fi
    read -p "Setup finished. Press [Enter] key to exit."
    exit
fi

if [[ $# -eq 1 ]]; then
    echo "[$NAME tool setup mode]"
    cd "$(dirname "$1")"
    TOOL_DIR=$(git rev-parse --show-prefix)
    TOOL_FILE_NAME=$(basename "$1")
    read -p "Install $TOOL_FILE_NAME? [y/n]: " ANS
    if [[ "$ANS" == "y" ]]; then
        read -p "Type the target extension: ." EXT
        git config difftool.$EXT.textconv "\"./$TOOL_DIR/$TOOL_FILE_NAME\""
        echo "Completed."
    else
        echo "Cancelled."
    fi
    read -p "Setup finished. Press [Enter] key to exit."
    exit
fi

if [[ $# -ne 2 ]]; then
    echo "Usage: $FILE_NAME <LOCAL> <REMOTE>"
    exit 1
fi

TOOL=$(git config --get difftool.$NAME.tool)
CMD=$(git config --get difftool.$TOOL.cmd)

LOCAL=$1
REMOTE=$2

LOCAL_EXT=${LOCAL##*.}
REMOTE_EXT=${REMOTE##*.}

if [[ "$REMOTE_EXT" == "$REMOTE" ]]; then
    echo "File has no extension, compare without textconv."
    eval $CMD
    exit
fi

if [[ $LOCAL_EXT != $REMOTE_EXT ]]; then
    echo "Extensions not match, compare without textconv."
    eval $CMD
    exit
fi

TEXTCONV=$(git config --get difftool.$REMOTE_EXT.textconv)
if [[ $? -ne 0 ]]; then
    echo "'$REMOTE_EXT' textconv not found, compare without textconv."
    eval $CMD
    exit
fi

cd $(git rev-parse --show-toplevel)
TEXTCONV=$(eval echo $TEXTCONV)

LOCAL_TXT=$(mktemp)
REMOTE_TXT=$(mktemp)
LOCAL_CMD="\"$TEXTCONV\" \"$LOCAL\" > \"$LOCAL_TXT\""
REMOTE_CMD="\"$TEXTCONV\" \"$REMOTE\" > \"$REMOTE_TXT\""
eval $LOCAL_CMD
if [[ $? -ne 0 ]]; then
    echo "'$LOCAL_CMD' failed, compare without textconv."
    eval $CMD
    exit
fi
eval $REMOTE_CMD
if [[ $? -ne 0 ]]; then
    echo "'$REMOTE_CMD' failed, compare without textconv."
    eval $CMD
    exit
fi
LOCAL=$LOCAL_TXT
REMOTE=$REMOTE_TXT
eval $CMD
rm "$REMOTE_TXT"
rm "$LOCAL_TXT"
