//
//  MCHandler.swift
//  Whisper
//
//  Created by Stephen Brown on 30/10/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import UIKit

protocol testDelegate {
    func recievedData(data: NSData)
}

class WhisperSession: NSObject, NSNetServiceDelegate, NSStreamDelegate, NSNetServiceBrowserDelegate {

    var delegate: testDelegate?

    // Server
    var server = NSNetService(domain: Constants.ServiceDomain, type: Constants.ServiceType, name: UIDevice.currentDevice().name, port: Constants.ServicePort)
    
    // Browser
    var browser = NSNetServiceBrowser()
    var foundServices = [NSNetService]()
    
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    var streamOpenCount = 0

    let writeLock = NSCondition()
    var dataToStream: NSData!
    var byteIndex: Int = 0
    
    var receivedData = NSMutableData()
    var receivingData = false
    var receivingDataTotalSize: Int?
    static var initalPacket = false

    
    override init() {
        super.init()
        
        // Prepare and start the server
        prepareServer()
        
        // Start looking for service candidates
        browserStart()
    }
    
    //MARK: Server Setup

    private func prepareServer() {
        server.includesPeerToPeer = true
        server.delegate = self
        server.publishWithOptions(NSNetServiceOptions.ListenForConnections)
        server.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    //MARK: Browser Setup
    func browserStart() {
        browser.includesPeerToPeer = true
        browser.delegate = self
        browser.searchForServicesOfType("_whisper._tcp.", inDomain: "local")
        //print("\(UIDevice.currentDevice().name) Browser has started searching")
    }
    
    //MARK: Net service delegate
    func netServiceDidPublish(sender: NSNetService) {
        //print("\(UIDevice.currentDevice().name) Server started")
    }
    
    func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream) {
        print("Server \(server.name) accepted connection")
        // set the streams
        self.inputStream = inputStream
        self.outputStream = outputStream
        openStreams()
    }
    
    func openStreams() {
        
        guard let inputStream = inputStream else {
            return
        }
        
        inputStream.delegate = self
        inputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream.open()
        
        guard let outputStream = outputStream else {
            return
        }
        
        outputStream.delegate = self
        outputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream.open()
    }
    
    func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Server failed to start ")
    }
    
    func sendBytes() {
        // Ensure there is data to write
        guard dataToStream != nil else {
            return
        }
        
        guard let outputStream = outputStream else {
            fatalError("Output streams to only write bytes.")
        }
        
        //writeLock.lock()

//        while !(outputStream.hasSpaceAvailable) {
//            //writeLock.wait()
//        }
        
        defer {
            //writeLock.unlock()
        }
        
        while outputStream.hasSpaceAvailable {
            
        
        
        var readBytes = dataToStream.bytes
        readBytes += byteIndex
        
        let dataLength = dataToStream.length
        
        var len: Int!
        if dataLength - byteIndex >= Constants.packetSize{
            len = Constants.packetSize
        }
        else{
            len = dataLength - byteIndex
        }
        
        let buffer = Array<UInt8>(count: len, repeatedValue: 0)
        memcpy(UnsafeMutablePointer(buffer), readBytes, len)
        
        len = outputStream.write(buffer, maxLength: len)
        
        if len == -1 {
            print("Error send : \(outputStream.streamError!)")
        } else if len == 0 {
            print("Output stream FINISHED! : \(len!)")
            print("Output stream stutus is now \(outputStream.streamStatus.rawValue)")
            //return
        }
        else {
            print("Output stream successfully wrote : \(len!)")
            byteIndex = byteIndex + len
        }
        //writeLock.signal()
            }
    }
    
    func readBytes(stream: NSStream) {
        
        guard let inputStream = stream as? NSInputStream else {
            fatalError("Input streams to have bytes.")
        }
        
//        if !receivingData {
//            receivingData = true
//            WhisperSession.initalPacket = true
//        }
        
        while inputStream.hasBytesAvailable {
        
        // Buffer for which the data will be written to,
        // * NOTE * this should really be a var but let(because i will be using pointer access) surpressing the warning by using a let.
        let buffer = Array<UInt8>(count: Constants.packetSize, repeatedValue: 0)
        // Read the data from the input stream and insert to buffer
        let len = inputStream.read(UnsafeMutablePointer(buffer), maxLength: Constants.packetSize)
        
        if len > 0 {
            //print("Successfully read data of size \(len)")
            receivedData.appendBytes(buffer, length: len)
            print("Total size is \(receivedData.length)")
            
//            if WhisperSession.initalPacket {
//                WhisperSession.initalPacket = false
//                print("Inital packet size is \(receivedData.length)")
//                let incomingStreamSizeDesc = NSString(data: NSData(bytes: receivedData.bytes, length: receivedData.length), encoding: NSUTF8StringEncoding) ?? ""
//                print("Recieved the following string from sender = \(incomingStreamSizeDesc)")
//                
//                let incomingStreamSize = Int(incomingStreamSizeDesc as String)
//                receivingDataTotalSize = incomingStreamSize
//                receivedData = NSMutableData.init(length: 0)!
//            }
        }
        
        print("INPUT STREAM STATUS \(inputStream.streamStatus.rawValue)")

        if inputStream.streamStatus == NSStreamStatus.AtEnd {
            print("INPUT STREAM HAS REACHED THE END!!!!!!!!!!!!")
        }
            
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let data = NSData(bytes: self.receivedData.bytes, length: self.receivedData.length)
            self.delegate?.recievedData(data)
            print("INPUT STREAM STATUS AFTER ASYNC  \(self.inputStream!.streamStatus.rawValue)")

        })
        
