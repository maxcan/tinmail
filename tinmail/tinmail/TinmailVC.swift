//
//  ViewController.swift
//  tinmail
//
//  Created by Max Cantor on 6/25/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import UIKit

class TinmailVC: UIViewController {
    
    var auth:GTMOAuth2Authentication?
    let kKeychainItemName = "OAuth2 Sample: Google+"
    let kMyClientID = "241491780934-na17dn4btvf2m2843cgvic8n6s0l13vc.apps.googleusercontent.com"    // pre-assigned by service
    let kMyClientSecret = "mWx1B6A9RonGSIxI6m21itn9" // pre-assigned by service
    
    //    init(coder aDecoder: NSCoder!) {
    //        auth = nil
    //        super(coder)
    //    }
    override func viewDidLoad() {
        
        self.auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(kKeychainItemName,
            clientID:kMyClientID,
            clientSecret:kMyClientSecret);
        
        super.viewDidLoad()
        
        // Retain the authentication object, which holds the auth tokens
        //
        // We can determine later if the auth object contains an access token
        // by calling its -canAuthorize method
        //                [self setAuthentication:auth];
    }
    
    
    @IBAction func startOauth(sender: AnyObject) {
//        if (auth != nil) {
//            println("already have it")
//            return
//        }
        println("init oauthvc")
        NSLog("init oa")
        let scope = "https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.modify" // scope for Google+ API
        //        self.onOauthSucc(nil, auth: nil, err: nil)
        // GTMOAuth2ViewControllerTouch *viewController;
        var gtmVC: GTMOAuth2ViewControllerTouch = GTMOAuth2ViewControllerTouch(scope:scope,
            clientID:kMyClientID,
            clientSecret:kMyClientSecret,
            keychainItemName:kKeychainItemName,
            delegate:self,
            finishedSelector:Selector("succ:auth:err:")
        )
        self.navigationController?.pushViewController(gtmVC, animated: true)
        
    }
    func succ(sender:UIViewController, auth: GTMOAuth2Authentication?, err: NSError){
        println("success")
        self.auth = auth
        getUserId()
    }
    func getUserId() {
        if let a = auth {
            let userIdUrl = "https://www.googleapis.com/gmail/v1/users/me/messages"
            var fetcher:GTMHTTPFetcher = GTMHTTPFetcher(URLString: userIdUrl)
            fetcher.authorizer = a
//            fetcher.beginFetchWithCompletionHandler(<#handler: ((NSData!, NSError!) -> Void)?#>)
            fetcher.beginFetchWithCompletionHandler({ s1, s2 in
                if (s2 != nil) {
                    println("erorr", s2)
                }
                let jsonDict = NSJSONSerialization.JSONObjectWithData(s1, options: nil, error: nil) as NSDictionary
                println(jsonDict)
        })
        
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

