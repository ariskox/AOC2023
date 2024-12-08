//
//  main.swift
//  ProjectDay18
//
//  Created by Aris Koxaras on 8/12/24.
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

enum Tile {
    case empty
    case trench
}

enum Direction {
    case north
    case south
    case east
    case west

    var move: Vector {
        switch self {
        case .north:
            return Vector(dx: 0, dy: -1)
        case .south:
            return Vector(dx: 0, dy: 1)
        case .east:
            return Vector(dx: 1, dy: 0)
        case .west:
            return Vector(dx: -1, dy: 0)
        }
    }
}

extension Direction {
    init(from lrup: String) throws {
        switch lrup {
        case "L":
            self = .west
        case "R":
            self = .east
        case "U":
            self = .north
        case "D":
            self = .south
        default:
            throw NSError(domain: "Invalid direction", code: 0)
        }
    }
}

struct Instruction {
    var direction: Direction
    var steps: Int
}

extension Instruction {
    init(from line: String) throws {
        let parts = line.components(separatedBy: " ")

        self.direction = try Direction(from: parts[0])
        self.steps = try Int.create(from: parts[1])
        // Skip color
    }
}

struct Puzzle {
    var instructions: [Instruction]
}

extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        var instructions = [Instruction]()

        for line in textLines {
            assert(line.count > 0)
            let instruction = try Instruction(from: line)
            instructions.append(instruction)
        }
        assert(instructions.count > 0)
        return Puzzle(instructions: instructions)
    }
}

struct Vector: Hashable, Equatable {
    var dx: Int
    var dy: Int
}

extension Puzzle {
    func solve1() -> Int {
        //  Everything doubled by 2 to avoid using floating point numbers
        
        var pos = 0
        var ans = 2

        for instruction in instructions {
            let n = instruction.steps
            let x = instruction.direction.move.dx
            let y = instruction.direction.move.dy

            pos += x*n * 2
            ans += y*n * pos + n

        }
        return ans / 2
    }
}

// MARK: - Part 1

func day18_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve1()
}

// MARK: - Part 2

func day18_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create2(from: lines)
    return map.solve1()
}

extension Puzzle {
    static func create2(from textLines: [String]) throws -> Puzzle {
        var instructions = [Instruction]()

        for line in textLines {
            assert(line.count > 0)
            let instruction = try Instruction(from2: line)
            instructions.append(instruction)
        }
        assert(instructions.count > 0)
        return Puzzle(instructions: instructions)
    }

}

extension Instruction {
    init(from2 line: String) throws {
        let parts = line.components(separatedBy: " ")
        let hex = String(parts[2].dropFirst().dropFirst().dropLast())
        let hexPart1 = String(hex.dropLast())
        let dirString = String(hex.last!)

        self.direction = try Direction(from2: dirString)
        if let decimalValue = Int(hexPart1, radix: 16) {
            self.steps = decimalValue
        } else {
            throw NSError(domain: "Invalid value", code: 0)
        }
    }
}

extension Direction {

    init(from2 str: String) throws {
        switch str {
        case "2":
            self = .west
        case "0":
            self = .east
        case "3":
            self = .north
        case "1":
            self = .south
        default:
            throw NSError(domain: "Invalid direction", code: 0)
        }
    }
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day18_Part1(url: inputURL)) // 39194
debugPrint(try day18_Part2(url: inputURL)) // 78242031808225


