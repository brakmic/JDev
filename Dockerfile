FROM ubuntu:22.04

ARG NONROOT_USER=jdev
ENV NONROOT_USER=${NONROOT_USER}
ENV HOME=/home/${NONROOT_USER}

###############################################################################
# (1) Base image setup: locale, sudo, dev tools, aliases, etc.
###############################################################################
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget gnupg software-properties-common dirmngr ca-certificates \
    unzip build-essential gcc g++ make git git-lfs nano xz-utils \
    sudo python3 python3-pip python3-distutils bash-completion locales \
    lsb-release \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

# Nano syntax highlighting
RUN mkdir -p /usr/share/nano-syntax \
    && curl -fsSL https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | bash

# Create user
RUN useradd -m -s /bin/bash ${NONROOT_USER} \
    && printf "%s ALL=(ALL) NOPASSWD:ALL\n" "${NONROOT_USER}" > /etc/sudoers.d/${NONROOT_USER} \
    && chmod 0440 /etc/sudoers.d/${NONROOT_USER}

# Shell config + friendlier aliases (less aggressive than before)
RUN cp /etc/skel/.bashrc ${HOME}/.bashrc \
    && cp /etc/skel/.profile ${HOME}/.profile \
    && printf "include /usr/share/nano-syntax/*.nanorc\n" >> ${HOME}/.nanorc \
    && printf "export EDITOR=nano\n" >> ${HOME}/.bash_profile \
    && printf "alias ll='ls -la'\nalias la='ls -A'\nalias l='ls -CF'\nalias gs='git status'\nalias ga='git add'\nalias gp='git push'\nalias gl='git log'\nalias safe-rm='rm -i'\nalias safe-cp='cp -i'\nalias safe-mv='mv -i'\nalias cp='cp --preserve=all'\nalias mv='mv'\nalias rm='rm'\nalias nano='nano -c'\nalias ..='cd ..'\nalias ...='cd ../..'\nalias ....='cd ../../..'\n" >> ${HOME}/.bash_aliases

RUN chown -R ${NONROOT_USER}:${NONROOT_USER} ${HOME}

###############################################################################
# (2) Docker CLI + Compose (for use with Docker Desktop host socket)
###############################################################################
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
    && printf "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\n" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin \
        docker-buildx-plugin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN groupadd -f docker && usermod -aG docker ${NONROOT_USER} \
    && mkdir -p ${HOME}/.docker && chown -R ${NONROOT_USER}:docker ${HOME}/.docker

###############################################################################
# (3) Install kubectl (latest stable version) via direct binary download
###############################################################################
RUN cd /tmp \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl kubectl.sha256

# Setup kubectl bash completion and alias
RUN kubectl completion bash > /etc/bash_completion.d/kubectl \
    && printf "alias k='kubectl'\n" >> ${HOME}/.bash_aliases \
    && printf "complete -o default -F __start_kubectl k\n" >> ${HOME}/.bashrc \
    && kubectl version --client

###############################################################################
# (4) Install Java tools: JDK 21, Maven, Gradle
###############################################################################
RUN apt-get update && apt-get install -y openjdk-21-jdk

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Maven
ENV MAVEN_VERSION=3.9.9
RUN wget https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -O /tmp/maven.tar.gz \
    && tar -xzf /tmp/maven.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && printf "export MAVEN_HOME=/opt/maven\nexport PATH=\$MAVEN_HOME/bin:\$PATH\n" >> /etc/profile.d/maven.sh \
    && chmod +x /etc/profile.d/maven.sh

# Gradle
ENV GRADLE_VERSION=8.13
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -O /tmp/gradle.zip \
    && unzip /tmp/gradle.zip -d /opt/ \
    && ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle \
    && printf "export GRADLE_HOME=/opt/gradle\nexport PATH=\$GRADLE_HOME/bin:\$PATH\n" >> /etc/profile.d/gradle.sh \
    && chmod +x /etc/profile.d/gradle.sh

###############################################################################
# (5) Install Node.js via NVM for JavaScript scripting support
###############################################################################
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=22.2.0

# Create NVM dir first, then install Node via NVM
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    export NVM_DIR=$NVM_DIR && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm use $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    npm install -g tsx typescript

# Persist NVM in shell for all future sessions
RUN printf "export NVM_DIR=%s\n" "$NVM_DIR" >> /etc/profile.d/nvm.sh && \
    printf '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\n' >> /etc/profile.d/nvm.sh && \
    printf "export PATH=\$NVM_DIR/versions/node/v%s/bin:\$PATH\n" "$NODE_VERSION" >> /etc/profile.d/nvm.sh && \
    chmod +x /etc/profile.d/nvm.sh

ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

###############################################################################
# (6) Final setup
###############################################################################
USER ${NONROOT_USER}
WORKDIR /workspace
CMD ["bash", "-i"]
