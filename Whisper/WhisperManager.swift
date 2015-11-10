//
//  WhisperManager.swift
//  Whisper
//
//  Created by Stephen Brown on 30/10/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import UIKit
import MultipeerConnectivity

public enum WhisperStatus {
    case Connected
    case Connecting
    case NotConnected
}

public protocol WhisperDelegate {
    func whisperDidRecieveImage(data: NSData)
    func whisperConnectionStatusDidChange(state: WhisperStatus)
}

public class WhisperManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var delegate: WhisperDelegate?
    var peersConnected = [MCPeerID]()
    lazy private var subscriptions = [String]()

    private var session: MCSession
    private var myPeerId: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    
    init(peerName: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let exisitingPeerIdData = userDefaults.dataForKey(Constants.DevicePeerKey) {
            myPeerId = NSKeyedUnarchiver.unarchiveObjectWithData(exisitingPeerIdData) as! MCPeerID
        } else {
            myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
            let peerIdData = NSKeyedArchiver.archivedDataWithRootObject(myPeerId)
            userDefaults.setObject(peerIdData, forKey: Constants.DevicePeerKey)
        }
        
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: Constants.ServiceType)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: Constants.ServiceType)
        
        super.init()
        session.delegate = self
        
        browser.delegate = self
        browser.startBrowsingForPeers()
        
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    
    //MARK: Session Delegate
    
    public func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        switch state {
        case .Connected:
            print("\(myPeerId.displayName) connected with \(peerID.displayName)")
            peersConnected.append(peerID)
        case .Connecting:
            print("\(myPeerId.displayName) connecting to \(peerID.displayName)")
        case .NotConnected:
            print("\(myPeerId.displayName) did not connect")
            // Removed peer if it exisits
            if peersConnected.contains(peerID) {
                peersConnected.removeObject(peerID)
            }
        }
        
        notifyDelegateOfStateChange(state)
    }
    
    public func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
    }
    
    public func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        print("\(myPeerId.displayName) recieved data from \(peerID.displayName)")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.delegate?.whisperDidRecieveImage(data)
            NSNotificationCenter.defaultCenter().postNotificationName("Whisper_Recieved_Data", object: nil)
        })
    }
    
    public func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    public func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
    }
    
    public func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        certificateHandler(true)
    }
    
    //MARK: Browser Delegate
    
    public func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Deterministic value to decide who connects.
        if myPeerId.hash > peerID.hash {
            print("\(myPeerId.displayName) is inviting  \(peerID.displayName) to connect")
            browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 0.0)
        }
    }
    
    public func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("\(UIDevice.currentDevice().name) did not start browsing")
    }
    
    public func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("\(UIDevice.currentDevice().name) lost peer \(peerID.displayName)")
        if peersConnected.contains(peerID) {
            peersConnected.removeObject(peerID)
        }
    }
    
    //MARK: Advertiser Delegate
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        print("\(myPeerId.displayName) is accepting invite")
        invitationHandler(true, session)
    }
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("Advertiser did not start advertising \(error)")
    }
    
    //MARK: Communication
    
    internal func sendData(data: NSData) {
        print("connect peer total = \(peersConnected.count)")
        do {
            try session.sendData(data, toPeers: peersConnected, withMode: .Reliable)
        } catch let error as NSError {
            print("Message FAILED to send = \(error)")
        }
    }
    
    // MARK: Subscriptions
    
    public func subscribeTo(channel: String) {
        subscriptions.append(channel)
    }
    
    public func unSubscribeFrom(channel:String) {
        subscriptions = subscriptions.filter() { $0 != channel }
    }
}
