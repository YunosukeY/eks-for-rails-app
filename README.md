# eks-for-rails-app
rails-appをEKS上にデプロイするためのマニフェストです

## 構築方法
1. 準備  
    kubectl, AWS CLI, terraformがインストール済みである必要があります
2. インフラを構築  
    成功すると最後にregion, cluster-name, node-role, 2つのsubnet IDが表示されます
    ```
    $ cd terraform
    $ terraform init
    
    ...
    
    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
    
    $ terraform plan

    ...

    Plan: 16 to add, 0 to change, 0 to destroy.
    
    ------------------------------------------------------------------------

    Note: You didn't specify an "-out" parameter to save this plan, so Terraform
    can't guarantee that exactly these actions will be performed if
    "terraform apply" is subsequently run.
    
    $ terraform apply

    ...
    
    Plan: 16 to add, 0 to change, 0 to destroy.
    
    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.
    
      Enter a value: yes

    ...
    
    aws_eks_cluster.cluster: Creation complete after 9m43s [id=cluster-for-rails-app]

    Apply complete! Resources: 16 added, 0 changed, 0 destroyed.
    
    Outputs:
    
    cluster-name = cluster-for-rails-app
    node-role = arn:aws:iam::833208907001:role/eks-node-role
    region = ap-northeast-1
    subnet1 = subnet-082c71cbbd8e53fcd
    subnet2 = subnet-0e579221a6ed63f46
    ```
3. kubeconfigの更新  
    先ほどのregion, cluster-nameを登録します  
    kubectlは設定されますが、Podは立ち上がっていないはずです
    ```
    $ aws eks --region ap-northeast-1 update-kubeconfig --name cluster-for-rails-app
    $ kubectl get pod -A -o wide
    NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE    IP       NODE     NOMINATED NODE       READINESS GATES
    kube-system   coredns-58986cd576-7hbxl   0/1     Pending   0          3m7s   <none>   <none>   <none>           <none>
    kube-system   coredns-58986cd576-ds56c   0/1     Pending   0          3m7s   <none>   <none>   <none>           <none>
    ```
4. ノードグループの作成  
    先ほどのcluster-name, subnet ID, node-roleを用います  
    冗長化のため、ノード数は2、インスタンスはMAX IP 10以上のものを選んでください  
    今度はPodは立ち上がるはずです
    ```
    $ aws eks create-nodegroup \
       --cluster-name cluster-for-rails-app \
       --nodegroup-name nodegroup \
       --scaling-config minSize=2,maxSize=2,desiredSize=2 \
       --subnets subnet-082c71cbbd8e53fcd subnet-0e579221a6ed63f46 \
       --instance-types t3.small \
       --ami-type AL2_x86_64 \
       --node-role arn:aws:iam::833208907001:role/eks-node-role
    
    $ kubectl get pod -A -o wide
    NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE     IP           NODE                                            NOMINATED NODE   READINESS GATES
    kube-system   aws-node-f7646             1/1     Running   0          2m45s   10.1.1.39    ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    kube-system   aws-node-fscfx             1/1     Running   0          2m43s   10.1.0.238   ip-10-1-0-238.ap-northeast-1.compute.internal   <none>           <none>
    kube-system   coredns-58986cd576-7hbxl   1/1     Running   0          10m     10.1.1.111   ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    kube-system   coredns-58986cd576-ds56c   1/1     Running   0          10m     10.1.1.213   ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    kube-system   kube-proxy-qplmn           1/1     Running   0          2m43s   10.1.0.238   ip-10-1-0-238.ap-northeast-1.compute.internal   <none>           <none>
    kube-system   kube-proxy-t6n5z           1/1     Running   0          2m45s   10.1.1.39    ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    ```
