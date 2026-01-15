# CLAUDE.md — OpenScan Development Standards

This file defines the development workflow and standards for the OpenScan project. These rules apply to ALL epics and features.

---

## Core Principle: Always Testable

The codebase must be **runnable and testable at any point in development**. Never leave the project in a broken state.

### Rules

1. **No broken commits** — Every commit must pass linting and all existing tests
2. **Incremental implementation** — Build features in small, working increments
3. **Run before commit** — Always run `flutter analyze` and `flutter test` (mobile) or `uv run ruff check` and `uv run pytest` (backend) before committing

---

## Testing Requirements

### Mandatory: Two-Scenario Testing

Every new implementation must include tests covering **at least two opposite scenarios**:

| Scenario Type | Description | Example |
|---------------|-------------|---------|
| **Happy path** | Expected input, successful outcome | Valid image → edge detection succeeds |
| **Failure path** | Invalid input, error handled gracefully | Corrupted file → returns error, no crash |

### Examples by Feature Type

**UI Component:**
- ✅ Renders correctly with valid data
- ✅ Shows error/empty state when data is missing or invalid

**Service/Repository:**
- ✅ Returns expected result on success
- ✅ Throws/handles appropriate exception on failure

**API Endpoint:**
- ✅ Returns 200 with valid request
- ✅ Returns 4xx/5xx with invalid request, proper error message

**State Provider:**
- ✅ State updates correctly on valid action
- ✅ State handles edge cases (empty, null, overflow)

### Test Naming Convention

Use descriptive names that state the scenario:

```dart
// Flutter/Dart
test('detectEdges returns four corners when document is visible', () { ... });
test('detectEdges throws NoDocumentException when image is blank', () { ... });
```

```python
# Python
def test_process_image_returns_corners_for_valid_document():
    ...

def test_process_image_raises_error_for_corrupted_file():
    ...
```

---

## Code Organization

### Flutter (Mobile)

Follow **feature-first** architecture:

```
lib/
├── features/
│   └── [feature_name]/
│       ├── presentation/    # UI (screens, widgets)
│       ├── domain/          # Business logic, entities
│       └── data/            # Repositories, data sources
```

- **Presentation** depends on **Domain**
- **Domain** has no dependencies on other layers
- **Data** implements **Domain** interfaces

### Python (Backend)

Follow **layered** architecture:

```
app/
├── api/routes/      # HTTP endpoints
├── services/        # Business logic
├── models/          # Data models (Pydantic)
└── core/            # Config, shared utilities
```

---

## Commit Standards

### Message Format

```
<type>(<scope>): <short description>

[optional body]
```

**Types:** `feat`, `fix`, `test`, `refactor`, `docs`, `chore`

**Examples:**
- `feat(camera): add capture button with haptic feedback`
- `fix(edge-detection): handle low-contrast images`
- `test(gallery): add tests for empty state`

### Commit Cadence

- One logical change per commit
- Each user story should be 1-3 commits
- Never commit failing tests

---

## Dependencies

### Adding New Dependencies

Before adding a dependency:
1. Check if the functionality exists in current dependencies
2. Verify the package is actively maintained (last update < 6 months)
3. Check for known vulnerabilities
4. Prefer packages with null safety (Flutter) and type hints (Python)

### Version Pinning

- **Flutter**: Use caret syntax `^1.2.3` for minor version flexibility
- **Python**: Use `uv` with `pyproject.toml` and `uv.lock` for dependency management

### Python Dependency Management (Backend)

The backend **must** use `uv` as the package manager:

1. **`pyproject.toml`** — Define all dependencies here (not in `requirements.txt`)
2. **`uv.lock`** — Lock file for reproducible builds (auto-generated, commit to repo)
3. **Never use `pip install` directly** — Always use `uv add <package>` or `uv sync`

**Common commands:**
```bash
# Install all dependencies from lock file
uv sync

# Add a new dependency
uv add <package>

# Add a dev dependency
uv add --dev <package>

# Update dependencies
uv lock --upgrade

# Run a command in the virtual environment
uv run pytest
uv run ruff check
```

**Pre-commit workflow:**
```bash
uv run ruff check
uv run pytest
```

---

## Error Handling

### Flutter

- Use custom exception classes in `lib/core/errors/`
- Never swallow exceptions silently
- Always provide user-friendly error messages in UI

```dart
// ✅ Good
try {
  await processImage(file);
} on ImageProcessingException catch (e) {
  state = ErrorState(message: e.userMessage);
}

// ❌ Bad
try {
  await processImage(file);
} catch (e) {
  // silent failure
}
```

### Python

- Use FastAPI's `HTTPException` for API errors
- Log exceptions with context
- Return structured error responses

```python
# ✅ Good
@router.post("/process")
async def process_image(file: UploadFile):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
```

---

## Documentation

### Code Comments

- Explain **why**, not **what**
- Document complex algorithms
- Add TODO comments with ticket/issue references

### README Updates

Update `README.md` when:
- Adding new setup steps
- Changing environment variables
- Adding new dependencies that require system-level installation

---

## Pre-Implementation Checklist

Before implementing any feature, verify:

- [ ] I understand the acceptance criteria
- [ ] I know what two test scenarios I will write
- [ ] I have identified which layer(s) this affects
- [ ] The project currently builds and all tests pass

---

## Questions?

If requirements are unclear or conflicting, **ask before implementing**. Do not make assumptions about business logic.
