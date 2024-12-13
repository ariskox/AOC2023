//
//  main.swift
//  ProjectDay19
//
//  Created by Aris Koxaras on 10/12/24.
//

import Foundation

// MARK: - Extensions

extension AsyncSequence {
    func collect() async throws -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

extension Collection where Self.Iterator.Element: RandomAccessCollection {
    // PRECONDITION: `self` must be rectangular, i.e. every row has equal size.
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else {
            return []
        }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
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

    func lines() throws -> [String] {
        let lines = try String(contentsOf: self, encoding: .utf8)
            .components(separatedBy: .newlines)
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

// MARK: - Models

enum Category: String {
    case x
    case m
    case a
    case s
}

struct Rating: Hashable {
    var category: Category
    var value: Int
}

struct WorkFlow: Hashable {
    var name: String
    var rules: [Rule]
    var lastRuleName: String
}

extension WorkFlow {
    init(from line: String) {
        let parts = line.components(separatedBy: "{")
        assert(parts.count == 2)
        let ruleLines = parts[1].replacingOccurrences(of: "}", with: "").components(separatedBy: ",")
        assert(ruleLines.count >= 2)
        self.name = parts[0]
        self.rules = ruleLines.dropLast().map(Rule.create)
        self.lastRuleName = ruleLines.last!
    }
}

struct Rule: Hashable {
    var category: Category
    var condition: Condition
    var value: Int
    var destination: String
}

extension Rule {
    static func create(from line: String) -> Rule {
        let parts = line.components(separatedBy: ":")
        assert(parts.count == 2)
        let destination = parts[1]
        let partName = String(parts[0].first!)
        let condition = Condition(rawValue: String(parts[0].dropFirst().first!))!
        let value = Int(String(parts[0].dropFirst().dropFirst()))!
        return Rule(category: Category(rawValue: partName)!, condition: condition, value: value, destination: destination)
    }

    func evaluate(with value: Int) -> Bool {
        switch self.condition {
        case .lessThan:
            return value < self.value
        case .greaterThan:
            return value > self.value
        }
    }
}

enum Condition: String {
    case lessThan = "<"
    case greaterThan = ">"
}

struct Part: Hashable {
    var ratings: [Rating]
}

extension Part {
    static func create(from line: String) -> Part {
        let parts = line.components(separatedBy: ",")
        assert(parts.count > 0)
        return Part(ratings: parts.map { part in
            let parts2 = part.components(separatedBy: "=")
            assert(parts2.count == 2)
            return Rating(category: Category(rawValue: parts2[0])!, value: Int(parts2[1])!)
        })
    }

    var sumOfRatings: Int {
        ratings.reduce(0) { $0 + $1.value }
    }
}

struct Puzzle {
    var workflows: [WorkFlow]
    var parts: [Part]
}

extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        assert(textLines.count > 0)

        var workflows = [WorkFlow]()
        var parts: [Part] = []

        var lines = textLines

        while true {
            let line = lines.removeFirst()
            if line.isEmpty { break }
            let workflow = WorkFlow(from: line)
            workflows.append(workflow)
        }

        while true {
            if lines.isEmpty { break }
            let line = lines.removeFirst().replacingOccurrences(of: "}", with: "").replacingOccurrences(of: "{", with: "")
            if line.isEmpty { break }
            let part = Part.create(from: line)
            parts.append(part)
        }

        return Puzzle(workflows: workflows, parts: parts)
    }
}

extension Rule {
    func evaluate(_ part: Part) -> Bool {
        guard let f = part.ratings.first(where: { $0.category == self.category }) else {
            return false
        }
        return self.evaluate(with: f.value)
    }
}

extension WorkFlow {

    // returns nextworkflow
    func nextWorkflowname(for part: Part) -> String {
        let partCategories = part.ratings.map { $0.category }

        let rules = self.rules.filter { partCategories.contains($0.category) }

        for rule in rules {
            if rule.evaluate(part) {
                return rule.destination
            }
        }

        // go to fall back
        return lastRuleName
    }
}

extension Puzzle {
    func solve1() -> Int {
        var sum = 0
        let startWorkFlow = workflows.first(where: { $0.name == "in" })!

        for part in self.parts {
            var currentWorkFlow: WorkFlow? = startWorkFlow

            while currentWorkFlow != nil {
                let nextWorkFlowName = currentWorkFlow!.nextWorkflowname(for: part)
                switch nextWorkFlowName {
                case "A":
                    sum += part.sumOfRatings
                    currentWorkFlow = nil
                case "R":
                    currentWorkFlow = nil
                    break
                default:
                    currentWorkFlow = workflows.first(where: { $0.name == nextWorkFlowName })!
                }
            }
        }
        return sum
    }
}

// MARK: - Part 1

func day18_Part1(url: URL) throws -> Int {
    let lines = try url.lines()
    let map = try Puzzle.create(from: lines)
    return map.solve1()
}

// MARK: - Part 2

func day18_Part2(url: URL) throws -> Int {
    let lines = try url.lines()
    let map = try Puzzle.create(from: lines)
    return map.solve2()
}

struct State: Hashable {
    var ranges: [Category: ClosedRange<Int>] = [
        Category.x: 1...4000,
        Category.a: 1...4000,
        Category.m: 1...4000,
        Category.s: 1...4000
    ]

