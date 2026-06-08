#!/bin/bash
set -e

# Update system
yum update -y

# Install Java 17
yum install -y java-17-amazon-corretto

# Install Tomcat 10
TOMCAT_VERSION="10.1.18"
TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-10/v/bin/apache-tomcat-.tar.gz"

cd /opt
wget -q $TOMCAT_URL
tar -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz
mv apache-tomcat-${TOMCAT_VERSION} tomcat
rm apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Create tomcat user
useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat || true
chown -R tomcat:tomcat /opt/tomcat
chmod -R 755 /opt/tomcat

# Create systemd service
cat > /etc/systemd/system/tomcat.service << 'SERVICE'
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

# Start and enable Tomcat
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

echo "Tomcat installation complete!"
