In order to allow our services within EKS to interact with AWS API, we need to configure the OIDC and that is still non-trivial. 

## Prerequisites
We are solving this problem with Terraform and some stock modules. If you provision EKS cluster using only AWS provider, pay attention to available outputs. With that
 - [Hahshicorp TLS provider](https://registry.terraform.io/providers/hashicorp/tls/latest)
 - [Terraform AWS EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

## How it works
If you create the OpenIDConnect configuration for the cluster manually, then IAM will call the issuer (by URL you have to provide) and import the fingerprint thumbnail automatically.
When you create said configuration with Terraform AWS provider, well, it does not. I won't dive into the argument should it or not, the fact is - its not. We need a method to ensure the 
thumbnail is passed to IAM though. And here how we're going to acheive that:
1. Fetch the certificate as a data resource:
```
data "tls_certificate" "k8s" {
  url = module.hashicorp-eks.cluster_oidc_issuer_url
}
```
Note, that we can get the actual certificate calling `module.hashicorp-eks.cluster_certificate_authority_data` but that is not good enough for TLS provider, it expects URL and wants to fetch certificate on its own.
2. Parse the certificate and send back the fingerprint:
```
resource "aws_iam_openid_connect_provider" "k8s-iam-connector" {
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = ["${data.tls_certificate.eks.certificates.0.sha1_fingerprint}"]
    url             = module.hashicorp-eks.cluster_oidc_issuer_url
}
```

You can confirm the configuration with AWS CLI:
```
aws iam get-open-id-connect-provider --open-id-connect-provider-arn $(aws iam list-open-id-connect-providers  --query "OpenIDConnectProviderList[0].Arn" --output text)
```

Of course if you have a single configuration, otherwise you need to be more specific in your `--query` statement
