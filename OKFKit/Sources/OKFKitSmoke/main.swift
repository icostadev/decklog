import Foundation
import OKFKit

// A no-XCTest smoke check: mirrors the key BundleSchema tests so the schema work can be
// verified with only the Command Line Tools (`swift run OKFKitSmoke`). Exits non-zero on
// any failure. This is a stopgap for the real XCTest suite (needs Xcode / a swift.org
// toolchain); keep the two in sync when the schema changes.

var failures = 0

func ok(_ cond: Bool, _ label: String) {
    print(cond ? "  ok   \(label)" : "FAIL  \(label)")
    if !cond { failures += 1 }
}

func eq<T: Equatable>(_ a: T, _ b: T, _ label: String) {
    let good = (a == b)
    print(good ? "  ok   \(label)" : "FAIL  \(label): \(a) != \(b)")
    if !good { failures += 1 }
}

func throwsError(_ label: String, _ body: () throws -> Void) {
    do { try body(); print("FAIL  \(label): did not throw"); failures += 1 }
    catch { print("  ok   \(label)") }
}

// MARK: schema-model

print("== schema-model ==")
let d = BundleSchema.default
eq(d.taskStatuses.map(\.id), TaskStatus.allCases.map(\.rawValue), ".default task ids == TaskStatus")
eq(d.milestoneStatuses.map(\.id), WorkStatus.allCases.map(\.rawValue), ".default milestone ids == WorkStatus")
eq(d.objectiveStatuses.map(\.id), ObjectiveStatus.allCases.map(\.rawValue), ".default objective ids == ObjectiveStatus")
ok(d.allowedStatuses(for: .task) == TaskStatus.allCases.map(\.rawValue), "allowedStatuses(.task)")
ok(d.allowedStatuses(for: .project) == WorkStatus.allCases.map(\.rawValue), "allowedStatuses(.project)")
ok(d.allowedStatuses(for: .objective) == ObjectiveStatus.allCases.map(\.rawValue), "allowedStatuses(.objective)")
ok(d.allowedStatuses(for: .agent) == nil, "allowedStatuses(.agent) == nil")
ok(d.taskStatus(for: .ready) == "ready", "role .ready -> ready")
ok(d.taskStatus(for: .inProgress) == "in_progress", "role .inProgress -> in_progress")
ok(d.taskStatus(for: .inReview) == "in_review", "role .inReview -> in_review")
ok(d.taskStatus(for: .done) == "done", "role .done -> done")
ok(d.taskStatus(for: .cancelled) == "cancelled", "role .cancelled -> cancelled")
eq(d.taskColumns.map(\.id), ["draft", "ready", "in_progress", "in_review", "done"], "taskColumns excludes cancelled")
eq(d.taskLabel("in_progress"), "In progress", "label: in_progress -> In progress")
eq(StatusDef.defaultLabel(for: "code-review"), "Code review", "defaultLabel: code-review -> Code review")

// MARK: schema parse

print("== schema parse ==")
eq(try BundleSchema.parse(yaml: ""), .default, "parse empty == .default")

let sh = try BundleSchema.parse(yaml: "task_statuses: [backlog, ready, done, cancelled]")
ok(sh.taskStatus(for: .ready) == "ready", "shorthand auto-binds .ready")
ok(sh.taskStatuses[0].role == nil, "shorthand `backlog` has no role")
eq(sh.taskColumns.map(\.id), ["backlog", "ready", "done"], "shorthand cancelled is off-board")

let full = try BundleSchema.parse(yaml: """
task_statuses:
  - { id: doing, label: Doing, role: in_progress }
  - { id: shipped, role: done }
""")
ok(full.taskStatus(for: .inProgress) == "doing", "renamed role: doing -> .inProgress")
eq(full.taskLabel("doing"), "Doing", "explicit label honored")
// Untouched sections keep the default.
eq(full.milestoneStatuses, BundleSchema.default.milestoneStatuses, "missing section falls back to default")

