//
//  Message.swift
//  help!
//
//  Created by 青井智弥 on 2020/10/11.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import Foundation
import Firebase

class Message {
    
    let userUID: String
    let userID: String
    let createdAt: Timestamp
    let text: String
    
    var partnerUser: User? // チャットルームでメッセージ読み込み時にセット
    
    init(dic: [String: Any]) {
        self.userUID = dic["userUID"] as? String ?? ""
        self.userID = dic["userID"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.text = dic["message"] as? String ?? ""
    }
    
}
