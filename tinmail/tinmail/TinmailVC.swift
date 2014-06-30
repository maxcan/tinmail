//
//  ViewController.swift
//  tinmail
//
//  Created by Max Cantor on 6/25/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import UIKit


class TinmailVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        
        //        finishedSelector:@selector(viewController:finishedWithAuth:error:)] autorelease];
        //
        //        [[self navigationController] pushViewController: animated:YES];
    }
    
    // typedef void (^GTMOAuth2ViewControllerCompletionHandler)(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error);
    
    
    @IBAction func startOauth(sender: AnyObject) {
        
        println("init oauthvc")
        NSLog("init oa")
        let kKeychainItemName = "OAuth2 Sample: Google+"
        
        let kMyClientID = "241491780934-na17dn4btvf2m2843cgvic8n6s0l13vc.apps.googleusercontent.com"    // pre-assigned by service
        let kMyClientSecret = "mWx1B6A9RonGSIxI6m21itn9" // pre-assigned by service
        
        let scope = "https://www.googleapis.com/auth/plus.me" // scope for Google+ API
        
        // GTMOAuth2ViewControllerTouch *viewController;
        var gtmVC: GTMOAuth2ViewControllerTouch = GTMOAuth2ViewControllerTouch(scope:scope,
            clientID:kMyClientID,
            clientSecret:kMyClientSecret,
            keychainItemName:kKeychainItemName,
            delegate:nil,
            finishedSelector:Selector("onOauthSucc::"))
        self.navigationController?.pushViewController(gtmVC, animated: true)
        
    }
    func onOauthSucc(auth: GTMOAuth2Authentication, err: NSError) {
        NSLog("success", auth)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

