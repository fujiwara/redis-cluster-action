# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A GitHub composite action that starts a Redis or Valkey Cluster for CI testing using official Docker images with `network_mode: host`.

## Security

**Never interpolate `${{ inputs.* }}` or `${{ github.* }}` directly into `run:` shell commands in GitHub Actions.** This creates shell injection vulnerabilities. Always pass values via `env:` and reference them as environment variables in the script.

Bad:
```yaml
run: echo "${{ inputs.password }}"
```

Good:
```yaml
env:
  PASSWORD: ${{ inputs.password }}
run: echo "$PASSWORD"
```

## Testing

CI runs on push/PR with a matrix of redis:7, redis:8, valkey/valkey:7, valkey/valkey:8 (`fail-fast: false`).
