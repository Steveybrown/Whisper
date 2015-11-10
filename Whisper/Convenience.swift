//
//  Convenience.swift
//  Whisper
//
//  Created by Stephen Brown on 07/11/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import UIKit
import Foundation

extension WhisperManager {
    
    public func sendImage(image: UIImage, toChannels: [String]) {
        
        if let data = UIImageJPEGRepresentation(image, Constants.TransitCompressionQuality) {
        
            let details: [String: AnyObject] = [
                MessageBodyKeys.TypeKey: MessageBodyKeys.TypePhoto,
                MessageBodyKeys.DataKey: data,
                MessageBodyKeys.ChannelsKey: toChannels
            ]
            
            sendMessage(details)
        }
    }
    
}

extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}
