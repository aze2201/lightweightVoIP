#!/bin/bash

curr=$(pwd)
script_path=$curr/scripts
log_path=$curr/log
log_filename=logParse.log


#$script_path/waiting.sh &

rm communicate_pipe
mkfifo communicate_pipe

exec 3<> communicate_pipe

cat communicate_pipe - | python3 wsdump.py ws://127.0.0.1:8001 | while read line; do   
  res=$(echo ${line} | grep "{" | grep "}");  
  if [ $? -eq 0 ]; then     
    line=$(echo -e ${line} | tr '>' ' ' | tr '<' ' '|sed 's/ //g'| sed "s/u'/'/g"| sed "s/'/\\\\\"/g");
    echo "$(date) : TERMINAL : ${line}" >> $log_path/$log_filename     
    cmd="./core.sh \"${line}\" > communicate_pipe";    
    eval $cmd;
  fi; 
done
  
