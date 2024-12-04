//
//  main.swift
//  ProjectDay11
//
//  Created by Aris Koxaras on 4/12/24.
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

extension Collection where Self.Iterator.Element: RandomAccessCollection {
    // PRECONDITION: `self` must be rectangular, i.e. every row has equal size.
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}


// MARK: - Models

enum Item: String {
    case space = "."
    case galaxy = "#"
}

struct Coordinate {
    var x: Int
    var y: Int
}

class Map {
    private var items: [[Item]]

    private var emptyLineIndices: [Int] = []
    private var emptyColumnIndices: [Int] = []

    init(items: [[Item]]) {
        self.items = items
    }
}

extension Map {
    static func create(from lines: [String]) throws -> Map {
        var items = [[Item]]()

        for line in lines {
            let row = line.map { Item(rawValue: String($0))! }
            assert(row.count > 0)
            items.append(row)
        }
        assert(items.count > 0)
        assert(items.count == items[0].count)
        assert(items.count == items[items.count-1].count)
        return Map(items: items)
    }

    func getEmptyLinesIndices() -> [Int] {
        let emptyLinesIdx = items.enumerated().filter { $0.element.allSatisfy { $0 == .space } }.map { $0.offset }

        return emptyLinesIdx
    }

    func getEmptyColumnsIndices() -> [Int] {
        let transposed = items.transposed()
        let emptyColumnsIdx = transposed.enumerated().filter { $0.element.allSatisfy { $0 == .space } }.map { $0.offset }
        return emptyColumnsIdx
    }

    func getGalaxies() -> [Coordinate] {
        var coords = [Coordinate]()

        for y in 0..<items.count {
            for x in 0..<items.count {
                if items[y][x] == .galaxy {
                    coords.append(Coordinate(x: x, y: y))
                }
            }
        }

        return coords
    }
}

extension Map {

    func solve(expandedSpaceWeight: Int) -> Int {
        var sumOfDistances = 0

        let galaxies = getGalaxies()
        emptyLineIndices = getEmptyLinesIndices()
        emptyColumnIndices = getEmptyColumnsIndices()

        for (idx, galaxy1) in galaxies.dropLast().enumerated() {
            for galaxy2 in galaxies[(idx+1)...] {
                let dxNormalSpace = abs(galaxy1.x - galaxy2.x)
                let dyNormalSpace = abs(galaxy1.y - galaxy2.y)
                let expandedSpace = getExpandedSpaceCount(from: galaxy1, to: galaxy2)
                let distance = dxNormalSpace + dyNormalSpace + (expandedSpaceWeight - 1) * expandedSpace
                sumOfDistances += distance
            }
        }
        return sumOfDistances
    }
}

extension Map {
    func getExpandedSpaceCount(from: Coordinate, to: Coordinate) -> Int {
        let minX = min(from.x, to.x)
        let maxX = max(from.x, to.x)
        let minY = min(from.y, to.y)
        let maxY = max(from.y, to.y)

        let columnsCrossed = emptyColumnIndices.filter { $0 >= minX && $0 <= maxX }
        let linesCrossed = emptyLineIndices.filter { $0 >= minY && $0 <= maxY }

        let count = columnsCrossed.count + linesCrossed.count

        return count
    }
}

// MARK: - Part 1

func day11_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Map.create(from: lines)
    return map.solve(expandedSpaceWeight: 2)
}

// MARK: - Part 2

func day11_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Map.create(from: lines)
    return map.solve(expandedSpaceWeight: 1_000_000)
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day11_Part1(url: inputURL)) // 9623138

debugPrint(try day11_Part2(url: inputURL)) // 726820169514


