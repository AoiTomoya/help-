//
//  ChatRoomTableViewCell.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/20.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import Nuke

class ChatRoomTableViewCell: UITableViewCell {
    
    // トーク相手のアイコン
    @IBOutlet var userImageView: UIImageView!
    // トーク相手のメッセージ
    @IBOutlet var partnerMessageTextView: UITextView!
    // トーク相手のmessageTextViewの幅
    @IBOutlet weak var partnerMessageTextViewWidthConstraint: NSLayoutConstraint!
    // トーク相手のメッセージの作成時間
    @IBOutlet var partnerTimeLabel: UILabel!
    // ログイン中ユーザのメッセージ
    @IBOutlet var myMessageTextView: UITextView!
    // ログイン中ユーザの作成時間
    @IBOutlet var myTimeLabel: UILabel!
    // ログイン中ユーザのmessageTextViewの幅
    @IBOutlet weak var myMessageTextViewWidthConstraint: NSLayoutConstraint!
    
    // メッセージ
    var message: Message!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // レイアウト
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // メッセージの送信主に応じてコンテンツをセット
        senderDetector()
    }
    
    // メッセージの送信主に応じてコンテンツをセット
    func senderDetector() {
        // ログイン中のuserUID（ユーザー個別に割り当てられるID）を取得
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if uid == message?.userUID { // ログイン中のuserUIDがmessage.uidと一致
            // トーク相手のmessageTextView非表示
            partnerMessageTextView.isHidden = true
            // トーク相手のtimeLabel非表示
            partnerTimeLabel.isHidden = true
            // トーク相手のアイコン非表示
            userImageView.isHidden = true
            // ログイン中ユーザのmessageTextView表示
            myMessageTextView.isHidden = false
            // ログイン中ユーザのtimeLabel表示
            myTimeLabel.isHidden = false
            
            if let message = message {
                // ログイン中ユーザのmessageTextView
                myMessageTextView.text = message.text
                // ログイン中ユーザのmessageTextViewの幅
                let width = estimateFrameForTextView(text: message.text).width + 20
                myMessageTextViewWidthConstraint.constant = width
                // ログイン中ユーザのtimeLabel
                myTimeLabel.text = dataFormatterForTimeLabel(date: message.createdAt.dateValue())
            }
        }
        else {
            // トーク相手のMessageTextView表示
            partnerMessageTextView.isHidden = false
            // トーク相手のTimeLabel表示
            partnerTimeLabel.isHidden = false
            // トーク相手のアイコン表示
            userImageView.isHidden = false
            // ログイン中ユーザのMessageTextView非表示
            myMessageTextView.isHidden = true
            // ログイン中ユーザのTimeLabel非表示
            myTimeLabel.isHidden = true
            // トーク相手のアイコン
            if let urlString = message?.partnerUser?.imageURL, let url = URL(string: urlString) {
                Nuke.loadImage(with: url, into: userImageView)
            }
            if let message = message {
                // トーク相手のmessageTextView
                partnerMessageTextView.text = message.text
                // トーク相手のmessageTextViewの幅
                let width = estimateFrameForTextView(text: message.text).width + 20
                partnerMessageTextViewWidthConstraint.constant = width
                // トーク相手のtimeLabel
                partnerTimeLabel.text = dataFormatterForTimeLabel(date: message.createdAt.dateValue())
            }
        }
    }
    // messageTextViewの横幅計算
    func estimateFrameForTextView(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000) // セルサイズの上限
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)], context: nil)
        // xibのフォントサイズ
    }
    // レイアウト
    func setupViews() {
        // アイコン角丸
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.clipsToBounds = true
        // メッセージ角丸
        partnerMessageTextView.layer.cornerRadius = 15
        myMessageTextView.layer.cornerRadius = 15
        // メッセージ枠線色
        partnerMessageTextView.layer.borderColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        // メッセージ枠線幅
        partnerMessageTextView.layer.borderWidth = 1
        // セル背景色
        backgroundColor = .clear
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
