//
//  Stretching.swift
//  Forge
//
//  Built-in stretching routines the user can add to their Today tab.
//

import Foundation
import SwiftData

struct Stretch: Hashable {
    let name: String
    /// e.g. "60 sec" or "10 each leg"
    let hold: String
    /// One-line summary of how to do it.
    var detail: String = ""
    /// Step-by-step instructions, shown when you open the stretch.
    var steps: [String] = []
    /// Where you should feel it.
    var feel: String = ""
    /// The most common mistake, or what makes it work.
    var tip: String = ""
    /// Seconds per hold (per side) for the follow-along timer; nil for reps or rolling.
    var seconds: Int? = nil
    /// 2 when it's done on each side.
    var sides: Int = 1

    /// Steps to show: the written steps, or the summary when there are none.
    var instructions: [String] { steps.isEmpty ? (detail.isEmpty ? [] : [detail]) : steps }

    /// A YouTube search for this stretch, for seeing it done.
    var videoSearchURL: URL? {
        var components = URLComponents(string: "https://www.youtube.com/results")
        components?.queryItems = [URLQueryItem(name: "search_query", value: "\(name) stretch how to")]
        return components?.url
    }
}

struct StretchRoutine: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let minutes: Int
    let stretches: [Stretch]
    /// Where the routine comes from, shown under its stretch list.
    var source: String = ""

    static let all: [StretchRoutine] = [agile8, fiveStretches] + StartingStretching.levels

    /// Routines offered on their own, outside the Starting Stretching level group.
    static let standalone: [StretchRoutine] = [agile8, fiveStretches]

    static func routine(id: String) -> StretchRoutine? {
        all.first { $0.id == id }
    }

    /// Joe DeFranco's lower-body mobility warm-up.
    static let agile8 = StretchRoutine(
        id: "defranco-agile-8",
        name: "DeFranco's Agile 8",
        summary: "Lower-body warm-up for hips and legs",
        minutes: 10,
        stretches: [
            Stretch(name: "Foam Roll IT Band", hold: "10–15 passes each leg",
                    detail: "Lie on your side on the roller and roll from hip to just above the knee.",
                    steps: ["Lie on your side with a foam roller under the outside of your thigh, just below the hip.",
                            "Prop yourself up on your forearm. Cross the top leg over and plant that foot in front to control the pressure.",
                            "Roll slowly down to just above the knee and back up.",
                            "Pause for a breath on any tight spot, then switch legs."],
                    feel: "The outside of the thigh.",
                    tip: "Go slowly. Put more weight on the front foot if it's too intense.",
                    sides: 2),
            Stretch(name: "Foam Roll Adductors", hold: "10–15 passes each leg",
                    detail: "Lie face down with one leg out to the side over the roller and roll the inner thigh.",
                    steps: ["Lie face down on your forearms with the roller beside you, parallel to your body.",
                            "Bend one knee out to the side like a frog and rest the inner thigh on the roller.",
                            "Shift your body side to side so the roller moves from near the knee towards the groin.",
                            "Switch legs."],
                    feel: "The inside of the thigh.",
                    tip: "Keep the movement small and slow near the groin.",
                    sides: 2),
            Stretch(name: "Glute Ball Release", hold: "30–60 sec each side",
                    detail: "Sit on a lacrosse or tennis ball and work it around the glute, pausing on tight spots.",
                    steps: ["Sit on the floor and put a lacrosse or tennis ball under one buttock.",
                            "Cross that ankle over the opposite knee to open the hip up.",
                            "Lean into the ball and roll it around in small circles.",
                            "When you find a tender spot, stay on it and breathe until it eases. Switch sides."],
                    feel: "Deep in the buttock.",
                    tip: "Tender is fine; sharp or tingling down the leg means move off that spot.",
                    seconds: 45, sides: 2),
            Stretch(name: "Rectus Femoris Stretch", hold: "3 × 30 sec each leg",
                    detail: "Back knee on the floor against a wall or bench with the foot up behind you; squeeze the glute and stay tall.",
                    steps: ["Kneel with your back to a wall or couch. Put one knee on the floor right against it, with that foot resting up the wall behind you.",
                            "Step the other foot forward into a lunge.",
                            "Squeeze the glute of the back leg and slowly bring your torso upright.",
                            "Hold, then switch legs. Do 3 rounds per leg."],
                    feel: "The front of the thigh and hip of the back leg.",
                    tip: "Don't arch your lower back. Squeezing the glute is what makes it work.",
                    seconds: 30, sides: 2),
            Stretch(name: "Glute Bridge", hold: "12 reps, 3 sec hold",
                    detail: "On your back, knees bent, drive through the heels and squeeze the glutes at the top.",
                    steps: ["Lie on your back, knees bent, feet flat and hip-width apart, arms by your sides.",
                            "Push through your heels and lift your hips until your body is straight from knees to shoulders.",
                            "Squeeze your glutes hard at the top for 3 seconds.",
                            "Lower slowly. Do 12."],
                    feel: "The glutes, not the lower back.",
                    tip: "If you feel it in your hamstrings, bring your feet a little closer to your hips."),
            Stretch(name: "Fire Hydrant Circles", hold: "10 each direction, each leg",
                    detail: "On hands and knees, lift the knee out to the side and draw big circles from the hip.",
                    steps: ["Get on your hands and knees, hands under shoulders and knees under hips.",
                            "Keeping the knee bent, lift one leg out to the side.",
                            "Draw big, slow circles with the knee: 10 forwards, then 10 backwards.",
                            "Switch legs."],
                    feel: "Around the hip joint and the side of the glute.",
                    tip: "Keep your back flat and still; only the leg moves.",
                    sides: 2),
            Stretch(name: "Mountain Climbers", hold: "10 each leg",
                    detail: "From a push-up position, bring one foot up beside the hand and sink the hips.",
                    steps: ["Start in the top of a push-up.",
                            "Step one foot up to the outside of the same-side hand.",
                            "Let your hips sink towards the floor and hold for a second or two.",
                            "Step back and switch legs. These are slow stretches, not fast cardio."],
                    feel: "The groin and the front of the back hip.",
                    tip: "Get the foot all the way up beside the hand.",
                    sides: 2),
            Stretch(name: "Grok Squat", hold: "2 × 30 sec",
                    detail: "Hold the bottom of a deep squat, heels down, elbows pushing the knees out.",
                    steps: ["Stand with feet a bit wider than shoulders, toes turned slightly out.",
                            "Squat down as low as you can with your heels on the floor.",
                            "Bring your hands together and push your knees out with your elbows.",
                            "Keep your chest up and hold. Do 2 rounds."],
                    feel: "The groin, hips and ankles.",
                    tip: "If your heels lift, hold onto a door frame or put a small plate under your heels.",
                    seconds: 30)
        ],
        source: "Joe DeFranco's Agile 8."
    )

    /// From MovementbyDavid's "Literally 5 Stretches is all you Need" (youtube.com/watch?v=QaKuVOhikaY).
    static let fiveStretches = StretchRoutine(
        id: "movementbydavid-5",
        name: "5 Stretches",
        summary: "Daily: hips, hamstrings, chest and lats",
        minutes: 5,
        stretches: [
            Stretch(name: "Pancake Stretch", hold: "30 sec",
                    detail: "Sit with the legs wide and hinge forward from the hips with a flat back.",
                    steps: ["Sit on the floor with your legs straight and spread as wide as is comfortable.",
                            "Point your toes and knees up to the ceiling.",
                            "Sit tall, then lean forward from your hips, walking your hands out in front of you.",
                            "Stop where you feel a stretch and breathe into it."],
                    feel: "The inner thighs and backs of the legs.",
                    tip: "Keep your back flat. Fold from the hips, not by rounding your spine. Sit on a cushion if that's hard.",
                    seconds: 30),
            Stretch(name: "Figure Four Stretch", hold: "30 sec each side",
                    detail: "Cross one ankle over the opposite knee and draw the legs in to open the hip.",
                    steps: ["Lie on your back with both knees bent and feet on the floor.",
                            "Cross your right ankle over your left knee, making a figure 4.",
                            "Reach through and hold behind your left thigh.",
                            "Pull your left knee gently towards your chest. Hold, then switch sides."],
                    feel: "The right buttock and outer hip (then the left).",
                    tip: "Keep the crossed foot flexed to protect the knee.",
                    seconds: 30, sides: 2),
            Stretch(name: "Hip Flexor Stretch", hold: "30 sec each side",
                    detail: "Half-kneeling lunge; squeeze the back glute and shift the hips forward.",
                    steps: ["Kneel on one knee with the other foot flat in front, both knees at about 90°.",
                            "Tuck your tailbone under and squeeze the glute of the back leg.",
                            "Shift your hips gently forward. You don't need to go far.",
                            "Hold, then switch sides."],
                    feel: "The front of the hip of the kneeling leg.",
                    tip: "Pad the knee with a folded towel. Stay tall instead of leaning forward.",
                    seconds: 30, sides: 2),
            Stretch(name: "Chest Opening Stretch", hold: "30 sec",
                    detail: "Open the arms back against a wall or doorway and let the chest stretch.",
                    steps: ["Stand in a doorway.",
                            "Put your forearms on either side of the frame, elbows at shoulder height.",
                            "Step one foot through and lean your body gently forward.",
                            "Hold and breathe."],
                    feel: "Across the chest and the front of the shoulders.",
                    tip: "Keep your shoulders down away from your ears. Ease off if your arms go tingly.",
                    seconds: 30),
            Stretch(name: "Lat Stretch", hold: "30 sec each side",
                    detail: "Reach overhead onto a support and sink the hips back to lengthen the side of the back.",
                    steps: ["Face a counter, bench or doorframe and hold it with one hand at about hip height.",
                            "Step back and hinge at the hips, letting your arm straighten out in front.",
                            "Sit your hips back and slightly away from the side you're holding.",
                            "Hold, then switch sides."],
                    feel: "Down the side of your back and under the arm.",
                    tip: "Let your head drop between your arms and breathe into your side ribs.",
                    seconds: 30, sides: 2)
        ],
        source: "From MovementbyDavid's video \"Literally 5 Stretches is all you Need\". Hold each for 30 seconds and do it every day. Watch the video for form."
    )
}

