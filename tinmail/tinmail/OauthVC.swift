//
//  OauthVC.swift
//  tinmail
//
//  Created by Max Cantor on 6/29/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import Foundation

class OauthVC: GTMOAuth2ViewControllerTouch {
    init() {
        println("init oauthvc")
        NSLog("init oa")
        let kKeychainItemName = "OAuth2 Sample: Google+"
        
        let kMyClientID = "241491780934-na17dn4btvf2m2843cgvic8n6s0l13vc.apps.googleusercontent.com"    // pre-assigned by service
        let kMyClientSecret = "mWx1B6A9RonGSIxI6m21itn9" // pre-assigned by service
        
        let scope = "https://www.googleapis.com/auth/plus.me" // scope for Google+ API
        
        // GTMOAuth2ViewControllerTouch *viewController;
        super.init(scope:scope,
        clientID:kMyClientID,
        clientSecret:kMyClientSecret,
        keychainItemName:kKeychainItemName,
        delegate:nil,
        finishedSelector:Selector("onOauthSucc::"))
        
    }
    func onOauthSucc(auth: GTMOAuth2Authentication, err: NSError) {
        NSLog("success", auth)
    }


}