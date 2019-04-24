//
//  DataController.swift
//  VirtualTourist
//
//  Created by Chase on 22/06/2018.
//  Copyright © 2018 s0w4. All rights reserved.
//

import Foundation
import CoreData

class DataController{
    let persistentContainer: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext
    
    static let shared = DataController(modelName: "VirtualTourist")
    
    var viewContext: NSManagedObjectContext{
        return persistentContainer.viewContext
    }
    
    init (modelName: String){
        persistentContainer = NSPersistentContainer(name: modelName)
        backgroundContext = persistentContainer.newBackgroundContext()
    }
 
    func load(){
        persistentContainer.loadPersistentStores {_, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
        }
    }
}
