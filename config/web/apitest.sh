#!/bin/bash
# apitest.sh — quick local API tester for beetroot backend - currently broken

BASE_URL="http://localhost:4200/api"

function test_endpoint() {
    local endpoint=$1
    echo "=== Testing: $endpoint ==="
    curl -s -X GET "$BASE_URL$endpoint" | jq
    echo ""
}

function post_script_run() {
    echo "=== Testing: POST /run ==="
    curl -s -X POST "$BASE_URL/run" \
        -H "Content-Type: application/json" \
        -d '{"script": "beetenv.sh"}' | jq
    echo ""
}

test_endpoint "/health"
test_endpoint "/version"
test_endpoint "/scripts/example"
post_script_run
