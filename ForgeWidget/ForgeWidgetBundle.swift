//
//  ForgeWidgetBundle.swift
//  ForgeWidget
//

import SwiftUI
import WidgetKit

@main
struct ForgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutStreakWidget()
        RunningStreakWidget()
        StepsStreakWidget()
        DailyWorkStreakWidget()
        StretchingStreakWidget()
        NextWorkoutWidget()
        RestLiveActivity()
    }
}
