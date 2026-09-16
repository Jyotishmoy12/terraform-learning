# Day 5: Terraform Provisioners Troubleshooting Notes

This project creates an EC2 instance and uses Terraform provisioners to copy a
Flask app to the instance, install dependencies, and start the app on port `80`.

## What This Project Does

1. Creates a VPC.
2. Creates a public subnet.
3. Creates an Internet Gateway.
4. Creates a route table for internet access.
5. Creates a security group with ports `22` and `80` open.
6. Creates an AWS key pair from a local public key.
7. Creates an EC2 instance.
8. Uses the `file` provisioner to copy `app.py` to the EC2 instance.
9. Uses the `remote-exec` provisioner to install Python packages and run Flask.

## Files

| File | Purpose |
| --- | --- |
| `main.tf` | Terraform configuration for AWS resources and provisioners. |
| `app.py` | Flask app that returns `Hello, Terraform!`. |
| `id_rsa_day5_pem` | Private SSH key used by Terraform and SSH. Do not push this to GitHub. |
| `id_rsa_day5_pem.pub` | Public SSH key uploaded to AWS as an EC2 key pair. |
| `provisoners.md` | Notes about Terraform provisioners. |

## Main Commands

### Initialize Terraform

```powershell
terraform init
```

Downloads the AWS provider plugin required by this project.

### Validate Terraform

```powershell
terraform validate
```

Checks whether the Terraform configuration is syntactically valid.

### Preview Resources

```powershell
terraform plan
```

Shows what Terraform will create, update, or destroy before applying changes.

### Create Resources

```powershell
terraform apply
```

Creates the AWS resources and runs the provisioners.

### Recreate Only the EC2 Instance

```powershell
terraform apply -replace="aws_instance.server"
```

Forces Terraform to destroy and recreate only the EC2 instance. This is useful
when provisioners need to run again.

### Destroy Resources

```powershell
terraform destroy
```

Deletes all resources created by this Terraform project.

## Bugs Encountered and Fixes

### 1. SSH Key Files Were Missing

Terraform expected SSH key files for the EC2 key pair and SSH connection.

Required files:

```text
DAY-5/id_rsa_day5_pem
DAY-5/id_rsa_day5_pem.pub
```

Fix:

```powershell
ssh-keygen -m PEM -t rsa -b 4096 -f .\id_rsa_day5_pem
```

Press `Enter` when asked for a passphrase so the key has no passphrase.

Why this matters:

Terraform provisioners need to SSH into the EC2 instance. The public key is
uploaded to AWS, and the private key is used locally to connect.

### 2. Private Key Was Passphrase Protected

Error:

```text
Failed to parse ssh private key: ssh: this private key is passphrase protected
```

Cause:

Terraform's SSH provisioner cannot use a private key that asks for a passphrase.

Fix:

Generate a PEM key without a passphrase:

```powershell
ssh-keygen -m PEM -t rsa -b 4096 -f .\id_rsa_day5_pem
```

### 3. Private Key Permission Was Too Open

Error:

```text
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions are too open.
Permission denied (publickey).
```

Cause:

SSH refuses to use private keys that are readable by too many users.

Fix:

Generate the key from your own PowerShell user inside the `DAY-5` folder. Avoid
creating private keys from another user or sandbox account.

If needed, tighten permissions:

```powershell
icacls .\id_rsa_day5_pem /inheritance:r
icacls .\id_rsa_day5_pem /grant:r "$env:USERNAME:R"
```

### 4. Ubuntu Blocked Global `pip install`

Error:

```text
externally-managed-environment
```

Cause:

Modern Ubuntu follows PEP 668 and blocks installing Python packages globally
with `pip`.

Fix:

Use a Python virtual environment:

```bash
sudo apt update -y
sudo apt-get install -y python3-pip python3-venv
cd /home/ubuntu
python3 -m venv venv
./venv/bin/pip install flask
```

The Terraform `remote-exec` provisioner now uses this approach.

### 5. Browser Showed `ERR_CONNECTION_REFUSED`

Symptom:

```text
This site can't be reached
ERR_CONNECTION_REFUSED
```

Cause:

The EC2 instance was reachable, but nothing was listening on port `80`.

How we checked:

```bash
ps aux | grep python
sudo ss -tulnp | grep :80
cat /home/ubuntu/app.log
```

Fix:

Start Flask with `nohup` so it keeps running after the SSH session closes:

```bash
sudo nohup /home/ubuntu/venv/bin/python /home/ubuntu/app.py > /home/ubuntu/app.log 2>&1 &
```

Then verify:

```bash
cat /home/ubuntu/app.log
sudo ss -tulnp | grep :80
ps aux | grep app.py
```

Successful output should show Flask running on `0.0.0.0:80`.

## SSH Into the Instance

Use the EC2 public IP from the AWS Console:

```powershell
ssh -i .\id_rsa_day5_pem ubuntu@PUBLIC_IP
```

Example:

```powershell
ssh -i .\id_rsa_day5_pem ubuntu@44.199.217.81
```

If prompted:

```text
Are you sure you want to continue connecting?
```

Type:

```text
yes
```

## Useful Debug Commands on EC2

Check if the app file was copied:

```bash
ls -l /home/ubuntu/app.py
```

Check Flask logs:

```bash
cat /home/ubuntu/app.log
```

Check if Python app is running:

```bash
ps aux | grep app.py
```

Check if port `80` is listening:

```bash
sudo ss -tulnp | grep :80
```

Check whether Flask is installed:

```bash
/home/ubuntu/venv/bin/pip show flask
```

Manually start the app:

```bash
sudo nohup /home/ubuntu/venv/bin/python /home/ubuntu/app.py > /home/ubuntu/app.log 2>&1 &
```

## Final Browser Test

After the app is running, open:

```text
http://PUBLIC_IP
```

Expected response:

```text
Hello, Terraform!
```

## Important Notes

- Do not commit private keys to GitHub.
- Do not commit Terraform state files.
- This project opens SSH port `22` to the world, which is okay for learning but
  not recommended for production.
- Provisioners are useful for learning, but in real projects, `user_data`,
  custom AMIs, Ansible, or container-based deployments are usually cleaner.
