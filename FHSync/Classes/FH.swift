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
import AeroGearHttp
import Reachability

public typealias CompletionBlock = (Response, NSError?) -> Void
/// HTTP standard methods.
public enum HTTPMethod: String {
    /// Http GET method.
    case GET = "GET"
    /// Http HEAD method.
    case HEAD = "HEAD"
    /// Http DELETE method.
    case DELETE = "DELETE"
    /// Http POST method.
    case POST = "POST"
    /// Http PUT method.
    case PUT = "PUT"
}
/**
 This class provides static methods to initialize the library and create new
 instances of all the API request objects.
 */
@objc(FH)
open class FH: NSObject {
    /// Properties is the returned object from a `FH.init` call when done successfully. It contains information like mbaas host name that are useful for FH.cloud call.
    static var props: CloudProps?
    /// Configuration object. Read form `fhconfig.plist` file.
    static var config: Config?
    /**
     Check if the device is online. The device is online if either WIFI or 3G
     network is available. Default value is true.

     - Returns: true if the device is online.
     */
    @objc
    open static var isOnline: Bool {
        guard let reachability = self.reachability else {return false}
        return reachability.connection != .none
    }

    /**
     If there was an error on FH.init it will be accessible from this method

     - Returns: the NSError from FH.init method.
     */
    open static var getInitError: NSError? {
        return initError
    }

    /// Boolean field to know if the reachability registration was done.
    static var initCalled: Bool = false
    /// Boolean field to indicate whether the app is online or offline.
    static var reachability: Reachability?

    /// NSError from FH.init method in case it fails
    static var initError: NSError? = nil

    /**
     Initialize the library.

     This must be called before any other API methods can be called. The
     initialization process runs asynchronously so that it won't block the main UI
     thread.

     You need to make sure it is successful before calling any other API methods. The
     best way to do is by catching the error that is thrown in case of failure to initialize.

     - parameter completionHandler: InnerCompletionBlock is a closure wrap-up that throws errors in case of init failure. If no error, the inner closure returns a JSON Object containing all the details from the init call.
     - throws NSError: Networking issue details.
     - returns: Void
     */
    open class func `init`(uri: String, _ completionHandler: @escaping CompletionBlock) -> Void {
        setup(config: uri, completionHandler: completionHandler)
    }

    /**
     Create a new instance of CloudRequest class and execute it immediately
     with the completionHandler closure. The request runs asynchronously.

     - parameter path: The path of the cloud API
     - parameter method: The HTTP request method to use for the request. Defaulted to .POST.
     - parameter headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     - parameter args: The request body data. Can be nil. Defaulted to nil.
     - parameter completionHandler: Closure to be executed as a callback of http asynchronous call.
     */
    @objc
    open class func performCloudRequest(_ path: String,  method: String, headers: NSDictionary?, args: NSDictionary?, completionHandler: @escaping CompletionBlock) -> Void {
        guard let httpMethod = HTTPMethod(rawValue: method) else {return}
        assert(props != nil, "FH init must be done prior th a Cloud call")
        args?.setValue(["cuid": self.config?.params["cuid"]], forKey: "__fh")
        let cloudRequest = CloudRequest(props: self.props, config: self.config, path: path, method: httpMethod, args: args as? [String : AnyObject], headers: headers as? [String : String])
        cloudRequest.exec(completionHandler: completionHandler)
    }

    /**
     Private method called by `FH.init`.
     */
    class func setup(config: String, completionHandler: @escaping CompletionBlock) -> Void {
        self.config = Config()
        let prop = [
            "hosts": [ "url": config ],
            "init": [ "trackId": UUID().uuidString ]
        ]
        self.props = CloudProps(props: prop as [String : AnyObject])
        // register for reachability and retry init if it fails because of offline mode
        do {
            try reachabilityRegistration()
        } catch let error as NSError {
            let response = Response()
            response.error = error
            completionHandler(response, error)
        }
        
        // completion callback for success
        completionHandler(Response(), nil)
    }

    /**
     Register for reachability and retry init if it fails because of offline mode.
     */
    class func reachabilityRegistration() throws -> Void {
        if initCalled == false {

            if reachability == nil {
                reachability = Reachability()!
            }

            do {
                try reachability!.startNotifier()
                initCalled = true
            } catch {
                let error = NSError(domain: "FeedHenryInitErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to start Reachability notifier"])
                throw error
            }
        }
    }
    
}
