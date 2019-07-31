//
//  Constants.swift
//  VirtualTourist
//
//  Created by Chase on 19/01/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import Foundation

struct Constants {
    
    // MARK: - Flickr
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        
    }
    
    // MARK: - Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let SearchMethod = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let SearchRadius = "radius"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let PhotosPerPage = "per_page"
        static let Page = "page"
    }
    
    // MARK: - Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "f6675e2ae3782fb953f8008655e5c719"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let URL = "url_q"
        static let UseSafeSearch = "1"
        static let SearchRadius = "4"
        static let PhotosPerPage = "18"
    }
    
    // MARK: - Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let URL = "url_q"
        static let Pages = "pages"
        static let TotalPhotos = "total"
    }
    
    // MARK: - Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    
}


