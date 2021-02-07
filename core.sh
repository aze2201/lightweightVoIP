#!/bin/bash
 
#{"command\":\"updatePeerID\",\"token\":\"YjA0OTY5YzcyMTI1Yzc1OTljNTcxYjky\",\"peerID\":\"12345qwert\"}
#{"command":"updatePeerID","token":"YjA3NDY1ODRlYTVlYjc3MzExMWI1NDA5","peerID":"12345qrewewt"}
#{"command":"updatePeerID","token":"YjA3NDY1ODRlYTVlYjc3MzExMWI1NDA5","peerID":"12345qwert"}
#{"command":"updatePeerID","token":"YjA3NDY1ODRlYTV","peerID":"12345qwert123"}
#{"command":"updatePeerID","token":"YjA3NDY1ODRlYTV1","peerID":"4545tytyt"}
# {"command":"updatePeerID","token":"YjAddNDY1ODRlYTV1","peerID":"wewew"}


#--------customer calling---------
#./parse.sh "{\"command\":\"startcall\",\"context\":\"azeee\"}"
# {"command":"startcall","context":"azeee","token":"YjA3NDY1ODRlYTV","callerPeerID":"12345qwert123"} 
#           {"command":"startcall","context":"azeee","token":"YjA3NDY1ODRlYTV1","callerPeerID":"4545tytyt"}
#                {"command":"startcall","context":"azeee","token":"YjAddNDY1ODRlYTV1","callerPeerID":"wewew"}
#--------member answering---------
#./parse.sh "{\"command\":\"answer\",\"token\":\"OWYwNjVjZGEzMWNmYjlkNTRlZmY4Mjc5\"}"
#{"command":"answer","token":"YjA3NDY1ODRlYTVlYjc3MzExMWI1NDA5","callerPeerID":"12345qwert123"}
#-------end call------------------
#{"command":"endcall","token":"YjA3NDY1ODRlYTVlYjc3MzExMWI1NDA5","remotePeerID":"12345qwert123"}
# ------reject call-----------
#{"command":"reject","token":"YjA3NDY1ODRlYTVlYjc3MzExMWI1NDA5","callerPeerID":"12345qwert123"}


## NOTES:
# if one of member reject call it will send stoprginging and to all member and will send busy call to caller
# need to keep call status. to idetify user is busy or not


jsonMessage=$1
curr=$(pwd)
#. ${curr}/scripts/functions.sh
cacheDir=${curr}/cache
logFile=${curr}/log/logParseSH.log

database=/root/callc/mysite/project.db
cdrdb=${curr}/data/cdr.database

command=$(echo "${jsonMessage}"  | jq -r '.command')



