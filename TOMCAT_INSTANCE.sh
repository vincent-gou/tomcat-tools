#!/bin/bash
#set -x
SOURCE_PATH=$(pwd)
SCRIPT_PATH=$(dirname $0)
CONFIG_PATH=$SCRIPT_PATH/../config/local.sh
JRE_HOME=

. $CONFIG_PATH
DATE=$(date +%Y-%m-%d_%H-%M)

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
    BLUE)
      echo -e "\e[44m";;
    BOLD) 
      echo -e "\e[1m";;
    UNDERL)
      echo -e "\e[4m";;
    BLUEUNDERL)
      echo -e "\e[4m\e[44m";;
    WHITEUNDERL)
      echo -e "\e[4m\e[107m\e[30m";;
  esac
fi
}


Convert_status() {
# Fonction convertissant les OK / KO ou autre en couleurs
if [ ! -z $1 ]
  then
    case $1 in
      OK)
        echo -e "$(Color GREEN)$1$(Color)";;
      KO)
        echo -e "$(Color RED)$1$(Color)";;
    esac
fi
}


Check_output() {
METRICS=$2
METRICS=x$2
if [ -z "$METRICS" ] || [ "$METRICS" == "x" ] || [ "$(echo "$2" | grep "csv\|json" 1>/dev/null; echo $?)" -ne "0" ]
  then METRICS="NON"
  else export METRICS=$2;export INCR=$(($3 + 1));Output_$2 $INCR 

fi

}

Output_csv() {
## Definition du formatage de l'heure dans cette fonction
TIME=$(date +%Y-%m-%d_%H:%M:%S)
OUTPUT_FILE=$INSTALL_DIR/tmp_dir/TOMCAT_Metrics_$DATE.csv
if [ $1 -eq 1 ]
then 
  echo -e "Date\t\t\tThreads\tHeap\tJVM CPU\tJVM Ram\tNb     \tNb     \tProc   \tThread\tError\tADP Cls\tNon ADP\tJDBC  " > $OUTPUT_FILE
  echo -e "----\t\t\t-------\tSize\t-------\tSize Mb\tSession\tRequest\tTimeavg\tPool  \tRate \tSize Mb\tClsSize\tCount " >> $OUTPUT_FILE
else
  cat $OUTPUT_FILE.tmp | sed -e "s/Actuel:/$TIME/g" | tee -a $OUTPUT_FILE.merge
  if [ -e  $OUTPUT_FILE.merge ]
    then paste $OUTPUT_FILE.merge $OUTPUT_FILE.tmp3 >> $OUTPUT_FILE
    #else echo "No file"; ls -l $INSTALL_DIR/tmp_dir;read
  fi
  rm -f $OUTPUT_FILE.merge
  rm -f $OUTPUT_FILE.tmp*
  
fi

}

Instance_Info() {
echo -e "$(Color WHITE)Legende:$(Color)\t\tJMX4PERL: $(Color BOLD)$(Color UNDERL)$(Color WHITE)VA$(Color GREEN)LE$(Color RED)UR$(Color)\tHEAPDUMP File: $(Color BLUE)$(Color BOLD)$(Color UNDERL)VALEUR$(Color)"
echo -e "$(Color WHITE)INSTANCE:\t\t$(Color)$(Color BOLD)$(Instance)$(Color) "
echo -e "$(Color WHITE)Demarree depuis:\t$(Color)$(Color BOLD)$(Start_time)$(Color)\tRefresh (Secs):\t$(Color BOLD)$1$(Color)\tMetrics:\t$(Color BOLD)$2$(Color)"
echo -e "$(Color WHITE)CATALINA_HOME:\t\t$(Color)$CATALINA_HOME"
echo -e "$(Color WHITE)CATALINA_BASE:\t\t$(Color)$CATALINA_BASE"
echo -e "$(Color WHITE)JAVA_HOME:\t\t$(Color)$JAVA_HOME"
echo -e "$(Color WHITE)UNIT SYSTEMD:$(Color)\t\tinstalled: $(Systemd_enable)\tStatut: $(Systemd_status)"
echo -e "$(Color WHITE)Controles:$(Color)\t\tJDK: $(Check_jdk)\tJstat: $(Check_jstat)\tJmx4perl: $(Check_jmx4perl)\tDIDA Conf: $(Check_dida_jdbc_info)\tDIDA cnx: $(Check_dida_connection)\tLast Heap_Dump: $(Check_jvm_heapdump_last_cron_date) "
echo -e "$(Color WHITE)Infos Techniques:$(Color)"
echo -e "\t$(Color BOLD)Port$(Color)\t$(Color BOLD)Thread$(Color)\t$(Color BOLD)Accept $(Color)\t$(Color BOLD)Compr$(Color)\t$(Color BOLD)Connect$(Color)\t$(Color BOLD)XMX$(Color)\t$(Color BOLD)XMS$(Color)"
echo -e "\t$(Color BOLD)$(Color)\t$(Color BOLD)PoolMax$(Color)\t$(Color BOLD)Count$(Color)\t$(Color BOLD)ession$(Color)\t$(Color BOLD)Type$(Color)\t$(Color BOLD)Mo$(Color)\t$(Color BOLD)Mo$(Color)"
echo -e "\t$(Color BOLD)----$(Color)\t$(Color BOLD)------$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)\t$(Color BOLD)----$(Color)"
echo -e "Config:\t$(Color BOLD)$(Port_http_check)$(Color)\t$(Color BOLD)$(Max_threads)$(Color)\t$(Color BOLD)$(Accept_count)$(Color)\t$(Color BOLD)$(Compression)$(Color)\t$(Color BOLD)$(Connector_type)$(Color)\t$(Color BOLD)$(Jvm_xmx_config)$(Color)\t$(Color BOLD)$(Jvm_xms_config)$(Color)"
echo -e "=======================================================================" 
# Positionnement du point de rafraichissement si le parametre est passé au programme
# Tout ce qui est affiché en dessous est rafraichi
tput sc
}

