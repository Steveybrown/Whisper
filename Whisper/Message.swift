//
//  Message.swift
//  Whisper
//
//  Created by Stephen Brown on 10/11/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import Foundation

class Message: NSObject, NSCoding {
    
    var type: String?
    var data: NSData?
    
    
    override init() {
        super.init()
    }
    
    init(type: String, data: NSData) {
        self.type = type
        self.data = data
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let type = aDecoder.decodeObjectForKey("type") as? String {
            self.type = type
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        if let type = self.type {
            aCoder.encodeObject(type, forKey: "type")
        }
    }
    
}
