//
//  Platform.swift
//  LoKey
//
//  Created by Will Steiner on 3/10/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import Foundation
import Alamofire

class Platform {
    
    let apiRoot = "https://platform.clearblade.com"
    let sysKey : String
    let sysSecret : String
    var token : String
    
    var headers: HTTPHeaders
    var delegate: PlatformLoadDelegate?
    var deviceKey : String
    
    init(deviceKey : String){
        self.sysKey = "eac2b78c0bc0a58df7e19b93d99201"
        self.sysSecret = "EAC2B78C0BF0B9A6C1D4D593B1B401"
        self.deviceKey = deviceKey
        self.headers = [
            "ClearBlade-Systemkey"    : self.sysKey,
            "ClearBlade-Systemsecret" : self.sysSecret
        ]
        self.token = ""
    }
    
    /*
    func logHttpResp(_ resp : Response){
        print("-req: \(resp.request)")  // original URL request
        print("-resp: \(resp.response)") // HTTP URL response
        print("-data: \(resp.data)")     // server data
        print("-result: \(resp.result)")   // result of response serialization
        
        if let data : NSDictionary = resp.result.value as? NSDictionary {
            
        }
    }
 */
    
    func initLogin(_ deviceKey:String){
        self.deviceKey = deviceKey
        print("--- Start Anonn login ---")
        Alamofire.request("\(apiRoot)/api/v/1/user/anon",method: .post, headers: self.headers)
        .responseJSON { response in
            //self.logHttpResp(response);
            print("--- Anonn login Results ---")
            print("-req: \(response.request)")  // original URL request
            print("-resp: \(response.response)") // HTTP URL response
            print("-data: \(response.data)")     // server data
            print("-result: \(response.result)")   // result of response serialization
            if let data : AnyObject = response.result.value as? AnyObject {
                // TODO: Implement header update logic
                self.headers = [
                    "ClearBlade-Systemkey": self.sysKey,
                    "ClearBlade-Systemsecret": self.sysSecret,
                    "ClearBlade-UserToken" : data["user_token"] as! String
                ]
                print("New headers: \n \(self.headers)")
                self.delegate?.anonLogin(success: true)
                
            } else {
                self.delegate?.anonLogin(success: false)
            }
        }
    }
    
    
    func handshake(){
        print("--- Attempt handshake ---")
        
        let parameters = [
            "device": self.deviceKey,
        ]
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/handshake",method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : [String:AnyObject] = response.result.value as? [String:AnyObject] {
                    print("result: \(data)")
                    
                    if(data["success"] as! Bool == true){
                        if let results : [String:AnyObject] = data["results"] as? [String:AnyObject]{
                            //if let state : [String:AnyObject] = results["state"] as? [String:AnyObject] {
                                if let user : [String:AnyObject] = results["user"] as? [String:AnyObject]{
                                    if let creds : [String:AnyObject] = user["creds"] as? [String:AnyObject]{
                                        if let token : String = creds["authToken"] as? String{
                                            self.token = token
                                            self.headers = [
                                                "ClearBlade-Systemkey"   : self.sysKey,
                                                "ClearBlade-Systemsecret": self.sysSecret,
                                                "ClearBlade-UserToken"   : self.token
                                            ]
                                            self.delegate?.newState(results)
                                            self.delegate?.stateLoad(success: true)
                                        }
                                    } else { self.delegate?.stateLoad(success: false) }
                                } else { self.delegate?.stateLoad(success: false) }
                            //} else { self.delegate?.stateLoad(success: false) }
                        } else { self.delegate?.stateLoad(success: false) }
                    } else { self.delegate?.stateLoad(success: false) }
                } else {
                    // Error making request
                    self.delegate?.stateLoad(success: false)
                }
        }
    }
    
    
    func pushChanges(changes : [Change], _ callback: @escaping (_ success : Bool)-> Void){
        print("--- Attempt change push ---")
        
        let parameters = [
            "changes": Fmt.packChanges(changes) as AnyObject,
            "method": "sync" as AnyObject
        ] as [String : AnyObject]
        
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/syncState", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("--- PUSH result ---")
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : NSDictionary = response.result.value as? NSDictionary {
                    print("result: \(data)")
                    
                    if(data["success"] as! Bool == true){
                        //self.delegate?.changesSynced(success: true)
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
        }

    }
    
    func sync(_ changes : [Change], _ events : [Event], _ callback: @escaping (_ success : Bool)-> Void){
        print("--- Attempt sync push ---")
        
        let parameters = [
            "changes": Fmt.packChanges(changes) as AnyObject,
            "events" : Fmt.packEvents(events) as AnyObject,
            "method" : "sync" as AnyObject
            ] as [String : AnyObject]
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/syncState", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("--- PUSH result ---")
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : NSDictionary = response.result.value as? NSDictionary {
                    print("result: \(data)")
                    
                    if(data["success"] as! Bool == true){
                        //self.delegate?.changesSynced(success: true)
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
        }
    }
    
    /*
    func proclaimLaunch(){
        print("--- Proclaim Launch ---")
        let parameters = [
            "status": "launch" as AnyObject
            ] as [String : AnyObject]
        
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/pulse", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("--- Proclaim Launch result ---")
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : NSDictionary = response.result.value as? NSDictionary {
                    print("result: \(data)")
                }
        }
    }
     */
    
    // App is about to be suspended... (fire request for timer to send push wakeup?)
    func proclaimSuspension(){
        print("--- Proclaim Suspension ---")
        let parameters = [
            "status": "suspended" as AnyObject
            ] as [String : AnyObject]
        
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/pulse", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("--- Proclaim Suspension result ---")
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : NSDictionary = response.result.value as? NSDictionary {
                    print("result: \(data)")
                }
        }
    }

    
    func proclaimRunning(){
        print("--- Proclaim Online ---")
        let parameters = [
            "status": "running" as AnyObject
            ] as [String : AnyObject]
        
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/pulse", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("--- Proclaim Online result ---")
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : NSDictionary = response.result.value as? NSDictionary {
                    print("result: \(data)")
                }
        }
    }

    
    func proclaimBackground(){
        print("--- Proclaim Background ---")
        let parameters = [
            "status": "background" as AnyObject
            ] as [String : AnyObject]
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/pulse", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("--- Proclaim Background result ---")
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : NSDictionary = response.result.value as? NSDictionary {
                    print("result: \(data)")
                }
        }
    }
    
    func pushState(_ state : [String:AnyObject]){
        print("--- Attempt PUSH ---")
        
        let parameters = [
            "state": state as AnyObject,
            "method": "push" as AnyObject
        ] as [String : AnyObject]
        
        
        Alamofire.request("\(apiRoot)/api/v/1/code/\(sysKey)/stateSync", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("--- PUSH result ---")
                print(response.request)  // original URL request
                print(response.response) // HTTP URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let data : NSDictionary = response.result.value as? NSDictionary {
                    print("result: \(data)")
                }
        }
    }
    
    
}
