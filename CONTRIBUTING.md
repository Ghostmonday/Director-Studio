# Contributing to DirectorStudio

## Branch Naming

Use the format: `type/task-name`

### Types:
- `feature/` - New functionality
- `fix/` - Bug fixes
- `refactor/` - Code restructuring
- `docs/` - Documentation changes
- `style/` - Formatting and style changes
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks

### Examples:
```
feature/multi-clip-generation
fix/orphan-clip-cleanup
refactor/repository-caching
docs/api-setup-guide
```

## Commit Message Format

Use the format: `type/scope: description`

### Types:
- `feature` - New functionality
- `fix` - Bug fixes
- `refactor` - Code restructuring without changing behavior
- `docs` - Documentation changes
- `style` - Formatting, spacing, etc. (no code change)
- `test` - Adding or updating tests
- `chore` - Maintenance tasks

### Scope (optional):
The area of code affected (e.g., `prompt`, `storage`, `repository`, `ui`)

### Examples:
```
feature/prompt: Add multi-clip generation support
fix/storage: Resolve orphan clip cleanup issue
refactor/repository: Improve ClipRepository caching logic
docs/readme: Update setup instructions
style: Fix spacing and import ordering
```

## Code Style

### Swift Formatting:
- Use 4 spaces for indentation
- Maximum line length: 120 characters
- One blank line between type definitions
- Consistent spacing around operators and braces

### Import Ordering:
1. Foundation/system imports
2. Third-party imports
3. Local app imports

### Naming Conventions:
- Types: PascalCase (`ClipRepository`, `FilmGeneratorViewModel`)
- Variables/Functions: camelCase (`clipCache`, `generateVideo`)
- Constants: camelCase with static/let (`let maxRetries = 3`)
- Private properties: camelCase with leading underscore or `private` keyword

### Documentation:
- All public APIs should have doc comments
- Use `///` for documentation comments
- Include parameter descriptions and return values

## Pull Request Process

1. Create a branch following the naming convention
2. Make your changes with clear commit messages
3. Ensure code passes linting (no warnings)
4. Update documentation if needed
5. Submit PR with clear description

