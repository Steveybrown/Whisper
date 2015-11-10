//
//  ViewController.swift
//  Whisper
//
//  Created by Stephen Brown on 30/10/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, WhisperDelegate {
    
    @IBOutlet weak var connectionStatusView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    var whisper = WhisperManager(peerName: UIDevice.currentDevice().name)
    var imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"dataHasBeenRecieved", name: "Whisper_Recieved_Data", object: nil)
                
        whisper.delegate = self
        imagePicker.delegate = self
        
        whisper.subscribeTo("whisper")
    }
    

    @IBAction func selectImage(sender: UIButton) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func advertise(sender: UIButton) {
        if let image = imageView!.image {
            whisper.sendImage(image, toChannels: ["whisper"])
        } else {
            print("View Controller : Image is nil")
        }
    }
    
    //MARK: Image Picker Delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageView.image = image
    }
    
    //MARK: Notification Responder
    
    func dataHasBeenRecieved() {
        if self.view.backgroundColor == UIColor.greenColor() {
            self.view.backgroundColor = UIColor.redColor()
        } else {
            connectionStatusView.backgroundColor = UIColor.greenColor()
        }
    }
    
    //MARK: Whisper Delegate
    
    func whisperDidRecieveImage(data: NSData) {
        let image = UIImage.init(data: data)
        imageView.image = image
    }
    
    func whisperConnectionStatusDidChange(state: WhisperStatus) {
        switch state {
        case .Connecting:
            connectionStatusView.backgroundColor = UIColor.orangeColor()
        case .Connected:
            connectionStatusView.backgroundColor = UIColor.greenColor()
        case .NotConnected:
            connectionStatusView.backgroundColor = UIColor.redColor()
        }
    }
}

