//
//  AccountVC.swift
//  tinmail
//
//  Created by Max Cantor on 7/1/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import Foundation


class AccountVC: UIViewController {
    
    @IBAction func startOauth(sender: AnyObject) {
        println("init oauthvc")
        NSLog("init oa")
        let scope = "https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.modify" // scope for Google+ API
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
        if err != nil {
            println("error:", err)
        } else {
            println("success")
            gAuth = auth
            self.navigationController.popToRootViewControllerAnimated(true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
}
}
