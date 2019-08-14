//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Chase on 21/01/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import UIKit
import CoreData

class PhotoAlbumViewController : UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var flowLayout : UICollectionViewFlowLayout!
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var cellCount = 0
    var imageURL : URL!
    let photosPerRow : CGFloat = 3
    var insertedIndexPaths : [IndexPath] = []
    var deletedIndexPaths : [IndexPath] = []
    private func setupFetchedResultsController(_ pin: Pin!) {
        
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate (format: "pin == %@", argumentArray: [pin!])
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    private func displayMessage(_ text : String){
        performUIUpdatesOnMain {
            self.messageLabel.text = text;
        }
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let api = FlickrAPI.init()
        guard let pin = pin else {
            return
        }
        guard let lat = pin.lat  else {
            print ("empty latitude")
            return
        }
        
        guard let long = pin.long else {
            print ("empty longitude")
            return
        }
        setupFetchedResultsController(pin)
        
        
        
        activityIndicator.startAnimating()
        
        let sections = fetchedResultsController.sections
        let photosCount = sections?[0].numberOfObjects
        
        if photosCount == 0 {
            api.photosRequestFromLatLong(lat, long) { parsedResult, error in
                
                
                print ("Parsed result: \(parsedResult ??  ["Empty result":"" as AnyObject])")
                
                performUIUpdatesOnMain {
                    self.activityIndicator.stopAnimating()
                }
                
                
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
                    try? DataController.shared.viewContext.save()
                    
                }
                
            
                
                performUIUpdatesOnMain {
                    self.activityIndicator.stopAnimating()
                    
                }
                
                
            }
        }
        
    }
}


extension PhotoAlbumViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fr = self.fetchedResultsController else {
            messageLabel.text = "No Results"
            return 0
        }
        guard let sections = fr.sections else {
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
                        try? DataController.shared.viewContext.save()
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
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertedIndexPaths.append(newIndexPath)
            }
            break
        case .delete:
            if let newIndexPath = newIndexPath {
                deletedIndexPaths.append(newIndexPath)
            }
        default: break
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                //let indexPath = IndexPath(row: self.cellCount, section: 0)
                //self.cellCount += 1
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                //let indexPath = IndexPath(row: self.cellCount, section: 0)
                //self.cellCount += 1
                self.collectionView.deleteItems(at: [indexPath])
            }
            //self.cellCount = 0
            
        }, completion: nil)
    }
}
