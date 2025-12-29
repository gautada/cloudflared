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


