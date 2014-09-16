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
    //    msg: Msg
    @IBOutlet var subjLbl: UILabel?
    @IBOutlet var fromLbl: UILabel?
    // this is ugly.. but we "know" there's an auth at this point
    let archFxn: Result<(msg: Msg) -> FrString>
    let saveFxn: Result<(msg: Msg) -> FrString>

    @IBAction func archive(sender:AnyObject) {
        println("archiving")
    }
    @IBAction func keep(sender:AnyObject) {
        println("keeping")
        saveFxn().fold() { saveResFxn in
            saveResFxn(msg).map() { saveRes in
                saveRes.toEither().either({e in die("ERROR getting msgres: \(e)", 4)}) { str in
                    printMain("save res: \(str)")
                    onMainThread() {
                        self.dismissViewControllerAnimated(false) { println("dismisssed VC") }
                    }
                }
            }
        }
    }
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
