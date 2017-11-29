//
//  ViewController.swift
//  FHSync
//
//  Created by jhellar@redhat.com on 11/29/2017.
//  Copyright (c) 2017 jhellar@redhat.com. All rights reserved.
//

import UIKit
import FHSync

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        FH.init(uri: "https://fh-sync-server-myproject.192.168.37.1.nip.io") {(resp: Response, error: NSError?) -> Void in
            if let error = error {
                print("FH init failed. Error = \(error)")
//                if FH.isOnline == false {
//                    self.presentAlert("Offline", message: "Make sure you're online.")
//                } else {
//                    if error.code > 0 {
//                        self.presentAlert("Init error", message: error.localizedDescription)
//                    } else {
//                        self.presentAlert("Missing Configuration", message: "Please fill in fhconfig.plist file.")
//                    }
//                }
                return
            }
            print("initialized OK:: Starting SyncClient")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

