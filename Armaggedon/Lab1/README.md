# my-armageddon-project-1

### Group Leader: Omar Fleming

### Team Leader: Larry Harris

### First meeting 01-04-25

### Time: 2pm - 4:30 est.

---

Members present:

- Larry Harris
- Kelly D Moore
- Dennis Shaw
- Logan T
- Tre Bradshaw
- Bryce Williams
- Jasper Shivers (Jdollas)
- Ted Clayton
- Torray
- Zeek-Miller
- Jay Mallard

---

Minutes:

- created and instructed everyone to create a Terraform repo in Github to share notes and test the Terraform builds
- went through Lab 1a discussed, seperated Larry's main.tf into portions. We tested trouble shot, spun up the code. Dennis will upload to github and after Larry looks through it, will make it available for everyone to download
- everyone inspect, test and come back with any feedback, suggestions and or comments
- Here is the 1st draft diagram. We want to hear if you guys have any feedback or suggestions for this as well.

![first draft diagram](./screen-captures/lab1a-diagram.png)

---

### Project Infrastructure

VPC name == bos_vpc01  
Region = US East 1  
Availability Zone

- us-east-1a
- us-east-1b
- CIDR == 10.26.0.0/16

| Subnets |                |                |
| ------- | -------------- | -------------- |
| Public  | 10.26.101.0/24 | 10.26.102.0/24 |
| Private | 10.26.101.0/24 | 10.26.102.0/24 |

### .tf file changes

- Security Groups for RDS & EC2

  - RDS (ingress)
  - mySQL from EC2

- EC2 (ingress)
  - student adds inbound rules (HTTP 80, SSH 22 from their IP)

\*\*\* reminder change SSH rule!!!

\*\*\*After your done "Terraform destroy", run "aws secretsmanager delete-secret --secret-id bos/rds/mysql --force-delete-without-recovery" to destroy the secret!

Connect the ec2 through the Session mananger (Privite instances, RDs, DB)

6.1 Verify EC2 Instance aws ec2 describe-instances
--filters "Name=tag:Name,Values=lab-ec2-app"
--query "Reservations[].Instances[].InstanceId" Expected: Instance ID returned Instance state = running

6.2 Verify IAM Role Attached to EC2 aws ec2 describe-instances
--instance-ids <INSTANCE_ID>
--query "Reservations[].Instances[].IamInstanceProfile.Arn"

Expected: ARN of an IAM instance profile (not null)

6.3 Verify RDS Instance State aws rds describe-db-instances
--db-instance-identifier lab-mysql
--query "DBInstances[].DBInstanceStatus"

Expected Available

6.4 Verify RDS Endpoint (Connectivity Target) aws rds describe-db-instances
--db-instance-identifier lab-mysql
--query "DBInstances[].Endpoint"

Expected: Endpoint address Port 3306

6.5 Verify Security Group Rules (Critical) RDS Security Group Inbound Rules aws ec2 describe-security-groups
--group-names sg-rds-lab
--query "SecurityGroups[].IpPermissions"

Expected: TCP port 3306 Source referencing EC2 security group ID, not CIDR

6.6 Verify Secrets Manager Access (From EC2) SSH into EC2 and run: aws secretsmanager get-secret-value
--secret-id lab/rds/mysql

Expected: JSON containing: username password host port

If this fails, IAM is misconfigured.

6.7 Verify Database Connectivity (From EC2) Install MySQL client (temporary validation): sudo dnf install -y mysql

Connect: mysql -h <RDS_ENDPOINT> -u admin -p

Expected: Successful login No timeout or connection refused errors

6.8 Verify Data Path End-to-End From browser: http://<EC2_PUBLIC_IP>/init http://<EC2_PUBLIC_IP>/add?note=cloud_labs_are_real http://<EC2_PUBLIC_IP>/list

Expected: Notes persist across refresh Data survives application restart