/// "Starting Stretching" (phrakture.github.io/starting-stretching.html): nine stretches,
/// 60 seconds each, with a beginner, intermediate and advanced version of every one.
enum StartingStretching {
    enum Level: String, CaseIterable {
        case beginner = "Beginner", intermediate = "Intermediate", advanced = "Advanced"
    }

    /// Where each one should be felt, and whether it's done on both sides.
    private static let extras: [String: (feel: String, sides: Int)] = [
        "Shoulder Extension": ("The chest, the front of the shoulders and the lats.", 1),
        "Underarm Shoulder Stretch": ("The front of the shoulders and the chest.", 1),
        "Rear Hand Clasp": ("The shoulders, especially the arm reaching up from behind.", 2),
        "Full Squat": ("The groin, hips and ankles.", 1),
        "Standing Pike": ("The hamstrings and the backs of the knees.", 1),
        "Kneeling Lunge": ("The front of the hip of the kneeling leg.", 2),
        "Butterfly": ("The inner thighs and groin.", 1),
        "Backbend": ("The front of the hips, the abs and the chest.", 1),
        "Lying Twist": ("The lower back, the outer hip and the chest.", 2),
    ]

    /// (name, beginner, intermediate, advanced)
    private static let stretches: [(String, String, String, String)] = [
        ("Shoulder Extension",
         "Hands on something overhead, arms straight, palms down; push the head and chest through.",
         "Elbows on the object with the hands together as if praying; push the head and chest through.",
         "Palms facing up (a stick helps), or a dead hang from a bar with a chin-up grip."),
        ("Underarm Shoulder Stretch",
         "Seated, hands behind you on the floor about shoulder width, fingers pointing away; slide the hips forward.",
         "Seated, hands behind you held narrower than shoulder width with a stick or band; slide the hips forward.",
         "German hang: hang from a bar with the arms behind you."),
        ("Rear Hand Clasp",
         "One hand overhead, one behind the lower back; use a towel or strap to bring them together. Both sides.",
         "Grab the opposite fingers or hands behind your back. Both sides.",
         "Grab the opposite wrists behind your back. Both sides."),
        ("Full Squat",
         "Heels down, squat as deep as you can with the arms inside the knees pressing out, and hold.",
         "Heels down, squat as deep as you can with the arms pressing the knees out; sit up tall, chest and head high.",
         "Heels down in a deep squat, sitting up vertically with the toes pointing forward."),
        ("Standing Pike",
         "Hinge forward with a flat back, reaching for the floor 1–2 feet in front of your toes. Bend the knees to come up.",
         "Once below parallel with a flat back, grab the calves and pull your chest towards your knees.",
         "Bring your chest to your knees without pulling with the arms."),
        ("Kneeling Lunge",
         "Back knee down, front shin vertical; squeeze the glutes and press the hips forward with hands on the front leg. Both sides.",
         "Back knee down, front shin vertical; squeeze the glutes and press the hips forward with hands at your sides, palms forward, shoulders back. Both sides.",
         "Raise the rear foot up to the glutes and hold it with both arms. Both sides."),
        ("Butterfly",
         "Seated, soles together, hold the feet and press the knees towards the floor using strength alone.",
         "Lean forward slightly with a flat back and press the knees down with your elbows.",
         "Lean forward with a flat back, aiming chest to legs and knees to the floor."),
        ("Backbend",
         "Glute bridge: on your back, feet near the glutes, squeeze the glutes and press the hips up.",
         "Camel: kneeling, toes tucked, hold your heels and push the hips forward, looking up.",
         "Bridge (wheel): hands by your head, press up onto the head, then straighten the arms. Stop if the lower back pinches."),
        ("Lying Twist",
         "On your back, arms out, bring a bent knee across the body with shoulders down; press with the arm. Both sides.",
         "On your back, arms out, bring a straight, locked leg across the body with shoulders down; press with the arm. Both sides.",
         "On your back, arms out, bring a straight leg across the body with shoulders down and hold it with muscle alone, no arm. Both sides.")
    ]

