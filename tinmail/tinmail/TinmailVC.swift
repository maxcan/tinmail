//
//  ViewController.swift
//  tinmail
//
//  Created by Max Cantor on 6/25/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import UIKit

let kKeychainItemName = "OAuth2 Sample: Google+"
let kMyClientID = "241491780934-na17dn4btvf2m2843cgvic8n6s0l13vc.apps.googleusercontent.com"    // pre-assigned by service
let kMyClientSecret = "mWx1B6A9RonGSIxI6m21itn9" // pre-assigned by service
var gAuth:GTMOAuth2Authentication? = nil

class TinmailVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println(gAuth?.accessToken)
        gAuth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(kKeychainItemName,
            clientID:kMyClientID,
            clientSecret:kMyClientSecret)
        println(gAuth?.accessToken)
        if gAuth?.accessToken == nil {
            self.performSegueWithIdentifier("showLogin", sender:self)
        } else {
            var g = gAuth
            getUserId()
        }
    }
    func getUserId() {
        if let a = gAuth {
            let userIdUrl = "https://www.googleapis.com/gmail/v1/users/me/messages"
            var fetcher:GTMHTTPFetcher = GTMHTTPFetcher(URLString: userIdUrl)
            fetcher.authorizer = a
            fetcher.beginFetchWithCompletionHandler({ s1, s2 in
                if (s2 != nil) {
                    println("erorr", s2)
                }
                let jsonDict = NSJSONSerialization.JSONObjectWithData(s1, options: nil, error: nil) as NSDictionary
                println(jsonDict)
                })
            println("getUserId succ")
            
        }
    }
    
}

