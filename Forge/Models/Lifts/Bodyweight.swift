//
//  Bodyweight.swift
//  Forge
//
//  Lifts done with your own bodyweight, like pull-ups and dips. Their sets store the
//  weight added on top (a belt or a dumbbell between the feet): 0 or none is just
//  bodyweight, shown as "BW", and 25 shows as "BW+25".
//

import Foundation

enum Bodyweight {
    private static let lifts = ["pullup", "chinup", "pushup", "muscleup", "invertedrow",
                                "hanginglegraise", "hangingkneeraise"]

    static func isBodyweight(_ name: String) -> Bool {
        let key = PersonalBests.key(name)
        return lifts.contains { key.contains($0) } || key == "dip" || key.hasSuffix("dip")
    }

    /// "BW" or "BW+25", for a set's added weight.
    static func label(added: Double?) -> String {
        guard let added, added > 0 else { return "BW" }
        return "BW+\(WeightConverter.format(added))"
    }

    /// A stand-in bodyweight for comparing sets, so more reps or more added weight both
    /// count as a personal best. Only the comparison uses it; it's never shown.
    static let referencePounds = 150.0
}
