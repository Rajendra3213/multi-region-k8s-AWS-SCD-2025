### Blue environment test
# EKS Blue-Green Deployment - Blue Cluster
```bash
URL=$(echo -n "https://" ; kubectl get ing -n team-burnham burnham-ingress -o json | jq ".spec.rules[0].host" -r)
curl -s $URL | grep CLUSTER_NAME | awk -F "<span>|</span>" '{print $4}'
```
```bash
URL=$(echo -n "https://" ; kubectl get ing -n team-burnham burnham-ingress -o json | jq ".spec.rules[0].host" -r)                                              
repeat 10 curl -s $URL | grep CLUSTER_NAME | awk -F "<span>|</span>" '{print $4}' && sleep 60

```
