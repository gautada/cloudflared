# cloudflared

A basic cloudeflare tunnel daemon

- Use the cloudflared package.
- Get some cfd examples

[Docker Container](https://hub.docker.com/r/cloudflare/cloudflared)
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)
[GitHub](https://github.com/cloudflare/cloudflared)

## Setup

### General (entry & exit)

#### Client Certificate

You must run a login cycle to generate the `cert.pem` file. Follow the prompts
and the cert file will be placed in the path `~/.cloudflared/cert.pem`.

```zsh
cloudflared login
```

### Server (exit)

This server is designed to run as a kubernetes pod.

#### Secure Token

To setup you need to provide the secure token.  The token can be generated
via the cloudflare site (Cloudflare > ZeroTrust > Networks > Connectors >
{tunnel} > Configure > Refresh Token).  This token must be provided to the
container as an environment variable with the name `CLOUDFLARED_TOKEN`.

#### Kubernetes

Create a secret to hold the token and client certificate.

```zsh
kubectl create --namespace security secret generic cloudflared \
  --from-literal=TOKEN="$(get_secret CLOUDFLARED_TOKEN)" \
  --from-file=cert.pem=~/.cloudflared/cert.pem
```

Modify the deployment yaml (yaml path: `spec:template:spec:containers`)  to
add the environment variable for token and add the client certificate through
a volume. Finally the security context must be set to all the container to
use **ping** sefely.

```yaml
          env:
            - name: CLOUDFLARED_TOKEN
              valueFrom:
                secretKeyRef:
                  name: cloudflared
                  key: TOKEN
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              add: ["NET_RAW"]
          volumeMounts:
            - name: secrets
              mountPath: /mnt/volumes/secrets
              readOnly: true
 
```

Mount the secret as a volume in the deplyment yaml (yaml path:
`spec:template:spec`)

```yaml
      volumes:
        - name: secrets
          secret:
            secretName: cloudflared
            items:
              - key: cert.pem
                path: cert.pem
```

### Server (exit) — locally-managed (config file, GitOps)

Instead of a dashboard-managed token, the tunnel can run **locally-managed** from
a config file. Ingress rules and `warp-routing` then live in git (a Kubernetes
ConfigMap) instead of the Cloudflare dashboard. This mode takes precedence: if a
config file is found the container runs it and ignores `CLOUDFLARED_TOKEN`.

The container looks for the config at `/etc/cloudflared/config.yaml` (override
with `CLOUDFLARED_CONFIG`). It runs:

```zsh
cloudflared tunnel --config /etc/cloudflared/config.yaml run
```

The config references a **tunnel credentials file** (the connector's secret,
distinct from `cert.pem`). Provide it via the mounted secret and point
`credentials-file:` at it. Example `config.yaml`:

```yaml
tunnel: <TUNNEL-UUID>
credentials-file: /mnt/volumes/secrets/credentials.json
no-autoupdate: true
warp-routing:
  enabled: true          # required for WARP private-network (CIDR) routes
ingress:
  - hostname: example.gautier.org
    service: http://svc.namespace.svc.cluster.local:8080
  - service: http_status:404   # required catch-all (must be last)
```

> Note: `warp-routing.enabled` turns the feature on, but the private **CIDR
> routes** (`cloudflared tunnel route ip add <CIDR> <tunnel>`) and public
> **DNS records** (`cloudflared tunnel route dns ...`) are stored in the
> Cloudflare account, not the config file. Likewise Zero Trust resolver
> policies, Split Tunnel, and device-enrollment policies remain account state.

Kubernetes: add the credentials file to the `cloudflared` secret and mount the
ConfigMap at `/etc/cloudflared`:

```yaml
          volumeMounts:
            - name: config
              mountPath: /etc/cloudflared
              readOnly: true
            - name: secrets
              mountPath: /mnt/volumes/secrets
              readOnly: true
      volumes:
        - name: config
          configMap:
            name: cloudflared-config
        - name: secrets
          secret:
            secretName: cloudflared
            items:
              - key: cert.pem
                path: cert.pem
              - key: credentials.json
                path: credentials.json
```

### Client (enter)

The cloudflared client is also designed to run a container but can be launched
directly from the command-line

#### Command-line

To launch from the cli first install the application using homebrew.

```zsh
brew install cloudflared
```

Then to launch just run the command to access.

```zsh
cloudflared access tcp --hostname application.example.com --url tcp://0.0.0.0:6000
```

#### Container

To launch the container natively install the
[apple/container](https://github.com/apple/container) tool.

```zsh
container system start
container run --detach --name cloudflared --rm docker.io/gautada/cloudflared:dev
```

**Note:** You can use the an environment file to povide the
`CLOUDFLARED_TUNNELS` to `container` via the `--env-file` parameter.
