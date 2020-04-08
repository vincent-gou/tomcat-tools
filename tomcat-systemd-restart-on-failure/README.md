# SYSTEMD service creation as Tomcat user

## Prerequisities

> :warning: **DBus must be active**: Systemd commands needs DBus so you must be connected directly (terminal or ssh) but avoid "su -" session. it may set incorrect DBus settings.

> :warning: To activate planned systemd service startup even if Tomcat is not connected, system must be set

> :lock: As root
```bash
root# loginctl enable-linger user
```
> :warning: in order to access systemd logs , tomcat user must be member of following groups:
* systemd-journal
 

# Systemd Tomcat user setup

## Tomcat user systemd service template 

```bash
mkdir -p ~/.config/systemd/user
vi ~/.config/systemd/user/tomcat@.service
```
```bash
# Systemd unit file template for tomcat systemd service
[Unit]
Description=Apache Tomcat Web Application Container Instance %i
After=syslog.target network.target
OnFailure=tomcat-failure-notify@%i.service
 
[Service]
Type=forking
ExecStart=/bin/sh -ec "<PATH_TO_TOMCAT_STARTUP_SCRIPT.sh>"
ExecStop=/bin/sh -ec "<PATH_TO_TOMCAT_SHUTDOWN_SCRIPT.sh>"
UMask=0007
RestartSec=10
Restart=on-failure
SuccessExitStatus=143
 
[Install]
WantedBy=default.target
```

## Tomcat user systemd notification service template 

```bash
vi ~/.config/systemd/user/tomcat-failure-notify@.service
``` 

```bash
[Unit]
Description=Tomcat instance failure notification: tomcat%i
[Service]
Type=oneshot
ExecStart=/bin/sh -ec "<PATH_TO_NOTIFICATION_SCRIPT>.sh %i %H"
```

Reload Systemd:
 
```bash
systemctl --user daemon-reload
```

## Tomcat user systemd service creation

```bash
tomcat@linux:~> systemctl --user enable tomcat@prod_i1
Created symlink from /opt/home/tomcat/.config/systemd/user/default.target.wants/tomcat@prod_i1.service to /opt/home/tomcat/.config/systemd/user/tomcat@.service.
tomcat@linux:~> systemctl --user enable tomcat@prod_i2
Created symlink from /opt/home/tomcat/.config/systemd/user/default.target.wants/tomcat@prod_i2.service to /opt/home/tomcat/.config/systemd/user/tomcat@.service.
tomcat@linux:~>
tomcat@linux:~> ll ~/.config/systemd/user/default.target.wants/
total 0
lrwxrwxrwx 1 tomcat tomcat 55 22 oct.  16:26 tomcat@prod_i1.service -> /ehc/fs1/home/infog/.config/systemd/user/tomcat@.service
lrwxrwxrwx 1 tomcat tomcat 55 22 oct.  16:26 tomcat@prod_i2.service -> /ehc/fs1/home/infog/.config/systemd/user/tomcat@.service
tomcat@linux:~>
tomcat@linux:~> ll ~/.config/systemd/user/
total 8
drwxr-xr-x 2 infog infog  76 22 oct.  16:26 default.target.wants
-rw-r--r-- 1 infog infog 486 22 oct.  16:25 tomcat@.service
-rw-r--r-- 1 infog infog 211 22 oct.  16:25 tomcat-failure-notify@.service
tomcat@linux:~>
```

## Tomcat user systemd service administration
### Display Tomcat user systemd units

```bash
tomcat@linux:~> systemctl --user list-units --all | grep tomcat
  tomcat@prod_i1.service                        loaded    inactive   dead      Apache Tomcat Web Application Container Instance prod_i1
  tomcat@prod_i2.service                        loaded    inactive   dead      Apache Tomcat Web Application Container Instance prod_i2
  tomcat-failure-notify@prod_i1.service        loaded    inactive   dead      Tomcat prod_i1 failure notification Instance prod_i1
  tomcat-failure-notify@prod_i2.service        loaded    inactive   dead      Tomcat prod_i2 failure notification Instance prod_i2
```

> :white_check_mark: Systemd unit activation has automatically created linked systemd units (tomcat-failure-notifiy) for each tomcat units.

### Tomcat user systemd unit startup

```bash
tomcat@linux:~> systemctl --user start tomcath@prod_i1
```

### Tomcat user systemd all unit status

```bash
tomcat@linux:~> systemctl --user list-units --all | grep tomcat
  tomcat@7prod_i1.service                        loaded    active     dead      Apache Tomcat Web Application Container Instance prod_i1
  tomcat@7prod_i2.service                        loaded    active     dead      Apache Tomcat Web Application Container Instance prod_i2
  tomcat-failure-notify@prod_i1.service        loaded    inactive   dead      Tomcat prod_i1 failure notification Instance prod_i1
  tomcat-failure-notify@prod_i2.service        loaded    inactive   dead      Tomcat prod_i2 failure notification Instance prod_i2
```

