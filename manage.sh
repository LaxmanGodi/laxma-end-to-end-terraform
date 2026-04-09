#!/bin/bash

# Configuration
BACKEND_DIR="./backend-setup"
APP_DIR="./app-infra"
REGION="us-west-2"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

# --- NEW: Cleanup Function ---
cleanup_temp_files() {
    echo -e "${YELLOW}🧹 Cleaning up temporary Application files...${NC}"
    
    # ONLY clean the App directory (Stage 2)
    # We leave backend-setup ALONE because it holds the local state for your S3 bucket
    rm -rf $APP_DIR/.terraform $APP_DIR/.terraform.lock.hcl
    rm -f $APP_DIR/backend.conf
    rm -f $APP_DIR/app.tfplan
    
    echo -e "${GREEN}✨ App Workspace cleaned. Backend state preserved.${NC}"
}

if [ "$1" == "deploy" ]; then
    # Run cleanup before starting
    cleanup_temp_files

    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}🚀 STAGE 1: INFRASTRUCTURE MANAGER (S3 BACKEND)${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    cd $BACKEND_DIR
    terraform init -input=false
    
    echo -e "${YELLOW}📋 Generating Backend Plan...${NC}"
    terraform plan -out=backend.tfplan
    
    read -p "Do you want to apply this Backend plan? (y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        terraform apply "backend.tfplan"
        rm backend.tfplan
    else
        echo -e "${RED}❌ Deployment aborted by user.${NC}"
        exit 1
    fi

    BUCKET_NAME=$(terraform output -raw s3_bucket_name)

    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}🚀 STAGE 2: APPLICATION INFRASTRUCTURE (EC2)${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${GREEN}Creating/Updating backend.conf for $BUCKET_NAME...${NC}"
    cat <<EOF > ../$APP_DIR/backend.conf
bucket         = "$BUCKET_NAME"
key            = "projects/ec2-demo/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "terraform-lock"
encrypt        = true
EOF

    cd ../$APP_DIR
    terraform init -backend-config=backend.conf -reconfigure
    
    echo -e "${YELLOW}📋 Generating App Plan...${NC}"
    terraform plan -out=app.tfplan
    
    echo -e "${GREEN}Plan summary:${NC}"
    terraform show -no-color app.tfplan | grep -E "plan:|will be created|will be destroyed"
    
    read -p "Apply this specific plan? (y/n): " confirm_app
    if [[ $confirm_app == [yY] ]]; then
        terraform apply "app.tfplan"
        rm app.tfplan
        echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
    else
        echo -e "${RED}❌ App Deployment aborted.${NC}"
        exit 1
    fi

elif [ "$1" == "destroy" ]; then
    # ... (Rest of destroy logic remains same)
    cd $APP_DIR
    terraform plan -destroy -out=destroy_app.tfplan
    read -p "Are you SURE you want to DESTROY the EC2 instance? (y/n): " kill_app
    if [[ $kill_app == [yY] ]]; then
        terraform apply "destroy_app.tfplan"
        rm destroy_app.tfplan
    fi

    echo -e "${RED}=================================================${NC}"
    echo -e "${RED}🔥 STAGE 2: REMOVING REMOTE BACKEND${NC}"
    echo -e "${RED}=================================================${NC}"
    
    cd ../$BACKEND_DIR
    terraform plan -destroy -out=destroy_backend.tfplan
    read -p "DANGER: Are you SURE you want to DESTROY the S3 State Bucket? (y/n): " kill_back
    if [[ $kill_back == [yY] ]]; then
        terraform apply "destroy_backend.tfplan"
        rm destroy_backend.tfplan
        echo -e "${GREEN}✅ CLEANUP COMPLETE - AWS IS CLEAR.${NC}"
    fi
else
    echo -e "${YELLOW}Usage: ./manage.sh [deploy|destroy]${NC}"
fi
