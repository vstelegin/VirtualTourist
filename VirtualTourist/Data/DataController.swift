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
    let viewContext : NSManagedObjectContext
    static let shared = DataController(modelName: "VirtualTourist")
    
    
    
    init (modelName: String){
        persistentContainer = NSPersistentContainer(name: modelName)
        viewContext = persistentContainer.viewContext
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    func configureContexts(){
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
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
        backgroundContext.performAndWait {
            if self.viewContext.hasChanges {
                do {
                    try self.backgroundContext.save()
                    print("Successfully saved context")
                } catch {
                    print("Failed to save context")
                }
            }
        }
        
    }
}
