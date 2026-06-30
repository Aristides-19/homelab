# Skill Quality Checklist

Run this audit before finalizing any Skill.

## Core Quality
- [ ] **Location**: Skill is placed in `.agents/skills/[skill-name]/`, not in editor-specific directories.
- [ ] **Frontmatter Name**: Lowercase, hyphens only, <64 chars (e.g., `writing-code`).
- [ ] **Frontmatter Description**: 3rd person, specific, includes "when to use".
- [ ] **Conciseness**: No "educational" fluff (e.g., explaining what a PDF is).
- [ ] **File Depth**: References are only one level deep from `SKILL.md`.
- [ ] **Paths**: All file paths use forward slashes (`/`), not backslashes.

## Code & Scripts (If applicable)
- [ ] **Error Handling**: Scripts handle errors explicitly; they do not punt to the agent.
- [ ] **Dependencies**: Required packages are listed.
- [ ] **Constants**: No "magic numbers" or undefined variables.

## Best Practices
- [ ] **Degrees of Freedom**: Specificity matches the fragility of the task.
- [ ] **Terminology**: Terms are consistent (e.g., always "field", never switching to "box").
- [ ] **Workflows**: Complex tasks include a checklist for the agent to track progress.