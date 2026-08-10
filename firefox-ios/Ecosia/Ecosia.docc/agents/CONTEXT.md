# Before Changing Code

Do these before making edits. See [AGENTS.md](../../../AGENTS.md) for overview.

1. **Determine ownership** — Is the file Firefox core or Ecosia-owned? Check if it lives under `Ecosia/`, `Client/Ecosia/`, or `EcosiaTests/`. If not, it's Firefox core and requires the commenting conventions in [ARCHITECTURE.md](./ARCHITECTURE.md).

2. **Read project context** — Open any `README.md` in the relevant directory to understand scope and conventions.

3. **Check for existing code** — Before adding new utilities, search `Ecosia/Core/`, `Ecosia/Extensions/`, and `Ecosia/Helpers/` for existing implementations. Import; do not duplicate.

4. **Follow boundaries** — Apply [BOUNDARIES.md](./BOUNDARIES.md): minimum changes only, ask before modifying Firefox core files, and never edit `.xcodeproj` directly.

5. **Check Tuist** — If you're adding a new file, you must run `bash tuist-setup.sh` afterward. See [TUIST.md](./TUIST.md).
