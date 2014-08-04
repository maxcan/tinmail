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

//let kMsgListUrl = "\(kGmailApiBase)messages?labelIds=INBOX&q=-label:tinmailed"

func initFetcher(urlTail:String) -> GTMHTTPFetcher {
    let kGmailApiBase = "https://www.googleapis.com/gmail/v1/users/me/"
    return GTMHTTPFetcher(URLString: "\(kGmailApiBase)\(urlTail)")
}

struct MsgRef : Printable, JSONDecode {
    let id:String
    let threadId:String
    var description: String {return "MsgRef: id:\(self.id) threadId:\(self.threadId)"}
    typealias J = MsgRef
    static func toJSON(x: J) -> JSValue {
        return JSValue.JSObject(["id": JSValue.JSString(x.id), "threadId": JSValue.JSString(x.threadId)])
    }
    static func fromJSON(x: JSValue) -> MsgRef? {
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
    static func toJSON(x: LabelMessageListVisibility) -> JSValue {
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
    static func toJSON(x: LabelListVisibility) -> JSValue {
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

struct Label:JSONDecode {
    let id: String
    let name: String
    let type: LabelType
    let messageListVisibility: LabelMessageListVisibility?
    let labelListVisibility: LabelListVisibility?
//    static func toJSON(x: J) -> JSValue {
//        return JSValue.JSNull()
//    }
    typealias J = Label
    static func create(id: String)(name: String)(type: LabelType)(mlv: LabelMessageListVisibility?)(llv:LabelListVisibility?) -> Label {
        return Label(id:id, name:name, type:type, messageListVisibility:mlv, labelListVisibility:llv)
    }
    static func fromJSON(x: JSValue) -> Label? {
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

struct Msg : Printable, JSONDecode {
    let id: String
    let from: String
    let subject: String
    let threadId:String
    let deliveredTo: String?
    var description:String {
        return "Msg: id:\(id) threadId:\(threadId) from:\(from) subject:\(subject)"
    }
    static func create(id: String)(from: String)(threadId: String)(subject: String) -> Msg {
        return Msg(id:id, from: from, subject: subject, threadId: threadId, deliveredTo: nil)
    }
    static func fromJSON(x: JSValue) -> Msg? {
        switch (x) {
        case let .JSObject(d):
            let i:String? = d["id"] >>= JString.fromJSON
            let ti:String? = d["threadId"] >>= JString.fromJSON
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
            msgs = dict["messages"] >>= JArrayFrom<MsgRef, MsgRef>.fromJSON
            if let m = msgs {return MsgList(m)} else { return Optional.None}
        default: return Optional.None
        }
    }
}


func decodeRes<A:JSONDecode>(mv: MVar<Result<A>>) -> ((s1:NSData?, s2:NSError?) -> Void) {
// func decodeRes<A:JSONDecode>(ret: Future<Result<A>>) -> ((s1:NSData?, s2:NSError?) -> Void) {
    return {s1, s2 in
        switch s2 {
        case .None:
            if let s1 = s1 {
//            JSValue.decode(s1).flatMap(Msg.fromJSON).maybe(
//                   ret.sig(Result.Error(NSError.errorWithDomain("MsgJSONParse", code: 1, userInfo:nil)))
//                , { m in ret.sig(Result.Value(Box(m))) })
                JSValue.decode(s1).map {(jsVal:JSValue) -> Void in
                    if let m:A.J = A.fromJSON(jsVal) {
                        mv.put(pure(m as A))
                    } else {
                        mv.put(Result.Error(NSError.errorWithDomain("MsgJSONParse", code: 1, userInfo:nil)))
                    }
                }
            }
        case let .Some(s2): mv.put(Result.Error(s2))
        }
    }
}

func getGmailApiItem<A:JSONDecode>(auth: GTMOAuth2Authentication, urlTail:String) -> Future<Result<A>> {
    var fetcher = initFetcher(urlTail)
    fetcher.authorizer = auth
    fetcher.delegateQueue = NSOperationQueue()
    fetcher.shouldFetchInBackground = true
    var ret: Future<Result<A>> = Future(exec: gcdExecutionContext) {
        let mv:MVar<Result<A>> = MVar()
        fetcher.beginFetchWithCompletionHandler(decodeRes(mv))
        return mv.take()
    }
    return ret
}

func getMsgDtl(auth: GTMOAuth2Authentication, msgRef: MsgRef) -> Future<Result<Msg>> {
    return getGmailApiItem(auth, "messages/\(msgRef.id)?format=full")
}

func getMsgList(auth:GTMOAuth2Authentication) -> Future<Result<MsgList>> {
    return getGmailApiItem(auth, "messages?labelIds=INBOX&q=-label:tinmailed")
}

internal func modifyMsgThreads( auth: GTMOAuth2Authentication
                              , msg: Msg
                              , newIds: [String]
                              , remIds: [String]) -> Future<Result<String>> {
    var ret:Future<Result<String>> = Future(exec: gcdExecutionContext)
    var fetcher:GTMHTTPFetcher =
                GTMHTTPFetcher(URLString: "https://www.googleapis.com/gmail/v1/users/me/messages/\(msg.id)/modify")
    fetcher.authorizer = auth
    fetcher.delegateQueue = NSOperationQueue()
    fetcher.shouldFetchInBackground = true
    let newLabelObj = JSValue.JSObject(
        [ "addLabelIds": JSValue.JSArray(newIds.map() { .JSString($0)})
        , "removeLabelIds": JSValue.JSArray(remIds.map() { .JSString($0)})
        ])
    fetcher.postData = newLabelObj.encode()
    fetcher.mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    printEncodedData(newLabelObj.encode())
    printMain("new label: \(newLabelObj)")
    fetcher.beginFetchWithCompletionHandler() { postRes, postErr in
        switch (JSValue.decode(postRes), postErr) {
        case let (_ , .Some(err)): ret.sig(Result.Error(err))
        case let (.Some(.JSObject(dict)), .None): ret.sig(pure("success"))
        default:  ret.sig(Result.Error(NSError.errorWithDomain("couldn't modify msg", code: 1, userInfo:nil)))
        }
    }
    return ret
}

typealias FrString = Future<Result<String>>
typealias FrMsgModification = Future<Result<(msg: Msg) -> FrString>>

// the genXyzMsg functions return a future<msg -> future>.  the idea is that
// since you need to know a label id, its better to just call that once and
// "cache" it by just using the closed function that is returned
func genArchiveMsg(auth: GTMOAuth2Authentication) -> FrMsgModification {
    let f:FrMsgModification = Future(exec:gcdExecutionContext)
    getLabelId("tinmailed", auth).map() { (res:Result<String>) -> Void in
         switch res {
            case let .Error(e): f.sig(.Error(e))
            case let .Value(lblId): f.sig(pure({ msg -> FrString in
                modifyMsgThreads(auth, msg, [lblId.value], ["INBOX"])
                }))
        }
    }
    return f
}

func genSaveMsg(auth: GTMOAuth2Authentication) -> FrMsgModification {
    let f:FrMsgModification = Future(exec:gcdExecutionContext)
    getLabelId("tinmailed", auth).map() { (res:Result<String>) -> Void in
         switch res {
            case let .Error(e): f.sig(.Error(e))
            case let .Value(lblId): f.sig(pure({ msg -> FrString in
                modifyMsgThreads(auth, msg, [lblId.value], [])
                }))
        }
    }
    return f
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
                var fetcher = initFetcher("labels")
                fetcher.authorizer = auth
                fetcher.delegateQueue = NSOperationQueue()
                fetcher.shouldFetchInBackground = true
                let newLabelObj = JSValue.JSObject([ "name": .JSString(label)
                    , "messageListVisibility": LabelMessageListVisibility.toJSON(.Show)
                    , "labelListVisibility": LabelListVisibility.toJSON(.LabelShow)
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
    var fetcher = initFetcher("labels")
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
            if let lblVals = dict["labels"] >>= JArrayFrom<Label, Label>.fromJSON {
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
