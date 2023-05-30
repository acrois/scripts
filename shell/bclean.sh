#!/bin/bash
set -eo pipefail

TEST_MODE=false
PUSH=false
DRY_RUN=true
REPO_PATH=
ANNOTATED_TAGS=true
KEEP_BRANCHES="trunk master main"

# list_include_item "10 11 12" "2"
function list_include_item {
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
    # yes, list include item
    result=0
  else
    result=1
  fi
  return $result
}

usage() {
    echo -e "\nUsage:\n" \
        "\t$0 --test --push --apply\n" \
        "\nFlags:\n" \
        "\t--keep [branch]     - keep a branch by name\n" \
        "\t--path [path]       - path to git repository\n" \
        "\t--test              - creates a git repository to self-test the cleanup procedure\n" \
        "\t--apply             - disable dry run and do it for real\n" \
        "\t--unannotated       - do not use annotated tags\n" \
        "\t--push, -p          - push after applying\n" \
        "\t--v                 - verbose output (\`set -x\`)\n" \
        "\t--help              - prints this useful information\n" >&2
    exit 1
}

# Process flags/options
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        --v)
            set -x
            ;;
        --help)
            usage
            ;;
        --path|-p)
            REPO_PATH=$VALUE
            ;;
        --apply)
            DRY_RUN=false
            ;;
        --push)
            PUSH=true
            ;;
        --test)
            TEST_MODE=true
            ;;
        --keep)
            KEEP_BRANCHES="$KEEP_BRANCHES $VALUE"
            ;;
        --unannotated)
            ANNOTATED_TAGS=false
            ;;
        *)
            echo "Unrecognized $PARAM"
            break
            ;;
    esac
    shift
done

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

_main() {
    if [ $TEST_MODE = true ]; then
        REPO_PATH="./test"
        REPO_TEST_ORIGIN="${REPO_PATH}2"

        # Clean up any previous test
        rm -rf $REPO_PATH
        rm -rf $REPO_TEST_ORIGIN

        # Create test repository
        git init -b trunk $REPO_PATH

        # Commit to main branch
        echo "Test" > $REPO_PATH/test.txt
        git -C $REPO_PATH add .
        git -C $REPO_PATH commit -m "Initial commit"

        # Create new branch
        git -C $REPO_PATH checkout -b test/branch
        echo "Test Again" >> $REPO_PATH/test.txt
        git -C $REPO_PATH add .
        git -C $REPO_PATH commit -m "Another one"

        # Switch to main
        git -C $REPO_PATH checkout trunk

        git init --bare $REPO_TEST_ORIGIN
        git -C $REPO_PATH remote add origin "$(dirname $(readlink -e $REPO_TEST_ORIGIN))/$(basename $REPO_TEST_ORIGIN)"
        git -C $REPO_PATH push origin --all
    fi

    git -C $REPO_PATH fetch --all

    if [ $DRY_RUN = true ]; then
        echo "================================="
        echo "DRY RUN - NOTHING WILL BE CHANGED"
        echo "================================="
    fi

    local current_date=`date +%Y%m%d`

    # Process branches
    for branch in $(git -C $REPO_PATH for-each-ref --format='%(refname)' refs/heads/); do
        branch_name="${branch/'refs/heads/'/''}"

        if `list_include_item "$KEEP_BRANCHES" "$branch_name"`; then
            echo "Skipping $branch_name (kept branch)"
            continue
        fi

        # TODO: Optional - Check GitHub Repo Protected Branches?
        # curl -L \
        #   -H "Accept: application/vnd.github+json" \
        #   -H "Authorization: Bearer <YOUR-TOKEN>"\
        #   -H "X-GitHub-Api-Version: 2022-11-28" \
        #   https://api.github.com/repos/OWNER/REPO/branches/BRANCH/protection

        echo "Processing $branch_name"

        # Tag branch

        if [ $ANNOTATED_TAGS = true ]; then
            git -C $REPO_PATH tag "archive/$current_date/$branch_name" -a -m "Archive of $branch_name on $current_date" $branch_name
        else
            git -C $REPO_PATH tag "archive/$current_date/$branch_name" $branch_name
        fi

        # Delete branch
        git -C $REPO_PATH branch -D $branch_name

        # Delete branch from origin
        if [[ $DRY_RUN = false && $PUSH = true ]]; then
            git -C $REPO_PATH push origin :$branch_name
        fi
    done

    # Push tags to origin
    if [[ $DRY_RUN = false && $PUSH = true ]]; then
        git -C $REPO_PATH push origin --tags
    fi
}

# If we are sourced from elsewhere, don't perform any further actions
if ! _is_sourced; then
	_main "$@"
fi
