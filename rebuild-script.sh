#!/bin/bash

# Step 1: Delete existing namespace (if it exists)
oc delete ns local-backstage --wait=true

# Step 2: Install dependencies and build projects
yarn && yarn run tsc && yarn run build:all

# Step 3: Export dynamic plugins
yarn --cwd plugins/mta-backend export-dynamic
yarn --cwd plugins/catalog-backend-module-mta-entity-provider export-dynamic
yarn --cwd plugins/scaffolder-backend-module-mta export-dynamic

# Step 4: Stage dynamic plugins and capture the output
output=$(./01-stage-dynamic-plugins.sh)
echo "$output"

# Step 5: Parse the output for integrity hashes
mta_backend_hash=$(echo "$output" | grep 'mta-backend plugin integrity Hash:' | awk '{print $NF}')
mta_frontend_hash=$(echo "$output" | grep 'mta-frontend plugin integrity Hash:' | awk '{print $NF}')
catalog_module_hash=$(echo "$output" | grep 'Catalog module plugin integrity Hash:' | awk '{print $NF}')
scaffolder_module_hash=$(echo "$output" | grep 'Scaffolder module plugin integrity Hash:' | awk '{print $NF}')

# Step 6: Recreate namespace
oc create ns local-backstage

# Step 7: Create the dynamic-plugins-rhdh ConfigMap
cat <<EOF | oc apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: dynamic-plugins-rhdh
  labels:
    rhdh.redhat.com/ext-config-sync: "true"
  annotations:
    rhdh.redhat.com/backstage-name: "developer-hub"
data:
  dynamic-plugins.yaml: |
    includes:
      - dynamic-plugins.default.yaml
    plugins:
      - package: 'http://plugin-registry:8080/internal-backstage-plugin-mta-backend-dynamic-0.1.0.tgz'
        disabled: false
        integrity: '$mta_backend_hash'
      - package: 'http://plugin-registry:8080/internal-backstage-plugin-mta-frontend-dynamic-0.1.0.tgz'
        disabled: false
        integrity: '$mta_frontend_hash'
      - package: 'http://plugin-registry:8080/internal-backstage-plugin-catalog-backend-module-mta-entity-provider-dynamic-0.1.0.tgz'
        disabled: false
        integrity: '$catalog_module_hash'
      - package: 'http://plugin-registry:8080/internal-backstage-plugin-scaffolder-backend-module-mta-dynamic-0.1.0.tgz'
        disabled: false
        integrity: '$scaffolder_module_hash'
EOF

# Step 8: Execute additional setup scripts and apply Kubernetes resources
./02-create-plugin-registry.sh
oc apply -f app-config-rhdh.yaml
oc apply -f backstage-operator-cr.yaml
