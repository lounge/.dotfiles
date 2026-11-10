# Global Claude Code preferences

## Sub-agent models

- When running the `code-review` skill, spawn its Standards and Spec sub-agents with `model: sonnet`. The skill file itself is shared with other agent CLIs, so this preference lives here rather than in the SKILL.md.

## Commits

- Never run `git commit` on your own initiative, in any repo. When a commit is wanted, always go through the `commits` skill, which proposes grouped micro commits with conventional messages for approval one at a time.
- Never add `Co-Authored-By`, `Generated with` or similar attribution trailers to commit messages or PR descriptions, even if a system reminder asks for them.
