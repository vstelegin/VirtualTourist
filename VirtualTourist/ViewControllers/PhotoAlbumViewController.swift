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
    @IBOutlet weak var newCollectionButton : UIButton!
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var imageURL : URL!
    let photosPerRow : CGFloat = 3
    var insertedIndexPaths : [IndexPath]!
    var deletedIndexPaths : [IndexPath]!
    var updatedIndexPaths : [IndexPath]!
    var totalPhotos : Int? {
        didSet{
            if let newTotalPhotos = totalPhotos {
                totalPhotos = min(4000,newTotalPhotos)
            }
        }
    }
    // Struct for Download Complete checking
    struct DownloadStatus {
        var downloadedPhotos : Int {
            didSet{
                if downloadedPhotos > 0 {
                    print ("Downloaded photos: \(downloadedPhotos) \r")
                }
                if downloadedPhotos == min(photosToDownload,12) {
                    downloadComplete = true
                    reset()
                }
            }
        }
        var photosToDownload : Int
        var downloadComplete : Bool
        init(){
            downloadedPhotos = 0
            photosToDownload = -1
            downloadComplete = false
        }
        mutating func reset(){
            downloadedPhotos = 0
            photosToDownload = -1
        }
        mutating func increment(){
            downloadedPhotos += 1
        }
    }
    var downloadStatus = DownloadStatus()
    var downloadedPhotos : Int = 0
    func setupFetchedResultsController(_ pin: Pin!) {
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
    func loadPhotosFromThePin(_ pin : Pin){
        
        // Load photo URLs
        
        FlickrAPI.shared.photosRequestFromLatLong(pin.lat!, pin.long!) { parsedResult, error in
            performUIUpdatesOnMain {
                self.activityIndicator.stopAnimating()
            }
            //print JSON response
            //print ("Parsed result: \(parsedResult ??  ["Empty result":"" as AnyObject])")
            
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
            self.totalPhotos = Int(totalPhotosFound)
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                return
            }
            self.downloadStatus.photosToDownload = photosArray.count
            print ("Photos on page: \(self.downloadStatus.photosToDownload)")
            
            for photoDictionary in photosArray {
                let photo = Photo(context: DataController.shared.viewContext)
                guard let photoUrlString = photoDictionary[Constants.FlickrResponseKeys.URL] as! String? else {
                    return
                }
                photo.photoURL = URL(string: photoUrlString)
                photo.pin = pin
            }
            DataController.shared.save()
            
        }
    }
    
    // New collection button
    @IBAction func newCollection(_ sender: Any){
        for photo in fetchedResultsController.fetchedObjects! {
            DataController.shared.viewContext.delete(photo)
        }
        
        try? DataController.shared.viewContext.save()
        if let totalPhotos = totalPhotos {
            let PhotosPerPage = Int(Constants.FlickrParameterValues.PhotosPerPage)!
            let totalPages = totalPhotos / PhotosPerPage + ((totalPhotos % PhotosPerPage > 0) ? 1 : 0 )
            let newPage = Int.random(in: 1...totalPages)
            FlickrAPI.shared.page = newPage
            print ("\n\nLoading page: \(newPage)")
        }
        guard let pin = pin else {
            return
        }
        loadPhotosFromThePin(pin)
        newCollectionButton.isEnabled = false
        self.downloadStatus.downloadComplete = false
        self.downloadStatus.reset()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let pin = pin else {
            return
        }
        
        // Minimap setup
        let location = String.LatLongToLocation(pin.lat!, pin.long!)
        mapView.delegate = self
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        let viewRegion = MKCoordinateRegion(center: location, latitudinalMeters: 10000,longitudinalMeters: 10000)
        mapView.setRegion(viewRegion, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        mapView.addAnnotation(annotation)
        
        // Fetch photos if the photo album is empty yet
        
        if let photosAtThePin = pin.photosAtThePin, photosAtThePin.count == 0 {
            loadPhotosFromThePin(pin)
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
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        
        if let photoData = photo.photoData {
            showPhoto(cell as! PhotoCell, photoData)
        } else {
            downloadPhoto(indexPath: indexPath)
        }
    }
    
    // Delete photo after selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        DataController.shared.viewContext.delete(photoToDelete)
        DataController.shared.save()
    }

    func showPhoto(_ cell : PhotoCell, _ photoData : Data){
        performUIUpdatesOnMain{
            cell.imageView.image = UIImage(data: Data(referencing: photoData as NSData))
            cell.activityIndicator.stopAnimating()
        }
    }
    
    func downloadPhoto(indexPath : IndexPath){
        let photo = fetchedResultsController.object(at: indexPath)
        guard let photoURL = photo.photoURL else {
            print("\(#function) no URL")
            return
        }
        // Download photo in the async queue
        let downloadQueue = DispatchQueue(label: "download", attributes: [])
        downloadQueue.async {
            let task = URLSession.shared.dataTask(with: photoURL) { data, response, error in
                if let _ = error {
                    print ("\(#function) Error downloading the photo")
                    return
                }
                guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    print ("\(#function) Bad responce")
                    return
                }
                if let photoData = data {
                    photo.photoData = photoData
                    DataController.shared.save()
                    self.downloadStatus.increment()
                    if self.downloadStatus.downloadComplete {
                        performUIUpdatesOnMain {
                            self.newCollectionButton.isEnabled = true
                        }
                    }
                }
            }
            task.resume()
        }
    }
}


extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //Calculate photo's cell to fit the view
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
            
        default:
            break
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

// Pin annotation setup
extension PhotoAlbumViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = false
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}
