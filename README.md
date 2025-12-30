# codespace-lite-desktop

This repository contains a devcontainer that launches a lightweight desktop environment inside a Codespace (or any devcontainer), runs SSH and RDP servers automatically, and exposes/forwards the ports so you can connect:

- SSH: container listens on port `2222` (forwarded by Codespaces)
- RDP: xrdp listens on port `3389` (forwarded by Codespaces)

Features
- Installs Xfce (lightweight desktop), xrdp, OpenSSH server, supervisord.
- Starts and supervises sshd, xrdp-sesman, and xrdp.
- Automated SSH public key injection via:
  - Codespaces repository secret `SSH_PUBLIC_KEY` (recommended), or
  - `.devcontainer/authorized_keys` file committed to the repo.
- postStart hook verifies and starts ssh/xrdp after the Codespace finishes starting.
- Forwarded ports configured in `devcontainer.json`.

Security notes
- The container includes a default password (`vscode:vscode`) for convenience. Prefer SSH keys and remove/replace the password before sharing access.
- For production or shared environments, restrict sudo, disable password auth in SSH after adding keys, and follow security best practices.

Quick start
1. Create a repository and add these files (or ask me to push them if you provide repo owner/name).
2. Open the repository in a Codespace (or locally use "Remote - Containers: Reopen in Container").
3. Wait for the container to build and start. postCreate will add an SSH key if provided, and postStart will ensure ssh/xrdp are running.
4. In the Codespaces UI open the "Ports" view to see forwarded ports (2222 and 3389).
5. Connect:
   - SSH: `ssh -p <forwarded_port> vscode@localhost` (use your injected key or password `vscode`)
   - RDP: Connect an RDP client to `localhost:<forwarded_port>`

Files
- .devcontainer/devcontainer.json — devcontainer config (build, forward ports, postCreate/postStart)
- .devcontainer/Dockerfile — builds the image (Xfce, xrdp, sshd, supervisord)
- .devcontainer/supervisord.conf — supervisord config for services
- .devcontainer/scripts/add_ssh_key.sh — installs SSH public key from secret or repo file
- .devcontainer/scripts/ensure_services.sh — ensures ssh/xrdp are running after Codespace start
- .devcontainer/authorized_keys.example — example keys file to place in the repo

If you'd like, I can:
- Push these files to a new GitHub repo for you (give me owner/repo), or
- Narrow the sudoers permissions to only allow starting ssh/xrdp (more secure), or
- Automatically disable PasswordAuthentication in SSH once a key is installed.