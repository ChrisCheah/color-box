---
name: devcontainer-generator
description: Analyze a repository and generate a production-quality Dev Container configuration for VS Code, Copilot Agent, Podman, Docker, DevPod, Kubernetes, or Azure-hosted development environments.
---

# Purpose

Generate or improve development container configurations.

The skill should:

- inspect the repository
- identify languages and frameworks
- identify build tools
- identify cloud dependencies
- identify AI tooling
- identify required VS Code extensions
- generate a complete Dev Container definition

Target runtimes:

- Podman
- Docker
- DevPod
- Kubernetes
- Azure-hosted development environments

# Analysis Process

Inspect all available files, including:

- package.json
- package-lock.json
- yarn.lock
- pnpm-lock.yaml
- requirements.txt
- environment.yml
- pyproject.toml
- poetry.lock
- Pipfile
- Cargo.toml
- go.mod
- pom.xml
- build.gradle
- gradlew
- *.csproj
- global.json
- Dockerfile
- Containerfile
- README.md
- docs/
- scripts/
- .github/workflows
- .azuredevops
- .devcontainer

Determine:

- primary language
- runtime version
- build tools
- testing framework
- linting framework
- Azure tooling requirements
- Kubernetes tooling requirements
- AI tooling requirements

# Output

Generate:

- .devcontainer/devcontainer.json
- .devcontainer/Containerfile
- .vscode/extensions.json

Do not overwrite existing files unless improvements are necessary.

Explain all recommendations.

# Dev Container Standards

Prefer:

- Podman compatibility
- non-root containers
- debian/bookworm images
- Microsoft Dev Container base images

Always include:

- git
- curl
- jq
- unzip
- zip
- bash-completion

When Azure is detected include:

- Azure CLI
- Bicep
- Az PowerShell

When Kubernetes is detected include:

- kubectl
- helm
- k9s

When Python is detected include:

- Ruff
- Black
- Pytest

When Node is detected include:

- npm
- pnpm

When Java is detected include:

- Temurin JDK

# Special handling

If workspace contains:

- Azure Foundry
- OpenAI
- Semantic Kernel
- LangChain
- CrewAI
- Autogen
- MCP

Configure the devcontainer for AI development.

# Deliverables

Produce:

1. architecture summary
2. generated files
3. rationale
4. future improvements