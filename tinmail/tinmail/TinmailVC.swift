//
//  ViewController.swift
//  tinmail
//
//  Created by Max Cantor on 6/25/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import UIKit
import swiftz
import swiftz_core

let kKeychainItemName = "tinmail google+ oauth"
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
    //    msg: Msg
    @IBOutlet var subjLbl: UILabel
    @IBOutlet var fromLbl: UILabel
    func setMsg(msg: Msg) {
        //self.msg = msg
        println("about to set subj \(msg.subject) and f \(msg.from)")
        
        if (subjLbl == nil && fromLbl == nil) {
            println("nils")
            return
        }
        subjLbl.text = msg.subject
        fromLbl.text = msg.from
    }
    init(coder: NSCoder) {
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
//        NSLog("refresh tokey: ", GAuthSingleton.sharedAuth()?.refreshToken)
        println("shared auth")
        println(GAuthSingleton.sharedAuth())
        if GAuthSingleton.sharedAuth()?.refreshToken == nil {
            self.performSegueWithIdentifier("showLogin", sender:self)
        } else {
            getUserId()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        println("view did appear")
        if GAuthSingleton.sharedAuth()?.refreshToken == nil {
            self.performSegueWithIdentifier("showLogin", sender:self)
        } else {
            getUserId()
        }
    }
    func getUserId() {
        if (GAuthSingleton.sharedAuth()?.refreshToken == nil) {
            println("authsingleton reftoken is null")
        }
        if let auth = GAuthSingleton.sharedAuth() {
            let msgListFut = getMsgList(auth)
            let labels = getLabelList(auth)
            func withMl(msgList:Result<MsgList>) -> Future<Result<Msg>> {
                switch msgList {
                case let .Value(ml):
                    return getMsgDtl(auth, ml.value.messages[0])
                case let .Error(e):
                    println("ERROR ", e.description)
                    return Future(exec:gcdExecutionContext, {return .Error(e)})
                }
            }
            func withMsg(msgRes: Result<Msg>) -> Void {
                switch msgRes {
                case let .Value(msgVal):
                    let msg = msgVal
                    println(msg.value.description)
                    let msgVC:Optional<MsgVC> = storyboard.instantiateViewControllerWithIdentifier("MsgVC") as? MsgVC
                    if let m = msgVC {
                            MsgView.addSubview(m.view)
                            m.setMsg(msg.value)
                            
                    }
                case let .Error(e):
                    println("ERROR ", e.description)
                    return
                }
            }
            let msgFut = msgListFut.flatMap(withMl)
            msgFut.map(withMsg)
            labels.map({res -> Void in
                println("labels cv:")
                switch(res) {
                    case let .Value(lbls):
                        println("labelS:")
                        println(lbls)
                        return
                    default: return
            }})
            return
        }
    }
}

