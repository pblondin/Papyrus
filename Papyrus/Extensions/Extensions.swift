//
//  Extensions.swift
//  Papyrus
//
//  Created by Chris Nevin on 3/07/2015.
//  Copyright © 2015 CJNevin. All rights reserved.
//

import Foundation

infix operator |>   { precedence 50 associativity left }

func |><T,U>(lhs: T, rhs: T -> U) -> U {
    return rhs(lhs)
}

infix operator >>=  { precedence 50 associativity left }

func >>=<A, B>(arr: [A], f: A -> [B]) -> [B] {
    return arr.map(f).reduce([], combine: +)
}

infix operator <~>  { precedence 50 associativity left }

func <~><T: IntegerType>(lhs: T, rhs: (T, T)) -> T? {
    guard lhs > rhs.0 && lhs < rhs.1 else { return nil }
    return lhs
}

func <~><T: IntegerType>(lhs: (T, T), rhs: (T, T)) -> (T, T)? {
    guard let a = lhs.0 <~> rhs, b = lhs.1 <~> rhs else { return nil }
    return (a, b)
}

func <~><T: IntegerType>(lhs: [(T, T)], rhs: (T, T)) -> [(T, T)]? {
    guard let a = lhs.map({($0 <~> rhs)}) as? [(T, T)] where a.count == lhs.count else { return nil }
    return a
}
