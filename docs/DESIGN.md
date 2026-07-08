# OKF-PM — Design & Data Model (v0.1 draft)

A git-native project management tool where every objective, project, milestone, and
task is a plain markdown file. Storage is an [OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
(Open Knowledge Format) bundle; git is the database.

> **Status:** draft for discussion. Open questions are collected at the end.
> Working name "OKF-PM" is a placeholder.

---

## 1. Guiding principle: a *conformant extension* of OKF

OKF is deliberately minimal — a directory of markdown files with YAML frontmatter,
`type` as the only required field, untyped markdown links, no statuses, no schema
registry. Project management needs the opposite: typed relationships, status state
machines, assignees, dates, ordering.

We reconcile these by treating PM as a **conformant extension**:

- Every entity is a valid OKF concept. It has a `type`, and the OKF-recommended
  fields (`title`, `description`, `tags`, `timestamp`) mean what OKF says they mean.
- All PM-specific structure lives in **additional frontmatter fields**, which the
  spec explicitly allows ("producers may include additional custom fields; consumers
  must preserve unknown keys").
- **Graceful degradation is a hard requirement.** A generic OKF reader that knows
  nothing about PM must still see a valid bundle: readable files, working `index.md`
  navigation, prose bodies. It simply won't render a kanban board.

Consequence: the *canonical* source of truth is the bundle. The app is a
**projection + editor** over it, never a separate database that the files merely
export to.

---

## 2. Entity model

A hierarchy of work entities — Objective → Project → Milestone → Task — plus an
optional Key Result and supporting concepts. Each entity is one markdown file; its
**OKF Concept ID** is its path minus `.md` (e.g.
`projects/checkout-revamp/tasks/apple-pay`).

**One human user, an assistant PM agent, and dispatched executor agents.** The user
does not edit files directly — they **chat with a PM agent** that reads and writes
the OKF bundle (creating objectives, projects, tasks; updating status). Task
*execution* is done by **executor agents**: the user dispatches a `ready` task to a
background **Claude Code** instance, which does the work and reports back. The human
stays in the loop as planner (via chat) and reviewer (merging the PRs executors open).
Agents are headless **Claude Code** agents: a concept's `charter` is its system prompt,
its `tools` are Claude tools.

```
Objective ──< Project ──< Milestone ──< Task ──< (Subtask = Task with a parent Task)
   │
   └─ Key Result (measurable, attached to an Objective)     [optional OKR layer]

Supporting: Agent (PM assistant + executor profiles), Knowledge (context for
executors), Cycle (iteration), Label (tags)
```

| Entity      | `type` value | Role |
|-------------|-------------|------|
| Objective   | `objective`   | Top-level goal / outcome. Created by the user via the PM agent. Optional OKR framing. |
| Key Result  | `key-result`  | Measurable target under an Objective. Optional. |
| Project     | `project`     | A body of work delivering toward objectives. Maps to a code repo / working dir. |
| Milestone   | `milestone`   | A dated checkpoint within a project. |
| Task        | `task`        | Atomic unit of work. Recurses via `parent` for subtasks. |
| **Agent**   | `agent`       | A Claude agent profile (`model`, `charter`, `tools`). `role: pm` (the chat assistant) or `role: executor` (dispatched to run a task as a Claude Code instance). |
| **Knowledge** | `knowledge` (or any non-PM type) | A plain OKF concept under `knowledge/` — spec, decision, domain note, playbook. Authored by the PM agent; linked from a task's `## Context` and injected into executors. No search/embeddings in v1. |
| Cycle       | `cycle`       | An iteration window. |

Types are just strings (per OKF); the app interprets known ones and ignores unknown
ones rather than erroring.

---

## 3. Frontmatter schema

### 3.1 Common frontmatter fields (fields marked *task-only* apply just to Tasks)

```yaml
---
# --- OKF core / recommended (unchanged meaning) ---
type: task                       # REQUIRED (OKF)
title: "Add Apple Pay to checkout"
description: "Enable Apple Pay as a one-tap option at checkout."
tags: [payments, mobile]
timestamp: 2026-07-08T10:32:00Z  # last modified, ISO 8601

# --- PM extension: state ---
status: in_progress              # see 4. state machines
assignee: agents/backend-impl    # (task-only) executor profile used when dispatched
priority: p1                     # p0 | p1 | p2 | p3
order: "0|hzzzzz:"               # fractional rank within its list/column

# --- PM extension: dates ---
start: 2026-07-06
due: 2026-07-14

# --- PM extension: typed relationships (Concept IDs) ---
parent: projects/checkout-revamp/milestones/beta
blocked_by: [projects/checkout-revamp/tasks/pci-review]  # `blocks` is derived, not stored
relates_to: [tables/payments]    # can point at *any* OKF concept, incl. non-PM
cycle: cycles/2026-q3-s2
artifacts:                       # (task-only) all PRs/outputs produced for this task
  - "https://github.com/…/pull/482"
---
```

For a task to be **agent-executable** it must be self-contained. Two conventional
body sections carry the executable spec (fits OKF's body-heading conventions):

- `## Acceptance criteria` — the checklist the output is judged against.
- `## Context` — the PM agent's brief: prose plus markdown links to the OKF concepts
  the executor should read. This section is the **single source** for context (there is
  no separate `context:` frontmatter field); it is what gets injected — with the linked
  concepts resolved — into the executor's prompt. Because knowledge and work share one
  bundle, these links point straight at OKF concepts.

### 3.2 Per-entity additions

- **Objective:** `cycle`, optional `key_results: [ids]`. Created via the PM chat.
- **Key Result:** `objective: objectives/…`, `metric` (string), `target`, `current`,
  `unit`. Progress = `current/target`.
- **Project:** `objectives: [ids]` (what it serves), `repo` (code repo / working dir
  executors run in), `start`, `due`.
- **Milestone:** `project: projects/…`, `due` (required in practice).
- **Agent:** `model` (e.g. `claude-opus-4-8`), `role: pm | executor`,
  `charter` (→ system prompt), `tools: [bash, edit, git]` (→ Claude tools).
- **Cycle:** `start`, `end`.

### 3.3 Why typed edges live in frontmatter (and how OKF readers still cope)

Rich PM needs to answer "what blocks this?" deterministically, so the **canonical**
relationships are typed frontmatter fields. To preserve OKF's browse-by-links
experience, the app **auto-mirrors** key relationships as ordinary markdown links in
the body (e.g. a generated `## Related` section), so a plain OKF reader still
traverses the graph — it just sees untyped links, exactly as OKF intends.

---

## 4. Status state machines

Statuses are per-type. Transitions are enforced by the app, not by the file format
(a hand-edited illegal status is tolerated and surfaced as a warning, never a crash).

- **Task (agent-executed):**
  `draft → ready → in_progress → in_review → done`
  with `cancelled` (terminal) reachable from any active state. **`blocked` is not a
  status** — it is derived from unresolved `blocked_by` and shown as a badge.
  `ready` means the spec is self-contained enough to hand to an agent (has acceptance
  criteria + a `## Context` brief). A task is **dispatchable only when it is `ready` and
  all `blocked_by` are `done`** — a hard gate, not a warning (§9). `in_review` = the
  executor produced one or more PRs
  (`artifacts`). A task reaches **`done` only after a human has merged *all* related PRs
  and no work remains** — the app never merges. The transition is written by the PM
  agent (which can watch PR/merge state); the read-only UI never mutates it.
- **Milestone / Project (not dispatched, not reviewed):**
  `planned → active → done`, with `cancelled` reachable from any state. No `in_review`
  — that is task-only (you don't dispatch or merge a milestone).
- **Objective:** `draft → active → {achieved | missed}` (`missed` is not failure —
  it's an outcome, OKR-style).
- **Key Result:** derived, not set — `on_track | at_risk | done` computed from
  `current/target` and time elapsed in the cycle.

A closed parent does not force children closed; the app flags the inconsistency
instead of cascading silently (destructive-by-default is worse than a warning).

---

## 5. Directory layout

```
bundle_root/
├── index.md                      # okf_version: "0.1" + bundle metadata (only FM allowed here)
├── log.md                        # append-only change history, newest first
├── objectives/
│   └── q3-growth.md
├── projects/
│   └── checkout-revamp/
│       ├── index.md              # auto-generated project overview / listing
│       ├── project.md            # the Project concept itself
│       ├── milestones/
│       │   └── beta.md
│       └── tasks/
│           ├── apple-pay.md
│           └── pci-review.md
├── agents/
│   ├── pm.md                     # the assistant PM agent (chat) profile
│   ├── backend-impl.md           # an executor profile (model + charter + tools)
│   └── frontend-impl.md
├── knowledge/                    # specs, decisions, domain notes — linked from `## Context`
│   ├── checkout-flow.md
│   └── decisions/
│       └── apple-pay-over-stripe-link.md
└── cycles/
    └── 2026-q3-s2.md
```

- One entity per file → minimal merge-conflict surface.
- `index.md` / `log.md` are OKF-reserved; the app regenerates `index.md` and appends
  to `log.md` on every write, matching OKF's documented formats.

---

## 6. Ordering

List position uses a **fractional rank** string (`order`), not integer indices, so
reordering an item rewrites exactly **one** file and concurrent reorders rarely
conflict. (LexoRank-style keys; rebalanced lazily when they grow long.) Ordering is
set by the PM agent on request ("put X above Y") — the UI is read-only and does not
drag-to-reorder.

---

## 7. Referential integrity & validation

OKF says consumers must "tolerate broken links gracefully." We honor that *and* add
an app-level validation pass that reports (never auto-deletes):

- dangling `parent` / `blocked_by` / `assignee` frontmatter references, plus broken
  `## Context` body links (advisory — OKF tolerates broken links),
- cycles in `parent` or `blocked_by` graphs,
- unknown `status` for a given `type`,
- date sanity (`start` ≤ `due`, task `due` ≤ milestone `due`).

Validation output is advisory — the bundle is still openable with warnings.

---

## 8. Derived views (all computed from the bundle, nothing stored)

- **Board (kanban):** a **task board** — task cards grouped by task `status`, sorted by
  `order`. Projects/Milestones are **scopes / swimlanes** (view "the board for project
  X"), shown with a coarse status badge — not cards sharing the columns.
- **Objective tree / roadmap:** the `objective → project → milestone → task` hierarchy.
- **Dependency graph:** `blocked_by` edges (`blocks` is the derived inverse).
- **Timeline / Gantt:** from `start` / `due`.
- **Cycle view:** everything with a given `cycle`.
- **Agent view:** an agent's queue — tasks where it is `assignee`, by status.
- **Review queue:** tasks in `in_review` awaiting the user's approval in the UI.

---

## 9. Architecture — local, single-user app

Runs on the user's machine; the git repo (bundle) is the entire application state.
Four parts:

1. **Bundle core (Swift)** — read/write/validate the OKF bundle ↔ typed domain model.
   Round-trips markdown **preserving unknown keys, comments, and body prose** (the PM
   agent, executors, and the user all edit these files) — `Yams` for frontmatter,
   `swift-markdown` for bodies. Graph queries + the §7 validation pass. On each write it
   also regenerates `index.md` files (preserving the root's `okf_version`), appends to
   `log.md`, and refreshes the auto-mirrored `## Related` body sections (§3.3). Commits
   each logical change.

2. **PM agent (chat)** — a headless **Claude Code** subprocess (`claude -p
   --output-format stream-json`) spawned via `Process`, scoped to the bundle repo with
   a PM system prompt. The user converses with it to plan and update work; it edits the
   markdown directly (Claude Code's own file tools), and the bundle core validates and
   commits. Its transcript streams to the chat panel. This is the app's "orchestrator" —
   human-driven, not an autonomous loop.

   **It plans, it doesn't just CRUD.** On request it decomposes an objective/project
   into a proposed tree of projects/milestones/tasks, proposes `blocked_by` edges, and
   drafts each task's `## Acceptance criteria` and `## Context` brief — **authoring any
   missing `knowledge/` concepts** the context needs. Its concrete job is to move tasks
   from `draft` to `ready` (§4). Every plan is **propose → user approves/edits in chat
   → then commit**; it never re-plans unprompted. After a task finishes it can also
   capture learnings into a `knowledge/` concept (the only path for agent-produced
   knowledge in v1 — executors never write to the bundle).

3. **Executor dispatcher** — on user action ("run this task"), spawns a background
   **Claude Code** subprocess to execute one task. **Dispatch is hard-gated:** the Run
   action is available *only* when the task's `status` is `ready` **and** every
   `blocked_by` dependency is `done`; otherwise it is disabled (not a warning).
   - working dir = the project's `repo`, in a fresh **git worktree per task** so
     background/parallel runs never clobber each other or the user's checkout;
   - prompt = task title + `## Acceptance criteria` + `## Context` (the linked OKF
     concepts, injected);
   - tools = the executor profile's `tools`;
   - output = one or more PRs, recorded in the task's `artifacts` list.

   Claude Code stream events are parsed and shown live via **SwiftTerm** in the task
   detail; the dispatcher sets `in_progress` on start and `in_review` when the PR opens,
   automatically (via the bundle core — see the writer rule below). The user follows
   along or ignores it and checks back later. **Multiple executors may run
   concurrently**, each in its own worktree, managed by Swift `async`/actors; the UI
   lists all active runs.

4. **UI (SwiftUI)** — **read-only with respect to bundle content**: it never edits OKF
   files. Its only actions are executor commands (run / cancel a task); all content
   authoring goes through the PM agent.
   - **chat panel** — talk to the PM agent (the sole author of bundle content);
   - **kanban board** — the main view: a task board with columns by task `status`,
     scoped/filtered by project / milestone / cycle (§8); cards reflect `order` but
     cannot be dragged;
   - **task detail** — a **full-page** view pushed when a card is tapped (back returns
     to the board), showing the spec, live executor progress (SwiftTerm), and links to
     the task's `artifacts` (PRs). Not a persistent side pane;
   - **roadmap / objective tree** (Swift Charts for the timeline). Reviewing/merging PRs
     and marking the task `done` happen via the PM agent, not UI buttons.

**Who writes the bundle.** Two writers only, both through the bundle core: the **PM
agent** authors all content (entities, fields, hand-set status, ordering) and writes
the `done` transition; the **executor dispatcher** writes in-flight task lifecycle
transitions (`in_progress → in_review`) as bookkeeping. The UI and the human
never write directly — the human acts through chat, plus run/cancel commands.

**Runtime & stack (decided):** a **native Swift / SwiftUI macOS app** — no webview and
no bundled runtime, so it launches instantly, sips memory, and feels native. Chosen
because this is a personal, macOS-only, performance-first tool; portability was
explicitly not required. (Trade-off accepted: macOS-only — SwiftUI has no Linux/Windows
story — and UI components are hand-built rather than reused from a web stack.)

- **App:** Swift + **SwiftUI** (AppKit where needed), targeting macOS; Xcode/SwiftPM
- **Bundle core:** Swift — `Yams` (YAML frontmatter), `swift-markdown` (bodies),
  round-trip preserving unknown keys; git via `libgit2`/`SwiftGit2` or shelling to `git`
- **Concurrency:** Swift `async`/`await` + actors to manage concurrent executor
  subprocesses (`Process` + `Pipe`) and stream their output
- **Live agent output:** **SwiftTerm** (native terminal widget)
- **Markdown rendering:** `swift-markdown` / `MarkdownUI`
- **Timeline/roadmap:** Swift Charts
- **macOS integration:** menu bar, native notifications on task completion, Keychain
  for the API key, code-signing / notarization
- **Tooling:** XCTest / Swift Testing, `swift-format`, SwiftPM

**Safety rails** (executors run `bash`/`git` unattended in the background):
- one worktree/branch per task — never commit onto the user's working branch;
- a per-dispatch iteration / token / wall-clock ceiling;
- artifacts land as PRs; **the app never merges** — a human merges every PR, and only
  then can the task become `done`.

---

## 10. Decisions & open questions

### Decided
- **Storage:** OKF bundle is its **own dedicated git repo**; each Project declares a
  `repo` pointing at the code repo executors work in. One app manages many code repos.
- **Runtime/stack:** **native Swift/SwiftUI macOS app**, no webview/runtime (see §9).
  Personal, **macOS-only** tool; portability explicitly not required.
- **Agents:** both the PM agent and executors are **headless Claude Code** subprocesses
  (`claude -p`); the PM agent edits bundle markdown **directly**, and the Swift bundle
  core validates + commits (no separate agent SDK, no custom MCP server for v1).
- **Executors:** one **git worktree per task**, **multiple concurrent** runs allowed.
- **Workforce:** single human user + PM chat agent + dispatched Claude Code executors;
  no autonomous loop, no human-in-bundle entities.
- **Editing model:** the UI is **read-only** for bundle content; the **PM agent is the
  sole author** of content. The dispatcher writes in-flight task lifecycle transitions
  automatically; the human acts only through chat + run/cancel commands.
- **Done / merge:** the app **never merges**. A task is `done` only after a human has
  merged **all** its related PRs (`artifacts`) and no work remains.
- **Relationships:** `blocked_by` is authored; `blocks` is derived. `## Context` (body
  prose + links) is the single source for a task's context and what executors get.
- **Board:** task-only columns; Projects/Milestones are scopes/swimlanes with a coarse
  `planned → active → done` status badge.
- **Knowledge concepts (in v1):** plain OKF concepts under `knowledge/`, authored by the
  PM agent, linked from `## Context`, injected into executors. **Lightweight** — no
  search/embeddings/curation. Executors never write knowledge; the PM agent captures it.
- **PM agent planning depth:** real **human-approved decomposition** (propose → approve
  → commit), whose job is to get tasks to `ready`. Not pure CRUD, not autonomous.
- **No `estimate` in v1:** story points don't fit AI executors; if we ever want a cost
  signal, capture observed wall-clock/cost from the run, post-hoc.
- **Field names: unprefixed** (`status`, `due`, `assignee`) — single producer, dedicated
  repo, so no collision risk. Documented as the "okf-pm extension vocabulary" in case we
  ever share bundles across tools and need to namespace or migrate.
- **Dependency gating: hard block.** A task is dispatchable only when `status: ready`
  **and** all `blocked_by` are `done`; the Run action is otherwise disabled. (Blocking an
  *action* is a precondition, not a destructive edit, so it's consistent with the
  advisory posture elsewhere.)

- **v1 scope & delivery:** target cut is `Objective(light) → Project → Milestone → Task`
  + knowledge + chat + read-only kanban + concurrent dispatch (defer Key Results/OKR and
  Cycles), delivered as the testable vertical slices in §11.

### Still open

_Nothing blocking. Remaining questions are implementation-level and can be settled as we
build each iteration in §11._

---

## 11. Delivery plan — testable vertical slices

Each iteration is an end-to-end slice you can run and validate, not a horizontal layer.
Entities exist in the bundle core from Iteration 1 (they are just OKF concepts); the
iterations gate on **capabilities and views**, not on which entity types exist. The full
v1 target is "through Iteration 6"; **Iteration 3 is the make-or-break proof point.**

### Iteration 1 — Read-only board over a real bundle (no agents)
Bundle core (parse / validate / round-trip) + read-only kanban + task detail with
rendered markdown, pointed at a **hand-authored** sample bundle.
→ *Validate:* projects/tasks render correctly; OKF-as-storage feels right to read. No
Claude, no writes — de-risks the data model cheaply.

### Iteration 2 — Chat authoring (PM agent, CRUD only)
Headless Claude Code PM agent scoped to the bundle repo + chat panel. Create / rename /
move / prioritize by conversation; core validates + commits; board refreshes live.
→ *Validate:* I can build and reshape a board entirely by talking, with clean git history
and a read-only UI. Proves the single-writer chat loop.

### Iteration 3 — Dispatch one task, end to end (the thesis)
Dispatch a `ready` + unblocked task → Claude Code in a worktree → live SwiftTerm output
→ `in_progress → in_review` → executor opens a PR → human merges → `done`.
Single executor only; hard dispatch gate in place.
→ *Validate:* the whole product in miniature. If this loop doesn't feel good, we learn it
here, cheaply.

### Iteration 4 — Concurrency + safety rails
Multiple concurrent executors, active-runs list, cancel, per-dispatch ceilings
(iterations / tokens / wall-clock), worktree lifecycle + cleanup.
→ *Validate:* run several at once, follow each, cancel one, trip a ceiling — robust for
daily use.

### Iteration 5 — Planning depth + knowledge
PM-agent decomposition (project → task tree + `blocked_by` + drafted `## Acceptance
criteria` + `## Context`), authoring `knowledge/` concepts; propose → approve → commit;
knowledge injected at dispatch.
→ *Validate:* hand it a goal, approve the breakdown, dispatch well-briefed tasks, and see
knowledge concepts visibly improve executor output.

### Iteration 6 — Objectives & roadmap
Objective + Milestone hierarchy fully wired; objective tree / roadmap (Swift Charts);
objective → task rollup. Completes the v1 target.
→ *Validate:* the roadmap and objective rollup read well.

**Post-v1:** Key Results / OKR, Cycles, agent-authored knowledge, automated PR/merge
detection.
