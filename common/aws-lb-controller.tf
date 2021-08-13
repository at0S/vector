/*
Automating provisioning of the AWS LoadBalancer Controler
https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/

Before we can get the the controller, some footwork is required.
We need to create an IAM Role for the service, policy, wire those
all tgether and finally create a role in EKS and linke both
*/

locals {
  sa_namespace = "kube-system"
  sa_name      = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "k8s-lb-controller-policy" {
  name        = local.sa_name
  path        = "/k8s/"
  description = "AWS Ingress Controller policy"
  policy      = file("aws-ingress-controller.json")
}

resource "aws_iam_role" "k8s-lb-controller-role" {
  name                  = "aws-load-balancer-controller"
  path                  = "/k8s/"
  force_detach_policies = true
  managed_policy_arns   = [aws_iam_policy.k8s-lb-controller-policy.arn]
  assume_role_policy = templatefile("aws-ingress-controller-assume.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.k8s-iam-connector.arn,
    OIDC_URL  = aws_iam_openid_connect_provider.k8s-iam-connector.url,
    NAMESPACE = local.sa_namespace,
  SA_NAME = local.sa_name })
}

resource "kubernetes_service_account" "k8s-lb-controller-sa" {
  metadata {
    name      = local.sa_name
    namespace = local.sa_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.k8s-lb-controller-role.arn
    }
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = local.sa_namespace
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "clusterName"
    value = local.cluster_name
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}
