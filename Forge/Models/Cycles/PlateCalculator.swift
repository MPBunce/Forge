//
//  PlateCalculator.swift
//  Forge
//
//  Forge Plus: which plates go on each side of the bar for a weight.
//

import Foundation

enum PlateCalculator {
    /// Plates per side, heaviest first, using standard plates down to the smallest one owned.
    /// `remainder` is what's left over per side when the weight can't be made exactly.
    static func plates(for weight: Double, bar: Double, smallest: Double, kilograms: Bool)
        -> (plates: [Double], remainder: Double)? {
        guard weight > bar else { return nil }
        let standard: [Double] = kilograms ? [25, 20, 15, 10, 5, 2.5, 1.25, 0.5] : [45, 35, 25, 10, 5, 2.5, 1.25]
        let available = standard.filter { $0 >= smallest - 0.001 }
        var perSide = (weight - bar) / 2
        var result: [Double] = []
        for plate in available {
            while perSide >= plate - 0.001 {
                result.append(plate)
                perSide -= plate
            }
        }
        return (result, perSide < 0.01 ? 0 : perSide)
    }

    /// "45 · 25 · 2.5", or "45 ×2 · 10" when a plate repeats.
    static func describe(_ plates: [Double]) -> String {
        var groups: [(plate: Double, count: Int)] = []
        for plate in plates {
            if let last = groups.last, last.plate == plate {
                groups[groups.count - 1].count += 1
            } else {
                groups.append((plate, 1))
            }
        }
        return groups.map { $0.count > 1 ? "\(WeightConverter.format($0.plate)) ×\($0.count)" : WeightConverter.format($0.plate) }
            .joined(separator: " · ")
    }
}
