//
//  MsgModel.swift
//  tinmail
//
//  Created by Max Cantor on 9/20/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import Foundation
import swiftz
import swiftz_core

class MsgModel {
    let auth: GTMOAuth2Authentication
    let onNewMsg: (MsgModel, Msg, Msg?) -> Void
    let onEmpty: () -> Void
    let actions: MsgActions
    var msgs: [Msg] = []

    init(_ auth:GTMOAuth2Authentication
            , _ actions: MsgActions
            , onEmpty: () -> Void
            , onNewMsg: ((MsgModel, Msg, Msg?) -> Void)) {
        self.auth = auth
        self.actions = actions
        self.onNewMsg = onNewMsg
        self.onEmpty = onEmpty
        self.loadMsgs()
    }
    func archMsg(msg: Msg, _ then:() -> Void) {
        actions.archive(msg:msg).map() { (res:Result<String>) -> Void in
            switch (res) {
                case let .Error(e): die("error archiving msg \(e)", 9)
                case let .Value(v):
                    self.removeMsgFromQueue(msg)
                    then()
            }
        }
    }
    func saveMsg(msg: Msg, _ then:() -> Void) {
        actions.save(msg:msg).map() { (res:Result<String>) -> Void in
            switch (res) {
                case let .Error(e): die("error saving msg \(e)", 10)
                case let .Value(v):
                    self.removeMsgFromQueue(msg)
                    then()
            }
        }

    }
    private func removeMsgFromQueue(msg: Msg) {
        self.msgs = self.msgs.filter() { t in t.id != msg.id}
        if (msgs.count > 0) {
            self.onNewMsg(self, msgs[0], (msgs.count > 1 ? msgs[1] : nil))
        } else {
            loadMsgs()
        }
    }
    private func loadMsgDtls(msgRefs: [MsgRef], _ idx:Int) {
        if (idx >= msgRefs.count) {
            if (msgs.count > 0) {
                self.onNewMsg(self, msgs[0], (msgs.count > 1 ? msgs[1] : nil))
            } else {
                die("no more messages",12)
            }
        } else {
            getMsgDtl(auth, msgRefs[idx]).map() { ( msgR: Result<Msg>) -> Void in
                switch(msgR) {
                case let .Error(e): die("error mdsg \(e)", 7)
                case let .Value(msg):
                    self.msgs.append(msg.value)
                    self.loadMsgDtls(msgRefs, idx + 1)
                }
            }
        }
    }
    private func loadMsgs() {
        printMain("load msgs")
        getMsgList(self.auth).map() { (listRes:Result<MsgList>) -> Void in
            printMain("load msgs - GML callback:")

            switch(listRes) {
            case let .Value(v):
                let msgRefs = v.value.messages
                // for some reason the message list doesn't work
//                let mrList = List fromSeq(msgRefs)
                if (msgRefs.count == 0) {
                    return self.onEmpty()
                }
                self.msgs.reserveCapacity(msgRefs.count)
                self.loadMsgDtls(msgRefs, 0)
            case let .Error(e):
                die("ERROR loading msg list: \(e)", 6)
            }
            return
        }
    }
}