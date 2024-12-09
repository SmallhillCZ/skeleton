#!/bin/bash -e

help() {
    echo "Usage:"
    echo "  $CMD [options] <skeleton> [<target>]"
    echo "Options:"
    echo "  -r <repo>  Use custom repo (default: https://github.com/smallhillcz/skeletons)"
    echo "  -b <branch>  Use custom branch for skeletons (default: skeleton)"
    exit 0
}

init() {

    # check if branch skeleton exists locally
    if git show-ref --quiet refs/heads/$SKELETON_BRANCH; then
        echo "Error: Branch $SKELETON_BRANCH already exists"
        exit 1
    fi

    # create branch skeleton
    git switch -f --orphan $SKELETON_BRANCH

    # create empty commit
    git commit --allow-empty -m "chore(skeleton): init"

    # merge skeleton branch to current branch
    git switch $REPO_BRANCH
    git merge --allow-unrelated-histories --no-edit $SKELETON_BRANCH

}

add() {

    cleanup() {
        rm -fr $TEMP_DIR 1>/dev/null
        rm -fr $UNTRACKED_DIR 1>/dev/null
        git switch $REPO_BRANCH 1>/dev/null
        git merge --no-ff --no-edit $SKELETON_BRANCH
    }

    SKELETON=$1
    TARGET=$SKELETON

    # error if skeleton is not specified
    if [ -z "$SKELETON" ]; then
        echo "Please specify skeleton path"
        exit 1
    fi

    # if second argument is specified, use it as target
    if [ ! -z "$2" ]; then
        TARGET=$2
    fi

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

    # create a list of all files in the repository which are not tracked by git
    UNTRACKED_FILES=$(git status --porcelain | grep '^??' | cut -c4-)
    # append ignored files
    UNTRACKED_FILES="$UNTRACKED_FILES
    $(git check-ignore -- **/*)"

    # move untracked paths out of the way
    mkdir -p $UNTRACKED_DIR
    for path in $UNTRACKED_FILES; do
        mkdir -p $(dirname "$UNTRACKED_DIR/$path")
        mv -T "$REPO_ROOT/$path" "$UNTRACKED_DIR/$path"
    done

    # remove target directory and copy new skeleton
    rm -fr $REPO_ROOT/$TARGET 1>/dev/null
    cp -r $TEMP_DIR/skeleton/$SKELETON $REPO_ROOT/$TARGET 1>/dev/null

    git add -A $REPO_ROOT/$TARGET

    # return untracked paths back
    echo "Returning untracked files back"
    for path in $UNTRACKED_FILES; do
        mkdir -p $(dirname "$REPO_ROOT/$path")
        mv -T "$UNTRACKED_DIR/$path" "$REPO_ROOT/$path"
    done

    # if no staged files, exit
    if [ -z "$(git diff --cached --exit-code)" ]; then
        echo "No changes"
        cleanup
        exit 0
    fi

    # merge changes to original branch
    if [ -z "$TARGET_EXISTS" ]; then
        git commit -m "feat(skeleton): add $TARGET from $REPO#$SKELETON"
    else
        git commit -m "feat(skeleton): update $TARGET from $REPO#$SKELETON"
    fi

    # cleanup
    cleanup
}

update() {

    TARGET=$2

    if [ -e $REPO_ROOT/$TARGET ]; then
}

REPO=https://github.com/smallhillcz/skeletons
CMD=$(basename $0)
TEMP_DIR=$(mktemp -d)
SKELETON_BRANCH=skeleton
WORKDIR=$(pwd)
UNTRACKED_DIR=$REPO_ROOT/.untracked
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_BRANCH=$(git branch --show-current)

while [[ $# -gt 0 ]]; do
    case "$1" in
    -r | --repo)
        REPO=$2
        shift 2
        ;;

    -b | --branch)
        SKELETON_BRANCH=$2
        shift 2
        ;;

    -h | --help)
        help
        ;;

    init)
        shift
        init $@
        break
        ;;

    add)
        shift
        add $@
        break
        ;;
    update)
        shift
        update $@
        break
        ;;
    merge)
        shift
        merge $@
        break
        ;;

    *)
        echo "Error: Invalid option: $1" 1>&2
        exit 1
        ;;
    esac
done
