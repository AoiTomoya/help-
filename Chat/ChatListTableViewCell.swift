//
//  ChatListTableViewCell.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/18.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Nuke

class ChatListTableViewCell: UITableViewCell {
    
    // トーク相手のアイコン
    @IBOutlet var userImageView: UIImageView!
    // トーク相手のユーザ名
    @IBOutlet var userNameLabel: UILabel!
    // トーク相手のユーザID
    @IBOutlet var userIDLabel: UILabel!
    // 最新のメッセージ
    @IBOutlet var messageTextView: UITextView!
    // 最新のメッセージの作成時間
    @IBOutlet var timeLabel: UILabel!
    
    var chatRoom: ChatRoom? {
        didSet {
            if let chatRoom = chatRoom {
                // プロフィール画像のURL取得（nilだったら空文字列）
                if let url = URL(string: chatRoom.partnerUser?.imageURL ?? "") {
                    // URLからプロフィール画像取得（Nuke）
                    Nuke.loadImage(with: url, into: self.userImageView) // Nuke：URLから画像取得
                }
                // トーク相手のユーザ名
                self.userNameLabel.text = chatRoom.partnerUser?.userName
                // トーク相手のユーザID
                self.userIDLabel.text = "@" + chatRoom.partnerUser!.userID
                // 最新のメッセージの作成時間
                timeLabel.text = dataFormatterForTimeLabel(date: chatRoom.latestMessage?.createdAt.dateValue() ?? Date())
                // 最新のメッセージ
                messageTextView.text = chatRoom.latestMessage?.text
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // レイアウト
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    // レイアウト
    func setupViews() {
        // アイコン角丸
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.clipsToBounds = true
    }
    // タイムラベルフォーマット
    func dataFormatterForTimeLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
}
