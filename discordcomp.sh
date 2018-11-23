#!/bin/bash
########################################
# This script needs `wc` and `seq`     #
# Set DB to a custom path if you want  #
# Note that this is untested           #
########################################


###########################
# Touch at your own peril #
###########################
TMP=/tmp/discordhelper
mkdir -p $TMP
rm -rf $TMP/*
DB=$TMP/pids
PID=0
COUNT=1

function thread {
    CURRENT="$1"
    PID=$2
    TMP="$3"

    if [[ -f "$TMP/$CURRENT.dummy" ]]
    then
        echo "$CURRENT already has an instance running or thread was force closed, exiting"
        exit
    fi
    if [[ -z $PID ]]
    then
        echo "vars not set, exiting"
        exit
    fi

    EXENAME="$(ps -q $PID -o comm=)"

    cp dummy "$TMP/$CURRENT.dummy"
    chmod +x "$TMP/$CURRENT.dummy"
    touch -t 200001010000 "$TMP/$CURRENT.dummy"
    "$TMP/$CURRENT.dummy" > /dev/null 2>&1 &
    DUMMYPID=$!

    while [ true ]
    do 
        if [[ "$(ps -q $PID -o comm=)" == "$EXENAME" ]]
        then
            sleep 5
        else
            kill -9 $DUMMYPID 
            sleep 1
            rm -f "$TMP/$CURRENT.dummy"
            exit
        fi
    done
    exit
}


while [[ true ]]
do
    pgrep -f "\.exe" -a | gawk 'sub(/\s/,"|")' | gawk -F\| 'function fn(f) { n=split(f,a,".exe"); gsub(/.*[\\\/]/,"",a[1]); f=sprintf(a[1] ".exe"); return(f) } IGNORECASE=1 { if ($2!~/(C:\\windows\\)|(Steam.exe)|(steamwebhelper.exe)|(\\Battle.net.exe)|([A-Z]:\\ProgramData\\Battle.net\\Agent\\Agent.[0-9]+\\Agent.exe)/ && $2~/^.*\.exe([^\.]+|\s.*)/) { f3=$2; gsub(/\s+$/,"",f3); f2=fn($2); if (f2==f3 || f3~/^[A-Z]\:.*/) { print $1 "|" f2 } } }' >$DB

    for i in $(seq 1 $(cat $DB | wc -l))
    do
        CURRENT=$(cat $DB | awk "NR == $COUNT")
        PID=`echo "$CURRENT" | awk -F\| '{print $1}'`
#        FULL=`echo "$CURRENT" | awk -F\| '{print $3}'`
        CURRENT=`echo "$CURRENT" | awk -F\| '{print $2}'`
        if [[ $PID == "0" ]]
        then
            true
        elif [[ -z "$PID" ]]
        then
            true
        else
            if [[ ! -f "$TMP/$CURRENT.dummy" ]]
            then
                echo "thread $CURRENT $PID $TMP"
                thread "$CURRENT" "$PID" "$TMP" > /dev/null 2>&1 &
            fi
        fi
        COUNT=$((COUNT + 1))
        if (( $COUNT > $(cat $DB | wc -l) ))
        then
            COUNT=1
        fi
        PID=0
    done
    sleep 10
done
