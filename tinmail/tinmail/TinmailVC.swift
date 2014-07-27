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

// save some keystrokes
func onMainThread(f:(() -> Void)) -> Void {
    dispatch_async(dispatch_get_main_queue(), f)
}

func printMain(s: AnyObject?) -> Void {
    onMainThread() { println(s)}
}

func printEncodedData(d: NSData?) -> Void {
    printMain(NSString(data:d, encoding:NSASCIIStringEncoding))
}
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
    @IBOutlet var subjLbl: UILabel?
    @IBOutlet var fromLbl: UILabel?
    func setMsg(msg: Msg) {
        //self.msg = msg
        printMain("about to set subj \(msg.subject) and f \(msg.from)")
        
        if (subjLbl == nil && fromLbl == nil) {
            printMain("nils")
            return
        }
        if let s = subjLbl { s.text = msg.subject}
        if let f = fromLbl { f.text = msg.from}
    }
    init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class TinmailVC: UIViewController {
    
    @IBOutlet var MsgView: UIView?
    override func viewDidLoad() {
        super.viewDidLoad()
        printMain(GAuthSingleton.sharedAuth()?.refreshToken)
        GAuthSingleton.sharedInstance.auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(kKeychainItemName,
            clientID:kMyClientID,
            clientSecret:kMyClientSecret)
//        NSLog("refresh tokey: ", GAuthSingleton.sharedAuth()?.refreshToken)
        printMain("shared auth")
        printMain(GAuthSingleton.sharedAuth())
        if GAuthSingleton.sharedAuth()?.refreshToken == nil {
            self.performSegueWithIdentifier("showLogin", sender:self)
        } else {
//            showMsgs()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        printMain("view did appear")
        showMsgs()
//        if GAuthSingleton.sharedAuth()?.refreshToken == nil {
//            self.performSegueWithIdentifier("showLogin", sender:self)
//        } else {
//            showMsgs()
//        }
    }
    func showMsgs() {
        if let auth = GAuthSingleton.sharedAuth() {
            ( GAuthSingleton.sharedAuth()?.refreshToken != nil
            ? showMsgsWithAuth(auth)
            : printMain("authsingleton reftoken is null") )
        } else {
            println("No auth in show msgs")
            exit(1)
        }
        
    }
    func showMsgsWithAuth(auth:GTMOAuth2Authentication) {
        let msgListFut = getMsgList(auth)
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
            msgRes.toEither().either({e in die("ERROR getting msgres: \(e)", 4)}) { msg in
                getLabelId("tinmailed", auth).map() {labelId -> Void in
                    labelId.toEither().either( { e in printMain("label err: \(e)") } )
                                               { e in printMain("label res: \(e)") }
                }
                printMain(msg.description)
                printMain("getting main")
                onMainThread() {
                    if let msgVC = self.storyboard.instantiateViewControllerWithIdentifier("MsgVC") as? MsgVC {
                        
                        printMain("about to add msg view)")
                        self.MsgView?.addSubview(msgVC.view)  //TODO test this
                        msgVC.setMsg(msg)
                    }
                }
            }
        }
        let msgFut = msgListFut.flatMap(withMl)
        msgFut.map(withMsg)
    }
}

func die(s: String, code: Int32) {
    println(s)
    exit(code)
}


