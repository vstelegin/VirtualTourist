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
    var backgroundContext: NSManagedObjectContext{
        return persistentContainer.newBackgroundContext()
    }
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    static let shared = DataController(modelName: "VirtualTourist")
    
    init (modelName: String){
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts(){
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func load(){
        persistentContainer.loadPersistentStores {storeDesription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContexts()
        }
    }
    func save(){
        viewContext.performAndWait {
            if self.viewContext.hasChanges {
                do {
                    try self.viewContext.save()
                } catch {
                    print("Failed to save context")
                }
            }
        }
    }
}
