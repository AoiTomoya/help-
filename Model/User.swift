//
//  User.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/20.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import Foundation
import Firebase // Timestamp

class User {
    let uid: String
    // サインアップ画面
    let userID: String
    let userName: String
    let email: String
    let password: String
    let createdAt: Timestamp
    // ユーザーページ
    let imageURL: String
    let introduction: String
    // ブロックリスト
    let blockList: [String] // userUIDの配列
    // 通報リスト
    let reportedBy: [String] // userUIDの配列
    
    // 初期化関数
    init(dic: [String: Any]) {
        self.uid = dic["uid"] as? String ?? ""
        // サインアップ画面
        self.userID = dic["userID"] as? String ?? "" // nilだった場合の初期値->空
        self.userName = dic["userName"] as? String ?? ""
        self.email = dic["email"] as? String ?? ""
        self.password = dic["password"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        // ユーザーページ
        self.imageURL = dic["imageURL"] as? String ?? ""
        self.introduction = dic["introduction"] as? String ?? ""
        // ブロックリスト
        self.blockList = dic["blockList"] as? [String] ?? [String]()
        // 通報リスト
        self.reportedBy = dic["reportedBy"] as? [String] ?? [String]()
    }
    
}
