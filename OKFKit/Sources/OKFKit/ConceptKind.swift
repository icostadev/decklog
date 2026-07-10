import Foundation

/// The known Decklog concept types. Because OKF types are just strings and consumers
/// must tolerate unknown ones, anything unrecognized maps to `.other`.
public enum ConceptKind: Equatable {
    case objective
    case keyResult
    case project
    case milestone
    case task
    case agent
    case knowledge
    case cycle
    case other(String)

    public init(type: String) {
        // Match case-insensitively (and trim surrounding whitespace): bundles authored by
        // hand or by other tools commonly capitalize (`Task`, `Project`). Unknown types keep
        // their original spelling in `.other`.
        switch type.trimmingCharacters(in: .whitespaces).lowercased() {
        case "objective":   self = .objective
        case "key-result":  self = .keyResult
        case "project":     self = .project
        case "milestone":   self = .milestone
        case "task":        self = .task
        case "agent":       self = .agent
        case "knowledge":   self = .knowledge
        case "cycle":       self = .cycle
        default:            self = .other(type)
        }
    }
}
