/*
 * JBoss, Home of Professional Open Source.
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

/**
 Config contains the setting available in `fhconfig.plist`, populated by customers or by RHMAP platform at project creation.
 */
open class Config {
    let dataManager: UserDefaults
    var bundle: Bundle
    /// Singleton instance.
    open static var instance = Config()
    
    /**
     Constructor.
     
     - parameter bundle: which bundle to find the file.
     - parameter storage: where to store the config and the cloud properties info. Defaulted to UserDefaults.standard.
     */
    init(bundle:Bundle, storage: UserDefaults = UserDefaults.standard) {
        self.bundle = bundle
        dataManager = storage
    }
    
    /**
     Convenience constructor.
     */
    public convenience init() {
        self.init(bundle: Bundle.main)
    }
    
    /**
     Parameters used for `FH.init` call.
     */
    open var params: [String: Any] {
        var params: [String: Any] = [:]
        params["destination"] = "ios"
        let uuidGenerated = uuid
        params["cuid"] = uuidGenerated
        return params
    }
    
    
    /**
     The unique UUID of the device.
     */
    open var uuid: String {
        get {
            if let uuid = dataManager.string(forKey: "FHUUID") {
                return uuid
            }
            let uuid = UUID().uuidString
            dataManager.set(uuid, forKey: "FHUUID")
            
            return uuid
        }
    }
    
}
