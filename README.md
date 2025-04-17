# jdev - Java Development Container

A comprehensive development container for Java, Docker, and Kubernetes development. This Docker image provides a complete, isolated environment for developing Java applications with modern tooling and cloud integration capabilities.

## 📋 Features

- **Base Environment**: Ubuntu 22.04 LTS with essential development tools
- **Java Toolchain**: Complete JDK 21, Maven 3.9.9, and Gradle 8.13 setup
- **Container Orchestration**: Docker CLI and Kubernetes (kubectl) integration
- **JavaScript Support**: Node.js 22.2.0 via NVM with TypeScript
- **Dev Convenience**: Pre-configured with useful aliases, bash completion, and syntax highlighting

## 🚀 Usage

### Basic Usage

```bash
docker run -it --rm brakmic/jdev:latest
```

### With Docker Socket for Docker-in-Docker

```bash
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  brakmic/jdev:latest
```

### As VS Code DevContainer

This image is designed to work seamlessly with VS Code's Remote - Containers extension. Create a devcontainer.json file:

```json
{
  "name": "Java Development",
  "image": "brakmic/jdev:latest",
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ],
  "remoteUser": "jdev",
  "containerEnv": {
    "NODE_OPTIONS": "",
    "HOST_WORKSPACE": "${localWorkspaceFolder}"
  }
}
```

## 🔧 Tools & Versions

| Tool                | Version           | Path                                |
|---------------------|-------------------|------------------------------------|
| Ubuntu              | 22.04 (Jammy)     | -                                  |
| JDK                 | 21 (OpenJDK)      | /usr/lib/jvm/java-21-openjdk-amd64 |
| Maven               | 3.9.9             | /opt/maven                         |
| Gradle              | 8.13              | /opt/gradle                        |
| Node.js             | 22.2.0            | Via NVM                            |
| Docker CLI          | Latest            | -                                  |
| kubectl             | Latest stable     | /usr/local/bin/kubectl             |
| Git + Git LFS       | Latest            | -                                  |
| Python              | 3                 | -                                  |
| PostgreSQL Client   | Latest            | -                                  |

## 💻 User Configuration

- Default non-root user: `jdev`
- User has sudo access
- Pre-configured with helpful aliases and bash completion
- Nano editor with syntax highlighting

## 🔄 Kubernetes Integration

The container includes kubectl for Kubernetes cluster management:

- Downloaded directly from official Kubernetes source
- Validated with SHA256 checksum
- Configured with bash completion
- Alias `k` for faster typing

## 🛠️ Customization

### Change Default User

Build the image with a different username:

```bash
docker build --build-arg NONROOT_USER=yourname -t custom-jdev .
```

### Accessing Kubernetes from Inside the Container

When using with Docker Desktop or other local Kubernetes:

1. Copy your Kubernetes config inside the container
2. Modify server addresses to use appropriate host names:
   - Docker Desktop: `docker-for-desktop`
   - KinD: `desktop-control-plane`

## 📚 Use Cases

- Java application development with Maven or Gradle
- Docker container development and testing
- Kubernetes deployment and management
- Full-stack development with Java backend and Node.js frontend
- CI/CD pipeline development and testing

## 🔒 Security Notes

- Container uses a non-root user by default
- Docker socket mounting requires proper host security considerations
- No sensitive credentials are baked into the image

---

Built with ❤️ for streamlining Java development workflows
