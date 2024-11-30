//
//  main.swift
//  ProjectDay06
//
//  Created by Aris Koxaras on 30/11/24.
//

import Foundation

// MARK: - Models

struct Race {
    var duration: Int
    var distance: Int
}

extension Race {

    func solve() -> Int {
        // time * (duration - time) > distance
        // Solve quadratic equation

        let discriminant = duration*duration - 4 * distance
        assert(discriminant >= 0, "No solution")

        let root = sqrt(Double(discriminant))

        let t1 = (Double(duration) - root) / 2
        let t2 = (Double(duration) + root) / 2
        assert(t1 > 0)
        assert(t2 > 0)
        assert(t1 != t2)

        let t1rounded = Int(ceil(t1))
        let t2rounded = Int(floor(t2))
        assert(t1rounded != t2rounded)

        let t1IsValid = t1rounded * (duration - t1rounded) > distance
        let t2IsValid = t2rounded * (duration - t2rounded) > distance

        let result = t2rounded - t1rounded - 1 + ( t1IsValid ? 1 : 0) + (t2IsValid ? 1 : 0)
        assert(result >= 1)

        return result
    }
}

// MARK: - Part 1

func day06_Part1(races: [Race]) -> Int {
    var results = [Int]()
    for race in races {
        results.append(race.solve())
    }

    return results.reduce(1, *)
}


// MARK: - Run

let exampleRaces = [
    Race(duration: 7, distance: 9),
    Race(duration: 15, distance: 40),
    Race(duration: 30, distance: 200)
]

let actualRaces = [
    Race(duration: 53, distance: 333),
    Race(duration: 83, distance: 1635),
    Race(duration: 72, distance: 1289),
    Race(duration: 88, distance: 1532)
]


//debugPrint(day06_Part1(races: actualRaces))  // 140220

let exampleRacePart2 = [
    Race(duration: 71530, distance: 940200)
]

let actualRacesPart2 = [
    Race(duration: 53837288, distance: 333163512891532)
]

debugPrint(day06_Part1(races: actualRacesPart2)) // 39570185

