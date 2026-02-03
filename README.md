# Apache Tomcat 10 Deployment on AWS EC2

![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazon-aws&logoColor=white)
![Tomcat](https://img.shields.io/badge/Apache%20Tomcat-10-F8DC75?logo=apache-tomcat&logoColor=black)
![Java](https://img.shields.io/badge/Java-11%2B-ED8B00?logo=openjdk&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20LTS-E95420?logo=ubuntu&logoColor=white)

A comprehensive guide for deploying and configuring **Apache Tomcat 10** on an **AWS EC2 Linux instance** to host Java web applications (WAR files) in the cloud with internet accessibility.

![Apache Tomcat Architecture](apache%20tomcat%20project.png)

##  Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [AWS Resources Required](#-aws-resources-required)
- [Quick Start Guide](#-quick-start-guide)
- [Deployment Steps](#-deployment-steps)
- [Deploying WAR Files](#-deploying-war-files)
- [Configuration](#-configuration)
- [Security Hardening](#-security-hardening)
- [Testing & Verification](#-testing--verification)
- [Troubleshooting](#-troubleshooting)
- [Automation & CI/CD](#-automation--cicd)
- [Best Practices](#-best-practices)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

This project provides a production-ready deployment guide for running Apache Tomcat 10 on AWS EC2 infrastructure. It demonstrates best practices for:

- Setting up a secure EC2 instance for Java applications
- Installing and configuring Apache Tomcat 10
- Deploying and managing WAR applications
- Implementing security hardening measures
- Automating deployment workflows

**Perfect for:** DevOps engineers, Java developers, and cloud architects looking to deploy enterprise Java applications on AWS.

##  Features

-  **Quick Setup** - Get Tomcat running in under 15 minutes
-  **Security First** - Built-in security best practices and hardening guidelines
-  **Automated Deployment** - Ready-to-use scripts for repeatable deployments
-  **Systemd Integration** - Proper service management with automatic restart
-  **Monitoring Ready** - Log management and health check configurations
-  **Production Ready** - Optimized JVM settings and performance tuning
-  **Comprehensive Docs** - Step-by-step instructions with troubleshooting guide


##  Prerequisites

### Required

- **AWS Account** with EC2 permissions
- **SSH Key Pair** for EC2 instance access
- **Basic Knowledge** of Linux, AWS, and Java applications

### Recommended

- **AWS CLI** configured locally (for automation)
- **Terraform** or CloudFormation experience (for IaC)
- **Git** for version control

### Software Versions

| Component | Version | Notes |
|-----------|---------|-------|
| Ubuntu | 22.04 LTS | Recommended base AMI |
| Java (OpenJDK) | 11 or 17 | Tomcat 10 requires Java 11+ |
| Apache Tomcat | 10.1.x | Latest stable release |

##  AWS Resources Required

### EC2 Instance

- **Instance Type:** `t2.micro` (free tier) or `t3.small` (recommended)
- **AMI:** Ubuntu Server 22.04 LTS
- **Storage:** 8GB minimum (20GB recommended)
- **Network:** VPC with public subnet

### Security Group Configuration

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP/CIDR | Secure shell access |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Tomcat HTTP (dev/test only) |
| HTTP | TCP | 80 | 0.0.0.0/0 | Optional (with reverse proxy) |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Optional (with TLS/SSL) |

>  **Security Warning:** For production, restrict port 8080 access and use a reverse proxy (NGINX/Apache) with TLS.

### Optional Resources

- **Elastic IP** - For static public IP address
- **Application Load Balancer** - For high availability
- **Route 53** - For DNS management
- **CloudWatch** - For monitoring and logging

##  Quick Start Guide

### 1. Launch EC2 Instance

```bash
# Using AWS CLI
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-group-ids sg-xxxxxxxxx \
  --subnet-id subnet-xxxxxxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Tomcat-Server}]'
```

### 2. Connect to Instance

```bash
ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

### 3. Run Installation Script

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Java 17
sudo apt install -y openjdk-17-jdk wget tar

# Verify installation
java -version
```

##  Deployment Steps

### Step 1: Create Tomcat User

Create a dedicated system user for running Tomcat:

```bash
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
sudo mkdir -p /opt/tomcat
sudo chown -R tomcat:tomcat /opt/tomcat
```

### Step 2: Download and Install Tomcat

```bash
# Set Tomcat version (check https://tomcat.apache.org for latest)
TOMCAT_VERSION=10.1.16

# Download Tomcat
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Extract to /opt/tomcat
sudo tar xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat --strip-components=1

# Set permissions
sudo chown -R tomcat:tomcat /opt/tomcat
sudo chmod +x /opt/tomcat/bin/*.sh
```

### Step 3: Configure Java Home

```bash
# Find Java path
sudo update-java-alternatives -l

# Set JAVA_HOME (add to /etc/environment)
echo 'JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' | sudo tee -a /etc/environment
source /etc/environment
```

### Step 4: Create Systemd Service

Create `/etc/systemd/system/tomcat.service`:

```bash
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<'EOF'
[Unit]
Description=Apache Tomcat 10 Web Application Container
Documentation=https://tomcat.apache.org/tomcat-10.1-doc/index.html
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
ExecReload=/bin/kill -s HUP $MAINPID

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF
```

### Step 5: Start and Enable Tomcat

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable Tomcat to start on boot
sudo systemctl enable tomcat

# Start Tomcat service
sudo systemctl start tomcat

# Check status
sudo systemctl status tomcat
```

### Step 6: Verify Installation

```bash
# Check if Tomcat is listening on port 8080
sudo netstat -tulpn | grep 8080

# Test locally
curl -I http://localhost:8080

# Access from browser
# http://<EC2_PUBLIC_IP>:8080
```

##  Deploying WAR Files

### Method 1: Manual Deployment

```bash
# Copy WAR file to EC2
scp -i /path/to/key.pem target/myapp.war ubuntu@<EC2_PUBLIC_IP>:/tmp/

# SSH to instance and move WAR to webapps
ssh -i /path/to/key.pem ubuntu@<EC2_PUBLIC_IP>
sudo mv /tmp/myapp.war /opt/tomcat/webapps/
sudo chown tomcat:tomcat /opt/tomcat/webapps/myapp.war

# Tomcat will auto-deploy the WAR
# Monitor deployment logs
tail -f /opt/tomcat/logs/catalina.out
```

### Method 2: Using Tomcat Manager (Recommended)

1. **Configure Tomcat Users** - Edit `/opt/tomcat/conf/tomcat-users.xml`:

```xml
<tomcat-users>
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <user username="admin" password="secure_password" roles="manager-gui,manager-script"/>
</tomcat-users>
```

2. **Allow Remote Access** - Edit `/opt/tomcat/webapps/manager/META-INF/context.xml`:

```xml
<!-- Comment out the Valve to allow remote access -->
<!--
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
       allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->
```

3. **Restart Tomcat**:

```bash
sudo systemctl restart tomcat
```

4. **Access Manager**: `http://<EC2_PUBLIC_IP>:8080/manager/html`

### Method 3: Automated with Script

Create `deploy.sh`:

```bash
#!/bin/bash
WAR_FILE=$1
EC2_IP=$2
KEY_FILE=$3

if [ $# -ne 3 ]; then
    echo "Usage: $0 <war-file> <ec2-ip> <key-file>"
    exit 1
fi

echo "Deploying $WAR_FILE to $EC2_IP..."
scp -i $KEY_FILE $WAR_FILE ubuntu@$EC2_IP:/tmp/
ssh -i $KEY_FILE ubuntu@$EC2_IP "sudo mv /tmp/$(basename $WAR_FILE) /opt/tomcat/webapps/ && sudo chown tomcat:tomcat /opt/tomcat/webapps/$(basename $WAR_FILE)"
echo "Deployment complete!"
```

Usage:

```bash
chmod +x deploy.sh
./deploy.sh target/myapp.war 54.123.45.67 ~/.ssh/my-key.pem
```

##  Configuration

### JVM Memory Settings

Edit `/etc/systemd/system/tomcat.service`:

```ini
# For 2GB RAM instance
Environment='CATALINA_OPTS=-Xms512M -Xmx1536M -server -XX:+UseParallelGC'

# For 4GB RAM instance
Environment='CATALINA_OPTS=-Xms1024M -Xmx3072M -server -XX:+UseG1GC'
```

### Server Configuration

Edit `/opt/tomcat/conf/server.xml`:

```xml
<!-- Change default port (optional) -->
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443"
           maxThreads="200"
           minSpareThreads="10"
           compression="on"
           compressionMinSize="2048"
           noCompressionUserAgents="gozilla, traviata"
           compressableMimeType="text/html,text/xml,text/plain,text/css,text/javascript,application/javascript,application/json"/>
```

### Logging Configuration

Edit `/opt/tomcat/conf/logging.properties`:

```properties
# Console logging level
java.util.logging.ConsoleHandler.level = INFO

# File handler for application logs
handlers = 1catalina.org.apache.juli.AsyncFileHandler, 2localhost.org.apache.juli.AsyncFileHandler

# Catalina log
1catalina.org.apache.juli.AsyncFileHandler.level = INFO
1catalina.org.apache.juli.AsyncFileHandler.directory = ${catalina.base}/logs
1catalina.org.apache.juli.AsyncFileHandler.prefix = catalina.
```

##  Security Hardening

### 1. Remove Default Applications

```bash
# Remove manager and host-manager for production
sudo rm -rf /opt/tomcat/webapps/manager
sudo rm -rf /opt/tomcat/webapps/host-manager
sudo rm -rf /opt/tomcat/webapps/examples
sudo rm -rf /opt/tomcat/webapps/docs
```

### 2. Disable Directory Listing

Edit `/opt/tomcat/conf/web.xml`:

```xml
<servlet>
    <servlet-name>default</servlet-name>
    <servlet-class>org.apache.catalina.servlets.DefaultServlet</servlet-class>
    <init-param>
        <param-name>listings</param-name>
        <param-value>false</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>
```

### 3. Hide Tomcat Version

Edit `/opt/tomcat/conf/server.xml`:

```xml
<Connector port="8080" protocol="HTTP/1.1"
           server="Apache" />
```

### 4. Enable Security Manager

```bash
# Start Tomcat with security manager
sudo /opt/tomcat/bin/startup.sh -security
```

### 5. Configure SSL/TLS (Production)

Generate keystore:

```bash
sudo keytool -genkey -alias tomcat -keyalg RSA -keystore /opt/tomcat/conf/keystore.jks
```

Edit `server.xml`:

```xml
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true">
    <SSLHostConfig>
        <Certificate certificateKeystoreFile="conf/keystore.jks"
                     type="RSA" />
    </SSLHostConfig>
</Connector>
```

### 6. Implement Reverse Proxy

Install and configure NGINX:

```bash
sudo apt install -y nginx

sudo tee /etc/nginx/sites-available/tomcat > /dev/null <<'EOF'
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/tomcat /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

##  Testing & Verification

### Health Checks

```bash
# Check if Tomcat is running
sudo systemctl status tomcat

# Check process
ps aux | grep tomcat

# Check listening ports
sudo netstat -tulpn | grep java

# HTTP health check
curl -f http://localhost:8080 || echo "Tomcat is down"

# Application health check
curl -f http://localhost:8080/myapp/health || echo "App is down"
```

### Log Monitoring

```bash
# Real-time logs
tail -f /opt/tomcat/logs/catalina.out

# Last 100 lines
tail -n 100 /opt/tomcat/logs/catalina.out

# Search for errors
grep -i error /opt/tomcat/logs/catalina.out

# View localhost logs
tail -f /opt/tomcat/logs/localhost.$(date +%Y-%m-%d).log
```

### Performance Testing

```bash
# Install Apache Bench
sudo apt install -y apache2-utils

# Run basic load test
ab -n 1000 -c 10 http://localhost:8080/myapp/

# More intensive test
ab -n 10000 -c 100 -t 60 http://localhost:8080/myapp/
```

##  Troubleshooting

### Tomcat Won't Start

**Problem:** Service fails to start

```bash
# Check service status
sudo systemctl status tomcat

# View detailed logs
sudo journalctl -u tomcat -b --no-pager

# Check Java installation
java -version

# Verify JAVA_HOME
echo $JAVA_HOME

# Check permissions
ls -la /opt/tomcat
```

**Solution:**
- Ensure Java is installed and JAVA_HOME is set correctly
- Verify tomcat user has proper permissions
- Check for port conflicts: `sudo lsof -i :8080`

### Out of Memory Errors

**Problem:** `java.lang.OutOfMemoryError`

```bash
# Check current memory settings
grep CATALINA_OPTS /etc/systemd/system/tomcat.service

# Monitor memory usage
free -h
top -u tomcat
```

**Solution:**
- Increase heap size in CATALINA_OPTS
- Optimize application code
- Consider upgrading instance type

### Application Deployment Fails

**Problem:** WAR doesn't deploy or 404 errors

```bash
# Check WAR file exists
ls -la /opt/tomcat/webapps/

# Check deployment logs
tail -f /opt/tomcat/logs/catalina.out
tail -f /opt/tomcat/logs/localhost.*.log

# Verify WAR is valid
jar -tf /opt/tomcat/webapps/myapp.war | head
```

**Solution:**
- Ensure WAR file is valid (not corrupted)
- Check application logs for exceptions
- Verify Tomcat has write permissions to webapps directory

### Cannot Connect to Tomcat

**Problem:** Timeout or connection refused

```bash
# Check if Tomcat is running
sudo systemctl status tomcat

# Verify port is listening
sudo netstat -tulpn | grep 8080

# Check security group rules (AWS)
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Test local connection
curl -v http://localhost:8080
```

**Solution:**
- Verify EC2 security group allows inbound traffic on port 8080
- Check if firewall (ufw) is blocking: `sudo ufw status`
- Ensure Tomcat is bound to correct IP: check `server.xml`

### High CPU Usage

**Problem:** Tomcat consuming excessive CPU

```bash
# Monitor CPU usage
top -u tomcat

# Get thread dump
sudo -u tomcat /opt/tomcat/bin/catalina.sh threaddump

# Check GC activity
jstat -gcutil $(pgrep java) 1000
```

**Solution:**
- Review thread dumps for blocked threads
- Tune GC settings
- Profile application code for performance issues
- Scale horizontally with load balancer

##  Automation & CI/CD

### Terraform Deployment

Create `main.tf`:

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "tomcat" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 22.04
  instance_type = "t2.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.tomcat.id]

  user_data = file("bootstrap.sh")

  tags = {
    Name = "Tomcat-Server"
  }
}

resource "aws_security_group" "tomcat" {
  name        = "tomcat-sg"
  description = "Security group for Tomcat server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_ip" {
  value = aws_instance.tomcat.public_ip
}
```

### GitHub Actions CI/CD

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Tomcat

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Build with Maven
      run: mvn clean package
    
    - name: Deploy to EC2
      env:
        SSH_PRIVATE_KEY: ${{ secrets.EC2_SSH_KEY }}
        EC2_HOST: ${{ secrets.EC2_HOST }}
      run: |
        echo "$SSH_PRIVATE_KEY" > key.pem
        chmod 600 key.pem
        scp -i key.pem -o StrictHostKeyChecking=no target/*.war ubuntu@$EC2_HOST:/tmp/
        ssh -i key.pem ubuntu@$EC2_HOST "sudo mv /tmp/*.war /opt/tomcat/webapps/ && sudo systemctl restart tomcat"
        rm key.pem
```

### Bootstrap Script

Create `bootstrap.sh`:

```bash
#!/bin/bash
set -e

# Update system
apt update && apt upgrade -y

# Install Java
apt install -y openjdk-17-jdk wget tar

# Create tomcat user
useradd -m -U -d /opt/tomcat -s /bin/false tomcat

# Download and install Tomcat
TOMCAT_VERSION=10.1.16
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
tar xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat --strip-components=1
chown -R tomcat:tomcat /opt/tomcat
chmod +x /opt/tomcat/bin/*.sh

# Create systemd service
cat > /etc/systemd/system/tomcat.service <<'EOF'
[Unit]
Description=Apache Tomcat 10
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start Tomcat
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

echo "Tomcat installation complete!"
```

##  Best Practices

### 1. Resource Management
- Size your EC2 instance based on application requirements
- Monitor memory and CPU usage regularly
- Implement auto-scaling for production workloads

### 2. Security
- Never expose Tomcat directly to the internet in production
- Use a reverse proxy (NGINX/Apache) with TLS
- Implement proper authentication and authorization
- Keep Tomcat and Java updated with security patches
- Use AWS IAM roles instead of hardcoded credentials

### 3. High Availability
- Deploy multiple instances behind a load balancer
- Use Amazon RDS for database instead of local storage
- Implement health checks and auto-recovery
- Store session data in external cache (Redis/Memcached)

### 4. Monitoring & Logging
- Set up CloudWatch for metrics and logs
- Configure log rotation to prevent disk fill
- Implement application performance monitoring (APM)
- Set up alerts for critical metrics

### 5. Backup & Disaster Recovery
- Regular snapshots of EC2 volumes
- Backup Tomcat configurations
- Document deployment procedures
- Test recovery procedures regularly

### 6. Performance Optimization
- Tune JVM parameters for your workload
- Enable HTTP/2 for better performance
- Implement caching strategies
- Use CDN for static content
- Optimize database queries and connections

##  Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/awesome-feature`)
3. **Commit your changes** (`git commit -m 'Add awesome feature'`)
4. **Push to the branch** (`git push origin feature/awesome-feature`)
5. **Open a Pull Request**

### Contribution Guidelines

- Follow existing code style and documentation format
- Test your changes thoroughly
- Update documentation for any new features
- Include examples and use cases
- Add your changes to the changelog

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Acknowledgments

- [Apache Tomcat Project](https://tomcat.apache.org/)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)

##  Support & Contact

- **Issues:** [GitHub Issues](https://github.com/serginhoedouazin13-ui/-Apache-Tomcat-Deployment-on-AWS-EC2/issues)
- **Documentation:** [Official Tomcat Docs](https://tomcat.apache.org/tomcat-10.1-doc/)
- **AWS Support:** [AWS Support Center](https://console.aws.amazon.com/support/)
