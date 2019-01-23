//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Chase on 21/01/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import Foundation

class FlickrAPI {
    
    func photosRequestFromLatLong(_ lat: String, _ long: String) -> Void{
        
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        let parameters = [
            Constants.FlickrParameterKeys.SearchMethod : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.SearchRadius : Constants.FlickrParameterValues.SearchRadius,
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Latitude : lat,
            Constants.FlickrParameterKeys.Longitude : long
        ]
        
        components.queryItems = [URLQueryItem]()
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        print(components.url!)
        
        let session = URLSession.shared
        let request = URLRequest(url: components.url!)
        
        let task = session.dataTask(with: request) { (data, responce, error) in
            guard let data = data else {
                print ("no data")
                return
            }
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
                print (parsedResult)
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
        }
        
        
        task.resume()
    }
    
    
}
