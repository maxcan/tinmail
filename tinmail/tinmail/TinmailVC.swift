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
    { s1 in printMain(NSString(data:s1, encoding:NSASCIIStringEncoding)) } <^> d
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

//class MsgModel {
//    var auth: GTMOAuth2Authentication?
//    class func sharedAuth() -> GTMOAuth2Authentication? {
//        return GAuthSingleton.sharedInstance.auth
//    }
//    class var sharedInstance : GAuthSingleton {
//        struct Static {
//            static let instance : GAuthSingleton = GAuthSingleton()
//        }
//        return Static.instance
//    }
//}


class TinmailVC: UIViewController {
    @IBOutlet var MsgView: UIView?
    var msgVC:MsgVC?  // only here to keep the msgVC from deinit'ing
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
    }
    func showMsgs() {
        if let auth = GAuthSingleton.sharedAuth() {
            if( GAuthSingleton.sharedAuth()?.refreshToken != nil) {
//                printMain("showMsgs got auth")
                genMsgActions(auth).map({ (r:Result<MsgActions>) -> Void in
//                    printMain("got msg actions \(r)")
                    switch(r) {
                    case let .Value(v):
                        printMain("about to init msg model")
                        func onEmpty () {
                            onMainThread() {
                                die("all done", 666)
                            }
                        }
                        let model = MsgModel(auth, v.value, onEmpty:onEmpty) { (msgModel:MsgModel, msg:Msg) in
                            onMainThread() {
                                if let msgVC = self.storyboard?.instantiateViewControllerWithIdentifier("MsgVC") as? MsgVC {
                                    printMain("about to add msg view)")
                                    self.msgVC = msgVC
                                    self.MsgView?.addSubview(msgVC.view)  //TODO test this
                                    msgVC.setMsg(msgModel, msg:msg)
                                }
                            }

                        }
                    case let .Error(e): die("ERROR getting msgres: \(e)", 6)
                    }
                })

            } else {
                die("authsingleton reftoken is null",11)
            }
        } else {
            println("No auth in show msgs")
            exit(1)
        }
    }
}
//    func showMsgsWithAuth(auth:GTMOAuth2Authentication) {


 //        var saveMsg:MsgAction?
//        var archMsg:MsgAction?
//        genSaveMsg(auth).map() { (s1:ResMsgAction) -> Void in
//            switch(s1) {
//                case let (.Error(e)): printMain("error in genSaveMsg \(e)")
//                case let (.Value(v)): saveMsg = v.value
//            }
//        }
//        genArchiveMsg(auth).map() { (s1:ResMsgAction) -> Void in
//            switch(s1) {
//                case let (.Error(e)): printMain("error in genArchMsg \(e)")
//                case let (.Value(v)): archMsg = v.value
//            }
//        }

//        genMsgActions(auth).map() {
//            switch($1) {
//        genMsgActions(auth).map() { (actionsR:Result<MsgActions>) -> Void in
//            switch(actionsR) {
//                case let (.Value(actions)):
//                    func withMl(msgListR:Result<MsgList>) -> Future<Result<Msg>> {
//                        switch(msgListR) {
//                        case let .Error(e): return Future(exec:gcdExecutionContext, {.Error(e)})
//                        case let .Value(v): return getMsgDtl(auth, v.value.messages[0])
//                        }
//
//                    }
//                    let msgFut = msgListFut.flatMap(withMl)
//                    msgFut.map() { (m:Result<Msg>) -> Void in
//
//                        func withMsg(msgActions:MsgActions, msgRes: Result<Msg>) -> Void {
//                            msgRes.toEither().either({e in die("ERROR getting msgres: \(e)", 4)}) { msg in
//                                getLabelId("tinmailed", auth).map() {labelId -> Void in
//                                    labelId.toEither().either( { e in printMain("label err: \(e)") } )
//                                        { e in printMain("label res: \(e)") }
//                                }
//                                printMain(msg.description)
//                                printMain("getting main")
//                                onMainThread() {
//                                    if let msgVC = self.storyboard?.instantiateViewControllerWithIdentifier("MsgVC") as? MsgVC {
//                                        printMain("about to add msg view)")
//                                        self.MsgView?.addSubview(msgVC.view)  //TODO test this
//                                        msgVC.setMsg(msgActions, msg:msg)
//                                    }
//                                }
//                            }
//                        }
//                        withMsg(actions.value, m)
//                    }
//                return
//                    msgListFut.flatMap() { (msgsR:Result<MsgList>) -> Future<Void> in
//                        msgsR.toEither().either({e in
//                            printMain("error")
//                            return pure(nil)
//                        }) { ml in
//                            withMl(ml).flatMap() { (msgR:Result<Msg>) -> Future<Void> in
//                                return pure(nil)
//                            }
//                        }
//
//                    }
//                    msgFut.map({ withMsg(s, a, $1) })
//                default:
//                    printMain("error geting save/arch fxns)")
//                    return
//            }
//        }
//    }
//
//}


func die(s: String, code: Int32) {
    println(s)
    exit(code)
}


