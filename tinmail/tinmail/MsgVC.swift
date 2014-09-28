//
//  MsgVC.swift
//  tinmail
//
//  Created by Max Cantor on 8/10/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import UIKit
import swiftz
import swiftz_core

@objc class MsgVC:  UIViewController {
    var msg: Msg? = nil
    @IBOutlet var subjLbl: UILabel?
    @IBOutlet var fromLbl: UILabel?
    // this is ugly.. It would be nice to be able to set these when
//    var archFxn: ((msg: Msg) -> FrString)? = .None
//    var saveFxn: ((msg: Msg) -> FrString)? = .None
    var msgModel: MsgModel? = nil

    @IBAction func archive(sender:AnyObject) {
        msgModel?.archMsg(msg!) {
            onMainThread() { self.dismissViewControllerAnimated(true, { return } ) }
        }
    }
    @IBAction func keep(sender:AnyObject) {
        println("keeping")
        msgModel?.saveMsg(msg!) {
            onMainThread() { self.dismissViewControllerAnimated(true, { return } ) }
        }

//        saveFxn().fold() { (saveResFxn:(Msg -> FrString)) in
//            saveResFxn(msg).toEither.either({ e in die("err")}) { saveRes in
//                saveRes.toEither().either({e in die("ERROR getting msgres: \(e)", 4)}) { str in
//                    printMain("save res: \(str)")
//                    onMainThread() {
//                        self.dismissViewControllerAnimated(false) { println("dismisssed VC") }
//                    }
//                }gmai
//            }
//        }
    }
    func setMsg(model:MsgModel, msg: Msg) {
        printMain("about to set subj \(msg.subject) and f \(msg.from)")
        if (subjLbl == nil && fromLbl == nil) {
            printMain("nils")
            return
        }
        self.msgModel = model
//        self.archFxn = msgActions.archive
//        self.saveFxn = msgActions.save
        self.msg = msg
        if let s = subjLbl { s.text = msg.subject}
        if let f = fromLbl { f.text = msg.from}
    }
    deinit {
        printMain("msgvc deinit")
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}
