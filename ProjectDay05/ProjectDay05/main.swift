//
//  main.swift
//  ProjectDay05
//
//  Created by Aris Koxaras on 30/11/24.
//

import Foundation

// MARK: - Extensions

extension AsyncSequence {
    func collect() async throws -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

// MARK: - Models

struct Seed {
    var name: String = "seed"
    let id: Int
}

extension Seed {
    static func create(from line: String) -> [Seed] {
        assert(line.hasPrefix("seeds:"))

        let seeds = line.dropFirst("seeds:".count).split(separator: " ").map { Int($0)! }
        return seeds.map { Seed(id: $0) }
    }
}

struct Mapper {
    var fromName: String
    var toName: String

    var maps: [MapRange]

}

struct MapRange {
    var from: ClosedRange<Int>
    var to: ClosedRange<Int>
}

extension MapRange {
    init(from line: String) {
        let cmps = line.split(separator: " ").compactMap { Int($0) }
        assert(cmps.count == 3)
        let fromStart = cmps[1]
        let toStart = cmps[0]
        let itemCount = cmps[2]
        assert(itemCount > 0)

        self.from = fromStart...(fromStart+itemCount-1)
        self.to = toStart...(toStart+itemCount-1)
    }
}

extension Mapper {
    func mapNode(id: Int) -> Int {
        for map in maps {
            if map.from.contains(id) {
                return id - map.from.lowerBound + map.to.lowerBound
            }
        }
        return id
    }

    static func create(from lines: [String]) -> [Mapper] {
        var mappers: [Mapper] = []

        var activeMapper: Mapper? = nil

        for line in lines.dropFirst() {
            if line.hasSuffix(" map:") {
                if activeMapper != nil {
                    mappers.append(activeMapper!)
                }
                let rest = line.dropLast(" map:".count).components(separatedBy: "-")
                assert(rest.count == 3)
                activeMapper = Mapper(fromName: rest[0], toName: rest[2], maps: [])
            } else {
                assert(activeMapper != nil)
                let mapRange = MapRange(from: line)
                activeMapper?.maps.append(mapRange)
            }
        }
        if activeMapper != nil {
            mappers.append(activeMapper!)
        }

        return mappers
    }
}

struct Puzzle {
    var seeds: [Seed] = []
    var seedRanges: [SeedRanges] = []
    var mappers: [Mapper]
}

extension Puzzle {
    func getMapper(from name: String) -> Mapper? {
        mappers.first { $0.fromName == name }
    }

    func getLocation(for seedId: Int) -> Int {
        var id = seedId
        var mapper: Mapper? = getMapper(from: "seed")
        var lastMapperTo: String?

        while mapper != nil {
            lastMapperTo = mapper!.toName
            id = mapper!.mapNode(id: id)
            mapper = getMapper(from: mapper!.toName)
        }
        assert(lastMapperTo == "location")
        return id
    }

    func solve() -> Int {
        var minLocation = Int.max

        for seed in seeds {
            minLocation = min(minLocation, getLocation(for: seed.id))
        }

        return minLocation
    }
}

// MARK: - Part 1

func day05_Part1(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()

    let seeds = lines.first.map { Seed.create(from: $0) } ?? []
    let mappers = Mapper.create(from: lines)
    let puzzle = Puzzle(seeds: seeds, mappers: mappers)
    return puzzle.solve()
}

// MARK: - Part 2

struct SeedRanges {
    var range: ClosedRange<Int>

    static func create(from line: String) -> [SeedRanges] {
        let numbers = line.dropFirst("seeds:".count).split(separator: " ").map { Int($0)! }
        assert(numbers.count % 2 == 0)
        var iterator = numbers.makeIterator()

        var ranges: [SeedRanges] = []
        while let start = iterator.next(), let end = iterator.next() {
            ranges.append(SeedRanges(range: start...(start+end-1)))
        }

        return ranges
    }
}

extension Mapper {

