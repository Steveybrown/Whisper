//
//  WhisperDelegateHelper.swift
//  Whisper
//
//  Created by Stephen Brown on 08/11/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension WhisperManager {
    
    // Thread safe method - suitable for upating UI
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
    
}