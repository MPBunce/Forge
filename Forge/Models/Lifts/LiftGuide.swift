//
//  LiftGuide.swift
//  Forge
//
//  How to do each lift in the built-in programs: three steps and the mistake to watch
//  for, plus a video search. Guides match on words in the exercise's name, so variants
//  ("Pull Ups", "Pull-ups", "Weighted Pullup") share one.
//

import Foundation

struct LiftGuide {
    let steps: [String]
    let mistake: String

    /// A YouTube search for the lift, like the stretch guides.
    static func videoURL(for name: String) -> URL? {
        var components = URLComponents(string: "https://www.youtube.com/results")
        components?.queryItems = [URLQueryItem(name: "search_query", value: "how to \(name) proper form")]
        return components?.url
    }

    /// The guide for an exercise, if Forge has one.
    static func guide(for exerciseName: String) -> LiftGuide? {
        var name = ExerciseSwaps.split(exerciseName).base.lowercased()
        // Some programs call the overhead press just "Press".
        if name == "press" { name = "overhead press" }
        return all.first { entry in entry.matches(name) }?.guide
    }

    private struct Entry {
        let keys: [String]
        var excluding: [String] = []
        let guide: LiftGuide

        func matches(_ name: String) -> Bool {
            keys.contains { name.contains($0) } && !excluding.contains { name.contains($0) }
        }
    }

