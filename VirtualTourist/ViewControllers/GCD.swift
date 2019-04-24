//
//  ViewController+Extensions.swift
//  VirtualTourist
//
//  Created by Chase on 27/01/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import Foundation
func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
