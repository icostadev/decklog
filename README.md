# Decklog

**Agentic project management in plaintext.** Objectives, milestones, and tasks live as
[OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
markdown bundles in a git repo, and are executed by Claude Code agents. A native macOS
app; git is the database.

<!-- Add a screenshot at docs/screenshot.png, then uncomment:
![Decklog board and PM chat](docs/screenshot.png) -->
_Screenshot coming soon._

## How it works

- **Your work is plaintext.** Every objective, project, milestone, and task is one
  markdown file with YAML frontmatter — an OKF bundle in a git repo. The files are the
  single source of truth; the app is a projection over them.
- **You plan by chatting.** A **PM agent** (a headless Claude Code process scoped to the
  bundle) creates and updates the work from a chat panel. The UI is read-only — all
  content is authored by the agent, and every change is a git commit.
- **Agents do the work.** You dispatch a `ready` task to a background **Claude Code**
  executor running in its own git worktree; it does the work and opens a PR. *(Execution
  is Iteration 3 — in progress.)*
- **You stay in control.** The app never merges. A task is `done` only after you've
  merged its PRs.

See [`docs/DESIGN.md`](docs/DESIGN.md) for the full design, data model, and the
six-iteration delivery plan.

## Status

| | |
|---|---|
| ✅ **Iteration 1** | Read-only kanban board over a bundle (markdown-rendered tasks, project scoping, validation panel). |
| ✅ **Iteration 2** | PM chat agent — plan and reshape the board by conversation; edits are committed and the board reloads. |
| 🔜 **Iteration 3** | Dispatch a task to a Claude Code executor in a git worktree (the core thesis). |
| ⬜ Iterations 4–6 | Concurrent executors + safety rails · agent decomposition + knowledge · objectives & roadmap. |

## Layout

```
OKFKit/         Swift package — the OKF bundle core (parse / validate / round-trip /
                git). Cross-platform and unit-tested.
app/            Swift package — the SwiftUI macOS app (target: Decklog). macOS only.
sample-bundle/  A hand-authored OKF bundle used by tests and for running the app.
scripts/        build-app.sh — build + package a launchable .app.
docs/DESIGN.md  Design & data model.
```

## Requirements

- **macOS 13+** and a Swift toolchain (Xcode or the command-line tools) for the app.
- The [**Claude Code**](https://docs.claude.com/en/docs/claude-code) CLI, installed and
  authenticated — the PM agent and executors run as `claude` subprocesses using your own
  auth. Decklog stores no API keys.

## Build & test the core

Cross-platform (any Swift toolchain, no macOS needed):

```sh
cd OKFKit
swift test
```

## Build & run the app (macOS)

Package a launchable `.app`:

```sh
scripts/build-app.sh            # release → dist/Decklog.app (ad-hoc signed)
```

Or run from source (Xcode or the terminal):

```sh
open app/Package.swift          # open in Xcode, run the "Decklog" scheme
# or:
cd app && DECKLOG_BUNDLE="$(cd ../sample-bundle && pwd)" swift run Decklog
```

`DECKLOG_BUNDLE` auto-opens that bundle on launch; otherwise use **Open Bundle…** (⌘O)
and pick a bundle directory. `DECKLOG_CLAUDE_BIN` overrides the path to the `claude` CLI
if it isn't on the app's `PATH`.

> Note: the YAML round-trip preserves unknown keys and key order but not comments (a
> later-iteration concern).

## License

MIT — see [LICENSE](LICENSE).