# parse 'command' object from json
case $command in
    updatePeerID)
        peerToken=$(echo ${jsonMessage}  | jq -r '.token')
        peerID=$(echo ${jsonMessage}     | jq -r '.peerID')
        socketID1=$(echo ${jsonMessage}  | jq -r '.socketID')
        tokenExist=$(grep ${peerToken} ${cacheDir}/*_token)
        if [ ${#tokenExist} -ne 0 ]; then
            echo "${peerID}|${socketID1}" > ${cacheDir}/${peerToken}_peer
            if [ ${#peerID} -ne 0 ]; then
                echo "{\"status\":\"ok\",\"destinationSocket\":\"${socketID1}\",\"command\":\"updatePeerID\",\"token\":\"${peerToken}\"}"
                echo "|free" > ${cacheDir}/${peerToken}_status
            else
                echo "{\"status\":\"nok\",\"destinationSocket\":\"${socketID1}\",\"command\":\"updatePeerID\",\"description\":\"PeerID is empty\"}"
            fi
        else
                echo "{\"status\":\"nok\",\"destinationSocket\":\"${socketID1}\",\"command\":\"updatePeerID\",\"description\":\"token is wrong\"}"
        fi
        ;;
    updatePeerIDBrowser)
        peerToken=$(echo ${jsonMessage}  | jq -r '.token')
        peerID=$(echo ${jsonMessage}     | jq -r '.peerID')
        socketID1=$(echo ${jsonMessage}  | jq -r '.socketID')
        # if file exist
        echo "${peerID}|${socketID1}" > ${cacheDir}/${peerToken}_peer 
        if [ ${#peerID} -ne 0 ]; then
            echo "{\"status\":\"ok\",\"destinationSocket\":\"${socketID1}\",\"command\":\"updatePeerID\",\"token\":\"${peerToken}\"}"
            echo "|calling" > ${cacheDir}/${peerToken}_status
        else
            echo "{\"status\":\"nok\",\"destinationSocket\":\"${socketID1}\",\"command\":\"updatePeerID\",\"description\":\"PeerID is empty\"}"
        fi
        ;;
    startcall)
        # not send current socket which is answered
        # send back no one is online, please call later message
        cntx=$(echo ${jsonMessage}  | jq -r '.context')
        callerToken=$(echo ${jsonMessage}  | jq -r '.token')
        callerPeerID=$(echo ${jsonMessage}  | jq -r '.callerPeerID')
        callerSocketID=$(cat ${cacheDir}/${callerToken}_peer| awk -v FS='|' '{print $2}')
        echo "$callerPeerID|$cntx" > ${cacheDir}/${callerToken}.calling
        #groupName=$(echo "select name from auth_group where name='${cntx}');" | sqlite3 ${database}  )
        #userlist=$(echo "select username from users where context='${cntx}';"| sqlite3 ${database})
        userlist=$(echo "select username from auth_user where id in ( select user_id from auth_user_groups where group_id=(select id from auth_group where name='${cntx}'));"| sqlite3 ${database})
        #userCount=$(echo "select count(username) from auth_user where id in ( select user_id from auth_user_groups where group_id=(select id from auth_group where name='${cntx}'));"| sqlite3 ${database})
        userCount=0
        userNonFree=0
		userlist="farizzz"
        for user in $userlist; do
            res=$(ls ${cacheDir} | grep ${user})
            if [ -f ${cacheDir}/${user}_token ]; then
                let " userCount = $userCount + 1 "
                tokn=$(cat ${cacheDir}/${user}_token)
                getStatus=$(cat ${cacheDir}/${tokn}_status | awk -v FS='|' '{print $2}')
                customerSocketID=$(cat ${cacheDir}/${tokn}_peer | awk -v FS='|' '{print $2}')
                if [ "$getStatus" == "free" ] ; then
                    echo "{\"command\":\"startringing\",\"destinationSocket\":\"$customerSocketID\",\"source\":\"$callerSocketID\",\"callerPeerID\":\"$callerPeerID\",\"status\":\"ok\"}"
                    echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$customerSocketID\",\"status\":\"ok\",\"userStatus\":\"calling\"}"
                    echo "$callerPeerID|calling" > ${cacheDir}/${tokn}_status
                else
                    let " userNonFree = $userNonFree + 1 "
                fi
            fi
        done
        echo "insert into session (session_id,start_date,context,caller_peer_id,caller_token,call_status) values ('${callerPeerID}${callerToken}','$(date +"%Y-%m-%d %H:%M:%S")','$cntx','$callerPeerID','${callerToken}','S'); " | sqlite3 $cdrdb
        echo "insert into session (session_id,start_date,context,caller_peer_id,caller_token,call_status) values ('${callerPeerID}${callerToken}','$(date +"%Y-%m-%d %H:%M:%S")','$cntx','$callerPeerID','${callerToken}','S'); " > sql.query
        if [ "$userNonFree" == "$userCount" ] ; then
            echo "{\"command\":\"busy\",\"destinationSocket\":\"$callerSocketID\",\"status\":\"ok\"}"
        else
            echo "{\"destinationSocket\":\"$callerSocketID\",\"command\":\"startbeeping\"}"
        fi
        ;;
    answer)
        # evvelce yoxla gor bu answer moddadi yoxsa yox. 
        callerPeerID=$(echo ${jsonMessage}  | jq -r '.callerPeerID')            # bu setr error vere biler. Eger zeng gelmemish basilsa. HANDLE it.
        tokenAnswer=$(echo ${jsonMessage}  | jq -r '.token')
        answerUser=$(grep  ${tokenAnswer} ${cacheDir}/*.csrf | awk -v FS='|' '{print $3}')
        # burda evvelce peer fayllarin exist olub olmamasini yoxlamaq lazimmdir, eks halda error vere biler
        callerSource=$(grep ${callerPeerID} ${cacheDir}/*_peer | awk -v FS='|' '{print $2}'| sed 's/\n//' | sed 's/\r//')
        #userID=$(ls ${cacheDir}/ | grep ${tokenAnswer} | grep peer | awk -v FS='_' '{print $1}')
        #userID=$(grep -l ${userID} ${cacheDir}/*_token | awk -v FS='_' '{print $1}' | rev | awk -v FS='/' '{print $1}' | rev )
        userID=$(grep -l ${tokenAnswer} ${cacheDir}/*_token | awk -v FS='_' '{print $1}' | rev | awk -v FS='/' '{print $1}' | rev )
        answerPeerID=$(cat ${cacheDir}/${tokenAnswer}_peer | awk -v FS='|' '{print $1}')
        answerSocket=$(cat ${cacheDir}/${tokenAnswer}_peer | awk -v FS='|' '{print $2}')
        echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$answerSocket\",\"status\":\"ok\",\"userStatus\":\"busy\"}"
        #if [ ${#tokenAnswer} -eq 32 ]; then
        echo " {\"command\":\"stopbeeping\",\"answerPeerID\":\"$answerPeerID\" ,\"destinationSocket\":\"$callerSource\"}"
        #userlistUser=$(echo "select username from users where context in (select context from users where username='${userID}');"| sqlite3 ${database})
        userlistUser=$(echo "select username from auth_user where id in ( select user_id from auth_user_groups where group_id in (select group_id from auth_user_groups where user_id in (select id from auth_user where username='${userID}'))) ;"| sqlite3 ${database})
        for u in ${userlistUser}; do
            for tk in $( ls ${cacheDir}/  |grep ${u}_token); do
                tokenFile=$(cat ${cacheDir}/${tk})
                socketID2=$(cat ${cacheDir}/${tokenFile}_peer| awk -v FS='|' '{print $2}')
                echo "{\"destinationSocket\":\"$socketID2\",\"command\":\"stopringing\",\"status\":\"ok\"}"
                echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$socketID2\",\"status\":\"ok\",\"userStatus\":\"free\"}"
                sleep 5s
                echo "|free" > ${cacheDir}/${tokenFile}_status 
            done
        done 
        echo "|incall" > ${cacheDir}/${tokenAnswer}_status
        echo "$callerPeerID|$answerPeerID" > ${cacheDir}/${tokenAnswer}_connected
        #echo "update session set start_date='$(date +"%Y-%m-%d %H:%M:%S")', called_id='$answerUser',called_peer_id='$answerPeerID',called_token='$tokenAnswer',call_status='A' where caller_peer_id='$callerPeerID' ;"|  sqlite3 $cdrdb
        echo "update session set start_date='$(date +"%Y-%m-%d %H:%M:%S")', called_id='$answerUser',called_peer_id='$answerPeerID',called_token='$tokenAnswer',call_status='A' where rowid in (select rowid from session where caller_peer_id='$callerPeerID' order by start_date desc limit 1) ;"|  sqlite3 $cdrdb
       
        ;;
    endcall)
        calledToken=$(echo ${jsonMessage}  | jq -r '.token')
        senderSocket=$(cat ${cacheDir}/${calledToken}_peer | awk -v FS='|' '{print $2}')
        remotePeerID=$(echo ${jsonMessage}  | jq -r '.remotePeerID')
        remoteSocket=$(grep -l ${remotePeerID} ${cacheDir}/*_peer  | rev | awk -v FS='/' '{print $1}' | rev )
        remoteStatusFile=$(echo $remoteSocket| awk -v FS='_peer' '{print $1}')
        remoteSocket=$(cat ${cacheDir}/${remoteSocket} | awk -v FS='|' '{print $2}') # this is peer file from grep -l
        echo "{\"command\":\"endcall\",\"destinationSocket\":\"$senderSocket\",\"status\":\"ok\"}"
        echo "{\"command\":\"endcall\",\"destinationSocket\":\"$remoteSocket\",\"status\":\"ok\"}"
        echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$senderSocket\",\"status\":\"ok\",\"userStatus\":\"free\"}"
        echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$remoteSocket\",\"status\":\"ok\",\"userStatus\":\"free\"}"
        echo "update session set call_status='ANSWERED',end_date='$(date +"%Y-%m-%d %H:%M:%S")' WHERE rowid in (select rowid from session where caller_peer_id='$remotePeerID' or called_peer_id='$remotePeerID' order by start_date desc limit 1) ;" | sqlite3 $cdrdb
        echo "|free" > ${cacheDir}/${calledToken}_status
        echo "|free" > ${cacheDir}/${remoteStatusFile}_status
        connected_file=$(grep -l  ${remotePeerID} ${cacheDir}/*_connected | rev | awk -v FS='/' '{print $1}' | rev )
        echo > ${cacheDir}/$connected_file
        ;;
        
    stopCalling)
        token=$(echo ${jsonMessage}  | jq -r '.token')
        context=$(echo ${jsonMessage}  | jq -r '.context')
        peerID=$(echo ${jsonMessage}  | jq -r '.peerID')
        checkContext=$(cat ${cacheDir}/${token}.calling | awk -v FS='|' '{print $2}' )
        ## eger dogurdan da call edirse
        if [ ${#checkContext} -ne 0 ]; then
           rightContext=$(echo ${checkContext}| rev | awk -v FS='/' '{print $1}'| rev | awk -v FS='.' '{print $1}')
           # eger dogurdan da bu contexte call edirse
           if [ "$context" == "$rightContext" ]; then
              # bu contextin userlerini al
              userlist=$(echo "select username from auth_user where id in ( select user_id from auth_user_groups where group_id=(select id from auth_group where name='${context}'));"| sqlite3 ${database})
              for user in $userlist ; do
                  # tokenlerinden , statuslarini ve kimden zeng gediklerini yoxla                  tokenUser=$(cat ${cacheDir}/${user}_token )
                  userToken=$(cat ${cacheDir}/${user}_token)
                  getStatusUser=$(cat ${cacheDir}/${userToken}_status | awk -v FS='|' '{print $2}' )
                  getCallerPeer=$(cat ${cacheDir}/${userToken}_status | awk -v FS='|' '{print $1}' )
                  # eger dogru peerden callingdedise
                  if [ "$getStatusUser" == "calling" ] && [ "$peerID" == "$getCallerPeer" ] ; then
                    getSocket=$(cat ${cacheDir}/${userToken}_peer | awk -v FS='|' '{print $2}' )
                    #echo "{\"command\":\"endcall\",\"status\":\"ok\",\"destinationSocket\":\"$getSocket\"}"
                    #echo "{\"command\":\"stopCalling\",\"status\":\"ok\",\"destinationSocket\":\"$getSocket\"}"
                    #echo "{\"command\":\"stopringing\",\"status\":\"ok\",\"destinationSocket\":\"$getSocket\"}"
                    echo "{\"command\":\"stopCalling\",\"status\":\"ok\",\"destinationSocket\":\"$getSocket\"}"
                    echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$getSocket\",\"status\":\"ok\",\"userStatus\":\"free\"}"
                    echo "update session set call_status='MISSED',end_date='$(date +"%Y-%m-%d %H:%M:%S")' WHERE rowid in (select rowid from session where call_status='S' and (caller_peer_id='$getCallerPeer' or called_peer_id='$getCallerPeer' order by start_date desc limit 1) ;" | sqlite3 $cdrdb
                    echo "|free" > ${cacheDir}/${userToken}_status
                  fi
              done            
           fi
        fi      
        ;;
        
    reject)
        callerPeerID=$(echo ${jsonMessage}  | jq -r '.callerPeerID')
        tokenAnswer=$(echo ${jsonMessage}  | jq -r '.token')
        answerUser=$(grep  ${tokenAnswer} ${cacheDir}/*.csrf| awk -v FS='|' '{print $3}')
        callerSource=$(grep ${callerPeerID} ${cacheDir}/*_peer | awk -v FS='|' '{print $2}')
        userID=$(ls ${cacheDir}| grep ${tokenAnswer} | grep peer | awk -v FS='_' '{print $1}')
        userID=$(grep -l ${userID} ${cacheDir}/*_token | awk -v FS='_' '{print $1}' | rev | awk -v FS='/' '{print $1}' | rev )
        answerPeerID=$(cat ${cacheDir}/${tokenAnswer}_peer | awk -v FS='|' '{print $1}')
            echo "{\"command\":\"reject\",\"destinationSocket\":\"${callerSource}\"}"
            userlistUser=$(echo "select username  from auth_user where id in ( select user_id from auth_user_groups where group_id in (select group_id from auth_user_groups where user_id in (select id from auth_user where username='${userID}'))) ;"| sqlite3 ${database})
            for u in ${userlistUser}; do
                for tk in $(ls ${cacheDir}  |grep ${u}_token); do
                    tokenFile=$(cat ${cacheDir}/${tk})
                    socketID2=$(cat ${cacheDir}/${tokenFile}_peer| awk -v FS='|' '{print $2}')
                    echo "{\"destinationSocket\":\"$socketID2\",\"command\":\"reject\",\"status\":\"ok\"}"
                    #getStatus=$(cat ${cacheDir}/${tokenFile}_status| awk -v FS='|' '{print $2}')
                    statusFile=$(grep -l ${callerPeerID} ${cacheDir}/*_status | rev | awk -v FS='/' '{print $1}' | rev  )
                    if [ ${#statusFile} -ne 0 ]; then
                        for i in $statusFile; do
                          echo "|free" > $cacheDir/$i
                          echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$socketID2\",\"status\":\"ok\",\"userStatus\":\"free\"}"
                        done
                    fi
                done
            done
            echo "|free" > ${cacheDir}/${tokenAnswer}_status
        echo "update session set start_date='$(date +"%Y-%m-%d %H:%M:%S")',called_id='$answerUser',caller_peer_id='$callerPeerID', called_peer_id='$answerPeerID',called_token='$answerPeerID',call_status='REJECTED' where rowid in (select rowid from session where caller_peer_id='$callerPeerID' order by start_date desc limit 1);" | sqlite3 $cdrdb
        ;;
    callRedirect)
        token=$(echo ${jsonMessage}  | jq -r '.token')
        socketID=$(echo ${jsonMessage}  | jq -r '.socketID')
        redirectContext=$(echo ${jsonMessage}  | jq -r '.redirectContext')
        remotePeerID=$(echo ${jsonMessage}  | jq -r '.remotePeerID')
        remoteSocket=$(grep -l ${remotePeerID} ${cacheDir}/*_peer  | rev | awk -v FS='/' '{print $1}' | rev )
        remoteStatusFile=$(echo $remoteSocket| awk -v FS='_peer' '{print $1}')
        remoteSocket=$(cat ${cacheDir}/${remoteSocket} | awk -v FS='|' '{print $2}')
        echo "{\"command\":\"callRedirect\",\"status\":\"ok\",\"redirectContext\":\"$redirectContext\",\"destinationSocket\":\"$remoteSocket\"}"     
        ;;
    AdminPage)
        adminToken=$(echo ${jsonMessage}  | jq -r '.token')
        socketID=$(echo ${jsonMessage}  | jq -r '.socketID')
        totalGroup=$(echo "select count(1) from auth_group ;" | sqlite3 ${database})
        totalAgent=$(echo "select count(1) from auth_user_groups where group_id not in ('1') ;" | sqlite3 ${database})
        onlineAgent=$(ls ${cacheDir} | grep "_token" | grep -v "admin_token"| wc -l)
        inCallAgent=$(find ${cacheDir}  -type f -name "*_status" -exec grep -l incall {} \;| wc -l)
        busyAgent=$(find ${cacheDir}  -type f -name "*_status" -exec grep -l incall {} \;| wc -l)
        freeAgent=$(find ${cacheDir}  -type f -name "*_status" -exec grep -l free {} \;| wc -l)
        answCall=$(echo " select  count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-30 day') and  call_status='ANSWERED' ;"| sqlite3 $cdrdb)
        rjctCall=$(echo  " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-7 day') and  call_status='REJECTED';"| sqlite3 $cdrdb )
        month=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-30 day') ;"| sqlite3 $cdrdb )
        RAM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
        CPU=$(top -n 1 -b | grep "load average:" | awk  -v FS="load average:" '{print $2}')
        #CPU=$(echo $CPU| sed 's/,/\",\"/g')
        fsName=$(df -T | grep -v "shm\|overlay" | rev | awk '{print $1}' | rev  | tail -n +2 | tr '\n' ',')
        fsName=$(echo "${fsName::-1}"  | sed 's/,/\",\"/g')
        fsValues=$(df -T | grep -v "shm\|overlay" | rev | awk '{print $2}' | rev  | tail -n +2 | tr '\n' ',')
        fsValues=$(echo "${fsValues::-1}" |sed 's/%//g'  | sed 's/,/\",\"/g')
        data="{\"answCall\":$answCall,\"rjctCall\":$rjctCall,\"TOTAL_GROUPS\":\"$totalGroup\",\"TOTAL_AGENTS\":\"$totalAgent\",\"ONLINE_AGENTS\":\"$onlineAgent\",\"BUSY_AGENTS\":\"$busyAgent\",\"IN_CALL_AGENTS\":\"$inCallAgent\",\"FREE_AGENTS\":\"$freeAgent\",\"CPU\":[$CPU],\"RAM\":[$RAM],\"FILESYSTEMNAME\":[\"$fsName\",\"null\"],\"FILESYSTEMVALUE\":[\"$fsValues\",\"100\"]}"
        echo "{\"command\":\"AdminPage\",\"destinationSocket\":\"$socketID\",\"status\":\"ok\",\"data\":$data}"
        # if token is adminitrator 
        ;;
    statPage)
        token=$(echo ${jsonMessage}  | jq -r '.token')
        socketID=$(echo ${jsonMessage}  | jq -r '.socketID')
        userID=$(grep  ${token} ${cacheDir}/*.csrf | awk -v FS='|' '{print $3}')
        todayA=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-1 day') and call_status='ANSWERED';"| sqlite3 $cdrdb)
        todayR=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-1 day') and call_status='REJECTED' ;"| sqlite3 $cdrdb)
        todayM=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-1 day') and call_status='MISSED';"| sqlite3 $cdrdb)
        weekA=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-7 day') and call_status='ANSWERED';"| sqlite3 $cdrdb)
        weekR=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-7 day') and call_status='REJECTED';"| sqlite3 $cdrdb)
        weekM=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-7 day') and call_status='MISSED';"| sqlite3 $cdrdb)
        monthA=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-30 day') and call_status='ANSWERED';"| sqlite3 $cdrdb)
        monthR=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-30 day') and call_status='REJECTED';"| sqlite3 $cdrdb)
        monthM=$(echo " select count(1) from session where Datetime(start_date,'localtime') > Datetime('now','localtime','-30 day') and call_status='MISSED';"| sqlite3 $cdrdb)
        data="{\"daily\":[[\"MISSED\",\"ANSWERED\",\"REJECTED\"],[$todayM,$todayA,$todayR]],\"weekly\":[[\"MISSED\",\"ANSWERED\",\"REJECTED\"],[$weekM,$weekA,$weekR]],\"monthly\":[[\"MISSED\",\"ANSWERED\",\"REJECTED\"],[$monthM,$monthA,$monthR]]}"
        echo "{\"command\":\"statPage\",\"destinationSocket\":\"$socketID\",\"status\":\"ok\",\"data\":$data}"
        ;;
    setStatus)
        token=$(echo ${jsonMessage}  | jq -r '.token')
        socketID=$(echo ${jsonMessage}  | jq -r '.socketID')
        userStatus=$(echo ${jsonMessage}  | jq -r '.userStatus')
        echo "|$userStatus" > ${cacheDir}/${token}_status
        ;;
    getStatus)
        token=$(echo ${jsonMessage}  | jq -r '.token')
        socketID=$(echo ${jsonMessage}  | jq -r '.socketID')
        userStatus=$(cat ${cacheDir}/${token}_status | awk -v FS='|' '{print $2}')
        echo "{\"command\":\"getStatus\",\"destinationSocket\":\"$socketID\",\"status\":\"ok\",\"userStatus\":\"$userStatus\"}"
        ;;
    getProfilePicture)
        token=$(echo ${jsonMessage}  | jq -r '.token')
        socketID=$(echo ${jsonMessage}  | jq -r '.socketID')
        userID=$(grep -l ${token} ${cacheDir}/*_token | awk -v FS='_' '{print $1}' | rev | awk -v FS='/' '{print $1}' | rev )
        imageString=$(cat pictures/${userID}.jpg| base64| tr -d '\n\r' )
        echo "{\"command\":\"profilePicture\",\"destinationSocket\":\"$socketID\",\"username\":\"$userID\",\"status\":\"ok\",\"imageString\":\"$imageString\"}"
        ;;
    removeClient)
        # bunu client de gondere biler. ehtiyyatli ol. 
        socketID=$(echo ${jsonMessage}  | jq -r '.socketID')
        for i in $(ls ${cacheDir}| grep '_peer'); do
            socket=$(cat ${cacheDir}/${i}| awk -v FS='|' '{print $2}')
            if [ ${#socket} -ne 0 ] && [ "${socket}" == "$socketID" ]; then
                token=$(echo ${i} | awk -v FS='_' '{print $1'})
                #rm -f ${cacheDir}/${token}_*
                #find ${cacheDir} -type f -exec grep -l ${token} {} \; | xargs rm -f
            fi
        done
        ;;
esac
