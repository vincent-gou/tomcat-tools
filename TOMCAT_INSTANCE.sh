#!/bin/bash
#set -x
SOURCE_PATH=$(pwd)
SCRIPT_PATH=$(dirname $0)
CONFIG_PATH=$SCRIPT_PATH/../config/local.sh
JRE_HOME=
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
      echo -e "\e[43m\e[30m";;
    BOLD) 
      echo -e "\e[1m";;
    UNDERL)
      echo -e "\e[4m";;
  esac
fi
}

Instance_Info() {
echo -e "$(Color WHITE)Legende:$(Color)\t\tJMX4PERL: $(Color WHITE)$(Color BOLD)$(Color UNDERL)VALEUR$(Color)"
echo -e "$(Color WHITE)INSTANCE:\t\t$(Color)$(Color BOLD)$(Instance)$(Color) "
echo -e "$(Color WHITE)Demarree depuis:\t$(Color)$(Color BOLD)$(Start_time)$(Color)\tRefresh (Secs):\t$(Color BOLD)$1$(Color)"
echo -e "$(Color WHITE)CATALINA_HOME:\t\t$(Color)$CATALINA_HOME"
echo -e "$(Color WHITE)CATALINA_BASE:\t\t$(Color)$CATALINA_BASE"
echo -e "$(Color WHITE)JAVA_HOME:\t\t$(Color)$JAVA_HOME"
echo -e "$(Color WHITE)UNIT SYSTEMD:$(Color)\t\tinstalled: $(Systemd_enable)\tStatut: $(Systemd_status)"
echo -e "$(Color WHITE)Controles:$(Color)\t\tJDK: $(Check_jdk)\tJstat: $(Check_jstat)\tJmx4perl: $(Check_jmx4perl)\tLdapsearch: $(Check_ldapsearch)\tDIDA Conf: $(Check_dida_jdbc_info)\tDIDA cnx: $(Check_dida_connection)"
echo -e "$(Color WHITE)Infos Techniques:$(Color)"
echo -e "\t$(Color BOLD)Port$(Color)\t$(Color BOLD)Thread$(Color)\t$(Color BOLD)Accept $(Color)\t$(Color BOLD)Compr$(Color)\t$(Color BOLD)Connect$(Color)\t$(Color BOLD)XMX$(Color)\t$(Color BOLD)XMS$(Color)"
echo -e "\t$(Color BOLD)$(Color)\t$(Color BOLD)PoolMax$(Color)\t$(Color BOLD)Count$(Color)\t$(Color BOLD)ession$(Color)\t$(Color BOLD)Type$(Color)\t$(Color BOLD)Mo$(Color)\t$(Color BOLD)Mo$(Color)"
echo -e "\t$(Color BOLD)----$(Color)\t$(Color BOLD)------$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)"
echo -e "Config:\t$(Color BOLD)$(Port_http_check)$(Color)\t$(Color BOLD)$(Max_threads)$(Color)\t$(Color BOLD)$(Accept_count)$(Color)\t$(Color BOLD)$(Compression)$(Color)\t$(Color BOLD)$(Connector_type)$(Color)\t$(Color BOLD)$(Jvm_xmx_config)$(Color)\t$(Color BOLD)$(Jvm_xms_config)$(Color)"
    echo -e "============================================================================================================" 
tput sc
}

Instance_info_dynamic() {
if  [  -n "$(Pid)" ]
  then
    echo -e "\t$(Color BOLD)Threads\tHeap\tJVM \tRam   \tSession\tRequest\tProcess\tThread \tAvg   $(Color)"
    echo -e "\t$(Color BOLD)OS     \tSize\tCPU \tMemory\tActive \tCount  \tTimeAvg\tPool   \tError $(Color)"
    echo -e "\t$(Color BOLD)       \t    \t    \t      \tCount  \t       \t       \tCur/Mx \tRate  $(Color)"
    echo -e "\t$(Color BOLD)-------\t----\t ---\t------\t-------\t-------\t-------\t-------\t------$(Color)"
    echo -e "$(Color BOLD)Actuel:\t$(Current_threads)\t$(Jvm_heap_memory)\t$(Jvm_cpu_use)\t$(Jvm_ram_memory)\t$(Session_active_count)\t$(Request_count)\t$(Avg_process_time)\t$(Thread_pool_buzyness)\t$(Error_average)$(Color)"
    echo -e "$(Color BOLD)Max:\t-----\t$(Jvm_max_heap_memory)\t-----\t-----\t$(Session_max_active_count)\t-------\t-------\t-------\t-------$(Color)"
    echo ""
    status 1 
  else
    echo ""
    status 1 
fi
echo ""
}

