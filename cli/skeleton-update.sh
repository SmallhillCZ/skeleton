SKELETON=$1
TARGET=$SKELETON

# error if skeleton is not specified
if [ -z "$SKELETON" ]; then
    echo "Please specify skeleton folder"
    exit 1
fi

# if second argument is specified, use it as target
if [ ! -z "$2" ]; then
    TARGET=$2
fi

echo -e "Updating \033[33m./$TARGET\033[0m in \033[33morigin/$SKELETON_BRANCH\033[0m branch using skeleton \033[33m$SKELETON_ORIGIN#$SKELETON\033[0m"

if [ ! -e "./$TARGET" ]; then
    if [ "$FORCE" = "1" ]; then
        echo "Target does not exist, adding..."
        ACTION="add"
    else
        echo "Error: Cannot update, target $TARGET does not exist"
        exit 1
    fi
fi

source "${SCRIPT_DIR}/scripts/update-skeleton.sh" "$@"
