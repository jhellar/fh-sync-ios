/*
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import UIKit
import CoreData
import FHSync

public let DATA_ID = "myShoppingList"

open class DataManager: NSObject {
    open var syncClient: FHSyncClient!
    open let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    open func start() {
        let conf = FHSyncConfig()
        conf?.syncFrequency = 1
        conf?.notifySyncStarted = true
        conf?.notifySyncCompleted = true
        conf?.notifySyncFailed = true
        conf?.notifyRemoteUpdateApplied = true
        conf?.notifyRemoteUpdateFailed = true
        conf?.notifyLocalUpdateApplied = true
        conf?.notifyDeltaReceived = true
        conf?.crashCountWait = 0;
        syncClient = FHSyncClient(config: conf)
        NotificationCenter.default.addObserver(self, selector:#selector(DataManager.onSyncMessage(_:)), name:Notification.Name(rawValue: "kFHSyncStateChangedNotification"), object:nil)
        syncClient.manage(withDataId: DATA_ID, andConfig:nil, andQuery:[:])
    }
    
    @objc open func onSyncMessage(_ note: Notification) {
        if let msg = note.object as? FHSyncNotificationMessage, let code = msg.code {
            print("Got notification: \(msg)")
            if code == REMOTE_UPDATE_APPLIED_MESSAGE {
                print("onSyncMessage::REMOTE_UPDATE_APPLIED_MESSAGE")
                if  let obj = msg.message.objectFromJSONString() as? [String: AnyObject], let action = obj["action"] as? String, action == "create" {
                    if let oldUid = obj["hash"] as? String,
                        let newUid = obj["uid"] as? String,
                        let item = findItemById(oldUid) {
                            item.uid = newUid
                    }
                    if managedObjectContext.hasChanges {
                        do {
                            try managedObjectContext.save()
                        } catch {
                            print("Failed to save in CoreData")
                        }
                    }
                }
            } else if code == LOCAL_UPDATE_APPLIED_MESSAGE || (code == DELTA_RECEIVED_MESSAGE && msg.uid != nil) {
                print("onSyncMessage::LOCAL_UPDATE_APPLIED_MESSAGE or DELTA_RECEIVED_MESSAGE")
                if let action = msg.message, let uid = msg.uid {
                    if action == "create" { // replace temporary id with the one assinged in cloud DB
                        let data = syncClient.read(withDataId: DATA_ID, andUID: uid)
                        let dataSource = data?["data"]
                        if let item = findItemById(uid) {
                            if let dataSource = dataSource as? [String: AnyObject] {
                                item.name = dataSource["name"] as? String
                            }
                        } else if let dataSource = dataSource as? [String: AnyObject]  {
                            //if findItemById(uid) == nil {
                                let newItem = NSEntityDescription.insertNewObject(forEntityName: "ShoppingItem", into: self.managedObjectContext) as! ShoppingItem
                                newItem.uid = uid
                                newItem.name = dataSource["name"] as? String
                                let createDoubleValue = dataSource["created"] as? NSNumber
                                if let doubleTime = createDoubleValue?.doubleValue {
                                    let date = Date(timeIntervalSince1970: doubleTime/1000)
                                    newItem.created = date
                                }
                            //}
                        }
                    } else if let item = findItemById(uid), action == "update" {
                        let data = syncClient.read(withDataId: DATA_ID, andUID: uid)
                        if let dataSource = data?["data"] as? [String: AnyObject] {
                            item.name = dataSource["name"] as? String
                        }
                    } else if let item = findItemById(uid), action == "delete" {
                        self.managedObjectContext.delete(item)
                    }
                }
                if managedObjectContext.hasChanges {
                    do {
                        try managedObjectContext.save()
                    } catch {
                        print("Failed to save in CoreData")
                    }
                }
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "kAppDataUpdatedNotification"), object: nil)
    }
    
    open func findItemById(_ uid: String) -> ShoppingItem? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ShoppingItem")
        fetchRequest.predicate = NSPredicate(format: "uid == %@", argumentArray: [uid])
        var fetchResults: [ShoppingItem]? = nil
        do {
            fetchResults = try managedObjectContext.fetch(fetchRequest) as? [ShoppingItem]
        } catch {
            print("DataManager::findItemById::Error fetching list")
        }
        if let results = fetchResults, results.count == 1 {
            return results[0]
        }
        return nil
    }
    
    open func listItems() -> [ShoppingItem]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ShoppingItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
        var fetchResults: [ShoppingItem]? = nil
        do {
            fetchResults = try managedObjectContext.fetch(fetchRequest) as? [ShoppingItem]
        } catch {
            print("DataManager::listItems::Error fetching list")
        }
        return fetchResults
    }
    
    open func createItem(_ item: ShoppingItem) {
        if let name = item.name, let created = item.created?.timeIntervalSince1970 {
            let myItem: [String: Any] = ["name": name as AnyObject, "created": created*1000]
            managedObjectContext.delete(item) // Remove the temporary coredata item for crete action
            syncClient.create(withDataId: DATA_ID, andData: myItem)
        }
    }
    
    open func updateItem(_ item: ShoppingItem) {
        if let uid = item.uid, let name = item.name, let created = item.created?.timeIntervalSince1970 {
            let myItem: [String: Any] = ["name": name as AnyObject, "created": created*1000]
            syncClient.update(withDataId: DATA_ID, andUID: uid, andData: myItem)
        }
    }
    
    open func deleteItem(_ item: ShoppingItem) {
        if let uid = item.uid {
            syncClient.delete(withDataId: DATA_ID, andUID: uid)
        }
    }
    
    open func getItem() -> ShoppingItem { // create a temporary coredata item to be created
        let entity = NSEntityDescription.entity(forEntityName: "ShoppingItem", in: managedObjectContext)
        let newItem = ShoppingItem(entity: entity!, insertInto: managedObjectContext)
        return newItem
    }
}
