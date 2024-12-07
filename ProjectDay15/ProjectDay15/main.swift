//
//  main.swift
//  ProjectDay15
//
//  Created by Aris Koxaras on 7/12/24.
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

struct Operation: Hashable {
    var name: String
    var hash: Int
    var type: OpType
}

enum OpType: Hashable {
    case replace(Int)
    case remove
}

struct Puzzle: Hashable {
    var words: [String]
    var operations: [Operation]
}

extension Operation {
    init?(rawValue: String) {
        let parts = rawValue.components(separatedBy: "-")
        if parts.count == 2 {
            self.name = parts[0]
            self.type = .remove
            self.hash = parts[0].gethash()
        } else {
            let min = rawValue.components(separatedBy: "=")
            if min.count == 2 {
                self.name = min[0]
                self.type = .replace(Int(min[1])!)
                self.hash = min[0].gethash()
            } else {
                return nil
            }
        }

    }
}

extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        var words = [String]()

        assert(textLines.count == 1)

        words = textLines[0].components(separatedBy: ",")

        let operations = words.map { Operation(rawValue: $0)! }

        assert(words.count > 0)
        return Puzzle(words: words, operations: operations)
    }
}

extension Puzzle {
    func solve1() -> Int {
        var sum = 0

        for word in words {
            let hashValue = word.gethash()
            sum += hashValue
        }

        return sum
    }
}

extension String {
    func gethash() -> Int {
        var sum = 0

        //        Determine the ASCII code for the current character of the string.
        //        Increase the current value by the ASCII code you just determined.
        //        Set the current value to itself multiplied by 17.
        //        Set the current value to the remainder of dividing itself by 256.

        for c in self {
            let ascii = Int(c.asciiValue!)
            sum += ascii
            sum *= 17
            sum %= 256
        }

        return sum
    }
}
// MARK: - Part 1

func day15_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve1()
}

// MARK: - Part 2

func day15_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve2()
}

struct Lens {
    var name: String
    var power: Int
}

extension Puzzle {

    func solve2() -> Int {
        var lenses = (0...255).map { _ in Array<Lens>() }

        for operation in operations {
            switch operation.type {
            case .remove:
                lenses[operation.hash].removeAll(where: { $0.name == operation.name })
            case .replace(let power):
                let lens = Lens(name: operation.name, power: power)

                if let idx = lenses[operation.hash].firstIndex(where: { $0.name == operation.name }) {
                    lenses[operation.hash][idx] = lens
                } else {
                    lenses[operation.hash].append(lens)
                }
            }
        }

        var sum = 0
        for (i, lensArray) in lenses.enumerated() {
            for (j, lens) in lensArray.enumerated() {
                sum += ( (i+1) * (j+1) * lens.power )
            }
        }
        return sum
    }

}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day15_Part1(url: inputURL)) // 515495
debugPrint(try day15_Part2(url: inputURL)) // 229349

