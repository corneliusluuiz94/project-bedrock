# Self-signed cert, imported into ACM (ACM's "import" feature, distinct from its
# "request/DNS-validate" feature — the latter requires owning the domain, which
# isn't possible for nip.io). This genuinely terminates TLS at the ALB using a
# cert ACM manages; browsers will just flag it as untrusted since it's self-signed,
# same as any self-signed cert would be.

resource "tls_private_key" "alb_cert" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "alb_cert" {
  private_key_pem = tls_private_key.alb_cert.private_key_pem

  subject {
    common_name  = coalesce(var.nip_io_host, "project-bedrock.local")
    organization = "InnovateMart Project Bedrock (self-signed, assessment use)"
  }

  validity_period_hours = 8760 # 1 year — plenty for an assessment lifecycle

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "alb_cert" {
  private_key      = tls_private_key.alb_cert.private_key_pem
  certificate_body = tls_self_signed_cert.alb_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.alb_cert.arn
}
