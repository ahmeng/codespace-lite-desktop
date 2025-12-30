# Based on the official VS Code devcontainer base image for Ubuntu 22.04
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install desktop, xrdp, openssh-server, supervisor, and utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal xfce4-goodies \
    xrdp \
    openssh-server \
    supervisor \
    dbus-x11 x11-xserver-utils \
    pulseaudio pulseaudio-utils \
    wget ca-certificates sudo iproute2 iputils-ping \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure /var/run/sshd exists
RUN mkdir -p /var/run/sshd

# Configure SSH to listen on 2222
RUN sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config || echo 'Port 2222' >> /etc/ssh/sshd_config
RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config || true
RUN sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config || true

# Configure xrdp to use xfce
RUN /bin/bash -c "echo 'startxfce4' > /etc/skel/.xsession"
RUN sed -i 's|/etc/X11/Xsession|/etc/X11/Xsession|' /etc/xrdp/startwm.sh || true
RUN sed -i '/^test -x/,$d' /etc/xrdp/startwm.sh || true
RUN printf '#!/bin/sh\nstartxfce4\n' > /etc/xrdp/startwm.sh
RUN chmod +x /etc/xrdp/startwm.sh

# Create a passwd for the vscode user to allow quick SSH/RDP testing (CHANGE THIS in production)
RUN usermod -aG sudo vscode \
 && echo "vscode:vscode" | chpasswd

# Allow passwordless sudo for vscode so postStart scripts can start services
RUN echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode && chmod 0440 /etc/sudoers.d/vscode

# Ensure the vscode user has a .xsession (if not present)
RUN mkdir -p /home/vscode && chown vscode:vscode /home/vscode \
 && cp /etc/skel/.xsession /home/vscode/.xsession || true \
 && chown vscode:vscode /home/vscode/.xsession || true

# Copy supervisord config
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Copy scripts so they are available during postCreate/postStart
COPY scripts /usr/local/bin/devcontainer-scripts
RUN chmod -R a+rx /usr/local/bin/devcontainer-scripts

# Expose the service ports (devcontainer.json will forward them)
EXPOSE 2222 3389

# Start supervisord as PID 1 so services come up automatically
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]