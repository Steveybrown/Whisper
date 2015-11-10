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
    
    // TODO - Add a boardcasting channel to boardcase the image to.
    func sendImage(image: UIImage) {
        if let data = UIImageJPEGRepresentation(image, Constants.TransitCompressionQuality) {
            sendData(data)
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
