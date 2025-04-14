#!/bin/bash -e

SKELETON_ORIGIN=https://github.com/smallhillcz/skeletons
SKELETON_BRANCH=skeleton

WORKDIR=$(pwd)
TEMP_DIR=$(mktemp -d)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

COMMIT_PREFIX="chore(skeleton): "

FORCE=0

help() {
    CMD=$(basename $0)
    PACKAGE_ROOT=$(realpath "$(dirname $(realpath $0))/..")
    VERSION=$(jq -r '.version' $PACKAGE_ROOT/package.json)
    echo "@smallhillcz/skeleton v$VERSION"
    echo ""
    echo "Usage:"
    echo "  $CMD [options] add <skeleton> [<target>]"
    echo "  $CMD [options] update <skeleton> [<target>]"
    echo "  $CMD help"
    echo ""
    echo "Options:"
    echo "  -h                  Show this help message"
    echo "  -r <repo>           Use custom repo (default: https://github.com/smallhillcz/skeletons)"
    echo "  -b <branch>         Use custom branch for skeletons (default: skeleton)"
    echo "  -c <commit-prefix>  Use custom commit prefix (default: \"chore(skeleton): \")"
    echo "  -f                  Force update if target already exists or add if target does not exist"
}

while getopts ":r:hfb:" opt; do
    case "${opt}" in
    r)
        REPO=$OPTARG
        shift
        ;;
    b)
        SKELETON_BRANCH=$OPTARG
        shift
        ;;
    c)
        COMMIT_PREFIX=$OPTARG
        shift
        ;;
    f)
        FORCE=1
        shift
        ;;
    h)
        help
        exit 0
        ;;
    :)
        echo "Error: Option -${OPTARG} requires an argument."
        exit 1
        ;;
    \?)
        echo "Error: Invalid option: $OPTARG" 1>&2
        exit 1
        ;;
    esac
done

ACTION=$1
shift || true

# switch based onthe first argument
case $ACTION in
# add command
add)
    source "${SCRIPT_DIR}/skeleton-add.sh" "$@"
    exit 0
    ;;
update)
    source "${SCRIPT_DIR}/skeleton-update.sh" "$@"
    exit 0
    ;;
help)
    help
    exit 0
    ;;
*)
    echo "Error: Missing or unknown command: \"$ACTION\"" 1>&2
    echo ""
    help
    exit 1
    ;;
esac
