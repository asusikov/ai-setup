# Project structure

### cmd/

Main applications for project. Each subfolder contains a `main.go` entry point (e.g., `cmd/ai-setup/`).

### internal/

Business logic, ports/adapters, and CLI commands.

#### internal/cmd/

Cobra command definitions.

#### internal/domain/

Domain use-cases and business logic.

### pkg/

Any helpers or common code.

### schemas/

OpenAPI and other API schema files, organized by service name (e.g., `schemas/gitlab/`).
