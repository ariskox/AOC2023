//
//  main.swift
//  ProjectDay16
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

enum Tile: String {
    case empty = "."
    case bltrMirror = "/"
    case tlbrMirror = "\\"
    case vMirror = "|"
    case hMirror = "-"
}

struct Puzzle: Hashable {
    var tiles: [[Tile]]
}

extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        var tiles = [[Tile]]()

        for line in textLines {
            assert(line.count > 0)
            let row = line.map { Tile(rawValue: String($0))! }
            tiles.append(row)
        }
        assert(tiles.count > 0)
        return Puzzle(tiles: tiles)
    }
}

struct Coordinate: Hashable, Equatable {
    var x: Int
    var y: Int
}

struct Vector: Hashable, Equatable {
    var dx: Int
    var dy: Int
}

extension Puzzle {
    func solve1() -> Int {
        var visited = Set<VectoredCoordinate>()

        let beam = Beam(start: Coordinate(x: 0, y: 0), direction: .east, tiles: tiles)
        beam.travel(visited: &visited)

        let sum = Set(visited.map { $0.coordinate }).count
        return sum
    }
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

struct Beam {
    var start: Coordinate
    var direction: Direction
    var tiles: [[Tile]]
}

extension Coordinate {
    static func +(lhs: Coordinate, rhs: Vector) -> Coordinate {
        Coordinate(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }
}

struct VectoredCoordinate: Hashable {
    var coordinate: Coordinate
    var direction: Direction
}

extension Beam {

    func travel(visited: inout Set<VectoredCoordinate>) {
        var current = start
        var currentDirection = direction

        while current.x >= 0 && current.x < tiles[0].count && current.y >= 0 && current.y < tiles.count {
            let vc = VectoredCoordinate(coordinate: current, direction: currentDirection)
            guard !visited.contains(vc) else {
                break
            }
            visited.insert(vc)
            let tile = tiles[current.y][current.x]

            switch tile {
            case .empty:
                break
            case .bltrMirror:
                switch currentDirection {
                case .north:
                    currentDirection = .east
                case .south:
                    currentDirection = .west
                case .east:
                    currentDirection = .north
                case .west:
                    currentDirection = .south
                }
            case .tlbrMirror:
                switch currentDirection {
                case .north:
                    currentDirection = .west
                case .south:
                    currentDirection = .east
                case .east:
                    currentDirection = .south
                case .west:
                    currentDirection = .north
                }
            case .vMirror:
                switch currentDirection {
                case .north, .south:
                    break
                case .east, .west:
                    let newBeam = Beam(start: current + Direction.north.move, direction: .north, tiles: tiles)
                    newBeam.travel(visited: &visited)
                    currentDirection = .south
                }
            case .hMirror:
                switch currentDirection {
                case .north, .south:
                    // stay north & dispatch one to south
                    let newBeam = Beam(start: current + Direction.east.move, direction: .east, tiles: tiles)
                    newBeam.travel(visited: &visited)
                    currentDirection = .west
                case .east, .west:
                    break
                }

            }
            current = current + currentDirection.move
        }
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


extension Puzzle {

    func solve2() -> Int {
        var max = Int.min

        for y in 0..<tiles.count {
            let tupples: [(Int, Direction)] = [(0, .east), (tiles[0].count - 1, .west)]

            for (x, direction) in tupples {
                var visited = Set<VectoredCoordinate>()
                let beam = Beam(start: Coordinate(x: x, y: y), direction: direction, tiles: tiles)
                beam.travel(visited: &visited)

                let sum = Set(visited.map { $0.coordinate }).count
                max = max > sum ? max : sum
            }
        }

        for x in 0..<tiles.count {
            let tupples: [(Int, Direction)] = [(0, .south), (tiles.count - 1, .north)]

            for (y, direction) in tupples {
                var visited = Set<VectoredCoordinate>()
                let beam = Beam(start: Coordinate(x: x, y: y), direction: direction, tiles: tiles)
                beam.travel(visited: &visited)

                let sum = Set(visited.map { $0.coordinate }).count
                max = max > sum ? max : sum
            }
        }

        return max
    }

}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day15_Part1(url: inputURL)) // 7074
debugPrint(try day15_Part2(url: inputURL)) // 7530


