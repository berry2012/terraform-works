# Pre Configured Amazon EKS Cluster using Terraform

**The EKS Cluster is preconfigured with necessary Addons to get started with production environment setup**


## Customizing

- Edit variables.tf with your own values


## Deploy

```
terraform init

terraform validate

terraform plan -out main.tfplan

terraform apply main.tfplan

```
## Authenticate your local machine kubectl

```
aws eks --region eu-west-2 update-kubeconfig --name poc
```


## Validate worker nodes

```
kubectl get nodes -o wide
NAME                                        STATUS                     ROLES    AGE     VERSION                INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-27-178.eu-west-2.compute.internal   Ready                      <none>   4m20s   v1.29.13-eks-5d632ec   10.0.27.178   <none>        Amazon Linux 2   5.10.233-224.894.amzn2.x86_64   containerd://1.7.25
ip-10-0-29-236.eu-west-2.compute.internal   Ready                      <none>   2m34s   v1.29.13-eks-5d632ec   10.0.29.236   <none>        Amazon Linux 2   5.10.233-224.894.amzn2.x86_64   containerd://1.7.25
ip-10-0-3-185.eu-west-2.compute.internal    Ready,SchedulingDisabled   <none>   14m     v1.29.13-eks-5d632ec   10.0.3.185    <none>        Amazon Linux 2   5.10.233-224.894.amzn2.x86_64   containerd://1.7.25
ip-10-0-35-144.eu-west-2.compute.internal   Ready                      <none>   4m8s    v1.29.13-eks-5d632ec   10.0.35.144   <none>        Amazon Linux 2   5.10.233-224.894.amzn2.x86_64   containerd://1.7.25
ip-10-0-6-199.eu-west-2.compute.internal    Ready                      <none>   2m43s   v1.29.13-eks-5d632ec   10.0.6.199    <none>        Amazon Linux 2   5.10.233-224.894.amzn2.x86_64   containerd://1.7.25```

## Verify EBS CSI Driver pods are running

```
% kubectl get deployment ebs-csi-controller -n kube-system

NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
ebs-csi-controller   2/2     2            2           8m42s
```

clusterName: poc
enableServiceMutatorWebhook: false
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::520817024429:role/alb-controller-20250306083558990100000014
  name: aws-load-balancer-controller-sa


## Verify Pods running:

