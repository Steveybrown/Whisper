//
//  WhisperDelegateHelper.swift
//  Whisper
//
//  Created by Stephen Brown on 08/11/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import Foundation
import MultipeerConnectivity


// Thread safe methods - suitable for calling to update the UI
extension WhisperManager {
    
    internal func notifyDelegateOfStateChange(state: MCSessionState) {
        if let delegate = self.delegate {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                switch state {
                case .Connected:
                    delegate.whisperConnectionStatusDidChange(.Connected)
                case .Connecting:
                    delegate.whisperConnectionStatusDidChange(.Connecting)
                case .NotConnected:
                    delegate.whisperConnectionStatusDidChange(.NotConnected)
                }
            })
        }
    }
    
    internal func notifyDelegateDataRecieved(dictionary: [String: AnyObject]) {
        if let data = dictionary[MessageBodyKeys.DataKey] as! NSData? {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.delegate?.whisperDidRecieveImage(data)
            })
        }
    }
    
}