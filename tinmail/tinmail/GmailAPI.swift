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

enum LabelType: JSONDecode {
    case User
    case System
    static func fromJSON(x: JSValue) -> LabelType? {
        switch(x) {
        case .JSString("user"): return User
        case .JSString("system"): return System
        default: return nil
        }
    }
}
enum LabelMessageListVisibility:JSONDecode {
    case Hide
    case Show
    static func fromJSON(x: JSValue) -> LabelMessageListVisibility? {
        switch(x) {
        case .JSString("hide"): return Hide
        case .JSString("show"): return Show
        default: return nil
        }
    }
}
enum LabelListVisibility: JSONDecode {
    case LabelHide
    case LabelShow
    case LabelShowIfUnread
    static func fromJSON(x: JSValue) -> LabelListVisibility? {
        switch(x) {
        case .JSString("labelHide"): return LabelHide
        case .JSString("labelShow"): return LabelShow
        case .JSString("labelShowIfUnread"): return LabelShowIfUnread
        default: return nil
        }
    }
}

class Label:JSONDecode, JSONEncode, JSON {
    let id: String
    let name: String
    let type: LabelType
    let messageListVisibility: LabelMessageListVisibility?
    let labelListVisibility: LabelListVisibility?
    func toJSON(x: J) -> JSValue {
        return JSValue.JSNull()
    }
    typealias J = Label
    init(_ id: String, _ name: String, _ type: LabelType, _ messageListVisibility: LabelMessageListVisibility?, _ labelListVisibility:LabelListVisibility? ) {
        self.id = id
        self.type = type
        self.name = name
        self.messageListVisibility = messageListVisibility
        self.labelListVisibility = labelListVisibility
    }
    class func create(id: String)(name: String)(type: LabelType)(mlv: LabelMessageListVisibility)(llv:LabelListVisibility) -> Label {
        return Label(id, name, type, mlv, llv)
    }
    class func fromJSON(x: JSValue) -> Label? {
        switch (x) {
        case let .JSObject(d):
            let i:String? = d["id"] >>= JString.fromJSON
            let n:String? = d["name"] >>= JString.fromJSON
            let mlv:LabelMessageListVisibility? = d["messageListVisibility"] >>= LabelMessageListVisibility.fromJSON
            let llv:LabelListVisibility? = d["labelListVisibility"] >>= LabelListVisibility.fromJSON
            let tp:LabelType? = d["type"] >>= LabelType.fromJSON
            return create <^> i <*> n <*> tp <*> mlv <*> llv
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
                let hdrs:[Dictionary<String,String>]? = payloadDict["headers"] >>= JArray<Dictionary<String, String>,JDictionary<String, JString>>.fromJSON
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
    let messages:[MsgRef]
    init(_ messages:[MsgRef]) { self.messages = messages }
    var description: String {
    return "MsgList: " + self.messages.description
    }
    class func fromJSON(x: JSValue) -> MsgList? {
        var msgs:[MsgRef]?
        switch (x) {
        case let .JSObject(dict):
            msgs = dict["messages"] >>= JArray<MsgRef, MsgRef>.fromJSON
            if let m = msgs {return MsgList(m)} else { return Optional.None}
        default: return Optional.None
        }
    }
}


func decodeRes<A:JSONDecode>(ret: Future<Result<A>>) -> ((s1:NSData?, s2:NSError?) -> Void) {
    return {s1, s2 in
        switch s2 {
        case .None:
            if let s1 = s1 {
//            JSValue.decode(s1).flatMap(Msg.fromJSON).maybe(
//                   ret.sig(Result.Error(NSError.errorWithDomain("MsgJSONParse", code: 1, userInfo:nil)))
//                , { m in ret.sig(Result.Value(Box(m))) })
                JSValue.decode(s1).map {(jsVal:JSValue) -> Void in
                    if let m:A.J = A.fromJSON(jsVal) {
                        ret.sig(Result.Value(Box(m as A)))
                    } else {
                        ret.sig(Result.Error(NSError.errorWithDomain("MsgJSONParse", code: 1, userInfo:nil)))
                    }
                }
            }
        case let .Some(s2): ret.sig(Result.Error(s2))
        }
    }
}

func getGmailApiItem<A:JSONDecode>(auth: GTMOAuth2Authentication, url:String) -> Future<Result<A>> {
    var fetcher:GTMHTTPFetcher =
    GTMHTTPFetcher(URLString: url)
    fetcher.authorizer = auth
    fetcher.delegateQueue = NSOperationQueue()
    fetcher.shouldFetchInBackground = true
    var ret: Future<Result<A>> = Future(exec: gcdExecutionContext)
    fetcher.beginFetchWithCompletionHandler(decodeRes(ret))
    return ret
}

func getMsgDtl(auth: GTMOAuth2Authentication, msgRef: MsgRef) -> Future<Result<Msg>> {
    return getGmailApiItem(auth, "https://www.googleapis.com/gmail/v1/users/me/messages/\(msgRef.id)?format=full")
}

func getMsgList(auth:GTMOAuth2Authentication) -> Future<Result<MsgList>> {
    return getGmailApiItem(auth, kMsgListUrl)
}

func getLabelList(auth: GTMOAuth2Authentication) -> Future<Result<Array<Label>>> {
   // return getGmailApiItem(auth, "https://www.googleapis.com/gmail/v1/users/me/labels")
    // why can't this code use the getGmailApiItem refactoring??
    var fetcher:GTMHTTPFetcher =
    GTMHTTPFetcher(URLString: "https://www.googleapis.com/gmail/v1/users/me/labels")
    fetcher.authorizer = auth
    fetcher.delegateQueue = NSOperationQueue()
    fetcher.shouldFetchInBackground = true
    var ret: Future<Result<[Label]>> = Future(exec: gcdExecutionContext)
    println("get label alist, about to run fetch")
    fetcher.beginFetchWithCompletionHandler() { s1, s2 in
        if (s2 == nil) {
            println("label list, no error")
            //let jsVal = JSValue.decode(s1)
            JSValue.decode(s1).map {(jsVal:JSValue) -> Void in
                if let m = JArray<Label, Label>.fromJSON(jsVal) {
                    ret.sig(Result.Value(Box(m)))
                } else {
                    ret.sig(Result.Error(NSError.errorWithDomain("LabelListParse", code: 1, userInfo:nil)))
                }
                return
            }
        } else {
            ret.sig(Result.Error(s2))
        }
    }
    return ret
}
