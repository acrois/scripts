#!/usr/bin/env bash
set -eo pipefail

# =========
# calver.sh
# =========
# Description: Utility for automatically tagging git repositories using CalVer.
# Author:      Aaron Croissette
# Created:     2023.05.10

FORMAT=
DRY_RUN=true
PUSH=false
FROM_DATE=
VARIANT=
REV=0
FULLVER=
SEMIVER=
VER=
SHOW=

tag() {
    local SHA=$1
    local TAG=$2

    if [ ! -z $SHOW ]; then
        echo "Adding $TAG"
    fi

    if [ $DRY_RUN = false ]; then
        git tag -d $TAG || true
        git tag $TAG
    fi
}

format_variant() {
    local __resultvar=
    local myresult=
    local VARIANT=
    local REVISION=

    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            --o)
                __resultvar=$VALUE
                ;;
            --i)
                myresult=$VALUE
                ;;
            --v)
                VARIANT=$VALUE
                ;;
            --r)
                REVISION=$VALUE
                ;;
            *)
                echo "ERROR: unknown parameter \"$PARAM\""
                exit 1
                ;;
        esac
        shift
    done

    if [ ! -z $VARIANT ]; then
        myresult="$myresult-$VARIANT"
    fi

    if [ ! -z $REVISION ]; then
        myresult="$myresult.$REVISION"
    fi

    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myresult'"
    else
        echo "$myresult"
    fi
}

ver_for_date() {
    local __resultvar=
    local FORMAT=
    local FROM_DATE='now'

    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            --o)
                __resultvar=$VALUE
                ;;
            --fmt)
                FORMAT=$VALUE
                ;;
            --d)
                FROM_DATE=$VALUE
                ;;
            *)
                echo "ERROR: unknown parameter \"$PARAM\""
                exit 1
                ;;
        esac
        shift
    done

    local myresult=

    if [ -z $FORMAT ]; then
        # Fix for zero-padding the %w (day of week)
        myresult="'$(printf "%s.%02d" $(date +%Y.%V -d "$FROM_DATE") $(date +%w -d "$FROM_DATE"))'"
    else
        myresult="'$(date +\"$FORMAT\" -d "$FROM_DATE")'"
    fi

    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myresult'"
    else
        echo "$myresult"
    fi
}

usage() {
    # Substitute some defaults for useful help dialog integration...
    FROM_DATE='2023-05-10'
    VARIANT='dev'
    REV=10
    FORMAT=''

    # Generate some example versions based on the date
    ver_for_date --o='VER' --d=$FROM_DATE
    format_variant --o='FULLVER' --i=$VER --v=$VARIANT --r=$REV
    format_variant --o='SEMIVER' --i=$VER --v=$VARIANT

    echo -e "\nUsage:\n" \
        "\t$0 --version=\"$VER\" --variant=\"$VARIANT\" --revision=\"$REV\"\n" \
        "\t$0 --from-date=\"$FROM_DATE\" --variant=\"$VARIANT\" --revision=\"$REV\"\n" \
        "\nOutput tags:\n" \
        "\tRevision:  $FULLVER\n" \
        "\tVariant:   $SEMIVER\n" \
        "\tCalendar:  $VER\n" \
        "\nFlags:\n" \
        "\t--format            - date format, defaults to %Y.%V.%w according to \`man date\`\n" \
        "\t--version           - version to release\n" \
        "\t--from-date         - date to base version off of\n" \
        "\t--variant           - adds a variant incrementer e.g $LESSVER\n" \
        "\t--revision          - adds a revision incrementer after the variant e.g $FULLVER\n" \
        "\t--apply             - disable dry run and do it for real\n" \
        "\t--push              - push after applying\n" \
        "\t--show              - show version tag (values: calendar, variant, revision)\n" \
        "\t--help              - prints this useful information\n" >&2
    exit 1
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        --version)
            VER=$VALUE
            ;;
        --format)
            FORMAT=$VALUE
            ;;
        --date)
            FROM_DATE=$VALUE
            ;;
        --revision)
            REV=$VALUE
            ;;
        --apply)
            DRY_RUN=false
            ;;
        --push)
            PUSH=true
            ;;
        --variant)
            VARIANT=$VALUE
            ;;
        --show)
            SHOW=$VALUE
            ;;
        --help)
            usage
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            exit 1
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
    if [ -z $VER ]; then
        ver_for_date --o='VER' --fmt=$FORMAT
    fi

    if [ -z $VER ]; then
        echo "No version detected, aborting."
        exit 1
    fi

    FETCH=`git fetch --all 2>/dev/null`
    GIT_SHA=`git rev-parse HEAD`
    
    if [ -z $SHOW ]; then
        echo "Current git SHA: $GIT_SHA"
    fi

    if [ -z $SHOW ]; then
        echo "Calendar: $VER"
    fi

    if [ ! -z $VARIANT ]; then
        format_variant --o='SEMIVER' --i=$VER --v=$VARIANT

        if [ -z $SHOW ]; then
            echo "Variant: $SEMIVER"
        fi
    fi
    
    VARLOOK=${SEMIVER:-$VER}
    CURR_TAG=`git tag -l --sort=-version:refname "$VARLOOK.*" | head -n 1 2>/dev/null`;
    # VARTAGS=`git tag -l --sort=refname "$VARLOOK*"`

    if [ ! -z $CURR_TAG ]; then
        CURR_TAG_SHA=`git rev-list -n 1 $CURR_TAG`

        if [[ "$GIT_SHA" != "$CURR_TAG_SHA" ]]; then
            OLD_IFS=$IFS
            IFS='.'
            read -a CURR_TAG_PARTS <<< "$CURR_TAG"
            IFS=$OLD_IFS
            CURR_REV=${CURR_TAG_PARTS[3]}
            REV="$((CURR_REV + 1))"

            if [ -z $SHOW ]; then
                echo "Existing revision $CURR_REV, incrementing ours to $REV"
            fi
        else
            if [ -z $SHOW ]; then
                echo "Existing revision $CURR_TAG, already tagged on our commit"
            fi
        fi
    fi

    format_variant --o='FULLVER' --i=$VER --v=$VARIANT --r=$REV

    if [ -z $SHOW ]; then
        echo "Revision: $FULLVER"
    fi

    case $SHOW in
        'calendar')
            echo -n $VER
            exit
            ;;
        'variant')
            echo -n $SEMIVER
            exit
            ;;
        'revision')
            echo -n $FULLVER
            exit
            ;;
        *)  ;;
    esac
    
    if [ $DRY_RUN = true ]; then
        echo "================================="
        echo "DRY RUN - NOTHING WILL BE CHANGED"
        echo "================================="
    fi

    # You are either tagging a variant or the main version
    if [ -z $SEMIVER ]; then
        tag $GIT_SHA $VER
    else
        tag $GIT_SHA $SEMIVER
    fi

    # You are always tagging a revision
    tag $GIT_SHA $FULLVER

    if [[ $DRY_RUN = false && $PUSH != false ]]; then
        git push origin --tags -f
    fi
}

# If we are sourced from elsewhere, don't perform any further actions
if ! _is_sourced; then
	_main "$@"
fi
