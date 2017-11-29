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

open class DetailledViewController: UIViewController {
    var item: ShoppingItem!
    var action: String!
    var dataManager: DataManager!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var createdTextField: UITextField!
    @IBOutlet weak var createdLabel: UILabel!
    
//    public var isUpdate: Bool {
//        if let uid = item.uid where uid != "" {
//            print("UID \(uid)")
//            return true
//        }
//        return false
//    }
    open override func viewDidLoad() {
        if let item = item {
            self.nameTextField.text = item.name
            self.createdLabel.isHidden = false
            self.createdTextField.isHidden = false
            if let created = item.created {
                let formatter = DateFormatter()
                formatter.dateStyle = DateFormatter.Style.long
                formatter.timeStyle = .medium
                self.createdTextField.text = formatter.string(from: created as Date)
            }
            
        } else {// create
            self.createdLabel.isHidden = true
            self.createdTextField.isHidden = true
        }
    }
    
    @IBAction func saveItem(_ sender: AnyObject) {
        if let name = self.nameTextField.text, name != "" {
            if let item = item {
                item.name = name
                item.created = Date()
                dataManager.updateItem(item)
                print("HIT CREATE > UPDATE BUTTON:: \(item)")
            } else {
                item = dataManager.getItem()
                item.name = name
                item.created = Date()
                dataManager.createItem(item)
                
                print("HIT CREATE > SAVE BUTTON:: \(item)")
            }
        } else {
            displayError("Name is required")
        }
        let parent = self.parent as! UINavigationController
        parent.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        if let parent = self.parent as? UINavigationController {
            parent.popViewController(animated: true)
        }
    }
    
    func displayError(_ error: String) {
        let alert = UIAlertController(title: error, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