Instance() {
INSTANCE=$(echo $CATALINA_BASE |  awk -F/ '{print $(NF-2)}' )
echo $INSTANCE
}

Start_time() {
if  [  -n "$(Pid)" ]
  then
    START_TIME=$(ps -eo pid,cmd,lstart | grep $(Pid) | grep -v grep | awk '{print $5" "$4" "$7" a: "$6}')
    echo $START_TIME
  else
    echo $(Color RED)N/A$(Color) 
fi
}

Port_http() {
PORT_HTTP=$(cat $CATALINA_BASE/conf/server.xml | grep "Connector port=" | awk '{print $2}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
echo $PORT_HTTP
}

Port_shutdown() {
PORT_SHUTDOWN=$(cat $CATALINA_BASE/conf/server.xml | grep "Server port=" | awk '{print $2}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
echo $PORT_SHUTDOWN
}

Port_jmx() {
PORT_JMX=$(echo $CATALINA_OPTS | awk -F"Dcom.sun.management.jmxremote.port=" '/Dcom.sun.management.jmxremote.port=/{print $2}'| awk {'print $1'})
if [ "$PORT_JMX" == "" ]
  then echo "NO_JMX"
  else echo $PORT_JMX
fi
}

Port_jmx_server() {
PORT_JMX_SERVER=$(echo $CATALINA_OPTS | awk -F"Dcom.sun.management.jmxremote.rmi.port=" '/Dcom.sun.management.jmxremote.rmi.port=/{print $2}'| awk {'print $1'})
if [ "$PORT_JMX_SERVER" == "" ]
  then echo "NO_JMX_SERVER"
  else echo $PORT_JMX_SERVER
fi
}


Port_http_check() {
#PORT_HTTP=$(cat $CATALINA_BASE/conf/server.xml | grep "Connector port=" | awk '{print $2}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g")
if  [  -n "$(Pid)" ]
  then
    STATE_PORT=$(netstat -anp 2>/dev/null | grep $(Pid) | grep LISTEN &>/dev/null)
  if [ $? -eq 0 ]
    then
    echo $(Color GREEN)$(Port_http)$(Color)
  fi
  else
    echo $(Color RED)$(Port_http)$(Color)
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
  then echo DEFAULT
  else 
    CONNECTOR_TYPE=$(cat $CATALINA_BASE/conf/server.xml | grep "protocol=" | awk '{print $3}'| sed -e "s/=/ /g"| awk '{print $2}' | sed -e "s/\"//g" | sed -e "s/\./ /g" | awk '{print $5}' | sed -e "s/Protocol//g" | sed -e "s/Http11//g")
    echo $CONNECTOR_TYPE | tr '[:lower:]' '[:upper:]'
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
            echo -e $(Color RED)$CURRENT_THREADS w:$WAITING_THREADS$(Color) 
	  else
	    echo -e $(Color YELLOW)$CURRENT_THREADS$(Color)	
	fi
    fi 
fi

}

Check_jdk() {
if [ ! -z $JDK_HOME -a -d $JDK_HOME ]
  then echo "$(Color BOLD)$(Color GREEN)OK$(Color)"
  else echo "$(Color BOLD)$(Color YELLOW)NON$(Color)"
fi
}

Check_jstat() {
if [ ! -z $JDK_HOME -a -x $JDK_HOME/bin/jstat ]
  then echo -e "$(Color BOLD)$(Color GREEN)OK$(Color)"
  else echo -e "$(Color BOLD)$(Color YELLOW)NON$(Color)"
fi
}

Check_ldapsearch() {
if [ ! -z $ORACLE_HOME -a -x $ORACLE_HOME/bin/ldapsearch -a -f $ORACLE_HOME/network/admin/ldap.ora ]
  then echo -e "$(Color BOLD)$(Color GREEN)OK$(Color)"
  else echo -e "$(Color BOLD)$(Color YELLOW)NON$(Color)"
fi
}

Check_dida_jdbc_info() {
APPLICATION_PROPERTIES="$CATALINA_BASE/conf/gamma/etc/application.properties"
if [ -f $APPLICATION_PROPERTIES ]
  then
    export DIDA_URL=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.url) 
    DIDA_DRIVER=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.driver) 
    DIDA_INSTANCE=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.instance | sed -e "s/=/ /g" | awk {'print $2'}) 
    DIDA_HOST=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.url | sed -e "s/=/ /g" |sed -e "s/:/ /g" | awk {'print $5'} | sed -e "s/@//g"  ) 
    DIDA_LISTENER=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.url | sed -e "s/=/ /g" |sed -e "s/:/ /g" | awk {'print $6'}  ) 
    DIDA_SID=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.url | sed -e "s/=/ /g" |sed -e "s/:/ /g" | awk {'print $7'}  ) 
    DIDA_USER=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.user | sed -s "s/dida.user=//g" ) 
    DIDA_PWD=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.password | sed -s "s/dida.password=//g") 
    DIDA_ENV=$(cat $APPLICATION_PROPERTIES | grep -v "#" | grep dida.env) 
    if [ ! -z $DIDA_URL -a ! -z $DIDA_DRIVER -a ! -z $DIDA_INSTANCE ]
      then echo -e "$(Color BOLD)$(Color GREEN)OK$(Color)"
    fi
  else echo -e "$(Color BOLD)$(Color RED)CONFIG !$(Color)"

