# Amazon EKS IPv6 Cluster with Terraform

## Customize The Setup

- Edit variables.tf with your own values


## Deploy

```
terraform init
terraform validate
terraform plan
terraform apply
```

## Verify the cluster creation

```
kubectl get nodes -o wide
NAME                                        STATUS   ROLES    AGE     VERSION               INTERNAL-IP                               EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-39-197.eu-west-1.compute.internal   Ready    <none>   5m38s   v1.27.4-eks-8ccc7ba   2a05:d018:1dfe:b505:2596:e69f:67f6:6458   <none>        Amazon Linux 2   5.10.186-179.751.amzn2.x86_64   containerd://1.6.19
```

## Verify EBS Driver is pre-installed
```
% kubectl get deployment ebs-csi-controller -n kube-system

NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
ebs-csi-controller   2/2     2            2           8m42s
```


## Check running pods

```
kubectl get pods -A -o wide

NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE     IP                                        NODE                                        NOMINATED NODE   READINESS GATES
default       server                                                      1/1     Running   0             5m46s   2600:1f16:812:8303:ffe5::a               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   aws-node-85zfs                                              2/2     Running   0             51m     2600:1f16:812:8303:1df2:e67b:d3a7:b094   ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   cluster-autoscaler-aws-cluster-autoscaler-5dc44597f-hrzbq   1/1     Running   0             8m48s   2600:1f16:812:8303:ffe5::                ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   coredns-6d75dbdb9c-gqtlw                                    1/1     Running   0             51m     2600:1f16:812:8303:ffe5::6               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   coredns-6d75dbdb9c-tr7f6                                    1/1     Running   0             51m     2600:1f16:812:8303:ffe5::4               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   ebs-csi-controller-5c6f8dddc7-l2qvj                         6/6     Running   1 (36m ago)   51m     2600:1f16:812:8303:ffe5::7               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   ebs-csi-controller-5c6f8dddc7-zrt5p                         6/6     Running   1 (36m ago)   51m     2600:1f16:812:8303:ffe5::3               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   ebs-csi-node-lcb84                                          3/3     Running   0             51m     2600:1f16:812:8303:ffe5::9               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   efs-csi-controller-fdb6dd69d-5kwqs                          3/3     Running   0             51m     2600:1f16:812:8303:ffe5::8               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   efs-csi-controller-fdb6dd69d-tcrtv                          3/3     Running   1 (36m ago)   51m     2600:1f16:812:8303:ffe5::5               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   efs-csi-node-t6c2w                                          3/3     Running   0             51m     2600:1f16:812:8303:ffe5::2               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   kube-proxy-fjqt8                                            1/1     Running   0             51m     2600:1f16:812:8303:1df2:e67b:d3a7:b094   ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>
kube-system   metrics-server-76c55fc4fc-h4xfb                             1/1     Running   0             9m11s   2600:1f16:812:8303:ffe5::1               ip-10-0-12-187.us-east-2.compute.internal   <none>           <none>

```

## Deploy a Test Pod in the Cluster

```
kubectl run test --image=nginx 
pod/test created


kubectl get pod/test -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP                            NODE                                        NOMINATED NODE   READINESS GATES
test   1/1     Running   0          18s   2a05:d018:1dfe:b505:6819::2   ip-10-0-39-197.eu-west-1.compute.internal   <none>           <none>
```

## Verify IRSA precreated
```
kubectl get sa -A | egrep "cert-manager|efs|ebs|aws-load|external|cloudwatch-agent|cluster-autoscaler"

kube-system       efs-csi-controller-sa                0         9m11s
kube-system       efs-csi-node-sa                      0         9m11s
```


## Clean up

```
terraform destroy
```

