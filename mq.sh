#!/bin/sh
################################################################
# MQTT Shell (Using pipes)

# export PATH=/usr/sbin:/bin:/usr/bin:/sbin:/var/bin
host=localhost
pipe=p
binStream=/tmp/tmp_binary
binDest=/tmp/bin

#pidfile=/var/run/subclient
# remove pipe on exit to keep things sane
trap "rm -f $pipe;rm enc;rm denc;rm output" EXIT INT
# Creat our pipe
if [ ! -p p ]; then
    mkfifo $pipe
fi
# Daemonize subclient and write to pipe (no hup needed!)
(subclient -h $host -t shell > $pipe) &
#pid=$!;echo pid="$!" > $pidfile &
# This is the magic. From mqsh, typing "quit' cleans everything up too.

while read line <$pipe
do
  echo $line > enc
#for i in quit _binary_ ps;do echo $i > tmpf;if ;then echo exiting now;elif grep -q "_binary_" $tmpf;then echo "This is binary data"; else sh $tmpf;fi;done

    base64 -d enc > denc;> enc
    if grep -q "quit" denc; then
        break
    fi
# If sending a binary, insert _binary_ as the first line, check for that,
    if grep -q "_binary_" denc; then
      #echo "$line" > $binStream
# remove it and save the binary to /tmp/bin
      sed '1d' denc > $binDest
      if ([ $? -eq "0" ]);then 
        echo 'Successfully transfered binary :' > output 
        ls -l $binDest >> output
      else 
        echo 'Failed to write binary' > output
      fi
# publish status
      pubclient -h $host -t data -f output;>output
    else
      sh denc > output
      pubclient -h $host -t data -f output;>output
    fi
done
#pid=`cat pidfile`;(kill $pid  && rm $pidfile) &>2 > /dev/null
exit
