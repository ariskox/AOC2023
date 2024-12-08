//
//  main.swift
//  ProjectDay17
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
    static func create(from string: Substring) throws -> Int {
        guard let value = Int(string) else {
            throw NSError(domain: "Invalid value", code: 0)
        }
        return value
    }
}

// MARK: - Directions & Coordinates

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

//    var reverse: Direction {
//        switch self {
//        case .north:
//            return .south
//        case .south:
//            return .north
//        case .east:
//            return .west
//        case .west:
//            return .east
//        }
//    }
//
    var restAndNotReverse: [Direction] {
        switch self {
        case .north:
            return [.east, .west]
        case .south:
            return [.east, .west]
        case .east:
            return [.north, .south]
        case .west:
            return [.north, .south]
        }
    }
}

struct Coordinate: Hashable, Equatable {
    var x: Int
    var y: Int
}

extension Coordinate {
    func move(_ direction: Direction) -> Coordinate {
        self + direction.move
    }
}

struct Vector: Hashable, Equatable {
    var dx: Int
    var dy: Int
}

extension Coordinate {
    static func +(lhs: Coordinate, rhs: Vector) -> Coordinate {
        Coordinate(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }
}

struct DirectionalCoordinate: Hashable {
    var coordinate: Coordinate
    var direction: Direction
}

// MARK: - Models

struct Puzzle: Hashable {
    var tiles: [[Int]]
    var width: Int
    var height: Int
}

extension Puzzle {
    static func create(from textLines: [String]) throws -> Puzzle {
        var tiles = [[Int]]()

        for line in textLines {
            assert(line.count > 0)
            let row = try line.map { try Int.create(from: String($0)) }
            tiles.append(row)
        }
        assert(tiles.count > 0)
        return Puzzle(tiles: tiles, width: tiles[0].count, height: tiles.count)
    }
}

struct State {
    var coordinate: Coordinate
    var direction: Direction
    var successive: Int
    var cost: Int
}

struct StateKey: Hashable {
    var coordinate: Coordinate
    var direction: Direction
    var successive: Int
}

extension StateKey {
    init(_ state: State) {
        self.coordinate = state.coordinate
        self.direction = state.direction
        self.successive = state.successive
    }
}

class PQueue {
    private var items: [Int: [State]] = [:]
    private var priorities: [Int] = []

    func dequeue() -> State? {
        guard let p = priorities.first else {
            return nil
        }
        var array = items[p]!
        let f = array.first

        array.removeFirst()
        if array.isEmpty {
            items[p] = nil
            priorities.removeFirst()
        } else {
            items[p] = array
        }
        return f
    }

    func enqueue(_ item: State, _ priority: Int) {
        if items[priority] == nil {
            items[priority] = [item]
            let idx = priorities.firstIndex(where: { $0 > priority}) ?? priorities.endIndex
            priorities.insert(priority, at: idx)
        } else {
            items[priority]!.append(item)
        }
    }
}

extension Puzzle {
    func solve1(minSuccessive: Int, maxSuccessive: Int) -> Int {
        let target = Coordinate(x: width-1, y: height-1)
        var visited = Set<StateKey>()
        let queue = PQueue()

        queue.enqueue(State(coordinate: Coordinate(x: 0, y: 0), direction: .east, successive: 0, cost: 0), 0)
        queue.enqueue(State(coordinate: Coordinate(x: 0, y: 0), direction: .south, successive: 0, cost: 0), 0)

        while let curr = queue.dequeue() {
            let key = StateKey(curr)
            if visited.contains(key) {
                continue
            }
            visited.insert(key)
            if curr.coordinate == target {
                return curr.cost
            }
            if curr.successive < maxSuccessive {
                let next = curr.coordinate.move(curr.direction)
                if isInside(next) {
                    let newState = State(
                        coordinate: next,
                        direction: curr.direction,
                        successive: curr.successive + 1,
                        cost: curr.cost + tiles[next.y][next.x]
                    )
                    if visited.contains(StateKey(newState)) {
                        continue
                    }
                    queue.enqueue(newState, curr.cost + tiles[next.y][next.x])
                }
                if curr.successive < minSuccessive {
                    continue
                }
            }
            for direction in curr.direction.restAndNotReverse {
                let next = curr.coordinate.move(direction)
                if isInside(next) {
                    let newState = State(
                        coordinate: next,
                        direction: direction,
                        successive: 1,
                        cost: curr.cost + tiles[next.y][next.x]
                    )
                    if visited.contains(StateKey(newState)) {
                        continue
                    }
                    queue.enqueue(newState, curr.cost + tiles[next.y][next.x])
                }
            }
        }
        fatalError()
    }


    func isInside(_ coordinate: Coordinate) -> Bool {
        coordinate.x >= 0 && coordinate.x < width && coordinate.y >= 0 && coordinate.y < height
    }
}

// MARK: - Part 1

func day17_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve1(minSuccessive: 0, maxSuccessive: 3)
}

// MARK: - Part 2

func day17_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Puzzle.create(from: lines)
    return map.solve1(minSuccessive: 4, maxSuccessive: 10)
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

let startTime = CFAbsoluteTimeGetCurrent()

debugPrint(try day17_Part1(url: inputURL)) // 1039
debugPrint(try day17_Part2(url: inputURL)) // 1201

let endTime = CFAbsoluteTimeGetCurrent()
let executionTime = endTime - startTime
print("Execution time: \(executionTime) seconds")
