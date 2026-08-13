variable "nip_io_host" {
  description = <<-EOT
    The nip.io hostname, e.g. "1-2-3-4.nip.io" — built from the ALB's IP.
    You won't know this until AFTER the ALB exists (chicken-and-egg), so this
    is a two-step process:
      1. Apply everything else first with ingress on HTTP only, get the ALB's
         address, resolve it to an IP.
      2. Come back, set this variable to "<that-ip-with-dashes>.nip.io", and
         re-apply — this module (and the ingress annotation) picks it up then.
    Leave as null for step 1.
  EOT
  type        = string
  default     = null
}