fi
}

Check_dida_connection() {
Check_dida_jdbc_info >/dev/null
URL="(description=(address_list=(address=(protocol=TCP)(host=$DIDA_HOST)(port=$DIDA_LISTENER)))(connect_data=(service_name=$DIDA_SID)))"

echo "exit" | sqlplus -L $DIDA_USER/$DIDA_PWD@$URL | grep Connected > /dev/null
if [ $? -eq 0 ]
  then echo -e "$(Color BOLD)$(Color GREEN)OK$(Color)"
	List_dida_ds_instance
  else echo -e "$(Color BOLD)$(Color RED)CONFIG !$(Color)" 
fi

}

List_dida_ds_instance() {
Check_dida_jdbc_info >/dev/null
URL="(description=(address_list=(address=(protocol=TCP)(host=$DIDA_HOST)(port=$DIDA_LISTENER)))(connect_data=(service_name=$DIDA_SID)))"

DIDA_DS_LIST_FILE=$INSTALL_DIR/tmp_dir/dida_ds_list.txt
>$DIDA_DS_LIST_FILE
sqlplus -s $DIDA_USER/$DIDA_PWD@$URL >/dev/null <<-EOF
	set heading off feedback off verify off
	SET PAGES 0
	column dbuser format a20
	column dburl format a59
	spool $DIDA_DS_LIST_FILE
	select dbuser,dburl from publi_databases where SITEDIDANAME='$DIDA_INSTANCE';
	spool off
	exit
EOF

}

Check_jdbc_connection() {
DIDA_DS_LIST_FILE=$INSTALL_DIR/tmp_dir/dida_ds_list.txt
JDBC_DIDA=$(cat $DIDA_DS_LIST_FILE | grep $1>/dev/null )
if [ $? -eq 0 ]
  then echo "OK"
  else echo "NO"
fi
}

Check_jmx4perl() {
if [ -x /usr/bin/jmx4perl ]
  then echo -e "$(Color BOLD)$(Color GREEN)OK$(Color)"
  else echo -e "$(Color BOLD)$(Color YELLOW)NON$(Color)"
fi
}