    var currentWorkFlow: WorkFlow
    var path: [String]
}

extension State {
    var possibleCombinations: Int  {
        ranges.reduce(1) { $0 * $1.value.count }
    }
}

extension Rule {
    func filterMatching(range: ClosedRange<Int>) -> ClosedRange<Int>? {
        switch condition {
        case .lessThan:
            if range.lowerBound < value {
                return range.lowerBound...min(4000,value-1)
            }
        case .greaterThan:
            if range.upperBound > value {
                return max(1, value+1)...range.upperBound
            }
        }

        return nil
    }

    func filterExcluding(range: ClosedRange<Int>) -> ClosedRange<Int>? {
        switch condition {
        case .greaterThan:
            if range.lowerBound <= value {
                return range.lowerBound...min(4000,value)
            }
        case .lessThan:
            if range.upperBound >= value {
                return  max(1,value)...range.upperBound
            }
        }
        return nil
    }

}

extension Puzzle {

    func solve2() -> Int {
        let startWorkFlow = workflows.first(where: { $0.name == "in" })!
        var queue: [State] = [State(currentWorkFlow: startWorkFlow, path: ["in"])]
        var seenStates = Set<State>()
        var acceptedStates = Set<State>()

        while queue.count > 0 {
            let state = queue.removeFirst()
            if seenStates.contains(state) {
                continue
            }
            seenStates.insert(state)


            var walkingState = state

            for rule in state.currentWorkFlow.rules {
                if rule.destination == "R" {
                   continue
                }

                if let newRage = rule.filterMatching(range: walkingState.ranges[rule.category]!) {

                    var newState = State(
                        ranges: walkingState.ranges,
                        currentWorkFlow: walkingState.currentWorkFlow,
                        path: walkingState.path + ["\(rule.category)_\(rule.condition)_\(rule.value)", rule.destination]
                    )
//                    if newState.path.joined(separator: ".") == "in.s_lessThan_1351.px.m_greaterThan_2090.A" {
//                        print("found it")
//                    }

                    newState.ranges[rule.category]! = newRage


                    if rule.destination == "A" {
                        acceptedStates.insert(newState)
                    } else if rule.destination != "R" {
                        newState.currentWorkFlow = workflows.first(where: { $0.name == rule.destination })!
                        queue.append(newState)
                    } else {
                        fatalError()
                    }
                }
                if let n = rule.filterExcluding(range: walkingState.ranges[rule.category]!) {
                    walkingState.ranges[rule.category]! = n
                } else {
                    break
                }
            }

            // Add last rule with inverse conditions
            if state.currentWorkFlow.lastRuleName != "R" {

                // Build inverse
                var newState = state
                newState.path = state.path + ["last:\(state.currentWorkFlow.lastRuleName)", state.currentWorkFlow.lastRuleName]

//                if newState.path.joined(separator: ".") == "in.s_lessThan_1351.px.m_greaterThan_2090.A" {
//                    print("found it")
//                }
//
                var shouldAddRule = true
                for rule in state.currentWorkFlow.rules {
                    let selectedRange: ClosedRange<Int> = newState.ranges[rule.category]!

                    if let r = rule.filterExcluding(range: selectedRange) {
                        newState.ranges[rule.category]! = r
                    } else {
                        shouldAddRule = false
                        break
                    }

                }
                if shouldAddRule {
                    if let w = workflows.first(where: { $0.name == state.currentWorkFlow.lastRuleName }) {
                        newState.currentWorkFlow = w
                        queue.append(newState)
                    } else if state.currentWorkFlow.lastRuleName == "A" {
                        acceptedStates.insert(newState)
                    } else {
                        fatalError()
                    }
                }
            }


        }

        var sum = 0
        for state in acceptedStates {
            let statePath = "" // "State: \(state.path.joined(separator: "."))
            print("\(state.possibleCombinations) \(statePath) \(state.ranges)"
                .replacingOccurrences(of: "ProjectDay19.Category.", with: "")
                .replacingOccurrences(of: "ClosedRange(", with: "")
                .replacingOccurrences(of: ")", with: "")
            )
            sum += state.possibleCombinations
        }

        return sum
    }
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let example2URL = Bundle.main.url(forResource: "example2", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day18_Part1(url: inputURL)) // 575412
let sol1 = try day18_Part2(url: inputURL)
print(sol1)
// ERROR. Correct is 126107942006821
assert(sol1 == 126107942006821)



