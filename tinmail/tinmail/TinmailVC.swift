//
//  ViewController.swift
//  tinmail
//
//  Created by Max Cantor on 6/25/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import UIKit
import swiftz_ios

let kKeychainItemName = "OAuth2 Sample: Google+"
let kMyClientID = "241491780934-na17dn4btvf2m2843cgvic8n6s0l13vc.apps.googleusercontent.com"    // pre-assigned by service
let kMyClientSecret = "mWx1B6A9RonGSIxI6m21itn9" // pre-assigned by service
// var gAuth:GTMOAuth2Authentication? = nil

class GAuthSingleton {
    var auth: GTMOAuth2Authentication?
    class func sharedAuth() -> GTMOAuth2Authentication? {
        return GAuthSingleton.sharedInstance.auth
    }
    class var sharedInstance : GAuthSingleton {
        struct Static {
            static let instance : GAuthSingleton = GAuthSingleton()
        }
        return Static.instance
    }
}


class TinmailVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println(GAuthSingleton.sharedAuth()?.refreshToken)
        GAuthSingleton.sharedInstance.auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(kKeychainItemName,
            clientID:kMyClientID,
            clientSecret:kMyClientSecret)
        println(GAuthSingleton.sharedAuth()?.refreshToken)
        if GAuthSingleton.sharedAuth()?.refreshToken == nil {
            self.performSegueWithIdentifier("showLogin", sender:self)
        } else {
        println("have ref token")
            getUserId()
        }
    }
    override func viewDidAppear(animated: Bool) {
        println("vDA")
    }
    func getUserId() {
        println("getUserId")
        if (GAuthSingleton.sharedAuth()?.refreshToken == nil) {
            println("authsingleton reftoken is null")
        }
        if let auth = GAuthSingleton.sharedAuth() {
            let msgListFut = getMsgList(auth)
//            let _:Future<()> = msgListFut.map { msgList in
//                println("msgslist:  " + msgList.description)
//                if let mg = msgList {
//                    println(mg.description)
//                    let msgFut = getMsgDtl(auth, mg.messages[0])
//                    println("getting messages")
//                    msgFut.map { msgDtl in
//                        println("we have  amsg: " + msgDtl.description)
//                    }
//                }
//                
//            }
//            return
            println("we have a msglist fut")
            let _:Future<()> = Future(exec:gcdExecutionContext, "getList") {
                let msgList = msgListFut.result()
                if let mg = msgList {
                    println(mg.description)
                    let msgFut = getMsgDtl(auth, mg.messages[0])
                    //let _:Future<()> = Future(exec:gcdExecutionContext, "getdtl") {
                        println("msg detail: about to fetch")
                        let dtl = msgFut.result()
                        println("msg detail: " + dtl.description)
                    //}
                }
            }
            println("done")
        }
    }
}