//        if receivedData.length >= receivingDataTotalSize {
//            print("All the data from stream has been recieved :  \(receivedData.length)")
//            // Pass to a delegate receivedData & reset for more.
////            dispatch_async(dispatch_get_main_queue(), { () -> Void in
////                let data = NSData(bytes: self.receivedData.bytes, length: self.receivedData.length)
////                self.delegate?.recievedData(data)
////                print("INPUT STREAM STATUS AFTER ASYNC  \(self.inputStream!.streamStatus.rawValue)")
////
////            })
//            print("INPUT STREAM STATUS outside ASYNC  \(inputStream.streamStatus.rawValue)")
//            receivingData = false
//            //receivedData = NSMutableData.init(length: 0)!
//        }
        }
    }
    
    //MARK: Stream delegate
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        switch eventCode {
        case NSStreamEvent.OpenCompleted:
            print("Stream Opened")
            break
        case NSStreamEvent.HasBytesAvailable:
            readBytes(aStream)
            break
        case NSStreamEvent.HasSpaceAvailable:
            print("Out has space")
            sendBytes()
            break
        case NSStreamEvent.ErrorOccurred:
            print("\(UIDevice.currentDevice().name) - Stream has ended \(aStream.description)")
            print("\(UIDevice.currentDevice().name) - Stream Error has occured \(aStream.streamError!)")
            break
        case NSStreamEvent.EndEncountered:
            print("\(UIDevice.currentDevice().name) Stream has ended \(aStream.description)")
            break
        case NSStreamEvent.None:
            break
        default:
            break
        }
    }
    
    //MARK: Browser delegate
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        if service != server {
            //print("\(UIDevice.currentDevice().name) Found service name with \(service.name)")
            // Determine who shall init a connection
            if service.hash > server.hash {
                //print("\(service.name) IS MAKING THE CONNECTION!!!!")
                connectToService(service)
            }
        }
    }
    
    func connectToService(service: NSNetService){
        //print("\(UIDevice.currentDevice().name) is connecting to service \(service.name)")
        
        var input : NSInputStream?
        var output : NSOutputStream?
        
        let success = service.getInputStream(&input, outputStream: &output)
        
        if success {
            self.inputStream  = input
            self.outputStream = output
            
            openStreams()
        }
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        print("service removed!")
    }
    
    //MARK: Communication 
    
    func send(data: NSData) {
        dataToStream = data
        print("Total size that will be sent : \(data.length)")
        byteIndex = 0
        //createAcknowledgementForIncomingDataSize(data)
        sendBytes()
    }
    
    private func createAcknowledgementForIncomingDataSize(data2: NSData) {
        print("Total size that will be sent : \(data2.length)")
        let message = "\(data2.length)" // \r\n enables the output stream to flush its data stright away.
        let data = message.dataUsingEncoding(NSUTF8StringEncoding)
        
        let readBytes = data!.bytes
        let buffer = Array<UInt8>(count: data!.length, repeatedValue: 0)
        memcpy(UnsafeMutablePointer(buffer), readBytes, data!.length)
        
        print("Stream status is \(outputStream!.streamStatus.rawValue)")
        let len = outputStream!.write(buffer, maxLength: data!.length)
        
        if len == -1 {
            //print("Error sending : \(outputStream!.streamError!)")
            print("Error sending")
        }
        
        if len == data!.length {
            print("Write Success")
            sendBytes()
        }
    }
}
