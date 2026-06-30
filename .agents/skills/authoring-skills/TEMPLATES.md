# Skill Templates

## Standard SKILL.md Structure

Use this skeleton for new Skills:

```markdown
---
name: [gerund-action-name]
description: [Third-person description of what it does and WHEN to use it. Max 1024 chars.]
---

# [Skill Name]

## Quick Start

[Most common usage pattern or script command]

## Instructions

[Concise, step-by-step guide]

## Reference

**Advanced Features**: See [ADVANCED.md](ADVANCED.md)
**API Schema**: See [SCHEMA.md](SCHEMA.md)

```

## Directory Structure

Create each skill in its own directory under `.agents/skills/`:

```
.agents/skills/
├── my-skill-name/
│   ├── SKILL.md
│   ├── TEMPLATES.md (optional)
│   └── CHECKLIST.md (optional)
└── another-skill/
    └── SKILL.md
```

**Important**: Never create skills directly in editor-specific directories. Always use `.agents/skills/`.

## Writing Descriptions

**Rule**: Always use third person. Describe triggers.

* **Bad**: "I can help you analyze data."
* **Good**: "Analyzes CSV datasets and generates statistical summaries. Use when the user provides raw data files."

## Progressive Disclosure Patterns

**Pattern 1: High-level guide**
Keep the main file simple. Link to ONE level of depth.

```markdown
# Main File
For error codes, see [ERRORS.md](ERRORS.md).

```

**Pattern 2: Domain-specific**
Organize by topic to avoid loading irrelevant tokens.

```markdown
# Main File
**Sales Data**: See [sales.md](sales.md)
**Finance Data**: See [finance.md](finance.md)

```