# cloudflared

A basic cloudeflare tunnel daemon

- Use the cloudflared package.
- Get some cfd examples

[Docker Container](https://hub.docker.com/r/cloudflare/cloudflared)
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)
[GitHub](https://github.com/cloudflare/cloudflared)


## Setup

### Secure Token

To setup you need to provide the secure token.  The token can be generated
via the cloudflare site (Cloudflare > ZeroTrust > Networks > Connectors >
{tunnel} > Configure > Refresh Token).  This token must be provided to the
container as an environment variable with the name `CLOUDFLARED_TOKEN`.

### Client Certificate

You must run a login cycle to generate the `cert.pem` file. Follow the prompts
and the cert file will be at `~/.cloudflared/cert.pem`.

```zsh
cloudflared login
```

#### Command-line

You can use the `.env` file to povide the variable to `podman run` and the
`--env-file` parameter.

### Kubernetes

Create a secret to hold the token.

```zsh
kubectl create --namespace security secret generic cloudflared \
  --from-literal=TOKEN="$(get_secret CLOUDFLARED_TOKEN)" \
  --from-file=cert.pem=./cert.pem
```

Modify the deployment's yaml config to add the environment variable

```zsh
          env:
            - name: CLOUDFLARED_TOKEN
              valueFrom:
                secretKeyRef:
                  name: cloudflared
                  key: TOKEN

```
