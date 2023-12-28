import Foundation
import SpineC

extension spEventType {
    var stringValue: String {
        switch self {
        case SP_ANIMATION_START:
            return "SP_ANIMATION_START"
        case SP_ANIMATION_INTERRUPT:
            return "SP_ANIMATION_INTERRUPT"
        case SP_ANIMATION_END:
            return "SP_ANIMATION_END"
        case SP_ANIMATION_COMPLETE:
            return "SP_ANIMATION_COMPLETE"
        case SP_ANIMATION_DISPOSE:
            return "SP_ANIMATION_DISPOSE"
        case SP_ANIMATION_EVENT:
            return "SP_ANIMATION_EVENT"
        default:
            return "SP_ANIMATION_UNDEFINED"
        }
    }
}

