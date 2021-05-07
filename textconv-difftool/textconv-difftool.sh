#!/bin/bash

#set -x

NAME="textconv-difftool"

if [[ $# -eq 0 ]]; then
    echo "[$NAME setup mode]"
    DIFFTOOL=$(git config --get diff.tool)
    if [[ $? -ne 0 ]]; then
        echo "difftool not found, $NAME cannot be installed."
    elif [[ "$DIFFTOOL" == "$NAME" ]]; then
        read -p "Uninstall $NAME? [y/n]: " ANS
        if [[ "$ANS" == "y" ]]; then
            TOOL=$(git config --get difftool.$NAME.tool)
            set -x
            git config --global diff.tool $TOOL
            git config --global --remove-section difftool.$NAME
            set +x
            echo "Completed."
        else
            echo "Cancelled."
        fi
    else
        read -p "Install $NAME? [y/n]: " ANS
        if [[ "$ANS" == "y" ]]; then
            DIR=$(cmd //c cd)
            set -x
            git config --global diff.tool $NAME
            git config --global difftool.$NAME.cmd "\"$DIR\\$(basename $0)\" \"\$LOCAL\" \"\$REMOTE\""
            git config --global difftool.$NAME.tool $DIFFTOOL
            set +x
            echo "Completed."
        else
            echo "Cancelled."
        fi
    fi
    read -p "Setup finished. Press [Enter] key to exit."
    exit
fi

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename $0) <LOCAL> <REMOTE>"
    exit 1
fi

TOOL=$(git config --get difftool.$NAME.tool)
CMD=$(git config --get difftool.$TOOL.cmd)

LOCAL=$1
REMOTE=$2

EXT1=${LOCAL##*.}
EXT2=${REMOTE##*.}

if [[ "$EXT2" == "$REMOTE" ]]; then
    echo "File has no extension, compare without textconv."
    eval $CMD
    exit
fi

if [[ $EXT1 != $EXT2 ]]; then
    echo "Extensions not match, compare without textconv."
    eval $CMD
    exit
fi

TEXTCONV=$(git config --get difftool.$EXT1.textconv)
if [[ $? -ne 0 ]]; then
    echo "'$EXT1' textconv not found, compare without textconv."
    eval $CMD
    exit
fi

TEXTCONV=$(eval echo $TEXTCONV)

LOCAL_TXT=.git/textconv_old.txt
REMOTE_TXT=.git/textconv.txt
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
