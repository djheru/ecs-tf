data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.app_name}.${var.environment_name}.${var.domain_name}"
  validation_method = "DNS"
  tags = {
    Name = "${var.app_name}.${var.environment_name}.${var.domain_name}"
  }
}
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation_record.fqdn]
}

resource "aws_route53_record" "cert_validation_record" {
  name    = tolist(aws_acm_certificate.cert.domain_validation_options).0.resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options).0.resource_record_type
  records = [tolist(aws_acm_certificate.cert.domain_validation_options).0.resource_record_value]

  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  ttl     = 60
}

resource "aws_route53_record" "a_record" {
  name    = "${var.app_name}.${var.environment_name}.${var.domain_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.hosted_zone.zone_id

  alias {
    name                   = aws_alb.main_lb.dns_name
    zone_id                = aws_alb.main_lb.zone_id
    evaluate_target_health = true
  }
}
