//
//  main.swift
//  ProjectDay04
//
//  Created by Aris Koxaras on 30/11/24.
//

import Foundation

// MARK: - Config

let exampleURL = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL = Bundle.main.url(forResource: "input", withExtension: "txt")!

// MARK: - Extensions

extension AsyncSequence {
    func collect() async throws -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

// MARK: - Models

enum Day04Error: Error {
    case invalidId(String)
    case invalidWinningNumber(String)
    case invalidMyNumber(String)
}

struct Card: Hashable {
    var id: Int
    var winningNumbers: [Int]
    var myNumbers: [Int]
}

// MARK: - Parsing

extension Card {
    init(line: String) throws {
        let cmps = line.components(separatedBy: "|")
        let cardPart = cmps[0].components(separatedBy: ":")
        let idStr = cardPart.first?.split(separator: " ").last.flatMap({ String($0) }) ?? ""

        guard let id = Int(idStr) else {
            throw Day04Error.invalidId(line)
        }

        let winningNumbers = try cardPart[1].components(separatedBy: " ").filter({ !$0.isEmpty }).map {
            guard let num = Int($0) else { throw Day04Error.invalidWinningNumber(line) }
            return num
        }
        let myNumbers = try cmps[1].components(separatedBy: " ").filter({ !$0.isEmpty }).map {
            guard let num = Int($0) else { throw Day04Error.invalidMyNumber(line) }
            return num
        }

        self.id = id
        self.winningNumbers = winningNumbers
        self.myNumbers = myNumbers
    }
}

// MARK: - Part 1

extension Card {
    func getMatches() -> Int {
        var matches: Int = 0

        var winIter = winningNumbers.sorted().makeIterator()
        var myIter = myNumbers.sorted().makeIterator()

        var winNum = winIter.next()
        var myNum = myIter.next()

        while winNum != nil && myNum != nil {
            if winNum! == myNum! {
                matches += 1
                winNum = winIter.next()
                myNum = myIter.next()
            } else if winNum! < myNum! {
                winNum = winIter.next()
            } else if winNum! > myNum! {
                myNum = myIter.next()
            }
        }

        return matches
    }

    func getMatchingScore() -> Int {
        let matches = getMatches()
        guard matches > 0 else {
            return 0
        }
        return (1..<matches).reduce(1, { a, b in a * 2 } )
    }
}

func day04_Part1(url: URL) async throws -> Int {

    let cards = try await url.lines.map { try Card(line: $0) }.collect()
    let sum = cards.map { $0.getMatchingScore() }.reduce(0, +)

    return sum
}


// MARK: - Part 2

struct Game {
    var cards: [Card]
}

extension Game {

    func play() -> Int {
        var pile: [Int] = (0..<cards.count).map { _ in 1 }
        var index = 0

        while index < cards.count {
            if pile[index] == 0 {
                index += 1
                continue
            }
            let card = cards[index]
            let matches = card.getMatches()
            if matches == 0 {
                index += 1
                continue
            }
            let numberOfCards = pile[index]
            for i in 1...matches {
                pile[index+i] += numberOfCards
            }
            index += 1
        }

        return pile.reduce(0, +)
    }
}

func day04_Part2(url: URL) async throws -> Int {
    let cards = try await url.lines.map { try Card(line: $0) }.collect()
    let game = Game(cards: cards)

    return game.play()
}

// MARK: - Run

debugPrint(try await day04_Part1(url: exampleURL))
