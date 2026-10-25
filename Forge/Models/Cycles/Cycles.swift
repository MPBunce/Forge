//
//  Cycles.swift
//  Forge
//
//  Created by Matthew Bunce on 2025-05-31.
//
import Foundation
import SwiftData

@Model
class Cycles {
    // iCloud sync needs every stored value to have a default, no unique constraints,
    // and optional relationships with inverses. The plain names wrap the stored ones.
    var id: UUID = UUID()
    var startDate: Date = Date()
    var template: String = ""
    @Relationship(deleteRule: .cascade, originalName: "trainingDays", inverse: \TrainingDay.cycle)
    var storedDays: [TrainingDay]? = []
    var trainingDays: [TrainingDay] {
        get { storedDays ?? [] }
        set { storedDays = newValue }
    }
    /// Unit the cycle's weights were written in. Fixed at creation so switching the
    /// app's unit later doesn't reinterpret existing numbers.
    var usesKilograms: Bool = false
    
    init( startDate: Date, template: String, usesKilograms: Bool, trainingDays: [TrainingDay]) {
        self.id = UUID()
        self.startDate = startDate
        self.template = template
        self.storedDays = trainingDays
        self.usesKilograms = usesKilograms
    }
    
    var weightUnit: String { usesKilograms ? "kg" : "lbs" }
    
    var isCompleted: Bool {
        !trainingDays.isEmpty && trainingDays.allSatisfy { $0.completedDate != nil }
    }

    var completedDayCount: Int { trainingDays.filter { $0.completedDate != nil }.count }

    /// The first training day not yet marked done.
    var nextDay: TrainingDay? {
        trainingDays.sorted { $0.dayIndex < $1.dayIndex }.first { $0.completedDate == nil }
    }
    
}
