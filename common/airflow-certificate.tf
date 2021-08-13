resource "aws_acm_certificate" "airflow-certificate" {
  domain_name       = "airflow.relevance.tools"
  validation_method = "DNS"

  tags = {
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "relevance-tools" {
  name         = "relevance.tools"
  private_zone = false
}

resource "aws_route53_record" "airflow" {
  for_each = {
    for dvo in aws_acm_certificate.airflow-certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.relevance-tools.zone_id
}


resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.airflow-certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.airflow : record.fqdn]
}

output "airflow_certificate" {
    value = "alb.ingress.kubernetes.io/certificate-arn: ${aws_acm_certificate.airflow-certificate.arn}"
}
