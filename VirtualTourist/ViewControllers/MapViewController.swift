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

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate{
    var albumViewActive = false
    var annotation : MKPointAnnotation? = nil
    //var dataController : DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "lat", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let photoAlbum = segue.destination as? PhotoAlbumViewController {
            photoAlbum.pin = sender as? Pin
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        mapView.gestureRecognizers?.first!.isEnabled = !editing
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
            let pin = Pin(context: DataController.shared.viewContext)
            pin.lat = String(coordinate.latitude)
            pin.long = String(coordinate.longitude)
            try? DataController.shared.viewContext.save()
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
    
    
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        
        let lat = String(annotation.coordinate.latitude)
        let long = String(annotation.coordinate.longitude)
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "lat == %@ AND long == %@", lat, long)
        fetchRequest.predicate = predicate
        var selectedPin: Pin?
        
        do {
            try selectedPin = DataController.shared.viewContext.fetch(fetchRequest).first
            
        } catch {
            print (error)
        }
        
        if isEditing {
            mapView.removeAnnotation(annotation)
            DataController.shared.viewContext.delete(selectedPin!)
            try? DataController.shared.viewContext.save()
            return
        }
        performSegue(withIdentifier: "showAlbum", sender: selectedPin)
    }
}
