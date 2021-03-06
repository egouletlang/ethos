//
//  Rect.swift
//  EthosUI
//
//  Created by Etienne Goulet-Lang on 4/20/19.
//  Copyright © 2019 egouletlang. All rights reserved.
//

import Foundation

open class Rect<T: Equatable>: NSObject, Sequence, NSCoding, NSCopying {
    
    // MARK: - Constants & Types
    fileprivate enum Archive: String {
        case left = "left"
        case top = "top"
        case right = "right"
        case bottom = "bottom"
    }
    
    // MARK: - Constructor
    public init(_ l: T, _ t: T,_ r: T,_ b: T) {
        self.left = l
        self.top = t
        self.right = r
        self.bottom = b
    }
    
    public convenience init?(_ l: [T]) {
        guard l.count >= 4 else { return nil }
        self.init(l[0], l[1], l[2], l[3])
    }
    
    public init(def: T) {
        self.left = (def as? NSCopying)?.copy(with: nil) as? T ?? def
        self.top = (def as? NSCopying)?.copy(with: nil) as? T ?? def
        self.right = (def as? NSCopying)?.copy(with: nil) as? T ?? def
        self.bottom = (def as? NSCopying)?.copy(with: nil) as? T ?? def
    }
    
    // MARK: - State variables
    open var left: T
    open var top: T
    open var right: T
    open var bottom: T
    
    // MARK: - Sequence methods
    open func makeIterator() -> IndexingIterator<[T]> {
        return [left, top, right, bottom].makeIterator()
    }
    
    // MARK: - Equatable Method -
    public static func == (lhs: Rect<T>, rhs: Rect<T>) -> Bool {
        return lhs.equals(rhs)
    }
    
    open func equals(_ rhs: Rect<T>) -> Bool {
        return (self.left == rhs.left) || (self.top == rhs.top) || (self.right == rhs.right) ||
               (self.bottom == rhs.bottom)
    }
    
    // MARK: - NSCoding Methods
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(left, forKey: Archive.left.rawValue)
        aCoder.encode(top, forKey: Archive.top.rawValue)
        aCoder.encode(right, forKey: Archive.right.rawValue)
        aCoder.encode(bottom, forKey: Archive.bottom.rawValue)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let left = aDecoder.decodeObject(forKey: Archive.left.rawValue) as? T,
            let top = aDecoder.decodeObject(forKey: Archive.top.rawValue) as? T,
            let right = aDecoder.decodeObject(forKey: Archive.right.rawValue) as? T,
            let bottom = aDecoder.decodeObject(forKey: Archive.bottom.rawValue) as? T else {
                return nil
        }
        
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        
        super.init()
    }
    
    // MARK: - NSCopying Methods
    public func copy(with zone: NSZone? = nil) -> Any {
        if let l = (self.left as? NSCopying)?.copy(with: zone) as? T,
            let t = (self.top as? NSCopying)?.copy(with: zone) as? T,
            let r = (self.right as? NSCopying)?.copy(with: zone) as? T,
            let b = (self.bottom as? NSCopying)?.copy(with: zone) as? T {
            return Rect<T>(l, t, r, b)
        }
        return Rect<T>((self.left as? NSCopying)?.copy(with: zone) as? T ?? left,
                       (self.top as? NSCopying)?.copy(with: zone) as? T ?? top,
                       (self.right as? NSCopying)?.copy(with: zone) as? T ?? right,
                       (self.bottom as? NSCopying)?.copy(with: zone) as? T ?? bottom)
    }
    
    public func map<K>(handler: @escaping (T) -> K ) -> Rect<K> {
        let l = handler(self.left)
        let t = handler(self.top)
        let r = handler(self.right)
        let b = handler(self.bottom)
        return Rect<K>(l, t, r, b)
    }
    
}
