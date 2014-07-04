//
//  GmailAPI.swift
//  tinmail
//
//  Created by Max Cantor on 7/2/14.
//  Copyright (c) 2014 Max Cantor. All rights reserved.
//

import Foundation
import swiftz_ios

let kMsgListUrl = "https://www.googleapis.com/gmail/v1/users/me/messages"

class MsgRef {
    var id:String
    var threadId:String
    init(id:String, threadId:String) {
        self.id = "id"
        self.threadId = "tid"
    }
}

func msgRefFromJson(json:NSDictionary) -> MsgRef? {
    switch (json["id"] as? String, json["threadId"] as? String) {
    case (.Some(let id), .Some(let tId)): return MsgRef(id:id, threadId: tId)
    default: return nil
    }
}

func msgListFromJson(rawJsonData:NSDictionary) -> MsgList? {
    if let msgsJson = rawJsonData["messages"] as? NSDictionary[] {
        // better error checking here would be good
        return MsgList(messages:msgsJson.map({msgRefFromJson($0)!}))
    } else {
        return nil
    }
}

class MsgList {
    let messages:MsgRef[]
    init(messages:MsgRef[]) { self.messages = messages }
}

func getMsgList(auth:GTMOAuth2Authentication) -> MsgList? {
    var fetcher:GTMHTTPFetcher = GTMHTTPFetcher(URLString: kMsgListUrl)
    fetcher.authorizer = auth
    fetcher.beginFetchWithCompletionHandler({ s1, s2 in
        if (s2 != nil) {
            println("erorr", s2)
        }
        let jsonDict = NSJSONSerialization.JSONObjectWithData(s1, options: nil, error: nil) as NSDictionary
        println(jsonDict)
        })
    println("getUserId succ")
    return nil
}