throwsError("parse throws on non-list") { _ = try BundleSchema.parse(yaml: "task_statuses: nope") }
throwsError("parse throws on missing id") { _ = try BundleSchema.parse(yaml: "task_statuses: [{ label: X }]") }
throwsError("parse throws on unknown role") { _ = try BundleSchema.parse(yaml: "task_statuses: [{ id: foo, role: bogus }]") }

// MARK: schema-load (tolerant, from decklog.yaml)

print("== schema-load ==")
func withTempBundle(_ yaml: String?, _ label: String, _ body: (OKFBundle) -> Void) {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("okfkit-smoke-\(UUID().uuidString)")
    do {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let yaml {
            try yaml.write(to: dir.appendingPathComponent("decklog.yaml"), atomically: true, encoding: .utf8)
        }
        body(try OKFBundle.load(at: dir))
    } catch {
        print("FAIL  \(label): setup error \(error)"); failures += 1
    }
    try? FileManager.default.removeItem(at: dir)
}

withTempBundle(nil, "absent decklog.yaml") { b in
    eq(b.schema, .default, "absent decklog.yaml -> .default")
}
withTempBundle("task_statuses: [backlog, doing, done]", "custom schema") { b in
    eq(b.schema.taskStatuses.map(\.id), ["backlog", "doing", "done"], "custom schema loaded")
    ok(b.loadErrors.isEmpty, "valid schema -> no load errors")
}
withTempBundle("task_statuses: oops", "malformed schema") { b in
    eq(b.schema, .default, "malformed -> .default")
    ok(b.loadErrors.contains { $0.path == "decklog.yaml" }, "malformed -> decklog.yaml load error")
}

// MARK: validation reads the schema (schema-board-validation)

print("== validation uses schema ==")
func withTempTaskBundle(
    schema: String, tasks: [String: String], _ label: String, _ body: (OKFBundle) -> Void
) {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("okfkit-smoke-\(UUID().uuidString)")
    do {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try schema.write(to: dir.appendingPathComponent("decklog.yaml"), atomically: true, encoding: .utf8)
        for (id, status) in tasks {
            let fileURL = dir.appendingPathComponent(id + ".md")
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "---\ntype: task\nstatus: \(status)\n---\n"
                .write(to: fileURL, atomically: true, encoding: .utf8)
        }
        body(try OKFBundle.load(at: dir))
    } catch {
        print("FAIL  \(label): setup error \(error)"); failures += 1
    }
    try? FileManager.default.removeItem(at: dir)
}

withTempTaskBundle(
    schema: "task_statuses: [backlog, doing, done]",
    tasks: ["projects/x/tasks/t1": "backlog", "projects/x/tasks/t2": "frozen"],
    "validation vs schema"
) { b in
    let issues = b.validate()
    func unknownStatus(_ id: String) -> Bool {
        issues.contains { $0.conceptID == id && $0.message.contains("unknown status") }
    }
    ok(!unknownStatus("projects/x/tasks/t1"), "custom status `backlog` accepted (no warning)")
    ok(unknownStatus("projects/x/tasks/t2"), "undeclared status `frozen` flagged")
}

// MARK: dispatch uses schema roles (schema-dispatch-executor)

print("== dispatch uses schema roles ==")
withTempTaskBundle(
    schema: """
    task_statuses:
      - { id: todo, role: ready }
      - { id: doing, role: in_progress }
      - { id: done, role: done }
    """,
    tasks: ["projects/x/tasks/a": "todo", "projects/x/tasks/b": "doing"],
    "dispatch vs schema"
) { b in
    ok(b.dispatchDecision(forTask: "projects/x/tasks/a").canDispatch,
       "role-ready status `todo` is dispatchable")
    ok(!b.dispatchDecision(forTask: "projects/x/tasks/b").canDispatch,
       "`doing` (not role-ready) is not dispatchable")
}

// MARK: summary

print("")
if failures == 0 {
    print("ALL PASS")
    exit(0)
} else {
    print("\(failures) FAILURE(S)")
    exit(1)
}
