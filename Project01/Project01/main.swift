//
//  main.swift
//  Project01
//
//  Created by Aris Koxaras on 29/11/24.
//

import Foundation


func day1() async throws {
    let url = URL(fileURLWithPath: "/Users/ariskox/Desktop/AOC2023/Problem01/Project01/Project01/input.txt")

    var sum = 0
    for try await line in url.lines {
        let numbers = String(line.filter { $0.isNumber })
        let number = Int(String(numbers.first!))! * 10 + Int(String(numbers.last!))!

        debugPrint("for line \(line) ------ \(numbers) -> \(number)")
        sum += number
    }

    debugPrint(sum)
}

func day1a() async throws {
    let url = URL(fileURLWithPath: "/Users/ariskox/Desktop/AOC2023/Problem01/Project01/Project01/input.txt")
    let numbers = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    var sum = 0
    for try await unprocessedLine in url.lines {
        var line = ""
        var remaining = unprocessedLine.lowercased()

        while remaining.count > 0 {
            var found = false
            for (index, numberLiteral) in numbers.enumerated() {
                if remaining.hasPrefix(numberLiteral) {
                    line += String(index+1)
                    remaining = String(remaining.dropFirst())
                    found = true
                    break
                }
            }
            if !found {
                line += String(remaining.first!)
                remaining = String(remaining.dropFirst())
            }
        }

        let numbers = String(line.filter { ["1", "2", "3", "4", "5", "6", "7", "8", "9"].contains($0) })
        assert(numbers.count > 0)

        let number = Int(String(numbers.first!))! * 10 + Int(String(numbers.last!))!
        sum += number
        debugPrint("for line \(unprocessedLine) ------> \(line) ---> \(numbers) -> \(number)")
    }
    debugPrint(sum)
}
