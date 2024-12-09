#!/bin/bash -e

REPO=https://github.com/smallhillcz/skeletons
CMD=$(basename $0)
TEMP_DIR=$(mktemp -d)
# TEMP_DIR=/workspaces/tmp
SKELETON=$1
TARGET=$SKELETON
SKELETON_BRANCH=skeleton
WORKDIR=$(pwd)
MODULE_DIR=$(dirname $(realpath $0))

VERSION=$(jq -r '.version' $MODULE_DIR/../package.json)

# error if skeleton is not specified
if [ -z "$SKELETON" ]; then
    echo "Please specify skeleton folder"
    exit 1
fi

# if second argument is specified, use it as target
if [ ! -z "$2" ]; then
    TARGET=$2
fi

# select custom repo with -r option
while getopts ":r:hb:" opt; do
    case ${opt} in
    r)
        REPO=$OPTARG
        ;;
    b)
        SKELETON_BRANCH=$OPTARG
        ;;
    h)
        echo "@smallhillcz/skeleton v$VERSION"
        echo ""
        echo "Usage:"
        echo "  $CMD [options] <skeleton> [<target>]"
        echo "Options:"
        echo "  -r <repo>  Use custom repo (default: https://github.com/smallhillcz/skeletons)"
        echo "  -b <branch>  Use custom branch for skeletons (default: skeleton)"
        exit 0
        ;;
    \?)
        echo "Error: Invalid option: $OPTARG" 1>&2
        exit 1
        ;;
    esac
done

REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_BRANCH=$(git branch --show-current)

cd $REPO_ROOT

# issue warning when REPO_BRANCH is equal to SKELETON_BRANCH
if [ "$REPO_BRANCH" == "$SKELETON_BRANCH" ]; then
    echo -e "\033[33mWarning:\033[0m current branch ($REPO_BRANCH) is equal to skeleton branch ($SKELETON_BRANCH)"
fi

if [ -e $REPO_ROOT/$TARGET ]; then
    TARGET_EXISTS=1
fi

if [ -z $TARGET_EXISTS ]; then
    echo -e "Adding \033[33m$SKELETON\033[0m from \033[33m$REPO\033[0m to \033[33m$TARGET\033[0m in \033[33mskeleton\033[0m branch and merging to \033[33m$REPO_BRANCH\033[0m"
else
    echo -e "Updating \033[33m$SKELETON\033[0m from \033[33m$REPO\033[0m to \033[33m$TARGET\033[0m in \033[33mskeleton\033[0m branch and merging to \033[33m$REPO_BRANCH\033[0m"
fi

echo ""

git clone --quiet --depth=1 $REPO $TEMP_DIR/skeleton 1>/dev/null

if [ ! -e "$TEMP_DIR/skeleton/$SKELETON" ]; then
    echo "Skeleton $SKELETON not found in $REPO"
    rm -fr $TEMP_DIR 1>/dev/null
    exit 1
fi

if git show-ref --quiet refs/heads/$SKELETON_BRANCH; then
    git switch $SKELETON_BRANCH 1>/dev/null
else
    git switch -c $SKELETON_BRANCH 1>/dev/null
fi

# move untracked files from original branch out of the way
git stash -a 1>/dev/null

# remove target directory and copy new skeleton
rm -fr $REPO_ROOT/$TARGET 1>/dev/null
cp -r $TEMP_DIR/skeleton/$SKELETON $REPO_ROOT/$TARGET 1>/dev/null

git add -A $REPO_ROOT/$TARGET

# return untracked files back
git stash pop 1>/dev/null

# if no staged files, exit
if [ -z "$(git diff --cached --exit-code)" ]; then
    echo "No changes"

    # cleanup
    rm -fr $TEMP_DIR/skeleton 1>/dev/null
    rm -d $TEMP_DIR 1>/dev/null

    # return to original branch
    git switch $REPO_BRANCH 1>/dev/null
    exit 0
fi

# merge changes to original branch
if [ -z "$TARGET_EXISTS" ]; then
    git commit -m "feat(skeleton): add $TARGET from $REPO#$SKELETON"
else
    git commit -m "feat(skeleton): update $TARGET from $REPO#$SKELETON"
fi

# cleanup
rm -fr $TEMP_DIR/skeleton 1>/dev/null
rm -d $TEMP_DIR 1>/dev/null

# return to original branch and merge
git switch $REPO_BRANCH 1>/dev/null

git merge --no-ff --no-edit $SKELETON_BRANCH
