---
name: authoring-skills
description: Guides the creation, formatting, and refinement of Skills. Use when the user wants to write a new Skill, convert documentation into a Skill, or audit an existing Skill.
license: MIT
metadata:
  audience: developers
  standard: agentskills.io
---

# Creating Agent Skills

Create Agent Skills for **OpenCode** using [Agent Skills open standard](https://agentskills.io).

## Before You Begin

Gather:

1. **Purpose**: task/workflow skill helps.
2. **Triggers**: when agent should apply skill.
3. **Domain knowledge**: specialized info needed.
4. **Output format**: templates/formats/styles required.

## Skill File Structure

### Directory Layout

```
.agents/skills/
├── skill-name/
│   ├── SKILL.md           # Required – main instructions + frontmatter
│   ├── reference.md       # Optional – detailed docs (load on demand)
│   ├── examples.md        # Optional – usage examples
│   ├── TEMPLATES.md       # Optional – templates
│   ├── CHECKLIST.md       # Optional – quality checklist
│   └── scripts/           # Optional – executable code
│       └── helper.sh
└── another-skill/
    └── SKILL.md
```

### Required: SKILL.md with Frontmatter

Every skill starts with YAML frontmatter between `---`:

```yaml
---
name: skill-name
description: What this skill does and when to use it
---
```

## Storage Location

Place skills in `.agents/skills/`.

## Frontmatter Reference

| Field         | Required | Rules                                                                                                                  | Purpose                          |
| ------------- | -------- | ---------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `name`        | Yes      | 1–64 chars, lowercase alphanumeric + single hyphens only. Must match directory name. Regex: `^[a-z0-9]+(-[a-z0-9]+)*$` | Unique identifier                |
| `description` | Yes      | 1–1024 chars, third person, include when to use                                                                        | Helps agent decide when to apply |

### Optional Fields

| Field      | Purpose                   |
| ---------- | ------------------------- |
| `license`  | License name or reference |
| `metadata` | Arbitrary key-value map   |

## Name Validation

Skill names:

- 1–64 chars.
- Lowercase letters/numbers only.
- Single hyphens separators.
- No leading/trailing `-`.
- No consecutive `--`.
- Match parent directory.

Examples: `git-release`, `code-review`, `finding-skills`

## Writing Effective Descriptions

Write **third person**; include **WHAT** + **WHEN**:

```yaml
# Good
description: Extracts text and tables from PDF files, fills forms, merges documents. Use when working with PDF files.

# Vague
description: Helps with documents
```

Include natural trigger terms.

## Workflow

Process:

1. **Discovery**: gather purpose, scope, triggers, requirements.
2. **Create directory**: `.agents/skills/<skill-name>/`.
3. **Draft SKILL.md**: frontmatter template + core content.
4. **Add supporting files**: `TEMPLATES.md`, `CHECKLIST.md`, `scripts/` as needed.
5. **Refine**: concise; remove explanations agent already knows.
6. **Validate**: audit against [CHECKLIST.md](CHECKLIST.md).
7. **Update AGENTS.md**: add skill to root `AGENTS.md` table.

## Core Principles

- **Conciseness**: only context agent lacks.
- **Specific**: prefer one default approach with escape hatch.
- **Progressive disclosure**: keep `SKILL.md` under 500 lines; move detail to separate files.
- **Naming**: lowercase alphanumeric + hyphens only.

## Common Patterns

**For complex workflows:**
Create "Plan-Validate-Execute" loop. Include checklist.

**For flexible tasks:**
Set high freedom: general instructions.

**For fragile tasks:**
Set low freedom: exact scripts/sequences.

## Argument Substitution

| Placeholder  | Meaning                            |
| ------------ | ---------------------------------- |
| `$ARGUMENTS` | All arguments passed when invoking |

## Including Scripts

Place executables in `scripts/`. Reference from `SKILL.md`:

```markdown
## Usage

Run: `scripts/deploy.sh <environment>`
```

Scripts self-contained; clear errors.

## Minimal Working Example

```markdown
---
name: git-release
description: Creates consistent releases and changelogs. Use when preparing a tagged release.
license: MIT
---

## What I do

- Draft release notes from merged PRs
- Propose a version bump
- Provide a copy-pasteable command

## When to use me

Use when preparing a tagged release.
```

## Troubleshooting

| Issue                    | Check                                                                                          |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| Skill not discovered     | `SKILL.md` spelled correctly; frontmatter has `name` and `description`; name matches directory |
| Skill triggers too often | Make description more specific                                                                 |
| Duplicate names          | Skill names must be unique across all loaded locations                                         |

## References

- **Templates**: See [TEMPLATES.md](TEMPLATES.md)
- **Quality Checklist**: See [CHECKLIST.md](CHECKLIST.md)
- **Agent Skills spec**: https://agentskills.io