//
//  main.swift
//  ProjectDay03
//
//  Created by Aris Koxaras on 30/11/24.
//

import Foundation

//let url = URL(fileURLWithPath: "/Users/ariskox/Desktop/AOC2023/ProjectDay03/ProjectDay03/example.txt")
let url = URL(fileURLWithPath: "/Users/ariskox/Desktop/AOC2023/ProjectDay03/ProjectDay03/input.txt")

struct Map {
    var width: Int
    var lines: [Line] = []
}

struct Line {
    var numberMatches: [Match] = []
    var symbols: [Symbol] = []
}

struct Match {
    var location: Location
    var length: Int
    var value: Int
}

struct Symbol {
    var symbol: String
    var location: Location
}

struct Location: Equatable {
    var x: Int
    var y: Int
}

extension Line {
    init(line: String, y: Int) throws {
        let numberPattern = "\\d+"

        // Create a regular expression object
        let numberRegex = try NSRegularExpression(pattern: numberPattern)

        // Find matches in the input string
        var matches: [Match] = []
        let regExpMatches = numberRegex.matches(in: line, range: NSRange(line.startIndex..., in: line))
        for regExpMatch in regExpMatches {
            let m = Match(location: Location(x: regExpMatch.range.location, y: y), length: regExpMatch.range.length, value: Int((line as NSString).substring(with: regExpMatch.range))!)
            matches.append(m)
        }
        self.numberMatches = matches

        let symbolPattern = "[^0-9]"
        let symbolRegex = try NSRegularExpression(pattern: symbolPattern)

        var symbols: [Symbol] = []
        let symbolMatches = symbolRegex.matches(in: line, range: NSRange(line.startIndex..., in: line))
        for symbolMatch in symbolMatches {
            let string = (line as NSString).substring(with: symbolMatch.range)
            if string != "." {
                let location = Location(x: symbolMatch.range.location, y: y)
                let symbol = Symbol(symbol: string, location: location)
                symbols.append(symbol)
            }
        }
        self.symbols = symbols

    }
}

extension Map {
    func getPartNumbers() -> [Match] {
        var matches = [Match]()
        for (index, line) in lines.enumerated() {
            for match in line.numberMatches {
                let possibleSymbols = lines[max(0, index - 1)...min(lines.count - 1, index + 1)].flatMap { $0.symbols }.map { $0.location }

                var found = false

                let minY = max(0, match.location.y - 1)
                let maxY = min(lines.count - 1, match.location.y + 1)
                let minX = max(0, match.location.x - 1)
                let maxX = min(width - 1, match.location.x + match.length)

            outer:
                for y in minY...maxY {
                    for x in minX...maxX {
                        let loc = Location(x: x, y: y)
                        if possibleSymbols.contains(loc) {
                            found = true
                            break outer
                        }
                    }
                }

                if found {
                    matches.append(match)
                }
            }
        }
        return matches
    }

    func getGearPartNumbersRatios() -> [Int] {
        var ratios = [Int]()

        for line in lines {
            let gears = line.symbols.filter { $0.symbol == "*" }
            for gear in gears {
                if let (number, number2) = getAdjacentNumbers(location: gear.location) {
                    let ratio = number * number2
                    ratios.append(ratio)
                }
            }
        }
        return ratios
    }

    func getAdjacentNumbers(location: Location) -> (Int, Int)? {
        let minY = max(0, location.y - 1)
        let maxY = min(lines.count - 1, location.y + 1)
        let minX = max(0, location.x - 1)
        let maxX = min(width - 1, location.x + 1)

        var matches: [Match] = []
        for line in lines[minY...maxY] {
            let range1 = minX...maxX

            for number in line.numberMatches {
                let range2 = (number.location.x)...(number.location.x + number.length - 1)
                if range1.overlaps(range2) {
                    matches.append(number)
                }
            }
        }

        guard matches.count == 2 else {
            return nil
        }
        return (matches[0].value, matches[1].value)
    }
}

func day03_Part1() async throws -> Int {

    var lines: [Line] = []
    var width = 0

    var y = 0
    for try await fileLine in url.lines {
        let line = try Line(line: fileLine, y: y)
        width = fileLine.count

        lines.append(line)
        y += 1
    }
    let map = Map(width: width, lines: lines)

    let partNumbers = map.getPartNumbers()

    let sum = partNumbers.map { $0.value }.reduce(0, +)

    return sum
}

func day03_Part2() async throws -> Int {

    var lines: [Line] = []
    var width = 0

    var y = 0
    for try await fileLine in url.lines {
        let line = try Line(line: fileLine, y: y)
        width = fileLine.count

        lines.append(line)
        y += 1
    }
    let map = Map(width: width, lines: lines)

    let ratios = map.getGearPartNumbersRatios()

    let sum = ratios.reduce(0, +)

    return sum
}

debugPrint(try await day03_Part2())
