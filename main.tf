terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
    token = var.github_token
    owner = var.github_owner
}

variable "github_token" {
  type = string
}

variable "github_owner" {
  type = string
}
variable "discord_webhook_url" {
  description = "Discord webhook URL"
  type        = string
  sensitive   = true
}

variable "deploy_key_pub" {
  description = "Public deploy SSH key"
  type        = string
  sensitive   = true
}

variable "github_pat" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

locals {
  repo_name = "github-terraform-task-Oleksandr-Naumchak"
  user_name = "softservedata"
  pr_tmplt_content = <<EOT
    ## Describe your changes

    ## Issue ticket number and link

    ## Checklist before requesting a review
    - [ ] I have performed a self-review of my code
    - [ ] If it is a core feauture, I have added thorought tests
    - [ ] Do we need to implement analytics?
    - [ ] Will this be part of a product update? If yes, please write one phrase about this update 
  EOT
}

resource "github_branch" "develop_branch" {
  repository = local.repo_name
  branch = "develop"
}

resource "github_branch_default" "github_branch_default" {
  repository = local.repo_name
  branch = github_branch.develop_branch.branch
}

resource "github_branch_protection" "main_protect_rules" {
  repository_id = local.repo_name
  pattern = "main"

  required_pull_request_reviews {
      require_code_owner_reviews = true
      require_approving_review_count = 0
  }
}

resource "github_branch_protection" "develop_protect_rules" {
  repository_id = local.repo_name
  pattern = "develop"

  required_pull_request_reviews {
       require_approving_review_count = 2
  }
}

resource "github_repository_collaborator" "a_repo_collaborator" {
  repository = local.repo_name
  username = local.user_name
  permission = "push"
}

resource "github_repository_file" "codeowners" {
  repository = local.repo_name
  branch = "main"
  file = ".github/CODEOWNERS"
  content = "* @softservedata"
  overwrite_on_create = true
}

resource "github_repository_file" "main_pr_template" {
  repository = local.repo_name
  branch = "main"
  file = ".github/pull_request_template.md"
  content = local.pr_tmplt_content
  overwrite_on_create = true
}

resource "github_repository_file" "develop_pr_template" {
  repository = local.repo_name
  branch = "develop"
  file = ".github/pull_request_template.md"
  content = local.pr_tmplt_content
  overwrite_on_create = true
  depends_on  = [github_branch.develop_branch]
}

resource "github_repository_webhook" "discord_webhook" {
  repository = local.repo_name
 configuration {
   url = var.discord_webhook_url
   content_type = "application/json"
 }
  events  = ["pull_request"]
}

resource "github_repository_deploy_key" "repository_deploy_key" {
  title = "DEPLOY_KEY"
  repository = local.repo_name
  key = var.deploy_key_pub
}

resource "github_actions_secret" "pat_secret" {
  repository = local.repo_name
  secret_name = "PAT"
  plaintext_value = var.github_pat
}

