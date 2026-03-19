# redis-cluster-action

A GitHub Action that starts a Redis (or Valkey) Cluster for CI testing.

Uses official Docker images with `network_mode: host`, so nodes are directly accessible from the runner.

## Usage

```yaml
steps:
  - uses: fujiwara/redis-cluster-action@v0
    id: redis
    with:
      password: testpass

  - name: Verify cluster
    env:
      REDIS_HOST: ${{ steps.redis.outputs.host }}
      REDIS_PORT: ${{ steps.redis.outputs.first-port }}
      REDISCLI_AUTH: ${{ steps.redis.outputs.password }}
    run: |
      echo "Host: $REDIS_HOST"
      echo "Ports: $REDIS_PORT"
      redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" cluster info
```

### With Valkey

```yaml
  - uses: fujiwara/redis-cluster-action@v0
    id: valkey
    with:
      image: valkey/valkey:8
      password: testpass
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `image` | Docker image to use | `redis:7` |
| `nodes` | Number of cluster nodes | `3` |
| `base-port` | Base port number (nodes use base-port, base-port+1, ...) | `16379` |
| `password` | Redis AUTH password (empty for no auth) | `""` |

## Outputs

| Name | Description | Example |
|------|-------------|---------|
| `host` | Host address | `127.0.0.1` |
| `ports` | Comma-separated list of node ports | `16379,16380,16381` |
| `first-port` | Port of the first node | `16379` |
| `password` | Password (same as input) | `testpass` |

## Requirements

- Runs on `ubuntu-latest` (or any Linux runner with Docker)
- Uses `network_mode: host`, so ports must be available on the runner

## License

MIT
