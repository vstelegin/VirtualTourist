//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Chase on 15/06/2018.
//  Copyright © 2018 s0w4. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {
    var  albumViewActive = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addPin (_ sender: UILongPressGestureRecognizer) {
        if !albumViewActive{
            performSegue(withIdentifier: "showAlbum", sender: nil)
            print ("seque")
        }
        albumViewActive = true
        
    }

}

