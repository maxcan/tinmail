//
//  GmailAPI.swift
//  tinmail
//
//  Created by Max Cantor on 7/2/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import Foundation
import swiftz
import swiftz_core

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
        return "Msg: id:\(id) threadId:\(threadId) from:\(from) subject:\(subject)"
    }
    class func create(id: String)(from: String)(threadId: String)(subject: String) -> Msg {
        return Msg(id:id, from: from, threadId: threadId, subject: subject)
    }
    class func fromJSON(x: JSValue) -> Msg? {
        switch (x) {
        case let .JSObject(d):
            let i:String? = d["id"] >>= JString.fromJSON
            let ti:String? = d["threadId"] >>= JString.fromJSON
            println("i: \(i) ti: \(ti)")
            switch(d["payload"]) {
            case let .Some(.JSObject(payloadDict)):
                let hdrs:Dictionary<String,String>[]? = payloadDict["headers"] >>= JArray<Dictionary<String, String>,JDictionary<String, JString>>.fromJSON
                if let h = hdrs {
                    var hdrDict:Dictionary<String,String> = [:]
                    for curHdr:Dictionary<String, String> in h {
                        curHdr["value"] >>= { v in
                            curHdr["name"] >>= { n in
                                hdrDict.updateValue(v, forKey:n)
                            }
                        }
//                        hdrDict.updateValue(curHdr["value"]!, forKey: curHdr["name"]!)
                    }
                    let subj:String? = hdrDict["Subject"]
                    let from:String? = hdrDict["From"]
                    //println("hdrDict: \(hdrDict) subj: \(subj) from: \(from)")
                    return create <^> i <*> from <*> ti <*> subj
                }
            default: return Optional.None
            }
        default: return Optional.None
        }
        return Optional.None
        
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

func getMsgDtl(auth: GTMOAuth2Authentication, msgRef: MsgRef) -> Future<Result<Msg>> {
    var fetcher:GTMHTTPFetcher =
    GTMHTTPFetcher(URLString: "https://www.googleapis.com/gmail/v1/users/me/messages/\(msgRef.id)?format=full")
    fetcher.authorizer = auth
    fetcher.delegateQueue = NSOperationQueue()
    fetcher.shouldFetchInBackground = true
    var ret: Future<Result<Msg>> = Future(exec: gcdExecutionContext)
    fetcher.beginFetchWithCompletionHandler() { s1, s2 in
        if (s2 == nil) {
            let jsVal = JSValue.decode(s1)
            if let m = Msg.fromJSON(jsVal) {
                ret.sig(Result.Value(m))
            } else {
                ret.sig(Result.Error(NSError.errorWithDomain("MsgJSONParse", code: 1, userInfo:nil)))
            }
        } else {
            ret.sig(Result.Error(s2))
        }
    }
    return ret
}


func getMsgList(auth:GTMOAuth2Authentication) -> Future<Result<MsgList>> {
    var fetcher:GTMHTTPFetcher = GTMHTTPFetcher(URLString: kMsgListUrl)
    fetcher.authorizer = auth
    fetcher.shouldFetchInBackground = true
    fetcher.delegateQueue = NSOperationQueue()
    var ret: Future<Result<MsgList>> = Future(exec: gcdExecutionContext)
    fetcher.beginFetchWithCompletionHandler() { s1, s2 in
        if (s2 == nil) {
            let jsVal = JSValue.decode(s1)
            if let m = MsgList.fromJSON(jsVal) {
                ret.sig(Result.Value(m))
            } else {
                ret.sig(Result.Error(NSError.errorWithDomain("MsgJSONParse", code: 1, userInfo:nil)))
            }
        } else {
            ret.sig(Result.Error(s2))
        }
    }
    return ret
}

