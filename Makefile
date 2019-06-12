
k8s_setup:
	kubectl apply -f kong-namespace.yaml
	-./setup_certificate.sh

run_dbless: k8s_setup
	-kubectl create configmap kongdeclarative -n kong --from-file=declarative.yaml
	kubectl create configmap kongdeclarative -n kong --from-file=declarative.yaml -o yaml --dry-run | kubectl replace -n kong -f -
	kubectl apply -f kong-dbless.yaml
	kubectl patch deployment kong-dbless -n kong -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"declarative\":\"`md5sum declarative.yaml | awk '{ print $$1 }'`\"}}}}}}"

run_cassandra: k8s_setup
	kubectl apply -f cassandra-service.yaml
	kubectl apply -f cassandra-statefulset.yaml
	kubectl -n kong apply -f kong-control-plane-cassandra.yaml

run_postgres: k8s_setup
	kubectl -n kong apply -f postgres.yaml
	kubectl -n kong apply -f kong-control-plane-postgres.yaml
	kubectl -n kong apply -f kong-ingress-data-plane-postgres.yaml

cleanup:
	-kubectl delete -f cassandra-service.yaml
	-kubectl delete -f cassandra-statefulset.yaml
	-kubectl -n kong delete -f postgres.yaml
	-kubectl -n kong delete -f kong-control-plane-cassandra.yaml
	-kubectl -n kong delete -f kong-control-plane-postgres.yaml
	-kubectl -n kong delete -f kong-ingress-data-plane-cassandra.yaml
	-kubectl -n kong delete -f kong-ingress-data-plane-postgres.yaml
	-kubectl -n kong delete -f kong-dbless.yaml
	-kubectl -n kong delete configmap kongdeclarative
	-kubectl certificate approve kong-control-plane.kong.svc
	-kubectl delete csr kong-control-plane.kong.svc
	kubectl delete -f kong-namespace.yaml