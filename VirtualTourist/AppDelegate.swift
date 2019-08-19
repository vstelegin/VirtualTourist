//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Chase on 15/06/2018.
//  Copyright © 2018 s0w4. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DataController.shared.load()
        return true
    }
}

