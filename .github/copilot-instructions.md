# SAP Deployment Automation Framework (SDAF) - AI Coding Agent Instructions

This is the SAP deployment automation framework on Azure - an open-source orchestration tool using Terraform for infrastructure deployment and Ansible for system/application configuration.

## Architecture Overview

**Multi-Tier Deployment Model**: The framework uses a structured hierarchy:
- **Control Plane**: Deployer (bootstrap VM) + Library (storage for state files and media)
- **Workload Zone**: Network infrastructure shared by multiple SAP systems
- **SAP System**: Individual SAP installations (HANA, NetWeaver, etc.)

**Repository Structure**:
- `/deploy/terraform/bootstrap/` - Control plane infrastructure (deployer, library), uses local state
- `/deploy/terraform/run/` - Runtime deployments (deployer, library, landscape, system), uses remote state
- `/deploy/terraform/terraform-units/modules/` - Reusable Terraform modules
- `/deploy/ansible/` - SAP installation playbooks and roles
- `/deploy/scripts/` - Installation and deployment orchestration scripts
- `/deploy/pipelines/` - Azure DevOps YAML pipelines
- `/boilerplate/WORKSPACES/` - Template folder structure for customer configs

## Key Concepts and Conventions

**Naming Convention**: Resources follow `{ENV}-{REGION_CODE}-{NETWORK_NAME}-{TYPE}` pattern:
- Example: `DEV-WEEU-SAP01-INFRASTRUCTURE` (tfvars files)
- Example: `MGMT-WEEU-DEP01-INFRASTRUCTURE` (deployer configs)

**WORKSPACES Folder Structure** (customer configuration repository):
```
WORKSPACES/
├── DEPLOYER/{ENV}-{REGION}-{NAME}-INFRASTRUCTURE/
├── LIBRARY/{ENV}-{REGION}-SAP_LIBRARY/
├── LANDSCAPE/{ENV}-{REGION}-{NETWORK}-INFRASTRUCTURE/
└── SYSTEM/{ENV}-{REGION}-{NETWORK}-{SID}/
```

**State Management**: Uses remote Terraform state in Azure Storage with state file sharing between deployment layers.

**Environment Variables**: Key exports for all operations:
- `SAP_AUTOMATION_REPO_PATH` - Path to this sap-automation repository
- `CONFIG_REPO_PATH` - Path to customer configuration repository
- `ARM_SUBSCRIPTION_ID` - Target Azure subscription

## Critical Workflows

**Initial Setup** (from `/deploy/scripts/`):
1. `configure_deployer.sh` - Sets up deployer VM with Terraform, Ansible, Azure CLI
2. `install_deployer.sh` - Bootstraps deployer infrastructure
3. `install_library.sh` - Creates library with state storage
4. `installer.sh` - Main orchestrator for all deployment types

**Version Management**: 
- Terraform version controlled via `TF_VERSION` env var (default in `configure_deployer.sh`)
- Update process: Set `TF_VERSION=1.12.2` environment variable or modify default in script

**Pipeline Deployment Order**:
1. `01-deploy-control-plane.yaml` - Deployer + Library
2. `02-sap-workload-zone.yaml` - Network infrastructure  
3. `03-sap-system-deployment.yaml` - SAP system infrastructure
4. `04-sap-software-download.yaml` - SAP media download
5. `05-DB-and-SAP-installation.yaml` - Ansible-based installation

## Integration Points

**Azure DevOps Integration**: Pipelines expect variable groups with deployment state information. The framework stores state metadata in `.sap_deployment_automation/` folder.

**Terraform State Sharing**: Uses `tfstate_resource_id`, `deployer_tfstate_key`, `landscape_tfstate_key` parameters to link deployments.

**Public API Integration**: `/deploy/ansible/action_plugins/public_api.py` provides SAP installation parameter transformation for various deployment scenarios (HA, clustering, standalone).

**WebApp Interface**: The `/Webapp/` provides a UI for configuration management with models in `Models/LandscapeModel.cs` and `Controllers/LandscapeController.cs`.

## Development Patterns

**Script Organization**: Main orchestration in `/deploy/scripts/`, with pipeline-specific scripts in `/deploy/scripts/pipeline_scripts/`.

**Error Handling**: Scripts use consistent exit codes and validation patterns. Check `deploy_utils.sh` for common functions.

**Multi-Distribution Support**: Installation scripts detect and handle Ubuntu, SLES, RHEL with distribution-specific package management.

**Testing**: Use nightly.yml in `/boilerplate/custom/` for validation deployments that auto-cleanup.

When working with this codebase, always consider the multi-tier dependency chain and ensure proper state file management between deployment layers.
