//
//  TimelineTableViewCell.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/10.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import Nuke

class TimelineTableViewCell: UITableViewCell {
    
    // 投稿者のアイコン
    @IBOutlet var userImageView: UIImageView!
    // 投稿者のユーザ名
    @IBOutlet var userNameLabel: UILabel!
    // 投稿者のユーザID
    @IBOutlet var userIDLabel: UILabel!
    // 投稿タイトル
    @IBOutlet var titleTextView: UITextView!
    // 投稿の作成時間
    @IBOutlet var timeLabel: UILabel!
    // 投稿との距離
    @IBOutlet var distanceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // レイアウト
        setupViews()
    }
    // レイアウト
    func setupViews() {
        // アイコン角丸
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