    /// Most specific first: "Front Squat" before "Squat", "Leg Curl" before "Curl".
    private static let all: [Entry] = [
        Entry(keys: ["front squat"], guide: LiftGuide(steps: [
            "Rest the bar on the front of your shoulders, fingertips under it and elbows pointing forward.",
            "Brace, then sit straight down between your heels, keeping your chest tall.",
            "Drive up through your whole foot, leading with your elbows.",
        ], mistake: "Elbows dropping, which tips the bar forward. Keep them high the whole rep.")),
        Entry(keys: ["split squat", "lunge", "step-up", "step up"], guide: LiftGuide(steps: [
            "Take a long stance (back foot on a bench for Bulgarian), weights at your sides.",
            "Lower straight down until your back knee nearly touches the floor.",
            "Push through the front heel to stand. Finish every rep on one side, then switch.",
        ], mistake: "A stance so short the front heel lifts. Step out far enough that your shin stays fairly upright.")),
        Entry(keys: ["goblet"], guide: LiftGuide(steps: [
            "Hold a dumbbell vertically against your chest, feet a little wider than hips.",
            "Sit down between your knees, elbows brushing the inside of your knees.",
            "Stand up keeping the weight close and your chest up.",
        ], mistake: "Rounding forward at the bottom. Hold the weight tight to your chest.")),
        Entry(keys: ["leg press", "hack squat"], guide: LiftGuide(steps: [
            "Set your feet shoulder-width in the middle of the platform.",
            "Lower until your knees are about 90°, without your lower back peeling off the pad.",
            "Press through your whole foot without locking your knees hard at the top.",
        ], mistake: "Going so deep your hips tuck under and your back rounds. Stop just before that.")),
        Entry(keys: ["squat"], guide: LiftGuide(steps: [
            "Bar on your upper back, feet shoulder-width, toes turned out a little.",
            "Breathe in, brace your stomach, and sit down and back until your hips are below your knees.",
            "Drive up, pushing your knees out over your toes, and breathe out at the top.",
        ], mistake: "Knees caving in on the way up. Think about spreading the floor apart with your feet.")),
        Entry(keys: ["romanian", "rdl", "stiff"], guide: LiftGuide(steps: [
            "Stand tall holding the weight, knees soft.",
            "Push your hips back, sliding the weight down your thighs, until you feel a strong hamstring stretch.",
            "Squeeze your glutes to bring your hips forward and stand up.",
        ], mistake: "Rounding your back to reach lower. Stop when your hips stop moving back.")),
        Entry(keys: ["sumo"], guide: LiftGuide(steps: [
            "Wide stance, toes out, hands inside your knees on the bar.",
            "Pull your chest up and push your knees out until your shins are near vertical.",
            "Push the floor away and bring your hips through to stand tall.",
        ], mistake: "Hips shooting up first. Keep your chest rising at the same pace as your hips.")),
        Entry(keys: ["deadlift", "rack pull", "block pull"], guide: LiftGuide(steps: [
            "Bar over the middle of your foot, grip just outside your legs.",
            "Bend your knees to the bar, chest up and back flat; take the slack out of the bar.",
            "Push the floor away and stand up, keeping the bar against your legs.",
        ], mistake: "The bar drifting away from your body. Drag it up your shins and thighs.")),
        Entry(keys: ["hip thrust", "glute bridge"], guide: LiftGuide(steps: [
            "Upper back on a bench, bar or weight over your hips, feet flat about hip-width.",
            "Tuck your chin and drive your hips up until your body is flat from knees to shoulders.",
            "Squeeze your glutes for a second at the top, then lower under control.",
        ], mistake: "Arching your lower back at the top. Finish with your ribs down and glutes tight.")),
        Entry(keys: ["kickback", "abduction"], guide: LiftGuide(steps: [
            "Set up so your hips stay still and only your leg moves.",
            "Move the leg out (or back) by squeezing your glute.",
            "Pause, then return slowly.",
        ], mistake: "Swinging with your lower back. Go lighter and keep your hips square.")),
        Entry(keys: ["good morning", "back extension", "hyperextension"], guide: LiftGuide(steps: [
            "Set up with your hips as the hinge point and your back flat.",
            "Bend forward from the hips until you feel your hamstrings stretch.",
            "Squeeze your glutes to come back up to a straight line.",
        ], mistake: "Over-arching at the top. Stop when your body is straight.")),
        Entry(keys: ["leg curl", "hamstring curl", "nordic", "glute-ham"], guide: LiftGuide(steps: [
            "Line up your knee with the machine's pivot.",
            "Curl your heels toward your glutes without lifting your hips.",
            "Lower slowly, taking about two seconds.",
        ], mistake: "Hips popping up to help. Press them into the pad.")),
        Entry(keys: ["leg extension"], guide: LiftGuide(steps: [
            "Line up your knee with the pivot, pad just above your ankles.",
            "Straighten your legs and squeeze your quads at the top.",
            "Lower slowly without letting the weight stack touch.",
        ], mistake: "Kicking the weight up fast. Control it both ways.")),
        Entry(keys: ["calf", "calves"], guide: LiftGuide(steps: [
            "Balls of your feet on an edge, heels hanging off.",
            "Lower your heels all the way for a full stretch.",
            "Rise up as high as you can and pause for a second.",
        ], mistake: "Bouncing through short reps. Pause at the bottom and the top.")),
        Entry(keys: ["curl"], excluding: ["leg", "hamstring"], guide: LiftGuide(steps: [
            "Stand tall, elbows by your sides.",
            "Curl the weight up by bending only at the elbow.",
            "Lower it slowly until your arms are straight.",
        ], mistake: "Swinging your body to lift it. Pin your elbows and go a little lighter.")),
        Entry(keys: ["close grip"], guide: LiftGuide(steps: [
            "Grip the bar about shoulder-width, elbows tucked close to your body.",
            "Lower the bar to your lower chest.",
            "Press up, focusing on your triceps.",
        ], mistake: "Gripping so narrow your wrists bend. Shoulder-width is close enough.")),
        Entry(keys: ["incline"], excluding: ["curl", "fly"], guide: LiftGuide(steps: [
            "Set the bench to about 30°, shoulder blades pulled back and down.",
            "Lower the weight to your upper chest, elbows about 45° from your body.",
            "Press up and slightly back over your shoulders.",
        ], mistake: "Setting the bench too steep, which turns it into a shoulder press. 30° is plenty.")),
        Entry(keys: ["bench", "chest press", "floor press", "larsen"], guide: LiftGuide(steps: [
            "Lie with your eyes under the bar, shoulder blades pinched and feet planted.",
            "Lower the bar to your lower chest, elbows about 45° from your body.",
            "Press up and slightly back until your arms are straight.",
        ], mistake: "Bouncing the bar off your chest. Touch, then press.")),
        Entry(keys: ["overhead press", "shoulder press", "push press", "ohp", "z press", "landmine press", "military"], guide: LiftGuide(steps: [
            "Bar at your collarbones, grip just outside your shoulders, glutes squeezed.",
            "Press straight up, moving your head back so the bar clears your chin.",
            "Finish with the bar over your mid-foot and your head through.",
        ], mistake: "Leaning way back to press. Squeeze your glutes and brace your stomach.")),
        Entry(keys: ["dip"], guide: LiftGuide(steps: [
            "Support yourself on the bars, arms straight, shoulders down.",
            "Lower until your upper arms are about parallel to the floor.",
            "Push back up to straight arms.",
        ], mistake: "Shrugging your shoulders up by your ears. Keep them pressed down.")),
        Entry(keys: ["push-up", "push up", "pushup"], guide: LiftGuide(steps: [
            "Hands under your shoulders, body in a straight line.",
            "Lower your chest to just above the floor, elbows at about 45°.",
            "Push the floor away to straight arms.",
        ], mistake: "Hips sagging. Squeeze your glutes and keep your body like a plank.")),
        Entry(keys: ["pulldown", "pull-down", "pull down"], excluding: ["push"], guide: LiftGuide(steps: [
            "Grip a little wider than your shoulders, thighs locked under the pad.",
            "Pull the bar to your upper chest, driving your elbows down.",
            "Let it rise slowly until your arms are straight.",
        ], mistake: "Leaning way back and yanking. Stay mostly upright and pull with your back.")),
        Entry(keys: ["pull-up", "pull up", "pullup", "chin"], guide: LiftGuide(steps: [
            "Hang with straight arms, hands just wider than shoulders (palms toward you for chin-ups).",
            "Pull your chest toward the bar until your chin is over it.",
            "Lower all the way to straight arms.",
        ], mistake: "Half reps. Start every rep from a full hang.")),
        Entry(keys: ["pullover"], guide: LiftGuide(steps: [
            "Lie across a bench holding one dumbbell over your chest with both hands.",
            "Lower it back over your head with a slight bend in your elbows.",
            "Pull it back over your chest using your lats.",
        ], mistake: "Bending your elbows more as you go. Keep the angle fixed.")),
        Entry(keys: ["dumbbell row", "one-arm", "single-arm"], guide: LiftGuide(steps: [
            "One hand and knee on a bench, back flat, dumbbell hanging straight down.",
            "Pull the weight toward your hip, elbow close to your side.",
            "Lower slowly to a full stretch.",
        ], mistake: "Twisting your torso to lift it. Keep your shoulders square to the floor.")),
        Entry(keys: ["row"], excluding: ["upright"], guide: LiftGuide(steps: [
            "Hinge forward (or brace against the pad), back flat, arms straight.",
            "Pull toward your lower ribs, squeezing your shoulder blades together.",
            "Lower under control to straight arms.",
        ], mistake: "Using momentum from your hips. Pause for a moment at the top.")),
        Entry(keys: ["face pull", "rear delt", "reverse pec", "pull-apart"], guide: LiftGuide(steps: [
            "Use a light weight, arms out in front.",
            "Pull your hands apart and back toward your face, elbows high.",
            "Squeeze your upper back, then return slowly.",
        ], mistake: "Going too heavy and pulling with your arms. Light, slow, and squeeze.")),
        Entry(keys: ["lateral", "upright"], guide: LiftGuide(steps: [
            "Stand tall with light dumbbells at your sides, a slight bend in your elbows.",
            "Raise your arms out to the side until they're level with your shoulders.",
            "Lower slowly, taking two to three seconds.",
        ], mistake: "Shrugging and swinging. Lead with your elbows and go lighter.")),
        Entry(keys: ["front raise"], guide: LiftGuide(steps: [
            "Stand tall, weights in front of your thighs.",
            "Raise them straight out in front to shoulder height.",
            "Lower slowly.",
        ], mistake: "Leaning back to lift. Keep your torso still.")),
        Entry(keys: ["shrug"], guide: LiftGuide(steps: [
            "Stand tall holding the weight at your sides.",
            "Lift your shoulders straight up toward your ears.",
            "Hold for a second, then lower.",
        ], mistake: "Rolling your shoulders. Straight up and down.")),
        Entry(keys: ["tricep", "push down", "pushdown", "skull", "jm press"], guide: LiftGuide(steps: [
            "Pin your elbows in one spot (by your sides, or overhead).",
            "Straighten your arms fully, squeezing your triceps.",
            "Return slowly, moving only at the elbow.",
        ], mistake: "Elbows drifting forward and back. Only your forearms should move.")),
        Entry(keys: ["leg raise", "knee raise"], guide: LiftGuide(steps: [
            "Hang from a bar with straight arms, legs together.",
            "Curl your pelvis up to lift your knees (or straight legs) toward your chest.",
            "Lower slowly without swinging.",
        ], mistake: "Swinging to lift. Pause at the bottom of each rep.")),
        Entry(keys: ["plank"], guide: LiftGuide(steps: [
            "Forearms under your shoulders, body in a straight line.",
            "Squeeze your glutes and brace your stomach.",
            "Hold, breathing steadily.",
        ], mistake: "Hips sagging or piking up. Keep a straight line from head to heels.")),
        Entry(keys: ["abs", "crunch", "ab wheel", "sit-up", "sit up"], guide: LiftGuide(steps: [
            "Pick one: cable crunches, hanging knee raises, or ab wheel.",
            "Curl your ribs toward your hips, rounding your spine slowly.",
            "Return under control, keeping tension in your stomach.",
        ], mistake: "Pulling with your arms or hips. Make your abs do the work.")),
    ]
}
