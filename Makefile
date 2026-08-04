OPENSEARCH_VERSION:= 2.38.0
OPENSEARCH_DASHBOARD_VERSION:= 2.34.0
OPENSEARCH_SECRET_DIR:= opensearch/etc/.secrets
OPENSEARCH_CONFIG_DIR:= opensearch/etc/config


helm:
	helm repo add opensearch https://opensearch-project.github.io/helm-charts/
	helm repo update 
	
opensearch: nodes dashboard

nodes:
	helm template opensearch opensearch/opensearch --version=${OPENSEARCH_VERSION} --values=values-opensearch-master.yaml > helm-opensearch-master.yaml
	helm template opensearch opensearch/opensearch --version=${OPENSEARCH_VERSION} --values=values-opensearch-worker.yaml > helm-opensearch-worker.yaml
	#helm template opensearch opensearch/opensearch --version=${OPENSEARCH_VERSION} --values=values-opensearch-coordinator.yaml > helm-opensearch-coordinator.yaml


dashboard:
	helm template opensearch opensearch/opensearch-dashboards --version=${OPENSEARCH_DASHBOARD_VERSION} --values=values-opensearch-dashboard.yaml > helm-opensearch-dashboard.yaml

run-dump: 
	kubectl kustomize .

dump:  get-secrets opensearch dashboard run-dump


run-apply:  
	kubectl apply -k .

apply: helm get-secrets opensearch run-apply

run-destroy:
	kubectl delete -k .

destroy: get-secrets opensearch dashboard run-destroy

get-secrets:
	mkdir -p opensearch/etc/.secrets
	vault kv get --field=hostcert secret/rubin/usdf-opensearch/opensearch > ${OPENSEARCH_SECRET_DIR}/hostcert.pem
	vault kv get --field=hostkey secret/rubin/usdf-opensearch/opensearch > ${OPENSEARCH_SECRET_DIR}/hostkey.pem
	vault kv get --field=password secret/rubin/usdf-opensearch/opensearch > ${OPENSEARCH_SECRET_DIR}/password
	vault kv get --field=admin-user secret/rubin/usdf-opensearch/opensearch > ${OPENSEARCH_SECRET_DIR}/username
	vault kv get --field=cookie secret/rubin/usdf-opensearch/opensearch > ${OPENSEARCH_SECRET_DIR}/cookie
	vault kv get --field=usdf-cacert secret/rubin/usdf-opensearch/opensearch > ${OPENSEARCH_SECRET_DIR}/root-ca.pem

get-config:
	mkdir -p opensearch/etc/config
	vault kv get --field=internal_users secret/rubin/usdf-opensearch/config > ${OPENSEARCH_CONFIG_DIR}/internal_users.yml
	vault kv get --field=roles secret/rubin/usdf-opensearch/config > ${OPENSEARCH_CONFIG_DIR}/roles.yml
	vault kv get --field=allowlist secret/rubin/usdf-opensearch/config > ${OPENSEARCH_CONFIG_DIR}/allowlist.yml
	vault kv get --field=tenants secret/rubin/usdf-opensearch/config > ${OPENSEARCH_CONFIG_DIR}/tenants.yml
	vault kv get --field=nodes_dn secret/rubin/usdf-opensearch/config > ${OPENSEARCH_CONFIG_DIR}/nodes_dn.yml

put-config:
	vault kv put secret/rubin/usdf-opensearch/config internal_users=@${OPENSEARCH_CONFIG_DIR}/internal_users.yml roles=@${OPENSEARCH_CONFIG_DIR}/roles.yml allowlist=@${OPENSEARCH_CONFIG_DIR}/allowlist.yml nodes_dn=@${OPENSEARCH_CONFIG_DIR}/nodes_dn.yml tenants=@${OPENSEARCH_CONFIG_DIR}/tenants.yml

put-secrets:
	vault kv put secret/rubin/usdf-opensearch/opensearch hostcert=@${OPENSEARCH_SECRET_DIR}/hostcert.pem hostkey=@${OPENSEARCH_SECRET_DIR}/hostkey.pem usdf-cacert=@${OPENSEARCH_SECRET_DIR}/root-ca.pem password=@${OPENSEARCH_SECRET_DIR}/password admin-user=@${OPENSEARCH_SECRET_DIR}/username cookie=@${OPENSEARCH_SECRET_DIR}/cookie

clean-config:
	rm -rf ${OPENSEARCH_CONFIG_DIR}

clean-secrets:
	rm -rf ${OPENSEARCH_SECRET_DIR}

local:	opensearch run-apply