Jvm_heap_memory() { 
if [[ $(Check_jmx4perl) == *OK* ]]
  then 
    HEAP_MEMORY=$((`/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "java.lang:type=Memory" HeapMemoryUsage used` / 1024 / 1024 ))
    echo $(Color WHITE)$(Color BOLD)$(Color UNDERL)$HEAP_MEMORY$(Color) Mo
  else
  if [[ $(Check_jstat) == *OK* ]]
    then 
      HEAP_MEMORY=$( ($JDK_HOME/bin/jstat -gc $(Pid) 2>/dev/null || echo "0 0 0 0 0 0 0 0 0") | tail -n 1 | awk '{split($0,a," "); sum=a[3]+a[4]+a[6]+a[8]; print sum/1024}' ) 2>/dev/null
      HEAP_MEMORY=${HEAP_MEMORY%.*}
      echo -e $(Color BOLD)$HEAP_MEMORY Mo$(Color)
    else
      echo -e $(Color BOLD)$(Color YELLOW)No JDK$(Color)
  fi
fi
}


Jvm_max_heap_memory() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    HEAP_MEMORY=$((`/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "java.lang:type=Memory" HeapMemoryUsage max` / 1024 / 1024 ))
    echo $(Color WHITE)$(Color BOLD)$(Color UNDERL)$HEAP_MEMORY$(Color) Mo
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}



Jvm_ram_memory() {
RAM_MEMORY=$(( ` cut -d' ' -f2 <<<cat /proc/$(Pid)/statm 2>/dev/null || echo "0" ` / 1024 ))
echo $RAM_MEMORY Mo
}

Jvm_cpu_use() {
CPU_USE=$( ps -p $(Pid) -o %cpu 2>/dev/null | tail -n 1  )
CPU_USE=${CPU_USE%.*}
if [[ $CPU_USE -lt 10 ]]
  then
    echo $(Color BOLD)$(Color GREEN)$CPU_USE %$(Color)
  else
    echo $(Color BOLD)$(Color RED)$CPU_USE %$(Color)
fi
}

Session_active_count() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CONNECTION_COUNT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read "Catalina:type=Manager,host=localhost,context=/gamma" activeSessions)
    echo -e $(Color WHITE)$(Color BOLD)$(Color UNDERL)$CONNECTION_COUNT$(Color)
  else  
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Session_max_active_count() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CONNECTION_COUNT_MAX=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read "Catalina:type=Manager,host=localhost,context=/gamma" maxActive )
    echo -e $(Color WHITE)$(Color BOLD)$(Color UNDERL)$CONNECTION_COUNT_MAX$(Color)
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Request_count() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    REQUEST_COUNT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read Catalina:type=GlobalRequestProcessor,name=\"http-nio2-$(Port_http)\" requestCount)
    REQUEST_COUNT_STAT=$REQUEST_COUNT
    echo -e $(Color WHITE)$(Color BOLD)$(Color UNDERL)$REQUEST_COUNT$(Color)
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Avg_process_time() {

Request_count >/dev/null
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    PROCESS_TIME=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read Catalina:type=GlobalRequestProcessor,name=\"http-nio2-$(Port_http)\" processingTime)
    AVG_PROCESS_TIME=$(echo "$PROCESS_TIME / $REQUEST_COUNT_STAT" | bc )
    #AVG_PROCESS_TIME=$REQUEST_COUNT_STAT
    echo -e $(Color WHITE)$(Color BOLD)$(Color UNDERL)$AVG_PROCESS_TIME ms$(Color)
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Thread_pool_buzyness() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CURR_THREAD_POOL_BUSY=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read Catalina:type=ThreadPool,name=\"http-nio2-$(Port_http)\" currentThreadsBusy)
    THREAD_POOL_MAX=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read Catalina:type=ThreadPool,name=\"http-nio2-$(Port_http)\" maxThreads)
    PERCENT_THREAD_POOL_BUSY=$(echo "(100 * $CURR_THREAD_POOL_BUSY ) / $THREAD_POOL_MAX" | bc)
  if [ $PERCENT_THREAD_POOL_BUSY -lt 80 ] 
    then 
      echo -e $(Color GREEN)$(Color BOLD)$(Color UNDERL)$CURR_THREAD_POOL_BUSY / $THREAD_POOL_MAX$(Color)
    else
      echo -e $(Color RED)$(Color BOLD)$(Color UNDERL)$CURR_THREAD_POOL_BUSY / $THREAD_POOL_MAX$(Color)
  fi
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi

}

