//
//  ChatRoom.swift
//  help!
//
//  Created by 青井智弥 on 2020/10/10.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import Foundation
import Firebase // Timestamp

class ChatRoom {
    
    let latestMessageID: String
    let members: [String] // userUID(String)の配列
    let createdAt: Timestamp
    
    // チャットリストで読み込み時にセット
    var latestMessage: Message?
    var documentID: String?
    var partnerUser: User?
    
    init(dic: [String: Any]) {
        self.latestMessageID = dic["latestMessageID"] as? String ?? "" // nilだった場合の初期値->空
        self.members = dic["members"] as? [String] ?? [String]()
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
    }
    
}
