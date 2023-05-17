#!/bin/bash
set -eo pipefail
# set -x

MODE=
CLIENT_PARAMS=
OUTPUT_FILE=
SOURCE_FILE=
TARGET_FILE=

OLD_BASE=
NEW_BASE=
NEW_SCHEME=
STRIP_TRIGGERS=
STRIP_TABLE_DATA=
INSERT_USE=

usage() {
    echo -e "\nUsage:\n" \
        "\t$0 prepare test.sql --insert-use=test --stip-data=test --old-base=test.com --new-base=test.localhost --new-scheme=http\n" \
        "\nFlags:\n" \
        "\t--v                 - verbose output (\`set -x\`)\n" \
        "\t--help              - prints this useful information\n" \
        "\nprepare [file] [options]\n" \
        "\t--old-base          - Segment of regular expression matching hostname & path to find for --new-base\n" \
        "\t--new-base          - Segment of hostname & path to substitute --old-base with\n" \
        "\t--new-scheme        - Segment of scheme (e.g. \"http\" or \"https\") for --new-base\n" \
        "\t--strip-triggers    - Remove any database triggers, specify a value for a delimiter (default \";;\")\n" \
        "\t--strip-data        - Escaped, pipe delimited (e.g. \"test\\|test2\") of tables to remove data. Specify flag multiple times to concatenate tables.\n" \
        "\t--insert-use        - Prepends USE statement with defined schema to database dump SQL\n" \
        "\nbackup [flags]\nrestore [file] [options]\n" \
        "\t--wordpress         - Looks up values in wp-config.php (if available and PHP is installed)\n" \
        "\t-t, --target-file   - Output filename override, default is based on the current timestamp\n" \
        "\t-M, --M             - Passthru to MySQL client/MySQL dump options\n" >&2
    exit 1
}

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

_main() {
    MODE=$1

    if [ -z $MODE ]; then
        echo "Invalid MODE!"
        usage
    fi
    
    shift # Remove $MODE

    case $MODE in
        prepare | restore)
            SOURCE_FILE=$1

            # Requires source file
            if [ -z $SOURCE_FILE ]; then
                echo "No source file specified!"
                exit 1
            fi
            shift # Remove file
            ;;
        --help | help)
            usage
            ;;
    esac

    # Print and yell about source files
    if [ ! -z $SOURCE_FILE ]; then
        echo "Source: $SOURCE_FILE"

        if [ ! -f $SOURCE_FILE ]; then
            echo "Source does not exist!"
            usage
        fi
    fi

    # Specify default target file
    #  if mode is not restore
    if [ $MODE != 'restore' ]; then
        if [ -z $TARGET_FILE ]; then
            TARGET_FILE="$MODE-$(date +%Y.%m.%d-%H.%M.%S).sql"
        fi

        echo "Target: $TARGET_FILE"
    fi

    # Process flags/options
    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            --wordpress)
                echo "TODO"
                ;;
            --old-base)
                OLD_BASE=$VALUE
                ;;
            --new-base)
                NEW_BASE=$VALUE
                ;;
            --new-scheme)
                NEW_SCHEME=$VALUE
                ;;
            --strip-triggers)
                STRIP_TRIGGERS=${VALUE:-'\;\;'}
                ;;
            --strip-data)
                if [ ! -z $VALUE ]; then
                    STRIP_TABLE_DATA="${STRIP_TABLE_DATA:+$STRIP_TABLE_DATA\|}$VALUE"
                fi
                ;;
            --insert-use)
                INSERT_USE=$VALUE
                ;;
            --target-file | -t)
                TARGET_FILE=$VALUE
                ;;
            --M* | -M*)
                CLIENT_PARAMS="${CLIENT_PARAMS:+$CLIENT_PARAMS }$PARAM${VALUE:+=$VALUE}"
                ;;
            --v)
                set -x
                ;;
            --help)
                usage
                ;;
            *)
                echo "Unrecognized $PARAM"
                break
                ;;
        esac
        shift
    done

    case $MODE in
        backup | restore)
            if [ ! -z $CLIENT_PARAMS ]; then
                # Replace "-M" with "-" to cover --M and -M cases
                CLIENT_PARAMS=`echo "$CLIENT_PARAMS" | sed 's/\-M/-/'`
                echo "MySQL: $CLIENT_PARAMS"
            fi
            ;;
    esac

    case $MODE in
        prepare)
            cp $SOURCE_FILE $TARGET_FILE

            # Table Data Cleanup
            if [ ! -z "$STRIP_TABLE_DATA" ]; then
                echo "Stripping table data: "$STRIP_TABLE_DATA" segment..."
                FULLREGEX='/INSERT INTO `*\('$STRIP_TABLE_DATA'\)\{1,\}/d'
                echo "Stripping table data: \"$FULLREGEX\""
                sed -i "$FULLREGEX" $TARGET_FILE
            fi

            # Trigger removal
            if [ ! -z "$STRIP_TRIGGERS" ]; then
                echo "Stripping triggers ($STRIP_TRIGGERS)..."
                FULLREGEX='s/DELIMITER '$STRIP_TRIGGERS'(.*?TRIGGER.*?)DELIMITER \;//gis'
                perl -0777 -pi -e "$FULLREGEX" $TARGET_FILE
            fi

            # Replace URLs
            if ! [[ -z $OLD_BASE && -z $NEW_BASE && -z $NEW_SCHEME ]]; then
                echo "Replacing $OLD_BASE with $NEW_BASE ($NEW_SCHEME)..."
                perl -pi -e "s/https?:\/\/$OLD_BASE/$NEW_SCHEME:\/\/$NEW_BASE/gi" $TARGET_FILE
                perl -pi -e "s/$OLD_BASE/$NEW_BASE/gi" $TARGET_FILE
            fi

            # USE statement
            if [ ! -z $INSERT_USE ]; then
                echo "Using: $INSERT_USE"
                sed -i "1s+^+USE \`$INSERT_USE\`;\n+" $TARGET_FILE
            fi
            ;;
        backup)
            echo "TODO"
            ;;
        restore)
            echo "TODO"
            ;;
    esac

    # gzip -9 -v $TARGET_FILE
}

# If we are sourced from elsewhere, don't perform any further actions
if ! _is_sourced; then
	_main "$@"
fi
