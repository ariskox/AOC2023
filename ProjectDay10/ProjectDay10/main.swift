//
//  main.swift
//  ProjectDay10
//
//  Created by Aris Koxaras on 3/12/24.
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

// MARK: - Models

struct Size {
    var width: Int
    var height: Int
}

struct Point: Hashable {
    var x: Int
    var y: Int
}

struct Map {
    var size: Size
    var startingPoint: Point
    var tiles: [[Tile]]
}

enum Tile {
    case ground
    case starting
    case pipe(Pipe)
}

extension Tile {
    var isStartingPoint: Bool {
        switch self {
        case .starting:
            return true
        default:
            return false
        }
    }
}

enum Pipe: String {
    case vertical = "|"
    case horizontal = "-"
    case northEast = "L"
    case northWest = "J"
    case southWest = "7"
    case southEast = "F"
}

enum Direction {
    case north
    case south
    case east
    case west
}

extension Tile {
    init(rawValue: Character) throws {
        let str = String(rawValue)
        if let pipe = Pipe(rawValue: str) {
            self = .pipe(pipe)
        } else if str == "S" {
            self = .starting
        } else if str == "." {
            self = .ground
        } else {
            throw NSError(domain: "Invalid value: \(rawValue)", code: 0)
        }
    }
}

extension Map {
    init(from lines: [String]) throws {
        let size = Size(width: lines[0].count, height: lines.count)
        var tiles = [[Tile]]()
        var startingPoint: Point?

        for (y, line) in lines.enumerated() {
            let row = try line.map { try Tile(rawValue: $0) }
            if let x = row.firstIndex(where: { $0.isStartingPoint }) {
                startingPoint = Point(x: x, y: y)
            }
            tiles.append(row)
        }
        assert(size.width > 0)
        assert(size.height > 0)
        assert(startingPoint != nil)
        self.size = size
        self.tiles = tiles
        self.startingPoint = startingPoint!
    }
}

extension Pipe {
    var availableDirections: [Direction] {
        switch self {
        case .horizontal:
            [.east, .west]
        case .vertical:
            [.north, .south]
        case .northEast:
            [.north, .east]
        case .northWest:
            [.north, .west]
        case .southWest:
            [.south, .west]
        case .southEast:
            [.south, .east]
        }
    }
}

extension Map {

    func solve1() -> (Int, Set<Point>) {
        var pathSize = 0
        var visited: Set<Point> = []
        var queue: [Point] = [startingPoint]
        var distance: [Point: Int] = [:]
        distance[startingPoint] = 0

        while !queue.isEmpty {
            let current = queue.removeFirst()
            visited.insert(current)
            let availableDirections = availableDirections(at: current)
            for direction in availableDirections {
                if let next = getPoint(direction, of: current), !visited.contains(next) {
                    queue.append(next)
                }
            }
            pathSize += 1
        }
        return ((pathSize - 1 ) / 2, visited)
    }

    func availableDirections(at point: Point) -> [Direction] {
        var directions: [Direction] = []
        let tile = tiles[point.y][point.x]

        switch tile {
        case .ground:
            return []
        case .starting:
            if let north = getPoint(.north, of: point), availableDirections(at: north).contains(.south) {
                directions.append(.north)
            }
            if let south = getPoint(.south, of: point), availableDirections(at: south).contains(.north) {
                directions.append(.south)
            }
            if let west = getPoint(.west, of: point), availableDirections(at: west).contains(.east) {
                directions.append(.west)
            }
            if let east = getPoint(.east, of: point), availableDirections(at: east).contains(.west) {
                directions.append(.east)
            }
            assert(directions.count == 2)
        case .pipe(let pipe):
            directions = pipe.availableDirections
        }

        assert(directions.count == 2)
        return directions
    }

    func getPoint(_ direction: Direction, of point: Point) -> Point? {
        switch direction {
        case .north:
            point.y - 1 >= 0 ? Point(x: point.x, y: point.y - 1) : nil
        case .south:
             point.y + 1 < size.height ? Point(x: point.x, y: point.y + 1) : nil
        case .west:
            point.x - 1 >= 0 ? Point(x: point.x - 1, y: point.y) : nil
        case .east:
            point.x + 1 < size.width ? Point(x: point.x + 1, y: point.y) : nil
        }
    }
}

// MARK: - Part 1

func day10_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Map(from: lines)
    return map.solve1().0
}

// MARK: - Part 2

func day10_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Map(from: lines)
    return map.solve2()
}

extension Map {
    func solve2() -> Int {
        let (_, visited) = solve1()
        var count = 0

        var lines: [String] = []
        for y in 0..<size.height {
            var crosses = 0
            var line = ""
            for x in 0..<size.width {
                let point = Point(x: x, y: y)
                let tile = tiles[y][x]
                var type = "."

                if visited.contains(point) {
                    switch tile {
                    case .pipe(let pipe):
                        switch pipe {
                        case .vertical:
                            crosses += 1
                            type = "x"
                        case .northWest:
//                            crosses += 1
                            type = "x"
                        case .southWest:
                            crosses += 1
                            type = "x"
                        case .northEast:
//                            crosses += 1
                            type = "x"
                        case .southEast:
                            crosses += 1
                            type = "x"
                        case .horizontal:
                            type = "x"
                            break
                        }
                    case .starting:
                        type = "x"
                        crosses += 1
                    default:
                        fatalError()
                    }
                } else if crosses % 2 == 1 {
                    switch tile {
                    case .ground:
                        type = "I"
                        count += 1
                    case .pipe:
                        type = "I"
                        count += 1
                    case .starting:
                        fatalError()
                    }
                }
                line += type
            }
            lines.append(line)
        }

//        print(lines.joined(separator: "\n"))
        return count
    }

}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let example2URL = Bundle.main.url(forResource: "example2", withExtension: "txt")!
let example3URL = Bundle.main.url(forResource: "example3", withExtension: "txt")!
let example4URL = Bundle.main.url(forResource: "example4", withExtension: "txt")!
let example5URL = Bundle.main.url(forResource: "example4", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day10_Part1(url: inputURL)) // 6931

debugPrint(try day10_Part2(url: inputURL)) // 357

