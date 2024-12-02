//
//  main.swift
//  ProjectDay09
//
//  Created by Aris Koxaras on 2/12/24.
//

import Foundation

// MARK: - Extensions

extension AsyncSequence {
    func collect() async throws -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

extension Int {
    static func create(from string: String) throws -> Int {
        guard let value = Int(string) else {
            throw NSError(domain: "Invalid value", code: 0)
        }
        return value
    }
}

// MARK: - Models

struct Report {
    var histories: [History]
}

struct History {
    var values: [Int]
}

extension Report {
    static func create(from lines: [String]) throws -> Report {
        let histories = try lines.map { try History.create(from: $0) }
        assert(histories.count > 0)
        return Report(histories: histories)
    }
}

extension History {
    static func create(from line: String) throws -> History {
        let values = try line.split(separator: " ").map { try Int.create(from: String($0)) }
        assert(values.count > 0)
        return History(values: values)
    }
}

extension Report {
    func solve() -> Int {
        var sum = 0

        for history in histories {
            let subhistories = history.getAllDiffs()
            let subsum = subhistories.map { $0.values.last! }.reduce(0, +) + history.values.last!
            sum += subsum
        }

        return sum
    }
}

extension History {
    func getDiffs() -> History {
        let values = zip(values.dropFirst(), values).map { $0 - $1 }
        return History(values: values)
    }

    func allIsZero() -> Bool {
        values.allSatisfy { $0 == 0 }
    }

    func getAllDiffs() -> [History] {
        var subhistories = [History]()
        var allValuesAreZero = false
        var current = self

        while !allValuesAreZero {
            let new = current.getDiffs()
            subhistories.append(new)
            allValuesAreZero = new.allIsZero()
            current = new
        }
        return subhistories
    }
}

// MARK: - Part 1

func day09_Part1(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()
    let report = try Report.create(from: lines)
    return report.solve()
}

// MARK: - Part 2

extension Report {
    func solve2() -> Int {
        var sum = 0

        for history in histories {
            let allHistories = [history] + history.getAllDiffs()
            var subsum = 0

            for history in allHistories.reversed() {
                subsum = history.values.first! - subsum
            }
            sum += subsum
        }

        return sum
    }
}

func day09_Part2(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()
    let report = try Report.create(from: lines)
    return report.solve2()
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try await day09_Part1(url: inputURL)) // 1757008019

debugPrint(try await day09_Part2(url: inputURL)) // 995
