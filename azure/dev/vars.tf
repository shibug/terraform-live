variable "env" {
  description = "name of the environment"
}

variable "project" {
  description = "Name of the project"
  default     = "Fions"
}

variable "location" {
  description = "Data center location"
  default     = "South Central US"
}

variable "useast2loc" {
  description = "US East 2 Data center location"
  default     = "East US 2"
}

variable "admin_username" {
  description = "Administrator username for any OS"
  type        = string
  sensitive   = true
}

variable "windows_admin_password" {
  description = "Windows administrator password"
  type        = string
  sensitive   = true
}

variable "keep_disk" {
  type        = bool
  description = "Prevents deleting storage disk when a VM is re-provisioned"
  default     = true
}
