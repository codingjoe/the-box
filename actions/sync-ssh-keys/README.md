# SSH Authorized Key Sync

Sync the SSH keys of all repository collaborators with push or admin access to a server, so that each of them can use that server's Docker API.

The action replaces `/home/collaborator/.ssh/authorized_keys` on the server, over the `github` account.
Collaborators who lose access disappear from the file with the next run.

## Key restrictions

The `collaborator` account owns the Docker socket, so every key is restricted in `authorized_keys`:

- `command="docker system dial-stdio"` — the key can do nothing but proxy the Docker socket. The Docker CLI tunnels the socket over stdin and stdout, so the forced command needs no port forwarding.
- `permitopen="127.0.0.1:8080",permitopen="localhost:8080"` — the key may open local and dynamic forwards (`-L`, `-D`), but only to [Dozzle] on the host loopback. `permitopen` compares the requested destination literally, so `ssh -L 5000:127.0.0.1:8080 collaborator@<your-server>` and `ssh -L 5000:localhost:8080 collaborator@<your-server>` both work, and any other host or port is refused. The local port is free to choose; only the destination is pinned.
- `no-X11-forwarding`, `no-agent-forwarding`, `no-pty` — no shell, no agent, no X11.

`permitopen` sets the complete list of allowed destinations, so no other host or port is reachable.
Remote forwards (`ssh -R`) stay possible, but only on the server loopback, because `GatewayPorts` defaults to `no`.

## Usage

Add [`workflows/sync-ssh-keys.yml`](https://github.com/codingjoe/the-box/blob/main/workflows/sync-ssh-keys.yml) to your repository as `.github/workflows/sync-ssh-keys.yml`.
It syncs on a schedule and on manual dispatch.
It needs the `SSH_HOSTNAME` and `SSH_KNOWN_HOSTS` repository variables and the `SSH_PRIVATE_KEY` secret.

[dozzle]: https://dozzle.dev/