Error_average() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    ERROR_COUNT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read Catalina:type=GlobalRequestProcessor,name=\"http-nio2-$(Port_http)\" errorCount)
    REQUEST_COUNT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat --method post read Catalina:type=GlobalRequestProcessor,name=\"http-nio2-$(Port_http)\" requestCount)
    PERCENT_ERROR_COUNT=$(echo "(100 * $ERROR_COUNT ) / $REQUEST_COUNT" | bc)
## taux Erreur sous 2%
  if [ $PERCENT_ERROR_COUNT -lt 2 ]
    then
      echo -e $(Color GREEN)$(Color BOLD)$(Color UNDERL)$PERCENT_ERROR_COUNT %$(Color)
    else
      echo -e $(Color RED)$(Color BOLD)$(Color UNDERL)$ERROR_COUNT/$REQUEST_COUNT$(Color)
  fi
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
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


Jvm_xmx_config() {
JVM_XMX_CONFIG=$(cat $CONFIG_PATH | grep -v "#"|egrep -o 'Xmx[0-9]*'|tr '\r' ' '| sed -e "s/Xmx//g")
echo $JVM_XMX_CONFIG
}

Jvm_xms_config() {
JVM_XMS_CONFIG=$(cat $CONFIG_PATH | grep -v "#"|egrep -o 'Xms[0-9]*'|tr '\r' ' '| sed -e "s/Xms//g")
echo $JVM_XMS_CONFIG
}


Jvm_xmx() {
JVM_XMX=$(ps -ef|grep $(Pid)| grep -v grep|egrep -o 'Xmx[0-9]*'|tr '\r' ' '| sed -e "s/Xmx//g")
echo $JVM_XMX
}

Jvm_xms() {
JVM_XMS=$(ps -ef|grep $(Pid)| grep -v grep|egrep -o 'Xms[0-9]*' |tr '\r' ' '| sed -e "s/Xms//g")
echo $JVM_XMS
}

Check_ldap_ora_oid_file() {
LDAP_ORA_OID_FILE="$CONFIG_PATH/tmp_dir/LDAP_ORA_OID_FILE.txt"
if [ -f $LDAP_ORA_OID_FILE ] 
  then
    CHECK_LDAP_ORA_OID_FILE=true
  else 
    CHECK_LDAP_ORA_OID_FILE=false
fi
}


