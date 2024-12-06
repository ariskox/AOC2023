//
//  main.swift
//  ProjectDay13
//
//  Created by Aris Koxaras on 6/12/24.
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

enum Tile: String, Hashable {
    case ash = "."
    case rock = "#"
}

struct Pattern: Hashable {
    var tiles: [[Tile]]
}

extension Pattern: CustomDebugStringConvertible {
    var debugDescription: String {
        tiles.map { $0.map { $0.rawValue }.joined() }.joined(separator: "\n")
    }
}

struct Puzzle {
    var patterns: [Pattern]
}


extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        var patterns = [Pattern]()

        var currentTiles = [[Tile]]()
        for line in textLines {
            if line.isEmpty {
                assert(currentTiles.count > 0)
                patterns.append(Pattern(tiles: currentTiles))
                currentTiles = []
                continue
            }
            let tiles = line.map { Tile(rawValue: String($0))! }
            currentTiles.append(tiles)
        }
        assert(patterns.count > 0)
        return Puzzle(patterns: patterns)
    }
}

extension Puzzle {
    func solve1() -> Int {
        var sum = 0

        for pattern in patterns {
            let symmetry = getSymmetry(pattern: pattern)
            if symmetry > 0 {
                sum += symmetry * 100
            }
            let patternTransposed = Pattern(tiles: pattern.tiles.transposed())
            let symmetryTransposed = getSymmetry(pattern: patternTransposed)
            if symmetryTransposed > 0 {
                sum += symmetryTransposed
            }
        }

        return sum
    }

    func getSymmetry(pattern: Pattern) -> Int {
        let patternHeight = pattern.tiles.count

        for y in 0..<patternHeight-1 {
            let height = min(y+1, patternHeight - y - 1)

            let firstSegment = (y-height+1)...y
            let secondSegment = (y+1)...(y+height)
            let first = Array(pattern.tiles[firstSegment].reversed())
            let second = Array(pattern.tiles[secondSegment])
            if first == second {
                return y + 1
            }
        }
        return 0
    }
}

// MARK: - Part 1

func day13_Part1(url: URL) throws -> Int {
    let lines = try url.lines()
    let map = try Puzzle.create(from: lines)
    return map.solve1()
}

// MARK: - Part 2

func day13_Part2(url: URL) throws -> Int {
    let lines = try url.lines()
    let map = try Puzzle.create(from: lines)
    return map.solve2()
}

extension Puzzle {

    func solve2() -> Int {
        var sum = 0

        for pattern in patterns {
            let symmetry = getSymmetry2(pattern: pattern)
            if symmetry > 0 {
                sum += symmetry * 100
            }

            let patternTransposed = Pattern(tiles: pattern.tiles.transposed())
            let symmetryTransposed = getSymmetry2(pattern: patternTransposed)
            if symmetryTransposed > 0 {
                sum += symmetryTransposed
            }
        }

        return sum
    }

    func getSymmetry2(pattern: Pattern) -> Int {
        let patternHeight = pattern.tiles.count

        for y in 0..<patternHeight-1 {
            let height = min(y+1, patternHeight - y - 1)

            let firstSegment = (y-height+1)...y
            let secondSegment = (y+1)...(y+height)
            let first = Array(pattern.tiles[firstSegment].reversed())
            let second = Array(pattern.tiles[secondSegment])
            if first != second {
                // if they differ by only ONE TILE
                // change it and check again
                if let newRHS = getDifference(lhs: first, rhs: second) {
                    if first == newRHS {
                        return y + 1
                    }
                }
            }
        }
        return 0
    }

    func getDifference(lhs: [[Tile]], rhs: [[Tile]]) -> [[Tile]]? {
        assert(lhs.count == rhs.count)

        for (y, (l, r)) in zip(lhs, rhs).enumerated() {
            assert(l.count == r.count)
            if l == r {
                continue
            }
            for (x, (lTile, rTile)) in zip(l, r).enumerated() {
                if lTile != rTile {
                    var newRHS = rhs
                    newRHS[y][x] = lTile
                    return newRHS
                }
            }
        }
        return nil
    }

}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day13_Part1(url: inputURL)) // 33975

debugPrint(try day13_Part2(url: inputURL)) // 29083



