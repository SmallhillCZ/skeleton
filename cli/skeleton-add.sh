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

echo -e "Adding skeleton \033[33m$SKELETON_ORIGIN#$SKELETON\033[0m as \033[33m./$TARGET\033[0m to \033[33morigin/$SKELETON_BRANCH\033[0m branch"

if [ -e "./$TARGET" ]; then
    if [ "$FORCE" = "1" ]; then
        echo "Target already exists, updating..."
        ACTION="update"
    else
        echo "Error: Cannot add, target $TARGET already exists"
        exit 1
    fi
fi

source "${SCRIPT_DIR}/scripts/update-skeleton.sh" "$@"