    func mapRanges(_ ranges: [ClosedRange<Int>]) -> [ClosedRange<Int>] {
        var untranslatedRanges = ranges
        var newRanges = [ClosedRange<Int>]()

        while untranslatedRanges.count > 0 {
            var didFindAny = false

            for mapperRange in maps {
                if untranslatedRanges.count == 0 {
                    break
                }
                let origRange = untranslatedRanges.first!

                if origRange.overlaps(mapperRange.from) {
                    didFindAny = true
                    untranslatedRanges.removeFirst()

                    let (untrans, overlapping) = intersectRange(original: origRange, with: mapperRange.from)
                    untranslatedRanges.append(contentsOf: untrans)
                    newRanges.append(contentsOf: overlapping.map { mapperRange.mapRange(range: $0) } )
                }
            }
            if !didFindAny {
                newRanges.append(untranslatedRanges.removeFirst())
            }
        }

        return newRanges
    }

    func intersectRange(original: ClosedRange<Int>, with mask: ClosedRange<Int>) -> (unaffectedRanges: [ClosedRange<Int>], overlapingRanges: [ClosedRange<Int>]) {
        var unaffectedRanges = [ClosedRange<Int>]()
        var overlapingRanges = [ClosedRange<Int>]()

        if original.lowerBound < mask.lowerBound  {
            if original.upperBound <= mask.upperBound {
                // 2 ranges
                let unaffected = original.lowerBound...(mask.lowerBound-1)
                let overlapping = mask.lowerBound...original.upperBound
                unaffectedRanges.append(unaffected)
                overlapingRanges.append(overlapping)
            } else {
                // 3 ranges
                let unaffected1 = original.lowerBound...(mask.lowerBound-1)
                let overlapping = mask.lowerBound...mask.upperBound
                let unaffected2 = mask.upperBound...original.upperBound
                unaffectedRanges.append(unaffected1)
                unaffectedRanges.append(unaffected2)
                overlapingRanges.append(overlapping)
            }
        } else {
            if original.upperBound <= mask.upperBound {
                // 1 range
                let overlapping = original.lowerBound...original.upperBound
                overlapingRanges.append(overlapping)
            } else {
                // 2 ranges
                let overlapping = original.lowerBound...mask.upperBound
                let unaffected = (mask.upperBound+1)...original.upperBound
                overlapingRanges.append(overlapping)
                unaffectedRanges.append(unaffected)
            }
        }

        return (unaffectedRanges, overlapingRanges)
    }
}

extension MapRange {
    func mapRange(range: ClosedRange<Int>) -> ClosedRange<Int> {
        let diff = self.to.lowerBound - self.from.lowerBound
        return (range.lowerBound+diff)...(range.upperBound+diff)
    }
}

extension Puzzle {
    func solveWithRanges() -> Int {
        var minLocation = Int.max

        for seedRange in seedRanges {
            var ranges = [seedRange.range]
            var mapper: Mapper? = getMapper(from: "seed")
            var lastMapperTo: String?

            while mapper != nil {
                lastMapperTo = mapper!.toName
                ranges = mapper!.mapRanges(ranges)
                mapper = getMapper(from: mapper!.toName)
            }
            assert(lastMapperTo == "location")
            for newRange in ranges {
                assert(newRange.lowerBound > 0 )
                minLocation = min(minLocation, newRange.lowerBound)
            }
        }

        return minLocation
    }
}

func day05_Part2(url: URL) async throws -> Int {
    let lines = try await url.lines.collect()

    let seedRanges = SeedRanges.create(from: lines.first!)
//    let seedRanges = [SeedRanges(range: 82...82)]
    let mappers = Mapper.create(from: lines)
    let puzzle = Puzzle(seedRanges: seedRanges, mappers: mappers)
    return puzzle.solveWithRanges()
}

// MARK: - Run

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

//debugPrint(try await day05_Part1(url: inputURL))  // 177942185
debugPrint(try await day05_Part2(url: inputURL)) // 69841803
