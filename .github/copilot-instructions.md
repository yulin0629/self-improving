# Copilot Instructions

Also read `CLAUDE.md` at repo root for project context.

## Versioning (CRITICAL)

Modifying functional files (`hooks/`, `skills/`, `assets/`) requires a version bump
in the **same commit**:

- `.claude-plugin/plugin.json` — `"version"` field
- `.claude-plugin/marketplace.json` — `"version"` field

Both files MUST have the same version. Follow semver:

- **patch**: bug fix, docs
- **minor**: new feature, backward-compatible
- **major**: breaking changes
