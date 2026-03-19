#!/bin/bash
set -euo pipefail

IMAGE="$1"
NODES="$2"
BASE_PORT="$3"
PASSWORD="$4"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Generate redis.conf
CONF="$TMPDIR/redis-cluster.conf"
cat > "$CONF" <<EOF
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
EOF

if [ -n "$PASSWORD" ]; then
  cat >> "$CONF" <<EOF
requirepass $PASSWORD
masterauth $PASSWORD
EOF
fi

# Build port list
PORTS=""
ENDPOINTS=""
for i in $(seq 0 $((NODES - 1))); do
  PORT=$((BASE_PORT + i))
  if [ -n "$PORTS" ]; then
    PORTS="$PORTS,$PORT"
  else
    PORTS="$PORT"
  fi
  ENDPOINTS="$ENDPOINTS 127.0.0.1:$PORT"
done

# Start nodes
for i in $(seq 0 $((NODES - 1))); do
  PORT=$((BASE_PORT + i))
  docker run -d \
    --name "redis-cluster-node-$i" \
    --network host \
    -v "$CONF:/usr/local/etc/redis/redis.conf:ro" \
    "$IMAGE" \
    redis-server /usr/local/etc/redis/redis.conf --port "$PORT"
done

# Wait for all nodes to be ready
AUTH_ARGS=""
if [ -n "$PASSWORD" ]; then
  AUTH_ARGS="-a $PASSWORD"
fi

for i in $(seq 0 $((NODES - 1))); do
  PORT=$((BASE_PORT + i))
  for attempt in $(seq 1 30); do
    if docker exec "redis-cluster-node-0" redis-cli $AUTH_ARGS -p "$PORT" ping 2>/dev/null | grep -q PONG; then
      break
    fi
    if [ "$attempt" -eq 30 ]; then
      echo "ERROR: Node on port $PORT failed to start" >&2
      exit 1
    fi
    sleep 1
  done
done

# Create cluster
docker exec "redis-cluster-node-0" redis-cli $AUTH_ARGS --cluster create $ENDPOINTS --cluster-replicas 0 --cluster-yes

# Wait for cluster to be ready
for attempt in $(seq 1 30); do
  if docker exec "redis-cluster-node-0" redis-cli $AUTH_ARGS -p "$BASE_PORT" cluster info 2>/dev/null | grep -q "cluster_state:ok"; then
    break
  fi
  if [ "$attempt" -eq 30 ]; then
    echo "ERROR: Cluster failed to become ready" >&2
    exit 1
  fi
  sleep 1
done

echo "Redis Cluster is ready: $ENDPOINTS"
echo "ports=$PORTS" >> "$GITHUB_OUTPUT"
