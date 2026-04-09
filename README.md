# laxma-end-to-end-terraform


his project demonstrates a professional Infrastructure as Code (IaC) workflow using Terraform. It features a remote S3 backend with DynamoDB state locking and a shell-script-based automation layer to manage the deployment lifecycle end-to-end.

📂 Project Structure
Plaintext
.
├── manage.sh                # The "Pilot" script (Automates deploy/destroy)
├── backend-setup/           # Stage 1: Infrastructure Manager
│   ├── backend_setup.tf     # Creates S3 Bucket & DynamoDB Table
│   └── outputs.tf           # Exports Bucket ID for the automation script
└── app-infra/               # Stage 2: Application Infrastructure
    ├── main.tf              # Creates EC2 Instance (uses dynamic AMI)
    └── backend.conf         # (Auto-generated) Connects App to the S3 Backend
🚀 Key Features
Remote State Storage: Moves the Terraform "brain" from local storage to a secure AWS S3 bucket.

State Locking: Uses DynamoDB to prevent concurrent executions from corrupting the state.

Zero-Manual Config: The manage.sh script dynamically captures the S3 bucket name and configures the application backend.

Safety Gated: Uses terraform plan -out to ensure the exact reviewed changes are applied.

Cost Optimized: Designed for AWS Free Tier; includes a "One-Command" destruction process to ensure $0 charges.

🛠 Usage Instructions
1. Prerequisites
Ubuntu environment with Terraform v1.14.0+ installed.

AWS CLI configured with valid credentials (aws configure).

2. Deployment
To build the backend and the EC2 instance in one go:

Bash
chmod +x manage.sh
./manage.sh deploy
Step A: The script builds the S3/DynamoDB backend.

Step B: It asks for approval.

Step C: It generates a backend.conf and deploys the EC2 instance.

3. Destruction (Cleanup)
To wipe all resources and avoid AWS billing:

Bash
./manage.sh destroy
Order of Operations: The script destroys the EC2 instance first, then safely removes the S3 bucket and DynamoDB table.

📝 Technical Deep Dive
The "Partial Configuration" Pattern
The main.tf file uses an empty backend "s3" {} block. This allows the same code to be used across multiple environments (Dev, QA, Prod) by simply injecting different .conf files during the init phase.

Automation Logic
The manage.sh script utilizes:

terraform output -raw: To bridge data between the backend and the app.

cat <<EOF: To dynamically generate configuration files.

terraform plan -out: To guarantee execution integrity.


🛑 Important Note on prevent_destroy
In backend-setup/backend_setup.tf, the prevent_destroy flag is set to false for testing purposes. In a production environment, this should be toggled to true to prevent accidental loss of the state bucket.
