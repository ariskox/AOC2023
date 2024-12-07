//
//  main.swift
//  ProjectDay14
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

enum Tile: String, Hashable {
    case empty = "."
    case rock = "#"
    case roundedRock = "O"
}


struct Puzzle: Hashable {
    var tiles: [[Tile]]
}

extension Puzzle: CustomDebugStringConvertible {
    var debugDescription: String {
        tiles.map { $0.map { $0.rawValue }.joined() }.joined(separator: "\n")
    }
}

extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        var tiles = [[Tile]]()

        for line in textLines {
            let lineTiles = line.map { Tile(rawValue: String($0))! }
            assert(lineTiles.count > 0 )
            tiles.append(lineTiles)
        }
        assert(tiles.count > 0)
        return Puzzle(tiles: tiles)
    }
}

extension Puzzle {
    func solve1() -> Int {
        var totalLoad = 0

        let tilesT = tiles.transposed()

        for row in tilesT {
            var weight = row.count

            for (idx, item) in row.enumerated() {
                switch item {
                case .rock:
                    weight = row.count - idx - 1
                case .roundedRock:
                    totalLoad += weight
                    weight -= 1
                    break
                case .empty:
                    break
                }
            }
        }

        return totalLoad
    }
}

// MARK: - Part 1

func day14_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve1()
}

// MARK: - Part 2

func day14_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve2()
}

extension Puzzle {

    func solve2() -> Int {
        var p = self

        // Puzzle : iteration #
        var cachedPuzzles: [Puzzle: Int] = [:]

        var remainingCycles = 1_000_000_000
        var currentCycle = 0

        while remainingCycles > 0 {
            p = p.performCycle()
            if let puzzleSeenAtIteratationWithNumber = cachedPuzzles[p] {

                let step = currentCycle - puzzleSeenAtIteratationWithNumber
                let remainder = remainingCycles % step
//                debugPrint("In iteration \(current) found a cycle at \(previousPuzzleIteration) with \(current - previousPuzzleIteration) step difference. setting remainder = \(remainder)")

                remainingCycles = remainder - 1

                // Way 1: Find the puzzle that would be loaded at the end of "remaining turns"
                if let puzzle = cachedPuzzles.first(where: { $0.value == puzzleSeenAtIteratationWithNumber + remainingCycles })?.key {
//                    debugPrint("would return load \(puzzle.getLoad())")
                    return puzzle.getLoad()
                }

                // Way 2: start over
//                currentCycle = 0
//                cachedPuzzles = [:]

                // Way 3: Perform the remaining cycles
//                while remainingCycles > 1 {
//                    p = p.performCycle()
//                    remainingCycles -= 1
//                }
//                break
            } else {
                cachedPuzzles[p] = currentCycle
                currentCycle += 1
                remainingCycles -= 1
            }
        }

        return p.getLoad()
    }

    func getLoad() -> Int {
        var sum = 0
        let width = tiles[0].count

        for x in 0..<width {
            for y in 0..<tiles.count {
                let tile = tiles[y][x]
                switch tile {
                case .empty:
                    break
                case .rock:
                    break
                case .roundedRock:
                    sum += tiles.count - y
                }
            }
        }


        return sum
    }

    func performCycle() -> Puzzle {
        let p1 = moveAllToNorth()
        let p2 = p1.moveAllToWest()
        let p3 = p2.moveAllToSouth()
        let p4 = p3.moveAllToEast()
        return p4
    }

    func moveAllToEast() -> Puzzle {
        var newTiles = tiles

        for y in 0..<tiles.count {

            var lastX = tiles[0].count - 1
            var x = tiles[0].count - 1
            while x >= 0 {
                let tile = tiles[y][x]
                switch tile {
                case .empty:
                    break
                case .rock:
                    lastX = x - 1
                case .roundedRock:
                    newTiles[y][x] = .empty
                    newTiles[y][lastX] = .roundedRock
                    lastX -= 1
                }
                x -= 1
            }
        }

        return Puzzle(tiles: newTiles)
    }

    func moveAllToWest() -> Puzzle {
        var newTiles = tiles

        for y in 0..<tiles.count {

            var lastX = 0
            for x in 0..<tiles[0].count {

                let tile = tiles[y][x]
                switch tile {
                case .empty:
                    break
                case .rock:
                    lastX = x + 1
                case .roundedRock:
                    newTiles[y][x] = .empty
                    newTiles[y][lastX] = .roundedRock
                    lastX += 1
                }
            }
        }

        return Puzzle(tiles: newTiles)
    }

    func moveAllToNorth() -> Puzzle {
        var newTiles = tiles

        let width = tiles[0].count

        for x in 0..<width {
            var lastY = 0
            for y in 0..<tiles.count {
                let tile = tiles[y][x]
                switch tile {
                case .empty:
                    break
                case .rock:
                    lastY = y + 1
                case .roundedRock:
                    newTiles[y][x] = .empty
                    newTiles[lastY][x] = .roundedRock
                    lastY += 1
                }
            }
        }
        return Puzzle(tiles: newTiles)
    }

    func moveAllToSouth() -> Puzzle {
        var newTiles = tiles

        let width = tiles[0].count

        for x in 0..<width {
            var lastY = tiles.count - 1
            var y = tiles.count - 1
            while y >= 0 {
                let tile = tiles[y][x]
                switch tile {
                case .empty:
                    break
                case .rock:
                    lastY = y - 1
                case .roundedRock:
                    newTiles[y][x] = .empty
                    newTiles[lastY][x] = .roundedRock
                    lastY -= 1
                }
                y -= 1
            }
        }
        return Puzzle(tiles: newTiles)
    }

}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day14_Part1(url: inputURL)) // 110821
debugPrint(try day14_Part2(url: inputURL)) // 83516
