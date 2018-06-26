//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Chase on 15/06/2018.
//  Copyright © 2018 s0w4. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    var albumViewActive = false
    var annotation : MKPointAnnotation? = nil
    var dataController : DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var pinToDelete: NSManagedObject?
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "lat", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        print("Pins: \(fetchedResultsController.sections![0].numberOfObjects)")
        
        guard let pins = fetchedResultsController.fetchedObjects else {
            return
        }
        for pin in pins {
            let lat = Double(pin.lat!)
            let long = Double (pin.long!)
            let coordinate = CLLocationCoordinate2DMake(lat!, long!)
            showPin(coordinate)
        }
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
    }
    fileprivate func showPin(_ coordinate: CLLocationCoordinate2D) {
        annotation = MKPointAnnotation()
        annotation!.coordinate = coordinate
        mapView.addAnnotation(annotation!)
    }
    
    @IBAction func addPin (_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
       
        switch sender.state {
        case .began:
            showPin(coordinate)
            
        case .changed:
            annotation!.coordinate = coordinate
        case .ended:
            let pin = Pin(context: dataController.viewContext)
            pin.lat = String(coordinate.latitude)
            pin.long = String(coordinate.longitude)
            try? dataController.viewContext.save()
            print("Saved")
        default:
            break
        }
        
        if !albumViewActive{
            //performSegue(withIdentifier: "showAlbum", sender: nil)
            print ("seque")
        }
        albumViewActive = true
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        let lat = String(annotation.coordinate.latitude)
        print ("Lat is \(lat)")
        for pin in fetchedResultsController.fetchedObjects!{
            print (pin.lat)
            
            if pin.lat == lat {
                pinToDelete = pin
            }
        }
        if isEditing {
            mapView.removeAnnotation(annotation)
            dataController.viewContext.delete(pinToDelete!)
            try? dataController.viewContext.save()
        } else {
            return
        }
    }
}

