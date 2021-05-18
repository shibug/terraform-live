variable "env" {
  description = "name of the environment"
}

variable "project" {
  description = "Name of the project"
  default     = "Fions"
}

variable "cidrblock" {
  description = "CIDR block for this environment"
  default     = "10.0.0.0/16"
}

variable "location" {
  description = "Data center location"
  default     = "South Central US"
}
