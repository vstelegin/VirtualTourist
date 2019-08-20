//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Chase on 21/01/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController : UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var flowLayout : UICollectionViewFlowLayout!
    @IBOutlet weak var mapView : MKMapView!
    
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var imageURL : URL!
    let photosPerRow : CGFloat = 3
    var insertedIndexPaths : [IndexPath]!
    var deletedIndexPaths : [IndexPath]!
    var updatedIndexPaths : [IndexPath]!
    private func setupFetchedResultsController(_ pin: Pin!) {
        
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate (format: "pin == %@", argumentArray: [pin!])
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print ("\(#function) Fetch failed")
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    private func displayMessage(_ text : String){
        performUIUpdatesOnMain {
            self.messageLabel.text = text;
        }
    }

    @IBAction func newCollection(_ sender: Any){
        guard let pin = pin else {
            return
        }
        guard let photosAtThePin = pin.photosAtThePin else {
            return
        }
        for photo in photosAtThePin {
            DataController.shared.viewContext.delete(photo as! NSManagedObject)
        }
        print("Deleted")
        DataController.shared.save()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let pin = pin else {
            return
        }
        let location = String.LatLongToLocation(pin.lat!, pin.long!)
        mapView.delegate = self
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        let viewRegion = MKCoordinateRegion(center: location, latitudinalMeters: 10000,longitudinalMeters: 10000)
        mapView.setRegion(viewRegion, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        mapView.addAnnotation(annotation)
     
        setupFetchedResultsController(pin)
        if let photosAtThePin = pin.photosAtThePin, photosAtThePin.count == 0 {
            
            guard let lat = pin.lat, let long = pin.long  else {
                print ("incorrect coordinates")
                return
            }
            
            FlickrAPI.shared.photosRequestFromLatLong(lat, long) { parsedResult, error in
                performUIUpdatesOnMain {
                    self.activityIndicator.stopAnimating()
                }
                print ("Parsed result: \(parsedResult ??  ["Empty result":"" as AnyObject])")
             
                if let error = error {
                    self.displayMessage(error)
                    return
                }
                
                guard let photosDictionary = parsedResult![Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    return
                }
                
                guard let totalPhotosFound = photosDictionary[Constants.FlickrResponseKeys.TotalPhotos] as! String?,  totalPhotosFound != "0" else {
                    self.displayMessage("No photos found")
                    return
                }
                
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    return
                }
                print ("Photos found: \(photosArray.count)")
                
                for photoDictionary in photosArray {
                    let photo = Photo(context: DataController.shared.viewContext)
                    guard let photoUrlString = photoDictionary[Constants.FlickrResponseKeys.URL] as! String? else {
                        return
                    }
                    photo.photoURL = URL(string: photoUrlString)
                    photo.pin = pin
                    DataController.shared.save()
                }
            }
        } else {
            performUIUpdatesOnMain {
                self.activityIndicator.stopAnimating()
            }
        }
    }
}

extension PhotoAlbumViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        cell.activityIndicator.startAnimating()
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let currentCell = cell as! PhotoCell
        currentCell.indexPath = indexPath
        loadPhoto(currentCell)

    }
    
    func loadPhoto(_ cell : PhotoCell){
        performUIUpdatesOnMain {
            cell.activityIndicator.startAnimating()
        }
        
        guard let indexPath = cell.indexPath else {
            return
        }
        
        guard let photo = fetchedResultsController.object(at: indexPath) as Photo? else {
            return
        }
        
        if let photoData = photo.photoData {
            performUIUpdatesOnMain{
                cell.imageView.image = UIImage(data: Data(referencing: photoData as NSData))
                cell.activityIndicator.stopAnimating()
            }
            
        }
        else {
            guard let photoURL = photo.photoURL else {
                return
            }
            
            let downloadQueue = DispatchQueue(label: "download", attributes: [])
            downloadQueue.async {
                if let photoData = try? Data(contentsOf: photoURL) {
                    
                    photo.photoData = photoData
                    DispatchQueue.global(qos: .background).async {
                        DataController.shared.save()
                    }
                    
                    performUIUpdatesOnMain {
                        cell.imageView.image = UIImage(data: Data(referencing: photoData as NSData))
                        cell.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
}

extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let photosRowWidth = view.frame.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right
        let widthPerItem = photosRowWidth / photosPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
}

extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
            
        default: break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
}

extension PhotoAlbumViewController : MKMapViewDelegate {
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
}
