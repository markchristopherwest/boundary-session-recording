#!/bin/bash
sudo touch /var/log/user-data.log
sudo chown root:adm /var/log/user-data.log
# exec > >(tee /var/log/boundary_worker_setup.log|logger -t boundary_worker_setup -s 2>/dev/console) 2>&1
#!/bin/bash -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'

sudo useradd -m boundary

sudo mkdir -p ${boundary_path_auth}
sudo mkdir -p ${boundary_path_captrure}

sudo chown boundary:boundary ${boundary_path_auth}
sudo chown boundary:boundary ${boundary_path_captrure}

sudo chmod 777 -Rf ${boundary_path_auth}
sudo chmod 777 -Rf ${boundary_path_captrure}

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - ;\
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" ;\
sudo apt-get update && sudo apt-get install boundary-enterprise -y

sudo apt-get update -y
sudo apt-get install -y awscli s3fs 

# Get the Meta Info
id_hostname="$(curl -s http://169.254.169.254/latest/meta-data/hostname)"
id_public_hostname="$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)"
id_instance="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
ip_inside="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
ip_outside="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
stanza_product=$(cat <<YAML
disable_mlock = true

listener "tcp" {
  address = "${boundary_worker_address}:${boundary_worker_port}"
  purpose = "${boundary_worker_purpose}"
}

worker {
  auth_storage_path = "${boundary_path_auth}"
  controller_generated_activation_token = "${boundary_activation_token}"
  public_addr = "$id_public_hostname"
  recording_storage_path = "${boundary_path_captrure}"

  tags {
    type = ["$id_instance", "downstream", "egress"]
  }

  initial_upstreams = ["${boundary_worker_upstream_host}:${boundary_worker_upstream_port}"]
  
}

YAML
)

echo "Generating downstream.hcl for Worker..."
echo "$stanza_product" > "/home/boundary/downstream-worker.hcl"

config_service=$(cat <<EOF
[Unit]
Description=Boundary Worker (Egress Downstream)

[Service]
ExecStart=/bin/boundary server -config /home/boundary/downstream-worker.hcl
User=boundary
Group=boundary
LimitMEMLOCK=infinity

CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK

[Install]
WantedBy=multi-user.target

EOF

)

echo "$config_service" | sudo tee /etc/systemd/system/boundary.service

sudo systemctl daemon-reload

# /bin/boundary server -config=/home/boundary/downstream-worker.hcl

sudo systemctl start boundary.service
sudo systemctl status boundary.service
sudo journalctl -u boundary

echo END
