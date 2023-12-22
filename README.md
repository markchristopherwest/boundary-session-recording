# boundary-session-recording

## Getting Started

This repo is designed as 2 modules which can be broken apart into 2 workspaces (for TFC and/or TFCB).  The modules are separate because of the boundary connection string requirements.  First, apply the repo including the before child module.  Next, uncomment the after child module & complete the setup.

```bash
# HashiCorp Doormat
function install_hashicorp_doormat() {
  if ! command -v doormat &>/dev/null; then
    log "INFO" ${FUNCNAME[0]}  "${USER} apparently DOES NOT have Doormat installed..."
      brew tap hashicorp/security https://github.com/hashicorp/homebrew-security
      brew install hashicorp/security/doormat-cli
      brew update 
      brew upgrade doormat-cli

  else
    log "INFO" ${FUNCNAME[0]}  "${USER} already has Doormat installed...good job ${USER}"
  fi
}

# you need creds from doormat like
doormat login -f
doormat aws list > /tmp/doormat-aws-list.txt
DOORMAT_ROLE=$(cat /tmp/doormat-aws-list.txt | grep boundary_team_acctest_dev    | tr -d '\011\012\013\014\015\040')
eval $(doormat aws export --role $DOORMAT_ROLE)


```


```bash

# https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/guides/auth#client-credentials
export HCP_CLIENT_ID=hcp_sp_client_id
export HCP_CLIENT_SECRET=hcp_sp_secret_id

# Initialized TF
terraform init

# Apply TF
terraform apply -auto-approve

# On a successful run, open main.tf and uncomment the "after" module thru EOF
open main.tf

# Run init Again (for the after module)
terraform init

# Run Apply Again
terraform apply -auto-approve

# Confirm Outside Connection
cat terraform.tfstate | jq -r '.outputs.instance_ssh_private_key.value' > ~/.ssh/demo

TARGET_IP_WORKER_DOWNSTREAM=$(cat terraform.tfstate | jq -r '.outputs.your_worker_downstream.value')

TARGET_IP_WORKER_UPSTREAM=$(cat terraform.tfstate | jq -r '.outputs.your_worker_upstream.value')

# ssh -o StrictHostKeyChecking=no ubuntu@$TARGET_IP_WORKER_UPSTREAM -i ~/.ssh/demo -f  'cat /var/log/user-data.log |grep Request:'

# ssh -o StrictHostKeyChecking=no ubuntu@$TARGET_IP_WORKER_DOWNSTREAM -i ~/.ssh/demo -f  'cat /var/log/user-data.log |grep Request:'

# Connect to Boundary Controller
export BOUNDARY_ADDR=$(cat terraform.tfstate | jq -r '.outputs.your_hcp_boundary_instance.value')

boundary authenticate

boundary scopes list -format=json | jq

boundary targets list -scope-id=TARGET_SCOPE -format=json | jq

TARGET_ID=selected_target_from_boundary_desktop_or_cli

boundary connect ssh -target-id=$TARGET_ID 

TARGET_PORT=selected_port_from_boundary_desktop_or_cli

open rdp://full%20address=s=127.0.0.1:$TARGET_PORT

terraform state rm module.after.boundary_storage_bucket.aws_example

terraform destroy -auto-approve

```
