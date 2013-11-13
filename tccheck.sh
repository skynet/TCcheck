#!/bin/sh
#: tccheck v0.1
#: ~~~~~~~~~~~~~~
#: Command-line utility to test for potential TrueCrypt containers
#:
#: :author: Kent Ma
#: :year: 2013
#:

#: Simple checks - TrueCrypt containers:
#: - have no known file headers
#: - are > 5 MB 
#: - have a file size divisible by 512.
basicchecks() 
{
    size=$(du -b $1 | awk '{print $1}')

    if [[ $(expr $size \> $(expr 5 \* 1024 \* 1024)) == '0' \
                            || $(expr $size % 512) > 0 \
                            || $(file $1 | awk '{print $2}') != 'data' ]]; then
        echo 0
        return
    fi
    echo 1
}

#: Chi-Squred Randomness Test
#: 
# TODO: Actually implement this
chicheck()
{
    echo 0
}

#: Run all tests on the file
tests()
{
    basic=$(basicchecks $1)
    chi=$(chicheck $1)
    if [[ $basic == '0' && $chi == '0' ]]; then
        echo "0"
    else
        echo "1"
    fi
}

usage() 
{
    echo -e "Usage: $0 [OPTION] file\n"
    echo "  -r       check subdirectories recursively"
    echo "  -v       verbose file checking"
    echo "  -h       display this help and exit"
}

OPTIND=1
rflag=
vflag=
args=""
while getopts "hrv" opt; do
    args+=$opt
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        r)
            rflag=1
            ;;
        v)
            vflag=1
            ;;
        *)
            echo "Try '$0 -h' for more information."
            exit 0
            ;;
    esac
done
shift $(($OPTIND - 1))

filename=$@
if [[ ! -e $filename ]]; then
    echo "$0: $1: No such file or directory"
    exit 1
fi

if [[ ! $rflag == 1 && -d $filename ]]; then
    echo -e "$0: $1: Is a directory."
    exit 1
else
    # Recursively check the directory specified.
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    for i in $(ls -A $filename); do
        if [[ -f $i ]]; then
            testval=$(tests $i)
            if [[ $vflag == 1 ]]; then
                echo "$i: $testval"
            else
                if [[ $testval == 1 ]]; then
                    if [[ $rflag == 1 ]]; then
                        echo $i
                    else
                        echo 1
                    fi
                fi
            fi
        fi
        
        if [[ -d $filename ]]; then
            ./$0 -$args $filename/$i
        fi
    done
    IFS=$SAVEIFS
fi
