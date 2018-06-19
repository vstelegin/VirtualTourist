//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Chase on 15/06/2018.
//  Copyright © 2018 s0w4. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate{
    var  albumViewActive = false
    var annotation : MKPointAnnotation? = nil
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addPin (_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            annotation = MKPointAnnotation()
            annotation?.coordinate = coordinate
            mapView.addAnnotation(annotation!)
        }
        if !albumViewActive{
            performSegue(withIdentifier: "showAlbum", sender: nil)
            print ("seque")
        }
        albumViewActive = true
        
    }

}

