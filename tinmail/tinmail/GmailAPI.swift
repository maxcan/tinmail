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
enum LabelMessageListVisibility:JSON {
    case Hide
    case Show
    func toJSON(x: LabelMessageListVisibility) -> JSValue {
        switch(x) {
        case Hide: return .JSString("hide")
        case Show: return .JSString("show")
        }
    }
    static func fromJSON(x: JSValue) -> LabelMessageListVisibility? {
        switch(x) {
        case .JSString("hide"): return Hide
        case .JSString("show"): return Show
        default: return nil
        }
    }
}
enum LabelListVisibility: JSON {
    case LabelHide
    case LabelShow
    case LabelShowIfUnread
    func toJSON(x: LabelListVisibility) -> JSValue {
        switch(x) {
        case LabelHide: return .JSString("labelHide")
        case LabelShow: return .JSString("labelShow")
        case LabelShowIfUnread: return .JSString("labelShowIfUnread")
        }
    }
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
    class func create(id: String)(name: String)(type: LabelType)(mlv: LabelMessageListVisibility?)(llv:LabelListVisibility?) -> Label {
        return Label(id, name, type, mlv, llv)
    }
    class func fromJSON(x: JSValue) -> Label? {
//        printMain("label from json:  \(x.description)")
        switch (x) {
        case let .JSObject(d):
            let i:String? = d["id"] >>= JString.fromJSON
            let n:String? = d["name"] >>= JString.fromJSON
            let mlv:LabelMessageListVisibility? = d["messageListVisibility"] >>= LabelMessageListVisibility.fromJSON
            let llv:LabelListVisibility? = d["labelListVisibility"] >>= LabelListVisibility.fromJSON
            let tp:LabelType? = d["type"] >>= LabelType.fromJSON
//            printMain("lable FJ mlv: \(mlv) llv: \(llv)  \(i) \(n)")
            return create <^> i <*> n <*> tp <*> .Some(mlv) <*> .Some(llv)
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
//            printMain("i: \(i) ti: \(ti)")
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
                    //printMain("hdrDict: \(hdrDict) subj: \(subj) from: \(from)")
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
                        ret.sig(pure(m as A))
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

func getLabelId(label: String, auth: GTMOAuth2Authentication) -> Future<Result<String>> {
    return getLabelList(auth).flatMap() {(res: Result<Array<Label>>) -> Future<Result<String>> in
//        var ret: Future<Result<Box<String>>> = Future(exec: gcdExecutionContext)
//        printMain("get label list res: \(res)")
        
        var ret:Future<Result<String>> = Future(exec: gcdExecutionContext)
        switch (res) {
        case let .Value(listRes):
//            printMain("get label list res: \(listRes.value)")
            let matchingLabels = filter(listRes.value) { $0.name == label }
            if (matchingLabels.isEmpty) {
                var fetcher:GTMHTTPFetcher =
                GTMHTTPFetcher(URLString: "https://www.googleapis.com/gmail/v1/users/me/labels")
                fetcher.authorizer = auth
                fetcher.delegateQueue = NSOperationQueue()
                fetcher.shouldFetchInBackground = true
                let newLabelObj = JSValue.JSObject([ "name": .JSString(label)
                    , "messageListVisibility": LabelMessageListVisibility.Show.toJSON(.Show)
                    , "labelListVisibility": LabelListVisibility.LabelShow.toJSON(.LabelShow)
                    ])
                fetcher.postData = newLabelObj.encode()
                fetcher.mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                //fetcher.setLoggingEnabled(true)
                printEncodedData(newLabelObj.encode())
//              printMain(fetcher.mutableRequest.description)
                printMain("new label: \(newLabelObj)")
                fetcher.beginFetchWithCompletionHandler() { postRes, postErr in
//                    printMain("label id response: \(postRes)")
                    switch (JSValue.decode(postRes) >>= Label.fromJSON, postErr) {
                        case let (_ , .Some(err)):
                            printMain("Error: \(err)")
                            printEncodedData(err.userInfo["data"] as? NSData)
                            ret.sig(Result.Error(err))
                        case let (.Some(lbl), .None): ret.sig(pure(lbl.id))
                        default:  ret.sig(Result.Error(NSError.errorWithDomain("couldn't get label", code: 1, userInfo:nil)))
                    }
                }
            } else {
                ret.sig(pure(matchingLabels[0].id))
            }
        case let .Error(e): ret.sig(.Error(e))
        }
        return ret
    }
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
//    printMain("get label alist, about to run fetch")
    fetcher.beginFetchWithCompletionHandler() { getRes, getErr in
        switch (JSValue.decode(getRes), getErr) {
        case let (_ , .Some(err)): ret.sig(Result.Error(err))
        case let (.Some(.JSObject(dict)), .None):
//            printMain("label list, no error: \(dict)")
            if let lblVals = dict["labels"] >>= JArray<Label, Label>.fromJSON {
//                printMain("label list PARSED:, no error: \(lblVals)")
            
                ret.sig(pure(lblVals))
            } else {
                ret.sig(Result.Error(NSError.errorWithDomain("LabelListParse", code: 1, userInfo:nil)))
            }
        default:  ret.sig(Result.Error(NSError.errorWithDomain("couldn't get label list", code: 1, userInfo:nil)))
        }
        
    }
    return ret
}
