1. 建立好 K8s 後需要再 `/etc/default/kubelet` 新增 `--node-ip` 的字段其值為當前主機的 IP

在 deployment/kubernetes 下使用 `kubectl apply -f .` 即可運行服務


## Helm

1. Initialize a Helm Chart Repository
```bash
helm repo add cilium https://helm.cilium.io/
helm search repo cilium
```
2. Install chart
```bash
$ helm repo update  # 獲取 repo 相關的 chart
$ helm install cilium cilium/cilium --version 1.11.0 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=$1  \
    --set k8sServicePort=6443 \
    --set nodePort.enabled=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}"
$ helm -n kube-system list # 查看已經被安裝的的 Chart
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
cilium  kube-system     1               2022-02-19 14:03:07.308324937 +0000 UTC deployed        cilium-1.11.0   1.11.0
```
3. Uninstall a Release
```bash
$ helm -n kube-system uninstall cilium
$ helm -n kube-system status cilium # 狀態查詢
NAME: cilium
LAST DEPLOYED: Sat Feb 19 14:03:07 2022
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
You have successfully installed Cilium with Hubble Relay and Hubble UI.

Your release version is 1.11.0.

For any further help, visit https://docs.cilium.io/en/v1.11/gettinghelp
```
簡單的來看可以想像他是 `apt-get`。因此他也有版本號控管使得 yaml 管理向應用程式一樣。

主要概念有以下
- Chart 
  - 基本單位，包含了 yaml 檔的設計(Kubernetes 資源)
- Repository
  - 想像是 docker hub，可以提供給第三方下載
  - 同樣也有 public/private
- Release
  - 想像是 namespace，一個 chart 可以被安裝多次，每一次安裝的物件都可稱為 Release

下面是一個描述 WordPress 的 Chart 儲存在 wordpress/ 目錄中。Chart 被組織為目錄內的文件集合，目錄名稱是 Chart 的名稱，沒有版本資訊。在 `templates` 目錄中，定義了依據需求的 yaml，當中會注入 Template 語法，使得佈署更有彈性。其搭配的值由 `Values.yaml` 組合。

```bash
wordpress/
  Chart.yaml          # A YAML file containing information about the chart
  LICENSE             # OPTIONAL: A plain text file containing the license for the chart
  README.md           # OPTIONAL: A human-readable README file
  values.yaml         # The default configuration values for this chart
  values.schema.json  # OPTIONAL: A JSON Schema for imposing a structure on the values.yaml file
  charts/             # A directory containing any charts upon which this chart depends.
  crds/               # Custom Resource Definitions
  templates/          # A directory of templates that, when combined with values,
                      # will generate valid Kubernetes manifest files.
  templates/NOTES.txt # OPTIONAL: A plain text file containing short usage notes
```

這樣只需維護一個供板，不論是 dev 或 stage 環境都能更靈活被使用。

```bash
$ helm create test # 建立 Chart
Creating test
~/test$ ls
charts  Chart.yaml  templates  values.yaml
```
- Chart.yaml 描述版本資訊

```bash
~/test$ helm install test . # 本地安裝，一次的安裝就是一個 Release，因此要給名稱
NAME: test
LAST DEPLOYED: Sun Feb 20 04:23:06 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=test,app.kubernetes.io/instance=test" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

這邊的 `NOTES` 被定義在 `templates/NOTES.txt` 中，所有資訊都可寫入這。

### 範例
在 `deployment/helm` 目錄下有定義簡單的 helm 範例
```bash
helm install spring-app . # 可以使用 -n 方式指定 namespace
NAME: spring-app
LAST DEPLOYED: Sun Feb 20 05:38:36 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
spring application
```

前綴為 release 名稱。
```bash
$ kubectl get all
NAME                              READY   STATUS    RESTARTS   AGE
pod/cicd-spring-f5d465696-754pv   1/1     Running   0          3m13s
pod/cicd-spring-f5d465696-9gpdx   1/1     Running   0          3m13s
pod/cicd-spring-f5d465696-vbrrb   1/1     Running   0          3m13s

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/cicd-spring   NodePort    10.107.70.193   <none>        8080:30274/TCP   3m13s
service/kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP          20h

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cicd-spring   3/3     3            3           3m13s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/cicd-spring-f5d465696   3         3         3       3m13s
```

使用 `NodePort` 測試，`192.168.56.22` 為 node2 的對外 IP，有些 POD 被分配在那
```bash
curl http://192.168.56.22:30274/ipadd
{"ip":"10.0.2.151"}
```
helm 一些查看
```bash
helm list
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
spring-app      default         1               2022-02-20 05:38:36.864645203 +0000 UTC deployed        cicd-spring-0.1.0       1.0.0
```

使用 `helm get manifest spring-app` 方式可以確認說長出來的 yaml 格式，如下
```yaml
---
# Source: cicd-spring/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: cicd-spring
spec:
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
      name: httpport
  selector:
    app: spring-example
    svc: spring-service
---
# Source: cicd-spring/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: spring-be
    svc: spring-service
  name: cicd-spring
spec:
  replicas: 3
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  selector:
    matchLabels:
      app: spring-example
      svc: spring-service # 引用 _helpers.tpl
  template:
    metadata:
      labels:
        app: spring-example
        svc: spring-service
    spec:
      containers:
      - image: cch0124/cicd-spring:latest
        imagePullPolicy: Always
        name: cicd-spring
        ports:
        - containerPort: 8080
          name: httpport
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 20
```
 
更新當前的 release 物件，使用 `upgrade` 和 `--set` 方式如下
```bash
$ helm  upgrade spring-app --set spring.image.tag=b48a4f2 .
Release "spring-app" has been upgraded. Happy Helming!
NAME: spring-app
LAST DEPLOYED: Sun Feb 20 05:54:37 2022
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
spring application
```
增加一個版本號，並使用 `get values` 來看當前被變動的值，當然也可以使用 `get manifest` 驗證
```bash
$ helm list
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
spring-app      default         2               2022-02-20 05:54:37.677444214 +0000 UTC deployed        cicd-spring-0.1.0       1.0.0
$ helm get values spring-app
USER-SUPPLIED VALUES:
spring:
  image:
    tag: b48a4f2
```

helm 回滾非基於 POD，而是基於 yaml，當前已經遍換了 image 的 tag，我們再將其回滾至 `latest` 使用 `rollback` 參數

```bash
$ helm rollback spring-app
$ helm list # 又增加一版
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
spring-app      default         3               2022-02-20 06:01:07.734659913 +0000 UTC deployed        cicd-spring-0.1.0       1.0.0
```