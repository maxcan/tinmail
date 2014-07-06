//
//  GmailAPI.swift
//  tinmail
//
//  Created by Max Cantor on 7/2/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import Foundation
import swiftz_ios
import swiftz_core_ios

let kMsgListUrl = "https://www.googleapis.com/gmail/v1/users/me/messages?q=-label:tinmailed"

class MsgRef : Printable, JSONDecode, JSONEncode, JSON {
    let id:String
    let threadId:String
    init(id:String, threadId:String) {
        self.id = id
        self.threadId = threadId
    }
    var description: String {return "MsgRef: id:\(self.id) threadId:\(self.threadId)"}
    typealias J = MsgRef
    //    class func show(ref: MsgRef) -> String {
    //        return "MsgRef: id:\(ref.id) threadId:\(ref.threadId)"
    //    }
    func toJSON(x: J) -> JSValue {
        return JSValue.JSObject(["id": JSValue.JSString(x.id), "threadId": JSValue.JSString(x.threadId)])
    }
    class func fromJSON(x: JSValue) -> MsgRef? {
        switch (x) {
        case let .JSObject(d):
            let i:String? = d["id"] >>= JString.fromJSON
            let ti:String? = d["threadId"] >>= JString.fromJSON
            switch(i, ti) {
            case (let .Some(si), let .Some(sti)): return MsgRef(id:si, threadId:sti)
            default: return Optional.None
            }
        default: return Optional.None
        }
    }
}

class Msg : Printable, JSONDecode {
    let id: String
    let from: String
    let subject: String
    let threadId:String
    let deliveredTo: String?
    init(id:String, from:String, threadId:String, subject: String) {
        self.id = id
        self.threadId = threadId
        self.from = from
        self.subject = subject
        self.deliveredTo = nil
    }
    var description:String {
    return "msg"
    }
    class func create(id: String)(from: String)(threadId: String)(subject: String) -> Msg {
        return Msg(id:id, from: from, threadId: threadId, subject: subject)
    }
    class func fromJSON(x: JSValue) -> Msg? {
        switch (x) {
        case let .JSObject(d):
            let i:String? = d["id"] >>= JString.fromJSON
            let ti:String? = d["threadId"] >>= JString.fromJSON
            switch(d["payload"]) {
            case let .Some(.JSObject(payloadDict)):
                let subj:String? = d["Subject"] >>= JString.fromJSON
                let from:String? = d["From"] >>= JString.fromJSON
                return create <^> i <*> from <*> ti <*> subj
            default: return Optional.None
            }
        default: return Optional.None
        }
    }
}

class MsgList : JSONDecode {
    let messages:MsgRef[]
    init(_ messages:MsgRef[]) { self.messages = messages }
    var description: String {
    return "MsgList: " + self.messages.description
    }
    class func fromJSON(x: JSValue) -> MsgList? {
        var msgs:MsgRef[]?
        switch (x) {
        case let .JSObject(dict):
            msgs = dict["messages"] >>= JArray<MsgRef, MsgRef>.fromJSON
            if let m = msgs {return MsgList(m)} else { return Optional.None}
        default: return Optional.None
        }
    }
}

func getMsgDtl(auth: GTMOAuth2Authentication, msgRef: MsgRef) -> Future<Msg?> {
    //var msgMvar: MVar<Msg?> = MVar()
    println("get msg detail start")
    var fetcher:GTMHTTPFetcher =
    GTMHTTPFetcher(URLString: "https://www.googleapis.com/gmail/v1/users/me/messages/\(msgRef.id)")
    //    fetcher.authorizer = auth
    fetcher.delegateQueue = NSOperationQueue()
    
    fetcher.shouldFetchInBackground = true
    var ret: Future<Msg?> = Future(exec: gcdExecutionContext)
    fetcher.beginFetchWithCompletionHandler() { s1, s2 in
        
        var msg:Msg? = nil
        if (s2 == nil) {
            if let m = Msg.fromJSON(JSValue.decode(s1)) {
                msg = m
            }
        } else {
            println("erorr", s2)
        }
        ret.sig(msg)
        println("don dtl cb")
    }
    return ret
}


func getMsgList(auth:GTMOAuth2Authentication) -> Future<MsgList?> {
    //var msgListMvar: MVar<MsgList?> = MVar()
    println("getMsgList")
    var fetcher:GTMHTTPFetcher = GTMHTTPFetcher(URLString: kMsgListUrl)
    fetcher.authorizer = auth
    fetcher.shouldFetchInBackground = true
    fetcher.delegateQueue = NSOperationQueue()
    var ret: Future<MsgList?> = Future(exec: gcdExecutionContext)
    fetcher.beginFetchWithCompletionHandler() { s1, s2 in
        var msgList:MsgList? = nil
        if (s2 == nil) {
            if let m = MsgList.fromJSON(JSValue.decode(s1)) {
                msgList = m
            }
        } else {
            println("erorr", s2)
        }
        ret.sig(msgList)
        //Future(exec:gcdExecutionContext) { ret.sig(msgList) }
        println("don list cb")
    }
    return ret
}

