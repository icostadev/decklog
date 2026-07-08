import Foundation

/// The known OKF-PM concept types. Because OKF types are just strings and consumers
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
        switch type {
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