Instance_info_dynamic() {

if  [  -n "$(Pid)" ]
  then
    echo -e "\t$(Color BOLD)Threads\tHeap\tJVM \tRam   \tSession\tRequest\tProcess\tThread \tAvg   \tADP    \tNon-ADP\tJDBC $(Color)"
    echo -e "\t$(Color BOLD)OS     \tSize\tCPU \tMemory\tActive \tCount  \tTimeAvg\tPool   \tError \tClasses\tClasses\tCount$(Color)"
    echo -e "\t$(Color BOLD)       \t    \t%   \t      \tCount  \t       \t       \tConnector\tRate  \tSize Mb\tSize Mb\t$(Color)"
    echo -e "\t$(Color BOLD)-------\t----\t ---\t------\t-------\t-------\t-------\t-------\t------\t-------\t-------\t-----$(Color)"
    echo -e "$(Color BOLD)Actuel:\t$(Current_threads)\t$(Jvm_heap_memory)\t$(Jvm_cpu_use)\t$(Jvm_ram_memory)\t$(Session_active_count)\t$(Request_count)\t$(Avg_process_time)\t$(Thread_pool_buzyness)\t$(Error_average)\t$(Check_adp_heap_classes_size)\t$(Check_nonadp_heap_classes_size)$(Color)" | tee -a $OUTPUT_FILE.tmp
    echo -e "$(Color BOLD)Max:\t-----\t$(Jvm_max_heap_memory)\t-----\t-----\t$(Session_max_active_count)\t-------\t-------\t-------\t-------\t-------\t-------$(Color)"
    if [ $TIMER -ne 0 -a $INCR -gt 0  ] 2>/dev/null
      then
            echo -e "$(Color BOLD)Max Se"
            echo -e "$(Color BOLD)ssion:\t$(Current_threads_max_session)\t$(Jvm_max_heap_memory_session)\t$(Jvm_cpu_use_max_session)\t$(Jvm_ram_memory_max_session)\t$(Session_max_active_count_session)\t-------\t$(Avg_process_time_max_session)\t$(Thread_pool_buzyness_max_session)\t$(Error_average_max_session)$(Color)\t-------\t-------\t$(Jdbc_count_max_session)$(Color)"
    fi
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
PORT_HTTP=$(xmllint --xpath 'string(/Server/Service/Connector/@port)' $CATALINA_BASE/conf/server.xml)
echo $PORT_HTTP
}

Port_shutdown() {
PORT_SHUTDOWN=$(xmllint --xpath 'string(/Server/@port)' $CATALINA_BASE/conf/server.xml)
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
  COMPRESSION=$(xmllint --xpath 'string(/Server/Service/Connector/@compression)' $CATALINA_BASE/conf/server.xml)
  if [ $COMPRESSION == on ]
    then
    echo $(Color GREEN)$COMPRESSION$(Color)
  else
    echo $(Color RED)$COMPRESSION$(Color)
fi
}

Max_threads() {
 MAX_THREADS=$(xmllint --xpath 'string(/Server/Service/Connector/@maxThreads)' $CATALINA_BASE/conf/server.xml)
echo $MAX_THREADS
}

Accept_count() {
 ACCEPT_COUNT=$(xmllint --xpath 'string(/Server/Service/Connector/@acceptCount)' $CATALINA_BASE/conf/server.xml)
echo $ACCEPT_COUNT
}

Connector_type() {
CONNECTOR_TYPE=$(xmllint --xpath 'string(/Server/Service/Connector/@protocol)' $CATALINA_BASE/conf/server.xml)
if [ $CONNECTOR_TYPE == HTTP/1.1 ]
  then echo DEFAULT
  else 
    CONNECTOR_TYPE=$(echo $CONNECTOR_TYPE | sed -e "s/\./ /g" | awk '{print $5}' | sed -e "s/Protocol//g" | sed -e "s/Http11//g")
    echo ${CONNECTOR_TYPE^^}
fi
}

