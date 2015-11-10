//
//  Constants.swift
//  Whisper
//
//  Created by Stephen Brown on 03/11/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import Foundation

extension WhisperSession {
    
    struct Constants {
        
        // NSNetService
        static let ServiceDomain = "local"
        static let ServiceType = "_whisper._tcp."
        static let ServicePort: Int32 = 0
        
        // How much data is written/read at a time.
        static let packetSize : Int = 1024

        // Acknowledgement message size
        static let AcknowledgementMessageByteSize = 255
        
    }
    
}


