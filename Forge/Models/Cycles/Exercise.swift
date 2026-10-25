import SwiftUI
import Foundation
import SwiftData

// MARK: - Set Completion Status
enum SetCompletionStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case completedSuccessfully = "completed_successfully"
    case failed = "failed"
}

@Model
class ExerciseSet {
    var setIndex: Int = 0
    var weight: Double?
    var reps: Int?
    var isEditable: Bool = true
    var isAmrap: Bool = false
    var amrapTargetReps: Int?
    var completionStatus: SetCompletionStatus = SetCompletionStatus.notStarted
    var exercise: Exercise?
    
    init(setIndex: Int, weight: Double? = nil, reps: Int? = nil, isEditable: Bool = true, isAmrap: Bool = false, amrapTargetReps: Int? = nil, completionStatus: SetCompletionStatus = .notStarted) {
        self.setIndex = setIndex
        self.weight = weight
        self.reps = reps
        self.isEditable = isEditable
        self.isAmrap = isAmrap
        self.amrapTargetReps = amrapTargetReps
        self.completionStatus = completionStatus
    }
    
    func copy() -> ExerciseSet {
        return ExerciseSet(
            setIndex: setIndex,
            weight: weight,
            reps: reps,
            isEditable: isEditable,
            isAmrap: isAmrap,
            amrapTargetReps: amrapTargetReps,
            completionStatus: .notStarted // Reset completion status on copy
        )
    }
    
    // Convenience methods
    func markAsCompleted() {
        completionStatus = .completedSuccessfully
    }
    
    func markAsFailed() {
        completionStatus = .failed
    }
    
    func reset() {
        completionStatus = .notStarted
    }

    /// Tap cycle used everywhere a set is toggled: not started -> done -> failed -> not started.
    func cycleStatus() {
        switch completionStatus {
        case .notStarted: markAsCompleted()
        case .completedSuccessfully: markAsFailed()
        case .failed: reset()
        }
    }

    var isCompleted: Bool {
        return completionStatus != .notStarted
    }
    
    var wasSuccessful: Bool {
        return completionStatus == .completedSuccessfully
    }
}

@Model
class Exercise {
    var exerciseIndex: Int = 0
    var name: String = ""
    var canAlterSets: Bool = true  // Combined add/delete permission
    @Relationship(deleteRule: .cascade, originalName: "sets", inverse: \ExerciseSet.exercise)
    var storedSets: [ExerciseSet]? = []
    var sets: [ExerciseSet] {
        get { storedSets ?? [] }
        set { storedSets = newValue }
    }
    var trainingDay: TrainingDay?
    
    init(exerciseIndex: Int, name: String, canAlterSets: Bool = true, sets: [ExerciseSet]) {
        self.exerciseIndex = exerciseIndex
        self.name = name
        self.canAlterSets = canAlterSets
        self.storedSets = sets
    }
    
    func copy() -> Exercise {
        let copiedSets = sets.map { $0.copy() }
        return Exercise(
            exerciseIndex: exerciseIndex,
            name: name,
            canAlterSets: canAlterSets,
            sets: copiedSets
        )
    }
    
    /// SwiftData does not preserve the order of to-many relationships, so always read sets through this.
    var orderedSets: [ExerciseSet] {
        sets.sorted { $0.setIndex < $1.setIndex }
    }

    // MARK: - Set Management Methods
    func addSet(isEditable: Bool = true, isAmrap: Bool = false) -> ExerciseSet? {
        guard canAlterSets else { return nil }
        
        let newSet = ExerciseSet(
            setIndex: sets.count,
            isEditable: isEditable,
            isAmrap: isAmrap
        )
        sets.append(newSet)
        return newSet
    }
    
    func deleteSet(at index: Int) -> Bool {
        guard canAlterSets && index >= 0 && index < sets.count else { return false }
        
        sets.remove(at: index)
        
        // Reindex remaining sets
        for (newIndex, set) in sets.enumerated() {
            set.setIndex = newIndex
        }
        
        return true
    }
    
    func canDeleteSet(at index: Int) -> Bool {
        return canAlterSets && index >= 0 && index < sets.count
    }
    
    // MARK: - Convenience methods for exercise completion
    var completedSetsCount: Int {
        return sets.filter { $0.isCompleted }.count
    }
    
    var successfulSetsCount: Int {
        return sets.filter { $0.wasSuccessful }.count
    }
    
    var failedSetsCount: Int {
        return sets.filter { $0.completionStatus == .failed }.count
    }
    
    var isFullyCompleted: Bool {
        return sets.allSatisfy { $0.isCompleted }
    }
    
    var completionPercentage: Double {
        guard !sets.isEmpty else { return 0.0 }
        return Double(completedSetsCount) / Double(sets.count)
    }
    
    // MARK: - Additional validation properties
    var hasAmrapSets: Bool {
        return sets.contains { $0.isAmrap }
    }
    
    var editableSetsCount: Int {
        return sets.filter { $0.isEditable }.count
    }
    
    var nonEditableSetsCount: Int {
        return sets.filter { !$0.isEditable }.count
    }
}

@Model
class TrainingDay {
    var dayIndex: Int = 0
    var dayName: String = ""
    @Relationship(deleteRule: .cascade, originalName: "day", inverse: \Exercise.trainingDay)
    var storedExercises: [Exercise]? = []
    var day: [Exercise] {
        get { storedExercises ?? [] }
        set { storedExercises = newValue }
    }
    var cycle: Cycles?
    var completedDate: Date?
    var canAddAccessory: Bool = true
    
    init(dayIndex: Int, dayName: String, day: [Exercise], completedDate: Date? = nil, canAddAccessory: Bool = false) {
        self.dayIndex = dayIndex
        self.dayName = dayName
        self.storedExercises = day
        self.completedDate = completedDate
        self.canAddAccessory = canAddAccessory
    }
    
    func copy() -> TrainingDay {
        let copiedExercises = day.map { $0.copy() }
        return TrainingDay(dayIndex: dayIndex, dayName: dayName, day: copiedExercises, completedDate: nil, canAddAccessory: canAddAccessory)
    }
    
    // Convenience methods for day completion
    var totalSets: Int {
        return day.reduce(0) { $0 + $1.sets.count }
    }
    
    var completedSets: Int {
        return day.reduce(0) { $0 + $1.completedSetsCount }
    }
    
    var successfulSets: Int {
        return day.reduce(0) { $0 + $1.successfulSetsCount }
    }
    
    var failedSets: Int {
        return day.reduce(0) { $0 + $1.failedSetsCount }
    }
    
    var isFullyCompleted: Bool {
        return day.allSatisfy { $0.isFullyCompleted }
    }
    
    var completionPercentage: Double {
        guard totalSets > 0 else { return 0.0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    func markAsCompleted() {
        completedDate = Date()
    }
}
