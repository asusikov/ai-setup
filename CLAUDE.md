See PROJECT.md for project description.

## Stack
The language used to build the application is Golang. The BubbleTea framework is used to create the user interface. The Cobra library is used to organize commands and their parameters. Use table tests for unit-testing.

## Key commands
- `go run .` — run application
- `go test ./...` — run tests

## Conventions
The business domain has its own package. Implement business logic in separate structs called "use-cases" — don't put it in commands. Use dependency inversion to make modules with low cohesion. The test coverage of use-cases should be no lower than 80%.

## Constraints
Don't change project structure without direct commands.