Generate_ldap_ora_oid_file() {
LDAP_BASE=$(cat $ORACLE_HOME/network/admin/ldap.ora | grep default_admin_context | awk '{print $3}' )
LDAP_SERVERS=$(cat $ORACLE_HOME/network/admin/ldap.ora | grep directory_servers | awk '{print $2}' | sed -e "s/(//g" | sed -e "s/)//g" | sed -e "s/,/ /g" | sed -e "s/:/ /g" )

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
if [ -z $CATALINA_BASE -o -z $LOG_DIR ]
  then
   echo "Une des variables nécessaires n'est pas definies" 
    exit 1;
  else
   echo "Suppression et nombre de fichiers supprimes:"
   for i in $CATALINA_BASE/logs $CATALINA_BASE/webapps/gamma/WEB-INF/logs $LOG_DIR
   do 
    printf "* $i: " 
    printf $(find $i -type f -name "*.log" -print -delete | wc -l)
    if [ ${PIPESTATUS[0]} -eq 0 ] 
      then echo -e "$(Color GREEN)\tOK$(Color)"
      else echo -e "$(Color RED)\tKO$(Color)" 
    fi
   done   
fi
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
#echo "## threads ouverts et cible reseau pour cette instance"
#echo -e "Source\t"
echo -e "$(Color BOLD)Connexions Actives$(Color)\tSOURCE\t\t\tDESTINATION IP\tPORT\tTYPE\tNOMBRE\tDESTINATION FQDN$(Color)"
echo -e "$(Color BOLD)(OS)\t\t\t------\t\t\t--------------\t----\t----\t------\t----------------$(Color)"
while read -r COUNT DEST PORT  
do 
FQDN=$(getent hosts $DEST | awk {'print $2'})
if [ "$(Check_jdbc_connection $PORT)" == "OK" ]
  then TYPE="JDBC"
  else TYPE="CLIENT"
fi
if [ "$PORT" == "1414" ]
  then TYPE="MQ"
fi


echo -e "$(Color WHITE)\t\t\tLOCALHOST$(Color)\t==>\t$DEST\t$PORT\t$TYPE\t$COUNT\t$FQDN"
TYPE=
done <<< "$(netstat -aopn 2>/dev/null | grep $(Pid) | grep tcp | grep -v LISTEN | awk {'print $5'} | sed -e "s/:/ /g" | sort | uniq -c)"

echo ""
echo -e "$(Color BOLD)Ports Ouverts$(Color)\t\tSOURCE\t\t\tPORT\t\tINTERFACE\tTYPE$(Color)"
echo -e "$(Color BOLD)(OS)\t\t\t------\t\t\t----\t\t---------\t----$(Color)"
while read -r SOURCE PORT INTERFACE PORT_INT
do
if [ "$SOURCE" == "127.0.0.1" ]
  then SOURCE="$(Color GREEN)LOCALE$(Color)"
  else SOURCE="TOUTES" 
fi

if [ "$INTERFACE" == "0.0.0.0" ]
  then INTERFACE="TOUTES"
fi

if [ "$PORT" == "$(Port_jmx)" ]
  then TYPE="JMX_REGISTRY"
  else
    if [ "$PORT" == "$(Port_jmx_server)" ]
      then TYPE="JMX_SERVER"
      else TYPE="RANDOM_JMX"
    fi
fi
if [ "$(Port_jmx)" == "NO_JMX" ]
 then TYPE="UNKNOWN"
fi

if [ "$PORT" == "$(Port_http)" ]
  then TYPE="HTTP"
fi
if [ "$PORT" == "$(Port_shutdown)" ]
  then TYPE="SHUTDOWN"
fi



echo -e "$(Color WHITE)\t\t\t$SOURCE$(Color)\t\t==>\t$PORT\t\t$INTERFACE\t\t$TYPE\t"
TYPE=
done <<< "$(netstat -aopn 2>/dev/null | grep $(Pid) | grep tcp | grep LISTEN | awk {'print $4" "$5'} | sed -e "s/:/ /g")" 
#echo -e "netstat -aopn 2>/dev/null | grep $(Pid) | grep tcp | grep LISTEN | awk {'print $4" "$5'} | sed -e "s/:/ /g""
}

Db_sessions() {
#echo "## Sesions Oracle pour cette instance TOMCAT" $(Instance)
#echo "---- BDD DIDADEV"
#sqlplus -s DIDADEV/DIDADEV@Z2X11 @$TOOLS_HOME/oracle_sessions.sql $(Instance)
#echo "----"
#echo "---- BDD DIDADEV BENCH"
#sqlplus -s DIDADEV/DIDADEV@Z2XB4I05 @$TOOLS_HOME/oracle_sessions.sql $(Instance)
#echo "----"
true
}


Diags() {
clear
TIMER=x$1
if [ -z $TIMER -o "$TIMER" == "x" -o $(echo "$1" | grep -qE '^[0-9]+$'; echo $?) -ne "0" ]
  then TIMER="NON"
  else TIMER="$1"
fi

Instance_Info $TIMER
if [ $TIMER -ne 0 2>/dev/null ] 
  then 
    while true   
      do
      Instance_info_dynamic
      Net_threads
      Db_sessions
      sleep $TIMER
      tput rc
     #tput cup 14 0 
     tput ed
    done
  else 
      TIMER="NON"
      Instance_info_dynamic   
      Net_threads
      Db_sessions
fi 


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
  Diags $2
;;
*)
  help
;;
esac

exit 0
