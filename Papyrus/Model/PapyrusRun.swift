//
//  PapyrusRun.swift
//  Papyrus
//
//  Created by Chris Nevin on 23/07/2015.
//  Copyright © 2015 CJNevin. All rights reserved.
//

import Foundation

extension Papyrus {
    typealias Run = [(offset: Offset, tile: Tile?)]
    typealias Runs = [Run]
    
    func currentRuns() -> Runs {
        return runs(withTiles: tiles(withPlacement: .Rack, owner: player))
    }
    
    /// Return an array of `runs` surrounding tiles played on the board.
    func runs(withTiles userTiles: [Tile]) -> Runs {
        let fixedTiles = tiles(withPlacement: .Fixed, owner: nil)
        let rackAmount = userTiles.count
        let checkCentre = fixedTiles.count == 0
        var runs = Runs()
        var buffer = Run()
        func validateRun(run: Run) {
            if checkCentre {
                if run.filter({$0.0 == PapyrusMiddleOffset}).count > 0 && run.count > 1 && run.count <= rackAmount {
                    runs.append(run)
                }
            } else {
                let letters = run.filter({$0.1 != nil}).map({$0.1!}).filter({fixedTiles.contains($0)}).count
                let diff = run.count - letters
                if letters > 0 && diff > 0 && diff <= rackAmount {
                    runs.append(run)
                }
            }
        }
        func checkOffset(offset: Offset?) {
            if let o = offset {
                if let tile = fixedTiles.filter({$0.square?.offset == o}).first {
                    buffer.append((o, tile))
                } else {
                    buffer.append((o, nil))
                }
                validateRun(buffer)
                for n in 1..<buffer.count {
                    let shaved = Array(buffer[n..<buffer.count])
                    validateRun(shaved)
                }
            }
        }
        
        let range = 1...PapyrusDimensions
        for x in range {
            buffer = Run()
            range.map({checkOffset(Offset.at(x: x, y: $0))})
        }
        for y in range {
            buffer = Run()
            range.map({checkOffset(Offset.at(x: $0, y: y))})
        }
        return runs
    }
}