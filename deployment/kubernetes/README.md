```bash
kubectl create deployment spring-example --image=cch0124/cicd-spring:latest --replicas=3 --port=8080 --dry-run=client -o yaml > deployment.yaml
```
