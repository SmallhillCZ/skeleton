TARGET_ROOT=$(git rev-parse --show-toplevel)
TARGET_BRANCH=$(git branch --show-current)
TARGET_ORIGIN=$(git remote get-url origin)

if [ -z "$TARGET_ORIGIN" ]; then
    echo "No origin URL found"
    exit 1
fi

cd $TEMP_DIR

# issue warning when REPO_BRANCH is equal to SKELETON_BRANCH
if [ "$TARGET_BRANCH" == "$SKELETON_BRANCH" ]; then
    echo -e "\033[33mWarning:\033[0m current branch ($TARGET_BRANCH) is equal to skeleton branch ($SKELETON_BRANCH)"
fi

git clone --quiet --depth=1 $SKELETON_ORIGIN skeleton

if [ ! -e "$TEMP_DIR/skeleton/$SKELETON" ]; then
    echo "Skeleton $SKELETON not found in $SKELETON_ORIGIN"
    rm -fr $TEMP_DIR
    exit 1
fi

echo ""

if git clone --quiet -b $SKELETON_BRANCH --depth=1 $TARGET_ORIGIN target; then
    cd target
else
    echo -e "Branch \033[33m$SKELETON_BRANCH\033[0m not found in \033[33m$TARGET_ORIGIN\033[0m, initializing..."
    mkdir target
    cd target
    git init -b $SKELETON_BRANCH
    git commit -m "${COMMIT_PREFIX}init" --allow-empty
    git remote add origin $TARGET_ORIGIN
fi

# remove target and copy new skeleton
rm -fr "./$TARGET"
cp -r ../skeleton/$SKELETON $TARGET

git add $TARGET

# if no staged files, exit
if [ -z "$(git diff --cached --exit-code)" ]; then
    echo "No changes"

    # cleanup
    rm -rf $TEMP_DIR
    cd $WORKDIR
    exit 0
elif [ "$action" = "update" ]; then
    git commit -m "${COMMIT_PREFIX}update ./$TARGET from $SKELETON_ORIGIN#$SKELETON"
else
    git commit -m "${COMMIT_PREFIX}add ./$TARGET from $SKELETON_ORIGIN#$SKELETON"
fi

git push -u origin $SKELETON_BRANCH

# cleanup
rm -rf $TEMP_DIR

# merge changes to original branch
cd $TARGET_ROOT
git fetch origin $SKELETON_BRANCH

# return to original branch and merge
echo "Merging changes from \033[33m$SKELETON_BRANCH\033[0m to \033[33m$TARGET_BRANCH\033[0m..."

git switch $TARGET_BRANCH
git merge --no-ff --no-edit --allow-unrelated-histories origin/$SKELETON_BRANCH

cd $WORKDIR
