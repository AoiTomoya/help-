//
//  Post.swift
//  help!
//
//  Created by 青井智弥 on 2020/10/06.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import Foundation
import Firebase // Timestamp
import CoreLocation // 位置情報

class Post {
    let postID: String
    let userUID: String
    let title: String
    let detail: String
    let createdAt: Timestamp
    let latitude: String
    let longitude: String
    
    // 初期化関数
    init(dic: [String: Any]) {
        self.postID = dic["postID"] as? String ?? "" // nilだった場合の初期値->空
        self.userUID = dic["userUID"] as? String ?? ""
        self.title = dic["title"] as? String ?? ""
        self.detail = dic["detail"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.latitude = dic["latitude"] as? String ?? ""
        self.longitude = dic["longitude"] as? String ?? ""
    }
    
}
