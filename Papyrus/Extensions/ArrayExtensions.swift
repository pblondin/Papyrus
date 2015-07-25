//
//  ArrayExtensions.swift
//  Papyrus
//
//  Created by Chris Nevin on 25/07/2015.
//  Copyright © 2015 CJNevin. All rights reserved.
//

import Foundation

extension Array {
    /// Return first element and all remaining items separately
    var decompose: (head: Element, tail: [Element])? {
        return (count > 0) ? (self[0], Array(self[1..<count])) : nil
    }
}

func between<T>(x: T, arr: [T]) -> [[T]] {
    if let (head, tail) = arr.decompose {
        return [[x] + arr] + between(x, arr: tail).map { [head] + $0 }
    } else {
        return [[x]]
    }
}

/// Return all permutations of a given array [1,2] = [[1,2], [2,1]]
func permutations<T>(arr: [T]) -> [[T]] {
    if let (head, tail) = arr.decompose {
        return permutations(tail) >>= { permTail in
            between(head, arr: permTail)
        }
    } else {
        return [[]]
    }
}

/// Iterate, with looping if boundary is passed
func iterate<T>(arr: Array<T>, start: Int, callback: (T) -> ()) {
    let count = arr.count
    for index in start..<(start + count) {
        callback(arr[index % count])
    }
}

/// Calculate min and max values of a given Int array
func minMax(values: [Int]) -> (min: Int, max: Int) {
    return (min: values.reduce(Int.max){min($0, $1)},
        max: values.reduce(Int.min){max($0, $1)})
}

/// Check if boundaries of minMax result match
func minEqualsMax(f: (min: Int, max: Int)) -> Int? {
    return f.min == f.max ? f.max : nil
}
