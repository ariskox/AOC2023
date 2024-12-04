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
    case expandedSpace = "X"
}

struct Coordinate {
    var x: Int
    var y: Int
}

class Map {
    var width: Int
    var height: Int

    var items: [[Item]]

    init(width: Int, height: Int, items: [[Item]]) {
        self.width = width
        self.height = height
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
        assert(items.count > 0 )
        let w = items.first!.count
        let h = items.count
        return Map(width: w, height: h, items: items)
    }

    func expandEmptySpaces() {
        let emptyLinesIdx = items.enumerated().filter { $0.element.allSatisfy { $0 == .space } }.map { $0.offset }

        let transposed = items.transposed()
        let emptyColumnsIdx = transposed.enumerated().filter { $0.element.allSatisfy { $0 == .space } }.map { $0.offset }

        for emptyLineIdx in emptyLinesIdx.reversed() {
            let newLine = Array(repeating:  Item.expandedSpace, count: width)
            items.insert(newLine, at: emptyLineIdx)
        }

        for emptyColumnIdx in emptyColumnsIdx.reversed() {
            for i in 0..<items.count {
                items[i].insert(.expandedSpace, at: emptyColumnIdx)
            }
        }

        width = items.first!.count
        height = items.count
    }

    func getGalaxies() -> [Coordinate] {
        var coords = [Coordinate]()

        for y in 0..<height {
            for x in 0..<width {
                if items[y][x] == .galaxy {
                    coords.append(Coordinate(x: x, y: y))
                }
            }
        }

        return coords
    }
}

extension Map {

    func solve1() -> Int {
        var sumOfDistances = 0

        expandEmptySpaces()
        let galaxies = getGalaxies()

        for (idx, galaxy1) in galaxies.dropLast().enumerated() {
            for galaxy2 in galaxies[(idx+1)...] {
                let dxNormalSpace = abs(galaxy1.x - galaxy2.x)
                let dyNormalSpace = abs(galaxy1.y - galaxy2.y)
                let distance = dxNormalSpace + dyNormalSpace
                sumOfDistances += distance
            }
        }
        return sumOfDistances
    }

}

// MARK: - Part 1

func day11_Part1(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Map.create(from: lines)
    return map.solve1()
}

// MARK: - Part 2

func day11_Part2(url: URL) throws -> Int {
    let lines = try url.nonEmptyLines()
    let map = try Map.create(from: lines)
    return map.solve2()
}

extension Map {
    func solve2() -> Int {
        var sumOfDistances = 0

        expandEmptySpaces()
        let galaxies = getGalaxies()

        for (idx, galaxy1) in galaxies.dropLast().enumerated() {
            for galaxy2 in galaxies[(idx+1)...] {
                let dxNormalSpace = abs(galaxy1.x - galaxy2.x)
                let dyNormalSpace = abs(galaxy1.y - galaxy2.y)

                let expandedSpace = getExpandedSpaceCount(from: galaxy1, to: galaxy2)
                let distance = dxNormalSpace + dyNormalSpace - 2 * expandedSpace + 1_000_000 * expandedSpace

                sumOfDistances += distance
            }
        }
        return sumOfDistances
    }

    func getExpandedSpaceCount(from: Coordinate, to: Coordinate) -> Int {
        var count = 0
        let fromX = min(from.x, to.x)
        let toX = max(from.x, to.x)

        for x in (fromX)...toX {
            let item = items[from.y][x]
            if item == .expandedSpace {
                count += 1
            }
        }

        let fromY = min(from.y, to.y)
        let toY = max(from.y, to.y)

        for y in (fromY)...toY {
            let item = items[y][from.x]
            if item == .expandedSpace {
                count += 1
            }
        }

        return count
    }

}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try day11_Part1(url: inputURL)) // 9623138

debugPrint(try day11_Part2(url: inputURL)) // 726820169514


