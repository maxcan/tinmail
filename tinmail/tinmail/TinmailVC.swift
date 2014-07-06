//
//  ViewController.swift
//  tinmail
//
//  Created by Max Cantor on 6/25/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import UIKit
import swiftz_ios
import swiftz_core_ios

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

class MsgVC: UIViewController {
    let msg: Msg
    let nextMsg: Msg?
    init(coder:NSCoder, msg:Msg, nextMsg:Msg?) {
        self.msg = msg
        self.nextMsg = nextMsg
        super.init(coder: coder)
    }
}

class TinmailVC: UIViewController {
    
    @IBOutlet var MsgView: UIView
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
        if (GAuthSingleton.sharedAuth()?.refreshToken == nil) {
            println("authsingleton reftoken is null")
        }
        if let auth = GAuthSingleton.sharedAuth() {
            let msgListFut = getMsgList(auth)
            func withMl(msgList:MsgList?) -> Future<Msg?> {
                if let mg = msgList {
                    
                    println(mg.description.substringToIndex(100))
                    return getMsgDtl(auth, mg.messages[0])
                }
                let n:Msg? = nil
                return Future(exec:gcdExecutionContext, {return nil})
            }
            func withMsg(msg: Msg?) -> Void {
                println("with msg")
                if let mg = msg {
                    println(mg.description)
                } else {
                    println("no msg")
                }
               // return Future(exec:gcdExecutionContext, {return })
            }
            println("got msg fut")
            let msgFut = msgListFut.flatMap(withMl)
            msgFut.map(withMsg)
            //msgListFut.result()
            println("got msg res")
            //let _ = msgFut.map(withMsg)
//            msgFut.result()
            return
        }
    }
}