```
kubectl get pods -A 

NAMESPACE            NAME                                                         READY   STATUS    RESTARTS   AGE
amazon-cloudwatch    aws-cloudwatch-metrics-58q4f                                 1/1     Running   0          7m21s
amazon-cloudwatch    aws-cloudwatch-metrics-9gwrk                                 1/1     Running   0          43s
amazon-cloudwatch    aws-cloudwatch-metrics-qmlmf                                 1/1     Running   0          2m43s
amazon-cloudwatch    aws-cloudwatch-metrics-r7878                                 1/1     Running   0          99s
amazon-cloudwatch    aws-cloudwatch-metrics-sdnnm                                 1/1     Running   0          3m38s
amazon-cloudwatch    aws-cloudwatch-metrics-vxw5v                                 0/1     Pending   0          9m6s
cert-manager         cert-manager-875c7579b-crqz4                                 1/1     Running   0          3m58s
cert-manager         cert-manager-cainjector-7bb6786867-x6ckl                     1/1     Running   0          3m58s
cert-manager         cert-manager-webhook-89dc55877-nrmsz                         1/1     Running   0          3m58s
default              backendapp                                                   1/1     Running   0          4m41s
demo                 go-http-deployment-67b56db748-dbd6f                          1/1     Running   0          9m37s
demo                 go-http-deployment-67b56db748-fnzbk                          1/1     Running   0          9m37s
demo                 go-http-deployment-67b56db748-p4rm9                          1/1     Running   0          9m37s
kube-system          aws-for-fluent-bit-52ctr                                     1/1     Running   0          99s
kube-system          aws-for-fluent-bit-9clc2                                     0/1     Pending   0          9m3s
kube-system          aws-for-fluent-bit-bccp7                                     1/1     Running   0          2m43s
kube-system          aws-for-fluent-bit-qbjs9                                     1/1     Running   0          7m21s
kube-system          aws-for-fluent-bit-shf8b                                     1/1     Running   0          3m38s
kube-system          aws-for-fluent-bit-zcbsz                                     1/1     Running   0          43s
kube-system          aws-load-balancer-controller-fd8985cb8-2qrgw                 1/1     Running   0          9m9s
kube-system          aws-load-balancer-controller-fd8985cb8-psqrd                 1/1     Running   0          9m9s
kube-system          aws-node-5k995                                               2/2     Running   0          2m57s
kube-system          aws-node-b6vc9                                               2/2     Running   0          7m34s
kube-system          aws-node-hb6w6                                               2/2     Running   0          3m52s
kube-system          aws-node-nfdj2                                               2/2     Running   0          11m
kube-system          aws-node-v4xxk                                               2/2     Running   0          113s
kube-system          aws-node-wzhbl                                               2/2     Running   0          58s
kube-system          cluster-autoscaler-aws-cluster-autoscaler-6b9999cd89-49ktx   1/1     Running   0          9m14s
kube-system          coredns-6d75dbdb9c-bpw8m                                     1/1     Running   0          11m
kube-system          coredns-6d75dbdb9c-q9jhg                                     1/1     Running   0          11m
kube-system          ebs-csi-controller-fb96d9c47-5gmdf                           6/6     Running   0          11m
kube-system          ebs-csi-controller-fb96d9c47-pkh5j                           6/6     Running   0          11m
kube-system          ebs-csi-node-4lxsb                                           3/3     Running   0          7m34s
kube-system          ebs-csi-node-bv295                                           3/3     Running   0          57s
kube-system          ebs-csi-node-dvbkz                                           3/3     Running   0          11m
kube-system          ebs-csi-node-grvbd                                           3/3     Running   0          2m57s
kube-system          ebs-csi-node-h9dfx                                           3/3     Running   0          3m52s
kube-system          ebs-csi-node-t6s2d                                           3/3     Running   0          113s
kube-system          efs-csi-controller-fdb6dd69d-mwww8                           3/3     Running   0          11m
kube-system          efs-csi-controller-fdb6dd69d-wx988                           3/3     Running   0          11m
kube-system          efs-csi-node-2dsf4                                           3/3     Running   0          7m34s
kube-system          efs-csi-node-k2v6v                                           3/3     Running   0          57s
kube-system          efs-csi-node-l6hz4                                           3/3     Running   0          2m57s
kube-system          efs-csi-node-q8fnn                                           3/3     Running   0          113s
kube-system          efs-csi-node-wwns7                                           3/3     Running   0          11m
kube-system          efs-csi-node-zfmwb                                           3/3     Running   0          3m51s
kube-system          external-dns-6899858bbf-9nbgj                                1/1     Running   0          4m26s
kube-system          kube-proxy-6fgm6                                             1/1     Running   0          11m
kube-system          kube-proxy-7kptk                                             1/1     Running   0          2m57s
kube-system          kube-proxy-8mzdd                                             1/1     Running   0          58s
kube-system          kube-proxy-jnnfx                                             1/1     Running   0          7m34s
kube-system          kube-proxy-mj8wf                                             1/1     Running   0          3m51s
kube-system          kube-proxy-tchnb                                             1/1     Running   0          113s
kube-system          metrics-server-76c55fc4fc-42hff                              1/1     Running   0          9m46s
persistent-storage   ebs-persistent-app                                           1/1     Running   0          4m41s

```

## Verify sample backend app exposed with ALB 

``` 
~ % kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
backendapp   1/1     Running   0          5m38s


~ % kubectl get svc backendapp
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP                                                                    PORT(S)        AGE
backendapp   LoadBalancer   172.20.224.226   k8s-default-backenda-3ab8549ac3-22d0208dbeea7e5e.elb.us-east-2.amazonaws.com   80:31748/TCP   6m5s
kubernetes   ClusterIP      172.20.0.1       <none>                                                                         443/TCP        19m
``` 

**Note: Wait a few minutes for the Loadbalancer to be fully provisioned**

```
~ % curl k8s-default-backenda-3ab8549ac3-22d0208dbeea7e5e.elb.us-east-2.amazonaws.com
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## Via Web Broser

[](./images/nginx2.png)


## Verify Backend app

```
~ % kubectl get pods -n demo
NAME                                  READY   STATUS    RESTARTS   AGE
go-http-deployment-67b56db748-dbd6f   1/1     Running   0          11m
go-http-deployment-67b56db748-fnzbk   1/1     Running   0          11m
go-http-deployment-67b56db748-p4rm9   1/1     Running   0          11m
```

## Test the persistent workload

```
 ~ % kubectl get pods -n  persistent-storage
