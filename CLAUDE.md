See PROJECT.md for project description.

## Stack

The language used to build the application is Golang. The BubbleTea framework is used to create the user interface. The Cobra library is used to organize commands and their parameters. Use table tests for unit-testing.

## Key commands
    
- `go run .` - run application
- `go test ./...` - run tests
- `go test ./... -coverprofile` - run tests with coverage
- `gh issue view ${issue_number} --json body --jq '.body'` - get brief from github issue 

## Conventions

The business domain has its own package. Implement business logic in separate structs called "use-cases" — don't put it in commands. Use dependency inversion to make modules with low cohesion. The test coverage of use-cases should be no lower than 80%.

## Constraints
    
Don't add top level folders what are not described in project structure.

## References

`.agents/specs` - memory bank with specifications and plans for tasks. The each task has subfolder with `<TASK_NUMBER>-<TASK_NAME>` name
`.agents/prompts` - prompts for SDD 
`docs/development` - development's conventions
