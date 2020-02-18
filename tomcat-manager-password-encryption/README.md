# Informations
Please find in this repository Tomcat 9 Tomcat manager password encryption method.

## Set server.xml Realm 
```xml
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase" >
                <CredentialHandler className="org.apache.catalina.realm.SecretKeyCredentialHandler"
                      algorithm="PBKDF2WithHmacSHA512"
                      iterations="10000"
                      keyLength="256"
                      saltLength="16"/>
        </Realm>
      </Realm>
```

See [server.xml](https://github.com/vincent-gou/tomcat-tools/edit/master/tomcat-manager-password-encryption/server.xml) for more information.

## Password generation 
### Linux
```
$CATALINA_HOME/bin/digest.sh -a "PBKDF2WithHmacSHA512" -i 10000 -s 16 -k 256 \
-h "org.apache.catalina.realm.SecretKeyCredentialHandler" password
password:4aedc867192f5fbbbf8f5a16f275f9f1$10000$5cbeefc0bb40d9a79ebcc90d120b7de280acf817a94d50a2989149590cdb4d87
```

### Windows
```
%CATALINA_HOME%\bin\digest.bat -a "PBKDF2WithHmacSHA512" -i 10000 -s 16 -k 256 -h "org.apache.catalina.realm.SecretKeyCredentialHandler" password
password:4adf2646795466f765215631741dbe98$10000$3cbf4f70cde7ae7cf1df04a0d82ff6692e43afdced9399bb22499855f7da4746
```

## Set tomcat-users.xml password

```xml
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<role rolename="manager-gui"/>
<role rolename="manager-jmx"/>
<role rolename="manager-script"/>
<user username="admin" password="58d3dc5f32ff6074ca9338f9fd4b6110$10000$66020098234b071efa23a6b2a256933150ddd3a46fb983ygeuygfb36813" roles="manager-gui,manager-jmx,manager-script "/>
</tomcat-users>
```
See [tomcat-users.xml](https://github.com/vincent-gou/tomcat-tools/edit/master/tomcat-manager-password-encryption/tomcat-users.xml) for more information.
