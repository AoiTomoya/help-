//
//  ChatInputAccessoryView.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/20.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit

// プロトコル宣言：このプロトコルを宣言したクラスでは以下が使用可能．
protocol ChatInputAccessoryViewDelegate: class {
    func tappedSendButton(text: String)
}

class ChatInputAccessoryView: UIView {
    
    // テキスト
    @IBOutlet var chatTextView: UITextView!
    // 送信ボタン
    @IBOutlet var sendButton: UIButton!
    // 送信ボタンが押されたときに呼ばれる関数
    @IBAction func tappedSendButton(_ sender: Any) {
        guard let text = chatTextView.text else {return}
        delegate?.tappedSendButton(text: text)
    }
    
    var delegate: ChatInputAccessoryViewDelegate? // プロトコル宣言
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 必須メソッド
        nibInit()
        // レイアウト
        setupViews()
        // textViewとaccessoryViewの高さを可変
        autoresizingMask = .flexibleHeight
    }
     // レイアウト
    func setupViews() {
        // デリゲートをselfに任せる
        chatTextView.delegate = self
        // chatTextView角丸
        chatTextView.layer.cornerRadius = 15
        // chatTextView枠線色
        chatTextView.layer.borderColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        // chatTextView枠線幅
        chatTextView.layer.borderWidth = 1
        // 送信ボタン角丸
        sendButton.layer.cornerRadius = 15
        // 送信ボタン画像アスペクト
        sendButton.imageView?.contentMode = .scaleAspectFill
        sendButton.contentHorizontalAlignment = .fill
        sendButton.contentVerticalAlignment = .fill
        // 送信ボタン無効化
        sendButton.isEnabled = false
    }
    // textFieldを空にする
    func removeText() {
        chatTextView.text = ""
        sendButton.isEnabled = false
    }
    // textFieldの高さに応じてアクセサリービューの高さを可変
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    // override initに必要なメソッド
    func nibInit() {
        let nib = UINib(nibName: "ChatInputAccessoryView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {return}
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(view)
    }
    // override initに必要なメソッド
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ChatInputAccessoryView: UITextViewDelegate {
    
    // textViewの編集状態を監視
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty { // textViewが空
            sendButton.isEnabled = false // 送信ボタン無効
        }
        else { // textViewが空ではない
            sendButton.isEnabled = true // 送信ボタン有効
        }
    }
    
}
