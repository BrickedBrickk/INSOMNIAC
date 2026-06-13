# INSOMNIAC Agent Rules

These rules apply to future Codex agents working in this repository unless the
user explicitly provides different instructions.

## Technical Constraints

- Use Godot 4.6.3.
- Use GDScript only.
- Keep all work web friendly.
- Use the Compatibility renderer.
- Do not use C#.
- Do not add native plugins.
- Do not use threads.
- Do not add VR support yet.

## Repository Discipline

- Read the existing implementation before making changes.
- Do not edit unrelated files.
- Keep changes scoped to the requested milestone.
- Preserve existing gameplay and save compatibility unless the task explicitly changes them.
- Do not rewrite working systems when a focused integration is sufficient.
- Same-live-repo agents must avoid shared files and respect files reserved by other agents.
- Never revert or overwrite changes made by another live agent.

## Verification And Handoff

- Run relevant smoke tests after gameplay or system changes.
- Run broader smoke tests when changing shared behavior.
- Report any tests that could not be run.
- List every file changed in the final summary.
- Identify merge-risk or shared files in the final summary.
- Only the user merges or pushes changes after completing a manual test.
