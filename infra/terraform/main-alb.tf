###########################
# Enable OIDC for EKS
###########################

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd60e1d"]
}

###########################
# IAM Role for ALB Controller (IRSA)
#"Terraform block defines a IAM policy document (data "aws_iam_policy_document") that allows the AWS ALB Ingress Controller (or AWS Load Balancer Controller) running in your EKS cluster to assume an IAM role using OIDC (OpenID Connect)."
###########################

data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:alb-ingress-controller"]
    }
  }
}

resource "aws_iam_role" "alb_ingress_role" {
  name               = "alb-ingress-controller-role-1000"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

resource "aws_iam_policy" "alb_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy1000"
  path        = "/"
  description = "Policy for ALB ingress controller"
  policy      = file("${path.module}/iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_ingress_role.name
  policy_arn = aws_iam_policy.alb_policy.arn
}

###########################
# Install ALB Ingress Controller via Helm
###########################

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.alb_controller_version
  create_namespace = false

  values = [
    <<EOF
clusterName: ${var.cluster_name}
serviceAccount:
  create: true
  name: alb-ingress-controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.alb_ingress_role.arn}
region: ${var.region}
vpcId: ${aws_vpc.main.id}
EOF
  ]

  depends_on = [aws_iam_role_policy_attachment.alb_attach]
}
