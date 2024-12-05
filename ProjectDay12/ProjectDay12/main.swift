//
//  main.swift
//  ProjectDay12
//
//  Created by Aris Koxaras on 5/12/24.
//

import Foundation

// MARK: - Extensions

extension AsyncSequence {
    func collect() async throws -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

extension URL {
    func nonEmptyLines() throws -> [String] {
        let lines = try String(contentsOf: self, encoding: .utf8)
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        assert(lines.count > 0)
        return lines
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

extension Collection where Self.Iterator.Element: RandomAccessCollection {
    // PRECONDITION: `self` must be rectangular, i.e. every row has equal size.
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}


// MARK: - Models

enum Spring: String {
    case operational = "."
    case unknown = "?"
    case damaged = "#"
}

struct Line: Hashable {
    var springs: [Spring]
    var conditions: [Int]
    var previousItem: Spring?
}

extension Line: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(springs.map { $0.rawValue}.joined(separator: "")) \(conditions)"
    }
}

struct Puzzle {
    var lines: [Line]
}

extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        var lines = [Line]()

        for line in textLines {
            let cmps = line.split(separator: " ")
            let springs = cmps[0].map { Spring(rawValue: String($0))! }
            let conditions = try cmps[1].split(separator: ",").map { try Int.create(from: String($0)) }
            assert(conditions.count > 0)
            lines.append(Line(springs: springs, conditions: conditions))
        }
        assert(lines.count > 0)
        return Puzzle(lines: lines)
    }
}

extension Line {
    static var cache: [Line: Int] = [:]

    func getSolutionCount(debug: String, orig: Line) -> Int {
        if let cached = Self.cache[self] {
            return cached
        }

        let damaged = springs.count { $0 == .damaged }
        if damaged == 0 && conditions.reduce(0, +) == 0 {
//            debugPrint("\(debug) \(self)  original: \(orig)")
            return 1
        }
        guard springs.count > 0 else { return 0 }
        guard conditions.count > 0 else { return 0 }

        let first = springs.first!
        switch first {
        case .operational:
            var newLine = self
            if previousItem == .damaged {
                if newLine.conditions.removeFirst() > 0 {
                    Self.cache[self] = 0
                    return 0
                }
            }
            let p = newLine.springs.removeFirst()
            newLine.previousItem = p
            let result = newLine.getSolutionCount(debug: debug + p.rawValue, orig: orig)
            Self.cache[self] = result
            return result
        case .damaged:
            if conditions[0] <= 0 {
                Self.cache[self] = 0
                return 0
            }
            var newLine = self
            let p = newLine.springs.removeFirst()
            newLine.conditions[0] -= 1
            newLine.previousItem = p
            return newLine.getSolutionCount(debug: debug + p.rawValue, orig: orig)
        case .unknown:
            var newLine1 = self
            newLine1.springs[0] = .operational
            let solution1 = newLine1.getSolutionCount(debug: debug, orig: orig)

            var newLine2 = self
            newLine2.springs[0] = .damaged
            let solution2 = newLine2.getSolutionCount(debug: debug, orig: orig)

            let result =  solution1 + solution2
            Self.cache[self] = result
            return result
        }
    }
}

extension Puzzle {
    func solve1() -> Int {
        var sum = 0

        for originalLine in lines {
            sum += originalLine.getSolutionCount(debug: "", orig: originalLine)
        }

        return sum
    }
}

// MARK: - Part 1

func day12_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve1()
}

// MARK: - Part 2

func day12_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve2()
}

extension Puzzle {

    func solve2() -> Int {
        var sum = 0

        for originalLine in lines {
            let newLine = Line(
                springs: (1...5).map { _ in originalLine.springs }.reduce([], { $0 + $1 + [Spring.unknown] }).dropLast(),
                conditions: (1...5).flatMap { _ in originalLine.conditions },
                previousItem: nil
            )
            sum += newLine.getSolutionCount(debug: "", orig: newLine)
        }
        return sum
    }
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day12_Part1(url: inputURL)) // 7204

debugPrint(try day12_Part2(url: inputURL)) // 1672318386674