    static let levels: [StretchRoutine] = Level.allCases.map(routine)

    static func isLevel(_ id: String) -> Bool {
        levels.contains { $0.id == id }
    }

    static func routine(_ level: Level) -> StretchRoutine {
        StretchRoutine(
            id: "starting-stretching-\(level.rawValue.lowercased())",
            name: "Starting Stretching: \(level.rawValue)",
            summary: "9 full-body stretches, 60 sec each",
            minutes: 15,
            stretches: stretches.map { name, beginner, intermediate, advanced in
                let detail: String
                switch level {
                case .beginner: detail = beginner
                case .intermediate: detail = intermediate
                case .advanced: detail = advanced
                }
                let extra = extras[name]
                // Each level's text is a few short sentences; show them as steps.
                let steps = detail.split(separator: ";").flatMap { $0.split(separator: ". ") }
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .map { $0.hasSuffix(".") ? $0 : $0 + "." }
                    .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                return Stretch(name: name, hold: "60 sec", detail: detail, steps: steps,
                               feel: extra?.feel ?? "",
                               tip: "Hold for 60 seconds in total. If that's too long, rest and finish in shorter holds of at least 20 seconds.",
                               seconds: 60, sides: extra?.sides ?? 1)
            },
            source: "From Starting Stretching. Hold each for 60 seconds in total (split into rests of no less than 20 seconds if needed). Stop if anything hurts."
        )
    }
}

/// Marks a routine as done on one calendar day.
@Model
class StretchEntry {
    var routineID: String = ""
    var day: Date = Date()

    init(routineID: String, day: Date) {
        self.routineID = routineID
        self.day = Calendar.current.startOfDay(for: day)
    }
}
