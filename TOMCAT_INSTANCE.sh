#!/bin/bash
#set -x
SOURCE_PATH=$(pwd)
SCRIPT_PATH=$(dirname $0)
#echo $SOURCE_PATH
#echo $SCRIPT_PATH
CONFIG_PATH=$SCRIPT_PATH/../config/local.sh
#echo $CONFIG_PATH

. $CONFIG_PATH

Color() {
if [ -z  $1 ]
  then echo -e "\e[0m"
  else
  case $1 in  
    GREEN)
      echo -e "\e[42m";;
    RED)
      echo -e "\e[41m";;
    GREY)      	
      echo -e "\e[100m";; 
    WHITE)
      echo -e "\e[107m\e[30m";; 
    YELLOW)
      echo -e "\e[43m";;
    BOLD) 
      echo -e "\e[1m";;
  esac
fi
}

Instance_Info() {
echo -e "$(Color WHITE)INSTANCE:\t\t$(Color)$(Instance)"
echo -e "$(Color WHITE)CATALINA_HOME:\t\t$(Color)$CATALINA_HOME"
echo -e "$(Color WHITE)CATALINA_BASE:\t\t$(Color)$CATALINA_BASE"
echo -e "$(Color WHITE)JAVA_HOME:\t\t$(Color)$JAVA_HOME"
echo -e "$(Color WHITE)UNIT SYSTEMD:$(Color)\t\tinstalled: $(Systemd_enable)\tStatut: $(Systemd_status)"
echo -e "$(Color WHITE)Infos Techniques:$(Color)"
echo -e "\t$(Color BOLD)Port$(Color)\t$(Color BOLD)Threads$(Color)\t$(Color BOLD)Accept $(Color)\t$(Color BOLD)Compr$(Color)\t$(Color BOLD)Connector$(Color)"
echo -e "\t$(Color BOLD)$(Color)\t$(Color BOLD)Max$(Color)\t$(Color BOLD)Count$(Color)\t\t$(Color BOLD)Type$(Color)"
echo -e "\t$(Color BOLD)----$(Color)\t$(Color BOLD)------$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)"
echo -e "Config:\t$(Color BOLD)$(Port_http)$(Color)\t$(Color BOLD)$(Max_threads)$(Color)\t$(Color BOLD)$(Accept_count)$(Color)\t$(Color BOLD)$(Compression)$(Color)\t$(Color BOLD)$(Connector_type)$(Color)"

if  [  -n "$(Pid)" ]
  then
    echo -e "=====================================================" 
    echo -e "\t$(Color BOLD)Threads$(Color)\t"
    echo -e "\t$(Color BOLD)-------$(Color)\t"
    echo -e "$(Color BOLD)Actuel:$(Color)\t$(Color BOLD)$(Current_threads)/$(Max_threads)\t  "
fi
status 1 
}

Instance() {
INSTANCE=$(echo $CATALINA_BASE |  awk -F/ '{print $(NF-2)}' )
echo $INSTANCE
}

