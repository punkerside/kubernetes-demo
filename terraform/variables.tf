variable "name" {
  description = "Nombre asignado a todos los recursos creados por esta plantilla"
  type        = string
  default     = null
}

variable "eks_version" {
  type = string
}