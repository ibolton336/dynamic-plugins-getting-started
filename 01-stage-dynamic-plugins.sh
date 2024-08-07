#!/bin/bash

# Uses "npm pack" to to create .tgz files containing the plugin static assets
DYNAMIC_PLUGIN_ROOT_DIR=./deploy
echo ""
echo "Packaging up plugin static assets"
echo ""
MTA_BACKEND_INTEGRITY_HASH=$(npm pack plugins/mta-backend/dist-dynamic --pack-destination $DYNAMIC_PLUGIN_ROOT_DIR --json | jq -r '.[0].integrity') &&
    echo "mta-Backend plugin integrity Hash: $MTA_BACKEND_INTEGRITY_HASH"

CATALOG_BACKEND_MODULE_INTEGRITY_HASH=$(npm pack plugins/catalog-backend-module-mta-entity-provider/dist-dynamic --pack-destination $DYNAMIC_PLUGIN_ROOT_DIR --json | jq -r '.[0].integrity') &&
    echo "Catalog module plugin integrity Hash: $CATALOG_BACKEND_MODULE_INTEGRITY_HASH"

echo ""
echo "Plugin .tgz files:"
ls -l $DYNAMIC_PLUGIN_ROOT_DIR

echo ""