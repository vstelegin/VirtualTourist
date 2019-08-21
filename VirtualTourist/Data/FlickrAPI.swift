//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Chase on 21/01/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import Foundation

class FlickrAPI {
    
    static let shared = FlickrAPI()
    var page : Int?
    func photosRequestFromLatLong(_ lat: String, _ long: String, completion: @escaping (_ parsedResult: [String:AnyObject]?, _ error: String? ) -> Void){
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        let parameters = [
            Constants.FlickrParameterKeys.SearchMethod : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.SearchRadius : Constants.FlickrParameterValues.SearchRadius,
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.URL,
            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PhotosPerPage : Constants.FlickrParameterValues.PhotosPerPage,
            Constants.FlickrParameterKeys.Page : "\(page ?? 1)",
            Constants.FlickrParameterKeys.Latitude : lat,
            Constants.FlickrParameterKeys.Longitude : long
        ]
        page = nil
        components.queryItems = [URLQueryItem]()
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        print("\n\(components.url!)")
        let session = URLSession.shared
        let request = URLRequest(url: components.url!)
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard (error == nil) else {
                print (error?.localizedDescription ?? "error returned")
                completion(nil, "error returned")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completion(nil, "Bad status code from server")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data was returned from server")
                print ("no data")
                return
            }
            
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
                completion (parsedResult, nil)
                
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                completion (nil, "Could not parse the data as JSON")
            }
            
        }
        
        
        task.resume()
    }
    
    
}