NAME                 READY   STATUS    RESTARTS   AGE
ebs-persistent-app   1/1     Running   0          7m27s

kubectl  exec -it ebs-persistent-app -n persistent-storage -- cat /data/out.txt
Mon Sep 4 14:41:21 UTC 2023
Mon Sep 4 14:41:26 UTC 2023
Mon Sep 4 14:41:31 UTC 2023
Mon Sep 4 14:41:36 UTC 2023
Mon Sep 4 14:41:41 UTC 2023
Mon Sep 4 14:41:46 UTC 2023
Mon Sep 4 14:41:51 UTC 2023
Mon Sep 4 14:41:56 UTC 2023
Mon Sep 4 14:42:01 UTC 2023
```


## Validate Metric Server is Running
```
~ % kubectl top nodes
NAME                                        CPU(cores)   CPU%        MEMORY(bytes)   MEMORY%     
ip-10-0-14-44.us-east-2.compute.internal    47m          2%          517Mi           15%         
ip-10-0-22-245.us-east-2.compute.internal   68m          3%          827Mi           25%         
ip-10-0-47-123.us-east-2.compute.internal   76m          3%          1052Mi          31%         
ip-10-0-28-48.us-east-2.compute.internal    <unknown>    <unknown>   <unknown>       <unknown>   
```


## Verify IRSAs

```
kubectl get sa -A | egrep "cert-manager|efs|ebs|aws-load|external|cloudwatch|fluent|cluster-autoscaler"

amazon-cloudwatch    aws-cloudwatch-metrics               0         14m
amazon-cloudwatch    default                              0         14m
cert-manager         cert-manager                         0         9m
cert-manager         cert-manager-cainjector              0         9m
cert-manager         cert-manager-webhook                 0         9m
cert-manager         default                              0         13m
kube-system          aws-for-fluent-bit-sa                0         14m
kube-system          aws-load-balancer-controller-sa      0         14m
kube-system          cluster-autoscaler-sa                0         14m
kube-system          ebs-csi-controller-sa                0         16m
kube-system          ebs-csi-node-sa                      0         16m
kube-system          efs-csi-controller-sa                0         16m
kube-system          efs-csi-node-sa                      0         16m
kube-system          external-dns-sa                      0         9m28s
```  

## Verify a sample IRSA e.g. external-dns

```
kubctl describe sa external-dns-sa -n kube-system | grep -i arn
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1111111111:role/external-dns-2023090414411173190000002d

kubctl describe sa aws-for-fluent-bit-sa -n kube-system | grep -i arn
eks.amazonaws.com/role-arn: arn:aws:iam::1111111111:role/aws-for-fluent-bit-2023090414411173170000002c
```

---
# Validate ALB Controller and ExternalDNS

## Deploy Host based Ingress Application

```
k apply -f 2048_full_custom.yaml
namespace/game-2048 created
deployment.apps/deployment-2048 created
service/service-2048 created
ingress.networking.k8s.io/ingress-2048 created
```

## Using CloudTrail, Verify the IAM role used by External DNS Service Account to create a host record for the ingress 

```
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=ChangeResourceRecordSets  \
    --start-time "September 04, 2023, 14:00:00" \
    --end-time "September 04, 2023, 23:59:00" --region us-east-1 | jq '.Events [] | .CloudTrailEvent | fromjson | {IAM: .userIdentity.arn}' 
    
{
  "IAM": "arn:aws:sts::1111111111:assumed-role/external-dns-2023090414411173190000002d/1693838779390842744"
}
```



## Clean up

```


kubectl delete -f manifests

terraform destroy --auto-approve


# if there is an issue after modify EKS outside terraform
export KUBE_CONFIG_PATH=/home/ec2-user/.kube/config 
terraform state rm `terraform state list | grep eks`
terraform state rm `terraform state list | grep kubectl`
terraform state rm `terraform state list | grep helm`
terraform state rm `terraform state list | grep kubernetes`
```


aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name eks-worker-group-1-2025022111304443980000001b-32ca9423-1a7b-10c8-1f24-8d7f8d454a48 \
    --min-size 2 \
    --max-size 3 \
    --desired-capacity 2 --region eu-west-2
    
    
    