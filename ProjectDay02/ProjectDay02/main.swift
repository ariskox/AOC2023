//
//  main.swift
//  ProjectDay02
//
//  Created by Aris Koxaras on 29/11/24.
//

import Foundation

let url = URL(fileURLWithPath: "/Users/ariskox/Desktop/AOC2023/ProjectDay02/ProjectDay02/input.txt")

let lines = [
    "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
    "Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue",
    "Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red",
    "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red",
    "Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"
]

struct Game {
    var id: Int
    var gameSet: [GameSet]
}

struct GameSet {
    var red: Int
    var green: Int
    var blue: Int
}

extension Game {
    init(line: String) {
        let cmps = line.components(separatedBy: ":")
        id = Int(cmps[0].replacingOccurrences(of: "Game ", with: ""))!
        let setsString = cmps[1].components(separatedBy: ";")
        gameSet = setsString.map { GameSet(line: $0) }
    }
}

extension GameSet {
    init(line: String) {
        var red: Int = 0
        var green: Int = 0
        var blue: Int = 0

        let cmps = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for cmp in cmps {
            if cmp.contains("red") {
                red = Int(cmp.replacingOccurrences(of: " red", with: ""))!
            } else if cmp.contains("green") {
                green = Int(cmp.replacingOccurrences(of: " green", with: ""))!
            } else if cmp.contains("blue") {
                blue = Int(cmp.replacingOccurrences(of: " blue", with: ""))!
            } else {
                fatalError()
            }
        }
        self.red = red
        self.green = green
        self.blue = blue
    }
}

func day2_Part1() async throws -> Int {
    let maxRed = 12
    let maxGreen = 13
    let maxBlue = 14

    var sum = 0
//    for line in lines {
    for try await line in url.lines {
        let game = Game(line: line)
        var isPossible = true

        for gameSet in game.gameSet {
            if gameSet.red > maxRed || gameSet.green > maxGreen || gameSet.blue > maxBlue {
                isPossible = false
                break
            }
        }
        if isPossible {
            sum += game.id
        }
    }

    return sum
}

func day2_Part2() async throws -> Int {

    var sum = 0
//    for line in lines {
    for try await line in url.lines {
        let game = Game(line: line)

        var minRed = 0
        var minGreen = 0
        var minBlue = 0

        for gameSet in game.gameSet {
            minRed = max(minRed, gameSet.red)
            minGreen = max(minGreen, gameSet.green)
            minBlue = max(minBlue, gameSet.blue)
        }
        let power = minRed * minGreen * minBlue
        sum += power
    }

    return sum
}

debugPrint(try await day2_Part2())
