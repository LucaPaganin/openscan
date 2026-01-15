# Working with Claude Code — Getting Started Guide

This guide explains how to use the OpenScan specification documents with Claude Code for effective implementation.

---

## Repository Setup

### 1. Create the GitHub Repository

```bash
# Create a new directory
mkdir openscan
cd openscan

# Initialize git
git init

# Create initial structure
mkdir -p mobile docs/specs .github/workflows
```

### 2. Add the Spec Files

Copy these files to your repository:

```
openscan/
├── CLAUDE.md              # Development standards (root)
├── docs/
│   ├── ROADMAP.md         # Overall project roadmap
│   └── specs/
│       └── E1-project-setup.md
```

### 3. Push to GitHub

```bash
git add .
git commit -m "chore: initial project structure with specs"
git remote add origin git@github.com:YOUR_USERNAME/openscan.git
git push -u origin main
```

---

## How to Use Claude Code

### Starting a Session

When you open Claude Code in your project directory, it will automatically read `CLAUDE.md` and understand your development standards.

### Implementing an Epic

**Step 1: Point Claude Code to the spec**

```
@claude Read docs/specs/E1-project-setup.md and implement it following the 
implementation order. Start with step 1.
```

**Step 2: Let it work incrementally**

Claude Code will:
- Create files and folders
- Write code
- Run commands
- Ask for clarification when needed

**Step 3: Review and commit**

After each logical unit:
```
@claude Commit this with message "feat(setup): implement theme system"
```

Or commit manually if you prefer more control.

### Best Practices for Prompting

**Be specific about what to implement:**
```
# ✅ Good
@claude Implement US-1.3 (Riverpod setup) from the E1 spec

# ❌ Vague
@claude Set up state management
```

**Reference the spec directly:**
```
# ✅ Good
@claude Following E1-project-setup.md, create the folder structure as specified in US-1.2

# ❌ Bad
@claude Create a folder structure for Flutter
```

**Ask for tests explicitly:**
```
@claude Now write tests for the StorageService. Remember CLAUDE.md requires 
two opposite scenarios: success case and failure case.
```

**Checkpoint frequently:**
```
@claude Before moving to the next user story, run flutter analyze and 
flutter test to verify everything passes.
```

---

## Session Workflow

### Recommended Flow for Each Epic

```
┌─────────────────────────────────────────────────┐
│ 1. START SESSION                                │
│    "Read the E[N] spec and CLAUDE.md"           │
└─────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│ 2. IMPLEMENT USER STORY                         │
│    "Implement US-X.Y from the spec"             │
└─────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│ 3. VERIFY                                       │
│    "Run tests and linting"                      │
└─────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│ 4. COMMIT                                       │
│    "Commit with conventional message"           │
└─────────────────────────────────────────────────┘
                     │
                     ▼
            Repeat for next US
```

### Example Session for E1

```bash
# Session 1: Project initialization
@claude Read docs/specs/E1-project-setup.md and CLAUDE.md. 
Start implementing from step 1 of the implementation order: 
create root folder structure and .gitignore

# After completion
@claude Run flutter pub get and verify no errors. Then commit.

# Continue
@claude Now implement step 4: set up folder structure in Flutter

# And so on...
```

---

## Handling Issues

### If Claude Code Gets Stuck

```
@claude Stop. Let's review what we have so far. Run flutter analyze 
and show me any errors.
```

### If Tests Fail

```
@claude The test for [X] is failing. Show me the error and fix it. 
Remember to maintain both success and failure test cases.
```

### If You Need to Deviate from Spec

```
@claude I want to change US-1.4 to use auto_route instead of go_router. 
Update the implementation accordingly but keep the same acceptance criteria.
```

### If You're Unsure About Something

Ask Claude Code to explain before implementing:
```
@claude Before implementing US-1.3, explain how Riverpod code generation 
works and what files will be created.
```

---

## File Naming Convention for Specs

As you progress through epics:

```
docs/specs/
├── E1-project-setup.md        ✅ (exists)
├── E2-camera-module.md        (you'll create next)
├── E3-local-gallery.md
├── E4-edge-detection.md
├── E5-manual-corner-adjust.md
├── E6-perspective-correction.md
├── E7-image-enhancement.md
├── E8-multipage-pdf.md
└── ...
```

---

## Updating the Roadmap

After completing each epic, update `docs/ROADMAP.md`:

```markdown
| E1 | ✅ Complete | 2025-XX-XX | 2025-XX-XX | |
```

---

## Tips for Success

1. **Don't rush** — Let Claude Code complete one user story before starting the next
2. **Verify often** — Run `flutter analyze` and `flutter test` frequently
3. **Read the output** — Claude Code explains what it's doing; understand it
4. **Commit atomically** — Small, focused commits make debugging easier
5. **Trust the spec** — If something seems wrong, check the spec first
6. **Ask questions** — Use Claude (this chat) to clarify specs before implementing

---

## Getting Help

- **Spec clarification**: Ask me (Claude in this chat) before starting implementation
- **Implementation issues**: Work through them with Claude Code
- **Architecture decisions**: Discuss here first, then update specs if needed

Good luck with OpenScan! 🚀