Connector_type_lower() {
CONNECTOR_TYPE=$(xmllint --xpath 'string(/Server/Service/Connector/@protocol)' $CATALINA_BASE/conf/server.xml)
if [ $CONNECTOR_TYPE == HTTP/1.1 ]
  then echo DEFAULT
  else
    CONNECTOR_TYPE=$(echo $CONNECTOR_TYPE | sed -e "s/\./ /g" | awk '{print $5}' | sed -e "s/Protocol//g" | sed -e "s/Http11//g")
    echo ${CONNECTOR_TYPE,,} 
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

Check_jvm_heapdump_last_cron_date() {
#LAST_HEAP_DUMP=$(find $LOG_DIR/server/appli -maxdepth 1 -mtime -1 -type f -name cron_print_object_summary.$(Instance)*.log -exec ls -rt  {} \; | tail -1)
#LAST_HEAP_DUMP_DATE=$( find $LOG_DIR/server/appli -maxdepth 1 -mtime -1 -type f -name cron_print_object_summary.$(Instance)*.log -exec ls -lrt  {} \; | tail -1 | awk '{print $8}')
LAST_HEAP_DUMP_DATE=$(ls -t $LOG_DIR/server/appli/cron_print_object_summary.$(Instance)*.log | head -1 | sed -e "s#.*$(Instance)-*\(\)#\1#"  )
if [ ! -z $LOG_DIR -a ! -z "$LAST_HEAP_DUMP_DATE" ]
  then echo $LAST_HEAP_DUMP_DATE
  else echo "NON"
fi
}

Check_jvm_heapdump_cron_status() {
if [ -n $(Check_jvm_heapdump_last_cron_date) ]
  then echo "OK"
  else echo "NON"
fi
}


Check_last_heapdump_cron() {
#LAST_HEAP_DUMP=$(find $LOG_DIR/server/appli -maxdepth 1 -mtime -1 -type f -name cron_print_object_summary.$(Instance)*.log -exec ls -rt  {} \; | tail -1)
LAST_HEAP_DUMP=$(ls -t $LOG_DIR/server/appli/cron_print_object_summary.$(Instance)*.log | head -1)
echo $LAST_HEAP_DUMP
}

Check_last_metrics_session_file() {
LAST_METRICS_SESSION_FILE=$(ls -t $INSTALL_DIR/tmp_dir/TOMCAT_Metrics_*.csv | head -1)
echo $LAST_METRICS_SESSION_FILE
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

#Check_ldapsearch() {
#if [ ! -z $ORACLE_HOME -a -x $ORACLE_HOME/bin/ldapsearch -a -f $ORACLE_HOME/network/admin/ldap.ora ]
#  then echo -e "$(Color BOLD)$(Color GREEN)OK$(Color)"
#  else echo -e "$(Color BOLD)$(Color YELLOW)NON$(Color)"
#fi
#}


Check_high_cpu_thread() {
THREAD_OUTPUT_FILE=$INSTALL_DIR/tmp_dir/TOMCAT_threads.tmp
top -b -n 1 -H -p $(Pid) | tail -n +8 | awk '{print $1" "$9}' | sed -e "s/,/ /g" | awk '{print $1" "$2}' > $THREAD_OUTPUT_FILE


LAST_HEAP_DUMP=$( ls -t $LOG_DIR/server/appli/threaddump.$(Instance)*.log | head -1)
    echo ""
    #echo -e "Tomcat instance thread PID is over 1% CPU utilization, check heapdump file to find code by hexadecimal nid"
    echo -e "$(Color BOLD)Thread(s)$(Color)\t\tPID\t\t\tHEX PID\t\t$(Color)"
    echo -e "$(Color BOLD)Consommateur(s) en CPU$(Color)\t---\t\t\t-------\t\t$(Color)"

for PID in $(cat $THREAD_OUTPUT_FILE | awk '{print $1}')
do 
  ## Affiche une alerte pour tout Child PID superieur a 1% de CPU
  if [ $(grep $PID $THREAD_OUTPUT_FILE| awk '{print $2}') -gt 1 ]
  then
    # Conversion du PID de decimal vers hexadecimal  
    HEX_PID=$(printf '%x\n' $PID)
    echo -e "\t\t\t$PID\t\t==>\t$HEX_PID"
    #echo -e "Tomcat instance thread PID $(Color RED)$PID --> $HEX_PID$(Hex PID)(Color) is over 1% CPU utilization, check heapdump file to find code by hexadecimal nid"
    # Recherche du nid dans le heapdump si present
    grep $HEX_PID $LAST_HEAP_DUMP 
  fi
done 
}

Check_adp_heap_classes_size() {
if [[ $(Check_jvm_heapdump_cron_status) == "OK" ]]
  then
    #LAST_HEAP_DUMP=$( find $LOG_DIR/server/appli -maxdepth 1 -mtime -1 -type f -name cron_print_object_summary.$(Instance)*.log -exec ls -rt  {} \; | tail -1)
    ADP_HEAP_CLASSES=$(cat $(Check_last_heapdump_cron) | grep com.adp | awk '{ SUM += $3} END { print SUM / 1024 / 1024 }'| awk '{$1=$1}1' FS=. OFS=, |  sed -e "s/,/ /g" | awk '{print $1}' )
    echo -e "$(Color BLUE)$(Color UNDERL)$ADP_HEAP_CLASSES$(Color)"
fi
}

Check_nonadp_heap_classes_size() {
if [[ $(Check_jvm_heapdump_cron_status) == "OK" ]]
  then
    LAST_HEAP_DUMP=$(ls -t $LOG_DIR/server/appli/cron_print_object_summary.$(Instance)*.log | head -1 )
   # NON_ADP_HEAP_CLASSES=$(cat $LAST_HEAP_DUMP | grep -v com.adp.fr | awk '{ SUM += $3} END { print SUM / 1024 / 1024 }' | sed -e "s/./ /g" | awk '{print $1}')
    NON_ADP_HEAP_CLASSES=$(cat $LAST_HEAP_DUMP | grep -v com.adp | awk '{ SUM += $3} END { print SUM / 1024 / 1024 }' | awk '{$1=$1}1' FS=. OFS=, |  sed -e "s/,/ /g" | awk '{print $1}' )
    echo -e "$(Color BLUE)$(Color UNDERL)$NON_ADP_HEAP_CLASSES$(Color)"
fi
}

Check_adp_heap_classes_instances_nb() {
if [[ $(Check_jvm_heapdump_cron_status) == "OK" ]]
  then 
    LAST_HEAP_DUMP=$(ls -t $LOG_DIR/server/appli/cron_print_object_summary.$(Instance)*.log | head -1)
    ADP_HEAP_CLASSES=$(cat $LAST_HEAP_DUMP | grep -v com.adp.fr | awk '{ SUM += $3} END { print SUM }')
    echo -e "$(Color BLUE)$(Color UNDERL)$ADP_HEAP_CLASSES$(Color)"
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
JDBC_DIDA=$(cat $DIDA_DS_LIST_FILE | grep $1 >/dev/null )
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
    echo $HEAP_MEMORY
  else
  if [[ $(Check_jstat) == *OK* ]]
    then 
      HEAP_MEMORY=$( ($JDK_HOME/bin/jstat -gc $(Pid) 2>/dev/null || echo "0 0 0 0 0 0 0 0 0") | tail -n 1 | awk '{split($0,a," "); sum=a[3]+a[4]+a[6]+a[8]; print sum/1024}' ) 2>/dev/null
      HEAP_MEMORY=${HEAP_MEMORY%.*}
      echo $HEAP_MEMORY 
    else
      echo -e $(Color BOLD)$(Color YELLOW)No JDK$(Color)
  fi
fi
}

Check_kernel_net.core.maxconn() {
KERNEL_MAXCONN=$(sysctl -n net.core.somaxconn)
echo $KERNEL_MAXCONN
}

Check_kernel_net.core.netdev_max_backlog() {
KERNEL_NETDEV_MAXBACKLOG=$(sysctl -n net.core.netdev_max_backlog)
echo $KERNEL_NETDEV_MAXBACKLOG
}

Check_kernel_net.ipv4.tcp_syncookies() {
KERNEL_SYNCOOKIES=$(sysctl -n net.ipv4.tcp_syncookies)
echo $KERNEL_SYNCOOKIES
}

Check_kernel_net.ipv4.tcp_max_syn_backlog() {
KERNEL_MAXSYNBACKLOG=$(sysctl -n net.ipv4.tcp_max_syn_backlog)
echo $KERNEL_MAXSYNBACKLOG
}

Check_kernel_net.ipv4.tcp_keepalive_time() {
KERNEL_TCPKEEPALIVE=$(sysctl -n net.ipv4.tcp_keepalive_time)
echo $KERNEL_TCPKEEPALIVE
}

Check_kernel_net.ipv4.tcp_mtu_probing() {
KERNEL_TCPMTUPROBING=$(sysctl -n net.ipv4.tcp_mtu_probing)
echo $KERNEL_TCPMTUPROBING
}


Jvm_max_heap_memory() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    HEAP_MEMORY=$((`/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "java.lang:type=Memory" HeapMemoryUsage max` / 1024 / 1024 ))
    echo $HEAP_MEMORY
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_server_address() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    SERVER_ADDRESS=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Server" address )
    echo $SERVER_ADDRESS
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_server_shutdown_port() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    SHUTDOWN_PORT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Server" port )
    echo $SHUTDOWN_PORT
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_server_version() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    SERVER_VERSION=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Server" serverNumber )
    echo $SERVER_VERSION
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}


Check_jmx4perl_tomcat_service_name() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    SERVICE_NAME=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Service" name )
    echo $SERVICE_NAME
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_engine_name() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    ENGINE_NAME=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Engine" name )
    echo $ENGINE_NAME
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_service_connector_name() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    SERVICE_CONNECTOR=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Service" connectorNames | sed -e "s#.*port=*\(\)#\1#"| grep -o -E '[0-9]+')
    echo $SERVICE_CONNECTOR
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_connector_connection_timeout() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CONNECTION_TIMEOUT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Connector,port=$(Check_jmx4perl_tomcat_service_connector_name)" connectionTimeout )
    echo $CONNECTION_TIMEOUT / 1000 | bc
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_connector_keepalive_timeout() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    KEEPALIVE_TIMEOUT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Connector,port=$(Check_jmx4perl_tomcat_service_connector_name)" keepAliveTimeout )
    echo $KEEPALIVE_TIMEOUT / 1000 | bc
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}



