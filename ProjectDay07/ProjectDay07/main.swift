//
//  main.swift
//  ProjectDay07
//
//  Created by Aris Koxaras on 1/12/24.
//

import Foundation

// MARK: - Models

enum Card: String {
    case cA = "A"
    case cK = "K"
    case cQ = "Q"
    case cJ = "J"
    case cT = "T"
    case c9 = "9"
    case c8 = "8"
    case c7 = "7"
    case c6 = "6"
    case c5 = "5"
    case c4 = "4"
    case c3 = "3"
    case c2 = "2"

    func cardValue(useJoker: Bool) -> Int {
        switch self {
        case .cA:
            return 14
        case .cK:
            return 13
        case .cQ:
            return 12
        case .cJ:
            return useJoker ? 1 : 11
        case .cT:
            return 10
        case .c9:
            return 9
        case .c8:
            return 8
        case .c7:
            return 7
        case .c6:
            return 6
        case .c5:
            return 5
        case .c4:
            return 4
        case .c3:
            return 3
        case .c2:
            return 2
        }
    }
}

struct Hand {
    var cards: [Card]
    var bid: Int
    var type: HandType
}

extension Hand: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(cards.map { $0.rawValue }) \(bid) \(type)"
    }
}

extension Hand {
    init(from line: String, useJokers: Bool) throws {
        let cmps = line.split(separator: " ")
        assert(cmps.count == 2)
        assert(cmps[0].count == 5)

        self.cards = cmps[0].map { Card(rawValue: String($0))! }
        self.bid = Int(cmps[1])!
        self.type = try HandType(with: cards, useJokers: useJokers)
    }
}

enum HandType: Int {
    case fiveOfAKind = 7
    case fourOfAKind = 6
    case fullHouse = 5
    case threeOfAKind = 4
    case twoPair = 3
    case onePair = 2
    case highCard = 1
}

extension HandType {
    init(with cards: [Card], useJokers: Bool) throws {
        assert(cards.count == 5)

        var dict: [Card: Int] = [:]
        var jokerCount = 0

        for card in cards {
            if useJokers && card == .cJ {
                jokerCount += 1
            } else {
                dict[card, default: 0] += 1
            }
        }

        var values = dict.values.sorted()
        if useJokers {
            if jokerCount != 5 {
                values[values.count - 1] += jokerCount
            } else {
                // All values are jokers, but jokers were skipped
                values = [5]
            }
        }

        if values.last == 5 {
            self = .fiveOfAKind
        } else if values.last == 4 {
            assert(values == [1, 4])
            self = .fourOfAKind
        } else if values.last == 3 && values.dropLast().last == 2 {
            assert(values == [2, 3])
            self = .fullHouse
        }  else if values.last == 3 {
            assert(values == [1, 1, 3])
            self = .threeOfAKind
        } else if values.last == 2 && values.dropLast().last == 2 {
            assert(values == [1, 2, 2])
            self = .twoPair
        } else if values.last == 2 {
            assert(values == [1, 1, 1, 2])
            self = .onePair
        } else {
            assert(values == [1, 1, 1, 1, 1])
            self = .highCard
        }
    }
}

extension Hand {
    static func sortByCard(useJokers: Bool, lhs: Hand, rhs: Hand) -> Bool {
        if lhs.type.rawValue != rhs.type.rawValue {
            return lhs.type.rawValue > rhs.type.rawValue
        }

        for (l, r) in zip(lhs.cards, rhs.cards) {
            let lValue = l.cardValue(useJoker: useJokers)
            let rValue = r.cardValue(useJoker: useJokers)
            if lValue != rValue {
                return lValue > rValue
            }
        }
        return false

    }
}

struct Game {
    var hands: [Hand]
}

extension Game {
    func solve(useJokers: Bool) -> Int {
        let sortedHands = hands.sorted { Hand.sortByCard(useJokers: useJokers, lhs: $0, rhs: $1) }

        var result = 0
        for (index, hand) in sortedHands.enumerated() {
            result += (sortedHands.count - index) * hand.bid
        }

        return result
    }
}

// MARK: - Part 1

func day07(url: URL, useJokers: Bool) async throws -> Int {

    var hands = [Hand]()

    for try await line in  url.lines {
        let hand = try Hand(from: line, useJokers: useJokers)
        hands.append(hand)
    }

    let game = Game(hands: hands)
    return game.solve(useJokers: useJokers)
}

func day07_Part1(url: URL) async throws -> Int {

    return try await day07(url: url, useJokers: false)
}

// MARK: - Part 2

func day07_Part2(url: URL) async throws -> Int {

    return try await day07(url: url, useJokers: true)
}

// MARK: - Run

let exampleURL1 = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL1 = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try await day07_Part1(url: inputURL1)) // 250347426


let exampleURL2 = Bundle.main.url(forResource: "example", withExtension: "txt")!
let inputURL2 = Bundle.main.url(forResource: "input", withExtension: "txt")!

debugPrint(try await day07_Part2(url: inputURL2)) // 251224870
