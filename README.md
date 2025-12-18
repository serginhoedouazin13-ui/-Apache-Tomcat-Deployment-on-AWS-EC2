# Apache Tomcat 10 Deployment on AWS EC2

This project demonstrates how to deploy and run an Apache Tomcat 10 application server on an AWS EC2 Linux instance. The goal is to host a Java web application (WAR) in the cloud and make it accessible over the internet.

---

## Table of contents
- [Overview](#overview)
- [Contents](#contents)
- [Prerequisites](#prerequisites)
- [AWS resources required](#aws-resources-required)
- [Quick start — manual steps (Ubuntu 22.04 example)](#quick-start)
- [Deploying a WAR to Tomcat](#deploying-a-war-to-tomcat)
- [Testing](#testing)
- [Security and hardening notes](#security-and-hardening-notes)
- [Automation suggestions](#automation-suggestions)
- [Troubleshooting](#troubleshooting)
- [License & Contributing](#license--contributing)

## Overview
This repository shows the standard steps to:
1. Launch an EC2 Linux instance.
2. Install Java (OpenJDK 11/17).
3. Download and configure Apache Tomcat 10.
4. Deploy a Java web application (WAR) to Tomcat and open the required ports.

The README provides commands and configurations you can follow manually. For repeatable deployments, consider using Infrastructure as Code (Terraform/CloudFormation) or automation scripts.

## Contents
- README.md (this file)
- (Optionally) scripts/ — user-friendly scripts to provision and configure the instance
- (Optionally) example-app/ — sample WAR or build artifacts to deploy

## Prerequisites
- An AWS account with permissions to create EC2 instances and security groups.
- AWS CLI configured locally (optional for automation).
- A key pair for SSH access to the instance.
- Basic familiarity with SSH, Linux package managers, and security groups.

Recommended:
- Ubuntu 22.04 LTS (AMI)
- OpenJDK 11 or 17 (Tomcat 10 works with Java 11+)

## AWS resources required
- EC2 instance (t2.micro or larger for testing)
- Security group allowing:
  - SSH (port 22) from your IP
  - HTTP (port 80) or custom port 8080 from 0.0.0.0/0 (for testing only)
  - HTTPS (port 443) if you plan to enable TLS
- (Optional) Elastic IP to keep a stable public IP

Important: For production, restrict inbound rules and use proper TLS/HTTPS setup, not open 8080 to the world.

## Quick start — manual steps (Ubuntu 22.04 example)
1. Launch EC2
   - Create EC2 instance with Ubuntu 22.04, add key pair, set security group (ports 22 and 8080/80).

2. SSH to the instance
```
ssh -i path/to/key.pem ubuntu@EC2_PUBLIC_IP
```

3. Update packages and install OpenJDK (example: Java 17)
```
sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk wget tar
java -version
```

4. Create a dedicated tomcat user and directories
```
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
sudo mkdir -p /opt/tomcat
sudo chown -R tomcat: /opt/tomcat
```

5. Download and install Tomcat 10
```
TOMCAT_VER=10.1.16   # replace with current Tomcat 10.x version
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-10/v$TOMCAT_VER/bin/apache-tomcat-$TOMCAT_VER.tar.gz
sudo tar xzf apache-tomcat-$TOMCAT_VER.tar.gz -C /opt/tomcat --strip-components=1
sudo chown -R tomcat: /opt/tomcat
sudo chmod +x /opt/tomcat/bin/*.sh
```

6. Create a systemd service for Tomcat
Create `/etc/systemd/system/tomcat.service` with appropriate contents (example below) and then enable/start.

Example unit (run as root or with sudo):
```
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<'EOF'
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx512M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat
sudo systemctl status tomcat
```

7. Verify Tomcat is running
- By default Tomcat listens on port 8080. If your security group allows it, open: http://EC2_PUBLIC_IP:8080
- Or use curl from the instance:
```
curl -I http://localhost:8080
```

## Deploying a WAR to Tomcat
- Copy WAR to Tomcat's webapps folder:
```
scp -i path/to/key.pem target/your-app.war ubuntu@EC2_PUBLIC_IP:/tmp/
ssh -i path/to/key.pem ubuntu@EC2_PUBLIC_IP
sudo mv /tmp/your-app.war /opt/tomcat/webapps/
sudo chown tomcat: /opt/tomcat/webapps/your-app.war
```
- Tomcat auto-deploys WARs placed in `webapps/`. Monitor logs:
```
tail -f /opt/tomcat/logs/catalina.out
```
- Access at: http://EC2_PUBLIC_IP:8080/your-app/

## Testing
- Basic: curl the root or app URL:
```
curl http://EC2_PUBLIC_IP:8080/
curl http://EC2_PUBLIC_IP:8080/your-app/
```
- Check logs for errors: `/opt/tomcat/logs/catalina.out` and `localhost.*.log`

## Security and hardening notes
- Do not expose Tomcat manager/host-manager to the public internet. Remove or secure those apps.
- Create proper Tomcat users and roles in `tomcat-users.xml` if you need management access; never commit credentials.
- Use a reverse proxy (NGINX) in front of Tomcat for TLS termination and additional filtering.
- Use AWS best practices: restrict security group inbound IPs, disable password-based SSH, use IAM roles for EC2 if accessing other AWS resources.

## Automation suggestions
- Add scripts in `scripts/`:
  - `bootstrap.sh` — installs Java and Tomcat and configures systemd
  - `deploy.sh` — uploads WAR and restarts Tomcat
- Consider Terraform or CloudFormation for provisioning EC2, security groups and Elastic IP.
- Add a GitHub Actions workflow to build the Java artifact and (optionally) publish to an S3 bucket or trigger deployment.

## Troubleshooting
- Tomcat fails to start:
  - Check `sudo journalctl -u tomcat -b` and `/opt/tomcat/logs/catalina.out`
  - Verify `JAVA_HOME` path and that Java is installed
- 403/404 when accessing app:
  - Confirm WAR deployed successfully and directory created under `webapps/`
  - Check application logs for exceptions (in Tomcat logs or app-specific logs)

## Example commands (summary)
- Install Java:
```
sudo apt update && sudo apt install -y openjdk-17-jdk
```
- Start/stop Tomcat:
```
sudo systemctl start tomcat
sudo systemctl stop tomcat
sudo systemctl status tomcat
```
- View logs:
```
tail -n 200 /opt/tomcat/logs/catalina.out
```

## License & Contributing
- Add a LICENSE file for your preferred license (MIT / Apache-2.0 recommended).
- Add CONTRIBUTING.md and issue/PR templates if you want community contributions.
- Example short CONTRIBUTING section:
  - Fork the repo
  - Create a branch
  - Open a PR with changes and a descriptive title
  - Include tests or verification steps for automation scripts

---

If you'd like, I can:
- Commit this README.md to your repository as a PR or direct commit,
- Add a suggested LICENSE and CONTRIBUTING.md,
- Or create automation scripts and a GitHub Actions workflow to build/test and (optionally) deploy artifacts.