Check_jmx4perl_tomcat_connector_acceptCount() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CONNECTOR_ACCEPT_COUNT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Connector,port=$(Check_jmx4perl_tomcat_service_connector_name)" acceptCount )
    echo $CONNECTOR_ACCEPT_COUNT
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_connector_maxThreads() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CONNECTOR_ACCEPT_COUNT=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Connector,port=$(Check_jmx4perl_tomcat_service_connector_name)" maxThreads )
    echo $CONNECTOR_ACCEPT_COUNT
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_threapool_current_threads() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CURRENT_THREADS=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read Catalina:type=ThreadPool,name=\"http-$(Connector_type_lower)-$(Check_jmx4perl_tomcat_service_connector_name)\" currentThreadCount )
    echo $CURRENT_THREADS
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_threapool_current_threads_buzy() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CURRENT_THREADS_BUSY=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read Catalina:type=ThreadPool,name=\"http-nio2-$(Check_jmx4perl_tomcat_service_connector_name)\" currentThreadsBusy )
    echo $CURRENT_THREADS_BUSY
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_threapool_acceptor_current_threads() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    ACCEPTOR_CURRENT_THREADS=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read Catalina:type=ThreadPool,name=\"http-nio2-$(Check_jmx4perl_tomcat_service_connector_name)\" acceptorThreadCount )
    echo $ACCEPTOR_CURRENT_THREADS
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_threapool_free_threads() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CURRENT_THREADS=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read Catalina:type=ThreadPool,name=\"http-nio2-$(Check_jmx4perl_tomcat_service_connector_name)\" currentThreadCount )
    CURRENT_THREADS_BUSY=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read Catalina:type=ThreadPool,name=\"http-nio2-$(Check_jmx4perl_tomcat_service_connector_name)\" currentThreadsBusy )
    CURRENT_FREE_THREADS=$(( CURRENT_THREADS - CURRENT_THREADS_BUSY ))
    echo $CURRENT_FREE_THREADS
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}