Port_http() {
  PORT_HTTP=$(cat $CATALINA_BASE/conf/server.xml | grep "Connector port=" | awk '{print $2}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
#$(Pid)
if  [  -n "$(Pid)" ]
  then
    STATE_PORT=$(netstat -anp 2>/dev/null | grep $(Pid) | grep LISTEN &>/dev/null)  
  if [ $? -eq 0 ]  
    then
    echo $(Color GREEN)$PORT_HTTP$(Color)
  fi
  else 
    echo $(Color RED)$PORT_HTTP$(Color)
fi  
}

Compression() {
  COMPRESSION=$(cat $CATALINA_BASE/conf/server.xml | grep "compression=" | sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
  if [ $COMPRESSION == on ]
    then
    echo $(Color GREEN)$COMPRESSION$(Color)
  else
    echo $(Color RED)$COMPRESSION$(Color)
fi
}

Max_threads() {
 MAX_THREADS=$(cat $CATALINA_BASE/conf/server.xml | grep "Connector port=" | awk '{print $5}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
echo $MAX_THREADS
}

Accept_count() {
 ACCEPT_COUNT=$(cat $CATALINA_BASE/conf/server.xml | grep "acceptCount=" | awk '{print $2}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
echo $ACCEPT_COUNT
}

Connector_type() {
CONNECTOR_TYPE=$(cat $CATALINA_BASE/conf/server.xml | grep "protocol=" | awk '{print $3}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
if [ $CONNECTOR_TYPE == HTTP/1.1 ]
  then echo $CONNECTOR_TYPE
  else 
    CONNECTOR_TYPE=$(cat $CATALINA_BASE/conf/server.xml | grep "protocol=" | awk '{print $3}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g" | sed -e "s/\./ /g" | awk '{print $5}' | sed -e "s/Protocol//g" | sed -e "s/Http11//g")
    echo ${CONNECTOR_TYPE^^}
fi
}

Current_threads() {

if  [  -n "$(Pid)" ]
  then
    CURRENT_THREADS=$(ps -eLf | grep $(Pid) | wc -l)
    THREAD_USED_PERCENT=$(echo "(100 * $CURRENT_THREADS) / $(Max_threads)" | bc)
    if [ $THREAD_USED_PERCENT -lt 80 ] 
      then
        echo -e $(Color GREEN)$CURRENT_THREADS$(Color)
      else
	if [ $THREAD_USED_PERCENT -gt 100 ]		
	  then 	
	    WAITING_THREADS=$(echo "$CURRENT_THREADS - $(Max_threads)" |bc)	
            echo -e $(Color RED)$CURRENT_THREADS waiting:$WAITING_THREADS$(Color) 
	  else
	    echo -e $(Color YELLOW)$CURRENT_THREADS$(Color)	
	fi
    fi 
fi

}


Systemd_exist() {
which systemd &>/dev/null
if [ $? -ne 0 ] 
  then echo NO
  else echo YES
fi
}

Systemd_dbus() {
systemctl --user status &>/dev/null
if [ $? -gt 0 ]
  then echo NO
  else echo YES
fi
}


Instance_systemd() {
if [ $(Systemd_exist) == YES ] 
  then 
    SYSTEMD_INSTANCE=$(echo $(Instance)| sed -e s/lsprh//g )
    echo lsprh@$SYSTEMD_INSTANCE
  else
    echo -e "$(Color GREY)N/A$(Color)"
fi
}

Systemd_status() {
if [ $(Systemd_exist) == YES ] && [ $(Systemd_dbus) == YES ]
  then
    SYSTEMD_ACTIVE=$(systemctl --user is-active $(Instance_systemd))
    if [ $SYSTEMD_ACTIVE == active ]
      then echo -e "$(Color GREEN)OK$(Color)"
      else echo -e "$(Color RED)KO$(Color)"
   fi
  else
  if  [ $(Systemd_dbus) == NO ]   
    then
    echo -e "$(Color RED)Dbus KO$(Color)"
    else
    echo -e "$(Color GREY)N/A$(Color)"
  fi
fi
}

Systemd_enable() {
if [ $(Systemd_exist) == YES ] && [ $(Systemd_dbus) == YES ]
  then 
    SYSTEMD_ENABLE=$(systemctl --user is-enabled $(Instance_systemd))
    if [ $SYSTEMD_ENABLE == enabled ]
      then echo -e "$(Color GREEN)OK$(Color)"
      else echo -e "$(Color RED)KO$(Color)"
    fi
  else
  if  [ $(Systemd_dbus) == NO ]
    then
    echo -e "$(Color RED)Dbus KO$(Color)"
    else
    echo -e "$(Color GREY)N/A$(Color)"
  fi

fi


}


Pid() { 
if [ -z $CATALINA_HOME ]
	then 
		echo "Variable CATALINA_HOME non definie... Sortie"
		exit 1;	
	else
		PID=$(ps -efwww | grep $CATALINA_HOME | grep $CATALINA_HOME | grep -v grep | awk '{print $2}')
	echo $PID	
fi
}

start() {
$CATALINA_HOME/bin/startup.sh
}

stop() {
$CATALINA_HOME/bin/shutdown.sh
}

kill() {
sleep 5
Pid
if [ ! -z $PID ]
  then
	echo "Tomcat ne s'est pas arrete proprement"
	/usr/bin/X11/kill -9 $PID
	echo "Arret en force du Process: $PID"
	sleep 20
fi
}

status() {
if [ -z $(Pid) ]
  then echo -e "$(Color WHITE)STATUT:\t$(Color)Instance Tomcat sous $(Color BOLD)$CATALINA_BASE$(Color) est $(Color RED)arretee$(Color).";exit $1
  else echo -e "$(Color WHITE)STATUT:\t$(Color)Instance Tomcat sous $(Color BOLD)$CATALINA_BASE$(Color) est $(Color GREEN)demarree$(Color). PID: $(Color BOLD)$(Pid)$(Color)"
fi

}

purge_logs() {
echo Purge des logs
rm -rf $CATALINA_BASE/logs/*
rm -rf $CATALINA_BASE/webapps/lsprh/WEB-INF/logs/*
}

purge_cache() {
echo Purge du cache
rm -rf $CATALINA_BASE/temp/*
rm -rf $CATALINA_BASE/work/*
}

purge_heapdump() {
echo Purge des heapdump
echo $INSTALL_DIR/heapdump ; rm -rf $INSTALL_DIR/heapdump/*
echo $INSTALL_DIR/heapdump_error ; rm -rf $INSTALL_DIR/heapdump/*
}

help() {
echo "Usage: start | stop | status | restart | restart_failure | purge_logs | purge_cache | purge_all | stats | diags"
}

alert() {
if [ $1 == "mail" ]
  then 
    echo "Envoi Mail pour raison de : $2 pour $CATALINA_BASE à $(date)" >> $CATALINA_BASE/logs/tomcat_out_of_memory_error.log 
fi
}

Net_threads() {
status $2 >/dev/null
echo "## threads ouverts et cible reseau pour cette instance"
netstat -aop 2>/dev/null | grep $(Pid) | grep tcp | grep -v LISTEN | awk {'print $5'} | sort | uniq -c
}

Db_sessions() {
echo "## Sesions Oracle pour cette instance TOMCAT" $(Instance)
echo "---- BDD DIDADEV"
sqlplus -s DIDADEV/DIDADEV@Z2X11 @$TOOLS_HOME/oracle_sessions.sql $(Instance)
echo "----"
#echo "---- BDD DIDADEV BENCH"
#sqlplus -s DIDADEV/DIDADEV@Z2XB4I05 @$TOOLS_HOME/oracle_sessions.sql $(Instance)
#echo "----"
}


Diags() {
clear
Instance_Info
echo "#######################"
Net_threads
echo "#######################"
Db_sessions

}
#################
case $1 in
start)
  start
;;
stop)
  stop
;;
restart)
  stop
  kill
  start
;;
restart_failure)
  alert mail OutOfMemoryError
  stop
  kill
#  start
;;
status)
  status
;;
purge_logs)
  purge_logs
;;
purge_cache)
  purge_cache
;;
purge_all)
  purge_logs
  purge_cache
  purge_heapdump
;;
stats)
  Net_threads
;;
diags)
  Diags
;;
*)
  help
;;
esac

exit 0
