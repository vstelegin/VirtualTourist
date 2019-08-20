//
//  Extensions.swift
//  VirtualTourist
//
//  Created by Chase on 19/08/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import Foundation
import MapKit
extension String {
    static func LatLongToLocation(_ lat : String, _ long : String) -> CLLocationCoordinate2D {
        print ("\(lat) , \(long)")
        return CLLocationCoordinate2DMake(Double (lat)!, Double (long)!)
    }
}

