#!/bin/bash

function init_env(){
    CMD_PATH=`/bin/readlink -f $0`
    WORKING_DIR="`/usr/bin/dirname $CMD_PATH`"
    PROGRAM_NAME=`/bin/basename $0`
    START_TIME=`/bin/date`
}

function execute_script(){              # USER MODIFY
    while [[ $from_date -le $to_date ]]
    do
        echo "$script -d=$from_date"
        $script -d=$from_date
        from_date=$(date -d"$from_date + 1 day" +"%Y%m%d")
    done
}

function check_parameter(){
    from_date_str=""
    to_date_str=""
    script_str=""

    local options
    options=`/usr/bin/getopt -o f:t:s: -l help,from:,to:,script: -n "$PROGRAM_NAME" -- $*`
    if [ $? -ne 0 ]; then
        return 1
    fi

    eval set -- "$options"
    while true; do
        case "$1" in
            --help)
                print_usage
                exit 0
                ;;
            -f|--from)
                from_date_str=$2
                shift 2
                ;;
            -t|--to)
                to_date_str=$2
                shift 2
                ;;
            -s|--script)
                script_str=$2
                shift 2
                ;;
            --)
                shift
                break
                ;;
        esac
    done

}

function check_script(){
    script=$WORKING_DIR/$script_str
    local ret=0
    if [ ! -f $script ]; then
        echo 1>&2 "$script : file not exist."
        ret=1
    fi
    return $ret
}

function check_date(){
    local ret=0
    to_date=`/bin/date --date="${to_date_str:0:8}" +%Y%m%d 2> /dev/null`
    if [ $? -ne 0 ]; then
        echo 1>&2 "$PROGRAM_NAME: invalid TO_DATE($to_date_str) for -t option."
        ret=1
    fi

    from_date=`/bin/date --date="${from_date_str:0:8}" +%Y%m%d 2> /dev/null`
    if [ $? -ne 0 ]; then
        echo 1>&2 "$PROGRAM_NAME: invalid TO_DATE($to_date_str) for -t option."
        ret=1
    fi

    if [ $to_date -lt $from_date ]; then
        echo 1>&2 "$PROGRAM_NAME: TO_DATE($to_date) must be late then FROM_DATE($from_date)."
        ret=1
    fi
    return $ret
}


function print_usage()
{
    /bin/cat << EOF
    Usage: $PROGRAM_NAME [OPTION]...
    Mandatory arguments to long options are mandatory for short options too.
     -f, --from=FROM_DATE      start of date period.
     -t, --to=TO_DATE          end of date period.
     -s, --script=SCRIPT_FILE  specify the execute script file.
     --help                    display this help and exit

EOF
}


### start of script ###
start_time="$(date -u +%s)"
echo "### init_env"
init_env

echo "### check_parameter"
check_parameter $*
if [ $? -ne 0 ]; then
    echo 1>&2 "Try '$PROGRAM_NAME --help' for more information."
    exit 1
fi

echo "### check_script"
check_script
if [ $? -ne 0 ]; then
    exit 1
fi

echo "### check_date"
check_date
if [ $? -ne 0 ]; then
    exit 1
fi

echo "### execute_script"
execute_script
end_time="$(date -u +%s)"

echo "## `/bin/date` end (started $START_TIME; elapsed "$(($end_time-$start_time))"sec) ##"
exit 0
