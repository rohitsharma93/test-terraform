# ==============================================================================
# ACM Certificate (Self-Signed Demo Certificate for ALB HTTPS)
# ==============================================================================

resource "tls_private_key" "demo" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "demo" {
  private_key_pem = tls_private_key.demo.private_key_pem

  subject {
    common_name  = var.demo_domain_name
    organization = "Demo Organization"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "demo" {
  private_key      = tls_private_key.demo.private_key_pem
  certificate_body = tls_self_signed_cert.demo.cert_pem

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-acm-cert"
  })
}

# ------------------------------------------------------------------------------
# Production Note: For real public domains, use DNS validation as shown below:
# ------------------------------------------------------------------------------
# resource "aws_acm_certificate" "production" {
#   domain_name       = "example.com"
#   validation_method = "DNS"
#   tags              = local.common_tags
#   lifecycle {
#     create_before_destroy = true
#   }
# }
