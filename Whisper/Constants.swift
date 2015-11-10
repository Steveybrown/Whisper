//
//  Constants.swift
//  Whisper
//
//  Created by Stephen Brown on 07/11/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import Foundation
import UIKit

extension WhisperManager {
    
    struct Constants {
        
        // NSNetService
        static let ServiceDomain = "local"
        static let ServiceType = "whisper"
        static let ServicePort: Int32 = 0
                
        // How much data is written/read at a time.
        static let PacketSize : Int = 1024
        
        // Peer id
        static let DevicePeerKey = "Device_Peer_Id"
        
        // Acknowledgement message size
        static let AcknowledgementMessageByteSize = 255
        
        static let TransitCompressionQuality: CGFloat = 0.5
    }
}