### Tomcat user systemd unit status

```bash
tomcat@linux:~> systemctl --user status -l tomcat@prod_i1
* tomcat@prod_i1.service - Apache Tomcat Web Application Container Instance prod_i1
   Loaded: loaded (/opt/home/infog/.config/systemd/user/tomcat@.service; enabled; vendor preset: disabled)
   Active: active (running) since mar. 2019-11-05 09:40:55 CET; 7min ago
  Process: 29401 ExecStart=/bin/sh -ec /opt/tomcat/%i/tools/TOMCAT_INSTANCE.sh start (code=exited, status=0/SUCCESS)
 Main PID: 29411 (java)
   CGroup: /user.slice/user-1002.slice/user@1002.service/tomcat.slice/tomcat@prod_i1.service
           `-29411 /opt/jdk/server-jre-8u221/bin/java -Djava.util.logging.config.file=/opt/tomcat/prod_i1/server/tomcat/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Doracle.jdbc.v$session.program=tomcatprod_i1 -Djdk.tls.ephemeralDHKeySize=2048 -Djava.protocol.handler.pkgs=org.apache.catalina.webresources -Dorg.apache.catalina.security.SecurityListener.UMASK=0027 -Xms1024m -Xmx2048m -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=9004 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djdbc.drivers=oracle.jdbc.OracleDriver -Dspring.profiles.active=tomcat -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/tomcat/tomcatprod_i1/heapdump -XX:+ExitOnOutOfMemoryError -Dignore.endorsed.dirs= -classpath /opt/tomcat/TOMCAT_LATEST/bin/bootstrap.jar:/opt/tomcat/TOMCAT_LATEST/bin/tomcat-juli.jar -Dcatalina.base=/opt/tomcat/tomcatprod_i1/server/tomcat -Dcatalina.home=/opt/tomcat/TOMCAT_LATEST -Djava.io.tmpdir=/opt/tomcat/tomcatprod_i1/server/tomcat/temp org.apache.catalina.startup.Bootstrap start
nov. 05 09:40:55 lx2811 systemd[1206]: Starting Apache Tomcat Web Application Container Instance 7tomcatdev_i1...
nov. 05 09:40:55 lx2811 sh[29401]: -Xms1024m -Xmx2048m -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=9004 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djdbc.drivers=oracle.jdbc.OracleDriver -Dspring.profiles.active=tomcat -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/tomcat/tomcatprod_i1/heapdump -XX:+ExitOnOutOfMemoryError
nov. 05 09:40:55 lx2811 sh[29401]: CATALINA_HOME: /opt/tomcat/TOMCAT_LATEST
nov. 05 09:40:55 lx2811 sh[29401]: CATALINA_BASE: /opt/tomcat/tomcatprod_i1/server/tomcat
nov. 05 09:40:55 lx2811 sh[29401]: Tomcat started.
nov. 05 09:40:55 lx2811 systemd[1206]: Started Apache Tomcat Web Application Container Instance prod_i1.
tomcat@linux:~>
```

### Tomcat user systemd unit logs

```bash
tomcat@linux:~> journalctl --user-unit  -f tomcat@prod_i1
-- Logs begin at sam. 2019-11-02 08:19:08 CET. --
nov. 04 10:36:08 lx2811 systemd[1206]: tomcat@prod_i1.service: Unit entered failed state.
nov. 04 10:36:08 lx2811 systemd[1206]: tomcat@prod_i1.service: Triggering OnFailure= dependencies.
nov. 04 10:36:08 lx2811 systemd[1206]: tomcat@prod_i1.service: Failed with result 'exit-code'.
nov. 04 10:36:11 lx2811 systemd[1206]: Stopped Apache Tomcat Web Application Container Instance prod_i1.
nov. 05 09:40:55 lx2811 systemd[1206]: Starting Apache Tomcat Web Application Container Instance prod_i1...
nov. 05 09:40:55 lx2811 sh[29401]: -Xms1024m -Xmx2048m -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=9004 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djdbc.drivers=oracle.jdbc.OracleDriver -Dspring.profiles.active=tomcat -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/tomcat/tomcatprod_i1/heapdump -XX:+ExitOnOutOfMemoryError
nov. 05 09:40:55 lx2811 sh[29401]: CATALINA_HOME: /opt/tomcat/TOMCAT_LATEST
nov. 05 09:40:55 lx2811 sh[29401]: CATALINA_BASE: /opt/tomcat/tomcatprod_i1/server/tomcat
nov. 05 09:40:55 lx2811 sh[29401]: Tomcat started.
nov. 05 09:40:55 lx2811 systemd[1206]: Started Apache Tomcat Web Application Container Instance prod_i1.
```
