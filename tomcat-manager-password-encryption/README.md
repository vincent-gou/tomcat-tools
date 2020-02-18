Please find in this repository Tomcat 9 Tomcat manager password encryption method.

Password generation 

Linux:
$CATALINA_HOME/bin/digest.sh -a "PBKDF2WithHmacSHA512" -i 10000 -s 16 -k 256 -h "org.apache.catalina.realm.SecretKeyCredentialHandler" password
password:4aedc867192f5fbbbf8f5a16f275f9f1$10000$5cbeefc0bb40d9a79ebcc90d120b7de280acf817a94d50a2989149590cdb4d87
