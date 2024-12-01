//
//  main.swift
//  ProjectDay08
//
//  Created by Aris Koxaras on 1/12/24.
//

import Foundation

// MARK: - Extensions

extension AsyncSequence {
    func collect() async throws -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}


// MARK: - Models

enum Instruction: String {
    case L
    case R
}

extension Instruction {
    static func create(from line: String) -> [Instruction] {
        line.map { Instruction(rawValue: String($0))! }
    }
}

class Puzzle {
    var instructions: [Instruction]
    var nodes: [Node]

    init(instructions: [Instruction], nodes: [Node]) {
        self.instructions = instructions
        self.nodes = nodes
    }
}

extension Puzzle {
    static func create(from lines: [String]) -> Puzzle {
        let instructions = Instruction.create(from: lines[0])

        var nodes = [Node]()
        for line in lines.dropFirst() {
            let cmps = line.split(separator: "=")
            assert(cmps.count == 2)
            let name = cmps.first?.trimmingCharacters(in: .whitespaces) ?? ""

            let cmps2 = cmps.last!
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: " ", with: "")
                .split(separator: ",").map { String($0) }
            assert(cmps2.count == 2)
            let node = Node(name: name, left: .unresolved(cmps2[0]), right: .unresolved(cmps2[1]))
            nodes.append(node)
        }

        // Check for duplicates
        var dict: [String: Int] = [:]
        for node in nodes {
            dict[node.name, default: 0] += 1
        }
        let values = dict.values
        assert(values.allSatisfy { $0 == 1 })

        let puzzle = Puzzle(instructions: instructions, nodes: nodes)
        return puzzle
    }
}

extension Puzzle {
    func getNode(with name: String) -> Node {
        nodes.first { $0.name == name }!
    }

    func resolveIfNeeded(node: Node) {
        switch node.left {
        case .unresolved(let name):
            node.left = .resolved(getNode(with: name))
        case .resolved:
            break
        }
        switch node.right {
        case .unresolved(let name):
            node.right = .resolved(getNode(with: name))
        case .resolved:
            break
        }
    }

    func solve(for nodeName: String, suffix: String) -> Int {
        for node in nodes {
            resolveIfNeeded(node: node)
        }

        var count = 0
        var current = getNode(with: nodeName)
        var iIndex = 0

        while !current.name.hasSuffix(suffix) {
            let instruction = instructions[iIndex]
            switch instruction {
            case .L:
                switch current.left {
                case .unresolved:
                    fatalError()
                case .resolved(let node):
                    current = node
                }
            case .R:
                switch current.right {
                case .unresolved:
                    fatalError()
                case .resolved(let node):
                    current = node
                }
            }
            iIndex = (iIndex + 1) % instructions.count
            count += 1
        }

        return count
    }
}

class Node {
    var name: String
    var left: NodeState
    var right: NodeState

    init(name: String, left: NodeState, right: NodeState) {
        self.name = name
        self.left = left
        self.right = right
    }

    var getLeft: Node {
        switch left {
        case .resolved(let node):
            return node
        case .unresolved:
            fatalError()
        }
    }
    var getRight: Node {
        switch right {
        case .resolved(let node):
            return node
        case .unresolved:
            fatalError()
        }
    }
}

extension Node: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(name) \(left) \(right)"
    }
}

enum NodeState {
    case unresolved(String) // name
    case resolved(Node)
}

extension NodeState: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .unresolved(let name):
            return "unresolved(\(name))"
        case .resolved(let node):
            return "resolved(\(node.name))"
        }
    }
}

// MARK: - Part 1

func day08_Part1(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()
    let puzzle = Puzzle.create(from: lines)
    return puzzle.solve(for: "AAA", suffix: "ZZZ")
}

// MARK: - Part 2

extension Puzzle {
    func getNodesEnding(in name: String) -> [Node] {
        nodes.filter { $0.name.hasSuffix(name) }
    }

    func solve2() -> Int {
        for node in nodes {
            resolveIfNeeded(node: node)
        }

        let current: [Node] = getNodesEnding(in: "A")
        let tries = current.map { solve(for: $0.name, suffix: "Z") }

        // solved MXA in 16343
        // solved VQA in 11911
        // solved CBA in 20221
        // solved JBA in 21883
        // solved AAA in 13019
        // solved HSA in 19667

        // 13524038372771

        // Find LCM of all the above numbers

        var totalLCM = 1

        for number in tries {
            totalLCM = lcm(totalLCM, number)
        }

        return totalLCM
    }
}

/*
 Returns the Greatest Common Divisor of two numbers.
 */
func gcd(_ x: Int, _ y: Int) -> Int {
    var a = 0
    var b = max(x, y)
    var r = min(x, y)

    while r != 0 {
        a = b
        b = r
        r = a % b
    }
    return b
}

/*
 Returns the least common multiple of two numbers.
 */
func lcm(_ x: Int, _ y: Int) -> Int {
    return x / gcd(x, y) * y
}

func day08_Part2(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()
    let puzzle = Puzzle.create(from: lines)
    return puzzle.solve2()
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let example2URL = Bundle.main.url(forResource: "example2", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try await day08_Part1(url: inputURL)) // 13019

debugPrint(try await day08_Part2(url: inputURL)) //