Check_jmx4perl_tomcat_connector_protocol() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    CONNECTOR_PROTOCOL=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "Catalina:type=Connector,port=$(Check_jmx4perl_tomcat_service_connector_name)" protocol | sed -e "s#.*org.apache.coyote.http11.Http11*\(\)#\1#" | sed -e "s/Protocol//g" )
    echo $CONNECTOR_PROTOCOL
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}



Jvm_max_heap_memory_session() {
HEAP_MEMORY_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $3}' | sort -r | head -n1) 
#if [[ $(Jvm_heap_memory) -lt $HEAP_MEMORY_MAX_SESSION ]]
#  then 
    echo $HEAP_MEMORY_MAX_SESSION
#  else 
    #echo $(Jvm_heap_memory) 
#    echo $HEAP_MEMORY
#fi
}

Check_jmx4perl_tomcat_jvm_maxfiledescriptor() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    JVM_MAXFILEDESCRIPTOR=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "java.lang:type=OperatingSystem" MaxFileDescriptorCount )
    echo $JVM_MAXFILEDESCRIPTOR
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_jvm_currentfiledescriptor() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    JVM_CURRENT_FILEDESCRIPTOR=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "java.lang:type=OperatingSystem" OpenFileDescriptorCount )
    echo $JVM_CURRENT_FILEDESCRIPTOR
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_jdbc_pool_count_bdz2x() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    JDBC_POOL_BDZ2X=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "tomcat.jdbc:name=Tomcat Connection Pool[*],type=ConnectionPool,class=org.apache.tomcat.jdbc.pool.DataSource" PoolName| grep PoolName | grep "BDZ2X" | wc -l )
    echo $JDBC_POOL_BDZ2X
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}

Check_jmx4perl_tomcat_jdbc_pool_count_non_bdz2x() {
if [[ $(Check_jmx4perl) == *OK* ]]
  then
    JDBC_POOL_BDZ2X=$(/usr/bin/jmx4perl http://localhost:$(Port_http)/j4p --product tomcat read "tomcat.jdbc:name=Tomcat Connection Pool[*],type=ConnectionPool,class=org.apache.tomcat.jdbc.pool.DataSource" PoolName | grep PoolName | grep -v "BDZ2X" | wc -l )
    echo $JDBC_POOL_BDZ2X
  else
    echo -e $(Color BOLD)$(Color YELLOW)No JMX$(Color)
fi
}



Session_max_active_count_session() {
MAX_ACTIVE_SESSION_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $8}' | sort -r | head -n1)
echo $MAX_ACTIVE_SESSION_SESSION
}

