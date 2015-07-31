//
//  PapyrusSquare.swift
//  Papyrus
//
//  Created by Chris Nevin on 8/07/2015.
//  Copyright © 2015 CJNevin. All rights reserved.
//

import Foundation

func ==(lhs: Square, rhs: Square) -> Bool {
    return lhs.offset == rhs.offset
}

struct Square: Equatable, Hashable {
    enum Modifier: String {
        case None = "_"
        case Center = "X"
        case Letterx2 = "D"
        case Letterx3 = "T"
        case Wordx2 = "W"
        case Wordx3 = "Z"
        var wordMultiplier: Int {
            switch (self) {
            case .Center, .Wordx2: return 2
            case .Wordx3: return 3
            default: return 1
            }
        }
        var letterMultiplier: Int {
            switch (self) {
            case .Letterx2: return 2
            case .Letterx3: return 3
            default: return 1
            }
        }
    }
    let modifier: Modifier
    let offset: Offset
    func at(x xx: Int, y yy: Int, inArray arr: [[Square]]) -> Square? {
        guard let n = offset.at(x: xx, y: yy) else { return nil }
        return arr[n.x][n.y]
    }
    func advance(o: Orientation, amount: Int, inArray arr: [[Square]]) -> Square? {
        guard let n = offset.advance(o, amount: amount) else { return nil }
        return arr[n.x][n.y]
    }
    func next(o: Orientation, inArray arr: [[Square]]) -> Square? {
        return advance(o, amount: 1, inArray: arr)
    }
    func prev(o: Orientation, inArray arr: [[Square]]) -> Square? {
        return advance(o, amount: -1, inArray: arr)
    }
    var hashValue: Int {
        return "\(offset.x),\(offset.y)".hashValue
    }
}

extension Papyrus {
    class func createSquares() -> [[Square]] {
        let m = PapyrusMiddle
        let modifiers: [Square.Modifier: [Offset]] = [
            .Center: [(0,0)].symmetrical(),
            .Wordx3: [(m-1, m-1), (0, m-1)].symmetrical(),
            .Letterx2: [(1, 1), (1, 5), (0, 4), (m-1, 4)].symmetrical(),
            .Letterx3: [(2, 6), (2, 2)].symmetrical(),
            .Wordx2: [(3, 3), (4, 4), (5, 5), (6, 6)].symmetrical()
        ]
        let range = (1...PapyrusDimensions)
        return range.map { (x) -> [Square] in
            return range.mapFilter({ Offset(x: x, y: $0) }).map({ (offset) -> Square in
                return Square(
                    modifier: modifiers.filter({ $0.1.contains(offset) }).map({ $0.0 }).first ?? Square.Modifier.None,
                    offset: offset)
            })
        }
    }
}