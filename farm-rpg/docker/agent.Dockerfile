# Agent-Sandbox: Godot (headless) + Git + aider + gdtoolkit
# Basis-Image mit Godot; Version über GODOT_VERSION (muss als Tag existieren).
ARG GODOT_VERSION=4.3
FROM barichello/godot-ci:${GODOT_VERSION}

ARG UID=1000
ARG GID=1000

RUN apt-get update \
 && apt-get install -y --no-install-recommends git python3 python3-venv python3-pip ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# aider und gdtoolkit (gdformat/gdlint) in eigenem venv
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir aider-chat gdtoolkit
ENV PATH="/opt/venv/bin:${PATH}"

# Nicht-Root-Benutzer, passend zur Host-UID für die gemounteten Dateien
RUN (id -u ubuntu >/dev/null 2>&1 && userdel -r ubuntu || true) \
 && (getent group ${GID} >/dev/null || groupadd -g ${GID} agent) \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash agent \
 && git config --system --add safe.directory /work \
 && git config --system user.name "dev-agent" \
 && git config --system user.email "agent@localhost"

USER agent
WORKDIR /work
CMD ["bash"]
