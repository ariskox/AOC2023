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

    func solve() -> Int {
        for node in nodes {
            resolveIfNeeded(node: node)
        }

        var count = 0
        var current = getNode(with: "AAA")
        var instructions = self.instructions

        while current.name != "ZZZ" {
            let instruction = instructions.removeFirst()
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
            instructions.append(instruction)
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
}

enum NodeState {
    case unresolved(String) // name
    case resolved(Node)
}

// MARK: - Part 1

func day08_Part1(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()
    let puzzle = Puzzle.create(from: lines)
    return puzzle.solve()
}

// MARK: - Part 2

func day08_Part2(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()
    let puzzle = Puzzle.create(from: lines)
    return puzzle.solve()
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try await day08_Part1(url: inputURL)) // 13019

debugPrint(try await day08_Part2(url: exampleURL)) //