Current_threads_max_session() {
THREADS_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $2}' | sort -r | head -n1)
echo $THREADS_MAX_SESSION
}

Jvm_cpu_use_max_session() {
JVM_CPU_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $5}' | sort -r | head -n1)
echo $JVM_CPU_MAX_SESSION
}

Jvm_ram_memory_max_session() {
JVM_RAM_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $6" "$7}' | sort -r | head -n1)
echo $JVM_RAM_MAX_SESSION
}

Avg_process_time_max_session() {
AVG_PROCESS_TIME_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $10" "$11}' | sort -r | head -n1)
echo $AVG_PROCESS_TIME_MAX_SESSION
} 

Thread_pool_buzyness_max_session() {
THREAD_POOL_BUSYNESS_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $12" / "$14}' | sort -r | head -n1)
echo $THREAD_POOL_BUSYNESS_MAX_SESSION
}

Error_average_max_session() {
ERROR_AVERAGE_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $15" "$16}' | sort -r | head -n1)
echo $ERROR_AVERAGE_MAX_SESSION
}

Jdbc_count_max_session() {
JDBC_COUNT_MAX_SESSION=$(cat $(Check_last_metrics_session_file) | tail -n +3 | awk '{print $20}' | sort -r | head -n1)
echo $JDBC_COUNT_MAX_SESSION

}

Jvm_ram_memory() {
RAM_MEMORY=$((` cut -d' ' -f2 <<< cat /proc/$(Pid)/statm 2>/dev/null || echo "0"` / 1024 ))
echo $RAM_MEMORY Mo
}

Jvm_cpu_use() {
CPU_USE=$( ps -p $(Pid) -o %cpu 2>/dev/null | tail -n 1  )
CPU_USE=${CPU_USE%.*}
if [[ $CPU_USE -lt 10 ]]
  then
    echo $(Color BOLD)$(Color GREEN)$CPU_USE$(Color)
  else
    echo $(Color BOLD)$(Color RED)$CPU_USE$(Color)
fi
}

Self_cpu_use() {
CPU_USE=$( ps -p $1 -o %cpu 2>/dev/null | tail -n 1  )
CPU_USE=${CPU_USE%.*}
if [[ $CPU_USE -lt 10 ]]
  then
    echo $(Color BOLD)$(Color GREEN)$CPU_USE %$(Color)
  else
    echo $(Color BOLD)$(Color RED)$CPU_USE %$(Color)
fi

}

Self_ram_memory() {
RAM_MEMORY=$((` cut -d' ' -f2 <<< cat /proc/$1/statm 2>/dev/null || echo "0"` / 1024 ))
if [[ $RAM_MEMORY -lt 10 ]]
  then
    echo $(Color BOLD)$(Color GREEN)$RAM_MEMORY Mo$(Color)
  else
    echo $(Color BOLD)$(Color RED)$RAM_MEMORY Mo$(Color)
fi
}

