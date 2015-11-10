//
//  ViewController.swift
//  Whisper
//
//  Created by Stephen Brown on 30/10/2015.
//  Copyright © 2015 Stephen Brown. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, testDelegate {
    
    var handler = WhisperSession()
    
    var imagePicker = UIImagePickerController()
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"dataHasBeenRecieved", name: "Data_Recieved", object: nil)
        
        imagePicker.delegate = self
        handler.delegate = self
        
        if TARGET_OS_SIMULATOR == 0 {
            //imagePicker.sourceType = .Camera
        }
        
    }
    
    @IBAction func pickPhoto(sender: UIButton) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageView.image = image
    }
    
    @IBAction func browse(sender: UIButton) {
        let imageData = UIImageJPEGRepresentation(imageView.image!, 0.3)
        handler.send(imageData!)
        
        //        let name = "Stephenbrown"
        //        let data = name.dataUsingEncoding(NSUTF8StringEncoding)
        //        handler.send(data!)
    }
    
    func dataHasBeenRecieved() {
        if (self.view.backgroundColor == UIColor.greenColor()) {
            self.view.backgroundColor = UIColor.redColor()
            return;
        }
        self.view.backgroundColor = UIColor.greenColor()
    }
    
    func recievedData(data: NSData) {
        let image = UIImage.init(data: data)
        imageView.image = image
    }
}

