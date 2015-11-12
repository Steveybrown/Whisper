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

    private var sessions = [MCSession]()
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
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: Constants.ServiceType)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: Constants.ServiceType)
        
        super.init()
        createSession()
        
        browser.delegate = self
        browser.startBrowsingForPeers()
        
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    
    //MARK: Session Delegate
    
    private func createSession() -> MCSession {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        session.delegate = self
        sessions.append(session)
        return session
    }
    
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
        fatalError("Not yet implemented")
    }
    
    public func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        print("\(myPeerId.displayName) recieved data from \(peerID.displayName)")
    
        let dictionary: [String: AnyObject] = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String: AnyObject]
        
        // Check if this device is subscribed to a channel of the message 
        // -TODO need to implement some sort of cache and check if the data recieved unique id has already been delegated to respondent
        if let channels = dictionary[MessageBodyKeys.ChannelsKey] as! [String]? {
            if Set(channels).isSubsetOf(Set(subscriptions)) {
                notifyDelegateDataRecieved(dictionary)
            }
        }
        
        // Forward on to all connected peers - 
        // excluding the peer that sent it, this ensure a constant ping-pong doesn't happen
        broadcastToConnectedPeers(data, excludePeer: peerID)
    }
    
    public func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("Not yet implemented")
    }
    
    public func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        fatalError("Not yet implemented")
    }
    
    public func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        certificateHandler(true)
    }
    
    private func getAvailableSession() -> MCSession {
        
        let sessionWithSpaceAvailable = sessions.filter {(session) in session.connectedPeers.count < 8}.first
        
        // check if we were able to get a session from exisiting otherwise create one.
        if let session = sessionWithSpaceAvailable {
            return session
        } else {
            return createSession()
        }
    }
    
    //MARK: Browser Delegate
    
    public func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Deterministic value to decide who connects.
        if myPeerId.hash > peerID.hash {
            print("\(myPeerId.displayName) is inviting  \(peerID.displayName) to connect")
            
            // Get an available session for the peer
            let session = getAvailableSession()
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
        let session = getAvailableSession()
        invitationHandler(true, session)
    }
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("Advertiser did not start advertising \(error)")
    }
    
    //MARK: Communication
    
    internal func sendMessage(data: NSData, toChannels: [String]) {
        
        let messageDetail: [String: AnyObject] = [
            MessageBodyKeys.UniqueIdentifier: NSUUID().UUIDString,
            MessageBodyKeys.TypeKey: MessageBodyKeys.TypeCustom,
            MessageBodyKeys.DataKey: data,
            MessageBodyKeys.ChannelsKey: toChannels
        ]
        
        // We send to every connected peer, they then handle to forward and deciding if they should respond.
        // Some operation queue is probably needed here to throttle. 
        let messageData : NSData = NSKeyedArchiver.archivedDataWithRootObject(messageDetail)
        broadcastToConnectedPeers(messageData)
    }
    
    private func broadcastToConnectedPeers(data: NSData, excludePeer: MCPeerID?=nil) {
        for s in sessions {
            do {
                var peers = s.connectedPeers
                
                if let excludePeer = excludePeer {
                    if peers.contains(excludePeer) {
                        peers.removeObject(excludePeer)
                    }
                }
                
                // Ensure we have a sufficent # of peers to send to after potentially removing the only connected peer
                guard peers.count != 0 else {
                    return
                }
                
                print("Sending to = \(peersConnected.count) peers ")
                try s.sendData(data, toPeers: peers, withMode: .Reliable)
            } catch let error as NSError {
                print("Message FAILED to send = \(error)")
            }
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