Self_info() {
echo ""
echo -e "$(Color BOLD)$(Color WHITE)CPU Used:$(Color)\t$(Self_cpu_use $1)\t$(Color BOLD)$(Color WHITE)RAM Used:$(Color)\t$(Self_ram_memory $1)$(Color)"
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

#Check_ldap_ora_oid_file() {
#LDAP_ORA_OID_FILE="$CONFIG_PATH/tmp_dir/LDAP_ORA_OID_FILE.txt"
#if [ -f $LDAP_ORA_OID_FILE ] 
#  then
#    CHECK_LDAP_ORA_OID_FILE=true
#  else 
#    CHECK_LDAP_ORA_OID_FILE=false
#fi
#}


#Generate_ldap_ora_oid_file() {
#LDAP_BASE=$(cat $ORACLE_HOME/network/admin/ldap.ora | grep default_admin_context | awk '{print $3}' )
#LDAP_SERVERS=$(cat $ORACLE_HOME/network/admin/ldap.ora | grep directory_servers | awk '{print $2}' | sed -e "s/(//g" | sed -e "s/)//g" | sed -e "s/,/ /g" | sed -e "s/:/ /g" )
#
#}

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
    printf $(find $i -type f \( -name "*.log" -o -name "*.out" -o -name "*.txt" \) -print -delete | wc -l)
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

Purge_metrics() {
echo Purge des metriques
if [ -z $INSTALL_DIR -o ! -d $INSTALL_DIR/tmp_dir ]
  then
   echo "Une des variables nécessaires n'est pas definies"
    exit 1;
  else
   echo "Suppression et nombre de fichiers supprimes:"
   for i in $INSTALL_DIR/tmp_dir 
   do
    printf "* csv sous $i: "
    printf $(find $i -type f -name "*.csv" -print -delete | wc -l)
    if [ ${PIPESTATUS[0]} -eq 0 ]
      then echo -e "$(Color GREEN)\tOK$(Color)"
      else echo -e "$(Color RED)\tKO$(Color)"
    fi
   done
   for i in $INSTALL_DIR/tmp_dir
   do
    printf "* json sous $i: "
    printf $(find $i -type f -name "*.json" -print -delete | wc -l)
    if [ ${PIPESTATUS[0]} -eq 0 ]
      then echo -e "$(Color GREEN)\tOK$(Color)"
      else echo -e "$(Color RED)\tKO$(Color)"
    fi
   done
   for i in $INSTALL_DIR/tmp_dir
   do
    printf "* *tmp* sous $i: "
    printf $(find $i -type f -name "*.tmp*" -print -delete | wc -l)
    if [ ${PIPESTATUS[0]} -eq 0 ]
      then echo -e "$(Color GREEN)\tOK$(Color)"
      else echo -e "$(Color RED)\tKO$(Color)"
    fi
   done

fi

}



help() {
echo "Usage: start | stop | status | restart | restart_failure | purge_logs | purge_cache | purge_all | purge_metrics | stats | diags <TIMER (secs)> <Metrics Output format (csv or json)>"
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

echo -e "$(Color WHITE)\t\t\tLOCALHOST$(Color)\t==>\t$DEST\t$PORT\t$TYPE\t$COUNT\t$FQDN" | tee -a $OUTPUT_FILE.tmp2
TYPE=
done <<< "$(netstat -aopn 2>/dev/null | grep $(Pid) | grep tcp | grep -v LISTEN | awk {'print $5'} | sed -e "s/:/ /g" | sort | uniq -c)"
cat $OUTPUT_FILE.tmp2 | grep JDBC | awk '{print $7}' | paste -sd+ - | bc >$OUTPUT_FILE.tmp3

Check_output $1 $2 $3 >/dev/null
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

#CONNECTOR_TYPE=$(echo $(Connector_type) |  tr '[:upper:]' '[:lower:]' )
#echo $CONECTOR_TYPE
clear
TIMER=x$1
if [ -z $TIMER -o "$TIMER" == "x" -o $(echo "$1" | grep -qE '^[0-9]+$'; echo $?) -ne "0" ]
  then TIMER="NON"
  else TIMER="$1"
fi

METRICS=$2
METRICS=x$2
#if [ -z "$METRICS" -o "$METRICS" == "x" -o $(echo "$2" | grep "csv\|json"; echo $?) -ne "0" ]
if [ -z "$METRICS" ] || [ "$METRICS" == "x" ] || [ "$(echo "$2" | grep "csv\|json" 1>/dev/null; echo $?)" -ne "0" ]
#if [ -z $METRICS -o "$METRICS" == "x" ]
  then METRICS="NON"
  else METRICS=$2
fi


Instance_Info $TIMER $METRICS
if [ $TIMER -ne 0 ] 2>/dev/null 
  then 
    while true   
      do
      Instance_info_dynamic $TIMER $METRICS $INCR
      Net_threads $TIMER $METRICS $INCR
      Db_sessions
# Desactivation car prob daffichage avec tput en cas de detection de thread consommateur
#      Check_high_cpu_thread
#      Self_info $$
      sleep $TIMER
      tput rc
      tput ed
    done
  else 
      TIMER="NON"
      METRICS="NON"
      Instance_info_dynamic   
      Net_threads
      Db_sessions
      Check_high_cpu_thread
fi 


}


Diagram() {
clear
echo ""
echo -e "                    __$(Color BOLD)OS$(Color)_________________________________________________________________________"
echo -e "                   |                                                                             |" 
echo -e "                   |    __$(Color BOLD)Kernel$(Color)___________________________________________________________      |" 
echo -e "                   |   |  kernel.sched_child_runs_first:                                   |     |" 
echo -e "                   |   |  __$(Color BOLD)Net$(Color)__________________________________________________________  |     |" 
echo -e "                   |   | | somaxconn: $(Color WHITE)$(Check_kernel_net.core.maxconn)$(Color)\t\tnetdev_max_backlog: $(Color WHITE)$(Check_kernel_net.core.netdev_max_backlog)$(Color)\t | |     |" 
echo -e "                   |   | | __$(Color BOLD)TCP$(Color)________________________________________________________ | |     |" 
echo -e "                   |   | || tcp_syncookies: $(Color WHITE)$(Check_kernel_net.ipv4.tcp_syncookies)$(Color)\t\ttcp_max_syn_backlog: $(Color WHITE)$(Check_kernel_net.ipv4.tcp_max_syn_backlog)$(Color)\t|| |     |" 
echo -e "                   |   | || tcp_keepalive_time: $(Color WHITE)$(Check_kernel_net.ipv4.tcp_keepalive_time)s$(Color)\ttcp_mtu_probing: $(Color WHITE)$(Check_kernel_net.ipv4.tcp_mtu_probing)$(Color)\t\t|| |     |" 
echo -e "                   |   | ||_____________________________________________________________|| |     |" 
echo -e "                   |   | |_______________________________________________________________| |     |" 
echo -e "                   |   |___________________________________________________________________|     |" 
echo -e "                   |                                                                             |" 
echo -e "                   |     __JVM_________________________________________________    |"
echo -e "                   |    | Max File descriptor: $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_jvm_maxfiledescriptor)$(Color)\t Count: $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_jvm_currentfiledescriptor)$(Color)\t       |   |"
echo -e "                   |    | Max File descriptor: $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_jvm_maxfiledescriptor)$(Color)\t Count: $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_jvm_currentfiledescriptor)$(Color)\t       |   |"
echo -e "                   |    |______________________________________________________|   |"

echo -e "                   |                                                                             |" 
echo -e "__Client___        |         _$(Color BOLD)Catalina Server$(Color)_Address:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_server_address)$(Color)_Shutdown:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_server_shutdown_port)$(Color)_Version:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_server_version)$(Color)__"
echo -e "|         |        |        |                                                                   |"
echo -e "|         |        |        |  __$(Color BOLD)Service$(Color)__Name:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_service_name)$(Color)______________________________________   |"
echo -e "|         |        |        | |                                                              |  |"
echo -e "|         |        |        | |   _$(Color BOLD)Engine$(Color)__Name:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_engine_name)$(Color)____________________________________    |"
echo -e "|         |        |        | |  |                                                          |   |"
echo -e "|         |        |        | | _|______________________________________________________    |   |"
echo -e "| BROWSER |        |        | ||$(Color BOLD)Connector:$(Color)$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_service_connector_name)$(Color) $(Color BOLD)Protocol:$(Color)$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_connector_protocol)$(Color)                            |   |   |"
echo -e "|         |        |        | ||Connection Timeout: $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_connector_connection_timeout )s$(Color)\tKeepAlive Timeout:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_connector_keepalive_timeout )s$(Color)\t\t|   |   |"
echo -e "|         |        |        | ||                                                        |   |   |"
echo -e "|         |        |        | || _Acceptor Thread_________   _Worker Thread__________   |   |   |"
echo -e "|         |        |        | ||| AcceptCount:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_connector_acceptCount)$(Color)         | | MaxThreads:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_connector_maxThreads)$(Color)         |  |   |   |"
echo -e "|         |        |        | ||| Acceptor Thread Count:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_threapool_acceptor_current_threads)$(Color) | | Current Thread Count:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_threapool_current_threads)$(Color)|  |   |   |"
echo -e "|         |        |        | |||_________________________| | Current Thread Buzy:$(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_threapool_current_threads_buzy)$(Color)  |  |   |   |"
echo -e "|         |        |        | || Free Thread Pool_______    |________________________|  |   |   |"
echo -e "|         |        |        | ||| Free Count:   $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_threapool_free_threads)$(Color)\t|                               |   |   |"
echo -e "|         |        |        | |||_______________________|                               |   |   |"
echo -e "|         |        |        | ||_______________________________________________________ |   |   |"
echo -e "|         |        |        | |  |                                                       |   |"
echo -e "|         |        |        | |  | _Host_________________________________________    |   |"
echo -e "|         |        |        | |  ||                                              |  ||   |"
echo -e "|         |        |        | |  || _Context____________________________________ |  |   |"
echo -e "|         |        |        | |  |||                                            ||| |   |"
echo -e "|         |        |        | |  |||                                            ||| |   |"
echo -e "|         |        |        | |  |||____________________________________________||| |   |"
echo -e "|         |        |        | |  ||______________________________________________|| |   |"
echo -e "|         |        |        | |  |________________________________________________| |   |"
echo -e "|         |        |        | |_____________________________________________________|   |"
echo -e "                   |        | __$(Color BOLD)JDBC$(Color)________________________________________________    |"
echo -e "                   |        || BDZ2X Datasources: $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_jdbc_pool_count_bdz2x)$(Color)\t\t\t\t|   |" 
echo -e "                   |        || Non BDZ2X Datasources: $(Color WHITEUNDERL)$(Check_jmx4perl_tomcat_jdbc_pool_count_non_bdz2x)$(Color)\t\t\t\t|   |" 
echo -e "|         |        |        |___________________________________________________________|"
echo -e "__________          _____________________________________________________________________________"
echo ""
echo ""
echo ""
echo -e "                    _Databases_______________________________________________________________"
echo -e "                   |   BDZ2X:                                                                |" 


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
purge_metrics)
  Purge_metrics
;;
purge_all)
  purge_logs
  purge_cache
  purge_heapdump
  Purge_metrics
;;
stats)
  Net_threads
;;
diags)
  Diags $2 $3
;;
diagram)
  Diagram
;;
*)
  help
;;
esac

exit 0