5. デプロイ  
    順にデプロイしていきます  
    masterをデプロイ → masterを指すサービスをデプロイ → masterをmigrate → railsアプリをデプロイ → ロードバランサーをデプロイ  
    TODO: slaveをデプロイ
    ```
    $ kubectl apply -f stateful-psql-master.yaml
    $ kubectl apply -f svc-psql.yaml
    $ kubectl apply -f job-migrate.yaml
    $ kubectl apply -f deployment-rails.yaml
    $ kubectl apply -f svc-loadbalancer.yaml
    
    $ kubectl get pod -A -o wide
    NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE     IP           NODE                                            NOMINATED NODE   READINESS GATES
    default       sample-deployment-ruby-7db75976f4-74gmj   1/1     Running     0          7m46s   10.1.1.157   ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    default       sample-deployment-ruby-7db75976f4-nsplp   1/1     Running     0          7m46s   10.1.0.105   ip-10-1-0-238.ap-northeast-1.compute.internal   <none>           <none>
    default       sample-job-migrate-qtvkz                  0/1     Completed   0          35m     10.1.0.105   ip-10-1-0-238.ap-northeast-1.compute.internal   <none>           <none>
    default       sample-statefulset-psql-master-0          1/1     Running     0          40m     10.1.0.229   ip-10-1-0-238.ap-northeast-1.compute.internal   <none>           <none>
    kube-system   aws-node-f7646                            1/1     Running     0          3h50m   10.1.1.39    ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    kube-system   aws-node-fscfx                            1/1     Running     0          3h50m   10.1.0.238   ip-10-1-0-238.ap-northeast-1.compute.internal   <none>           <none>
    kube-system   coredns-58986cd576-7hbxl                  1/1     Running     0          3h58m   10.1.1.111   ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    kube-system   coredns-58986cd576-ds56c                  1/1     Running     0          3h58m   10.1.1.213   ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    kube-system   kube-proxy-qplmn                          1/1     Running     0          3h50m   10.1.0.238   ip-10-1-0-238.ap-northeast-1.compute.internal   <none>           <none>
    kube-system   kube-proxy-t6n5z                          1/1     Running     0          3h50m   10.1.1.39    ip-10-1-1-39.ap-northeast-1.compute.internal    <none>           <none>
    
    $ kubectl describe services sample-gateway
    Name:                     sample-gateway
    Namespace:                default
    Labels:                   <none>
    Annotations:              <none>
    Selector:                 app=rails-app
    Type:                     LoadBalancer
    IP:                       172.20.209.100
    LoadBalancer Ingress:     ae5945cbb2de811ea91900a91f93ff27-1936263502.ap-northeast-1.elb.amazonaws.com
    Port:                     <unset>  80/TCP
    TargetPort:               3000/TCP
    NodePort:                 <unset>  32094/TCP
    Endpoints:                10.1.0.105:3000,10.1.1.157:3000
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:
      Type    Reason                Age   From                Message
      ----    ------                ----  ----                -------
      Normal  EnsuringLoadBalancer  6s    service-controller  Ensuring load balancer
      Normal  EnsuredLoadBalancer   4s    service-controller  Ensured load balance
    ```
6. 確認  
    LoadBalancer Ingressのアドレスにアクセスします  
    この例ではae5945cbb2de811ea91900a91f93ff27-1936263502.ap-northeast-1.elb.amazonaws.comです

## 詰まりポイント
- PVCだけデプロイしようとしたがずっとpending
    - nodeを作っていなかった
- postgreがvolumeをマウントしない
    - subPathを書く
- postgreがマウントした場所の権限がないと言ってくる
    - initContainersでchmod
    - chmodの権限がない
        - securityContext.runAsUserを0
- LoadBalancer Ingressにアクセスできない
    - 待つ
- slaveがデプロイできない
    - POSTGRESQL_REPLICATION_USERがいないと言われる
    - なんで？

## 参考
[AWS マネジメントコンソール の開始方法](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/getting-started-console.html)  
[[アップデート] EKSがマネジメントコンソールおよびCLIでのワーカーノードの作成・管理をサポートしました](https://dev.classmethod.jp/cloud/aws/eks-support-provisioning-and-managing-worker-nodes/)  
[kubernetesクラスタでRailsアプリを公開するチュートリアル](https://qiita.com/tatsurou313/items/223dfa599ee5aaf6b2f0)  
[EC2Instances.info](https://www.ec2instances.info/?region=ap-northeast-1)  
[Amazon EKS ワーカーノード IAM ロールの作成](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/worker_node_IAM_role.html#create-worker-node-role)  
[TerraformでEKS環境を構築する](https://qiita.com/samskeyti/items/5855f1f2b5262e27af6e)  
