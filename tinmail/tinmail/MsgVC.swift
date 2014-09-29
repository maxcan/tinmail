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
    @IBOutlet var from2Lbl: UILabel?
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
        let regexWithName = NSRegularExpression(pattern: "\\s*(\\S.*\\S)\\s*<(\\S+@\\S+)>\\s*", options: nil, error: nil)
        let regexWithoutName = NSRegularExpression(pattern: "\\s*(\\S+@\\S+)\\s*", options: nil, error: nil)
        let matchWithoutName = regexWithoutName.firstMatchInString(msg.from, options: nil, range:NSMakeRange(0, countElements(msg.from)))
        let matchWithName = regexWithName.firstMatchInString(msg.from, options: nil, range:NSMakeRange(0, countElements(msg.from)))
        if let s = subjLbl { s.text = msg.subject}
        fromLbl >>- { f in self.from2Lbl >>- { (f2:UILabel) -> Void in
            func rangeSubstr(s:String, r:NSRange) -> String {
                return (s as NSString).substringWithRange(r)
            }
            if let matches = matchWithName {
                f.text = rangeSubstr(msg.from, matches.rangeAtIndex(1))
                f2.text = rangeSubstr(msg.from, matches.rangeAtIndex(2))
            } else if let matches = matchWithoutName {
                f.text = rangeSubstr(msg.from, matches.rangeAtIndex(1))
                f2.text = rangeSubstr(msg.from, matches.rangeAtIndex(2))
            } else {
                f.text = msg.from
                f2.text = ""
            }
            return
        } }
    }
    deinit {
        printMain("msgvc deinit")
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}
