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

import UIKit

open class RootViewController: UITableViewController {
    open var items: [ShoppingItem]!
    open var dataManager: DataManager!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO once Swift2.2 is released change selector
        //let sel = #selector(RootViewController.onDataUpdated(_))
        NotificationCenter.default.addObserver(self, selector: #selector(RootViewController.onDataUpdated(_:)), name: NSNotification.Name(rawValue: "kAppDataUpdatedNotification"), object: nil)
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc open func onDataUpdated(_ note: Notification) {
        print("::onDataUpdated::refresh tableview")
        items = dataManager.listItems()

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
//        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension RootViewController {
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let item = self.items[indexPath.row]
        if let itemName = item.name {
            cell?.textLabel?.text = "\(itemName)"
        }
        if let itemDate = item.created {
            let formatter = DateFormatter()
            formatter.dateStyle = DateFormatter.Style.long
            formatter.timeStyle = .medium
            cell?.detailTextLabel!.text = formatter.string(from: itemDate as Date)
        }
        return cell!
    }
    open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            dataManager.deleteItem(items[indexPath.row])
            tableView.reloadData()
        }
    }
}

// MARK: Segue
extension RootViewController {
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, identifier == "showExistingItemDetails" {
            if let sender = sender as? UITableViewCell,
                let cell = tableView.indexPath(for: sender) {
                let dest = segue.destination as? DetailledViewController
                dest?.item = items[cell.row]
                dest?.dataManager = dataManager
            }
        } else if let identifier = segue.identifier, identifier == "showNewItemDetails" {
            let dest = segue.destination as? DetailledViewController
            //dest?.item = dataManager.getItem()
            dest?.dataManager = dataManager
        }
    }
}
