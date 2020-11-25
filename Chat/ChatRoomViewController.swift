//
//  ChatRoomViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/18.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase

class ChatRoomViewController: UIViewController {
    
    @IBOutlet var chatRoomTableView: UITableView!
    
    // ログイン中のユーザ情報
    var currentUser: User? {
        didSet {
            if currentUser == nil {return}
            // ブロック機能
            self.blockContents(chatRoom: self.chatRoom)
        }
    }
    // チャットルームの情報（チャットリストから値渡しで受け取る）
    var chatRoom: ChatRoom!
    // メッセージの配列
    var messages = [Message]() // 初期値空
    // 下側のsafeArea
    var bottomSafeArea: CGFloat {
        self.view.safeAreaInsets.bottom // get,setの省略形（getの時だけの場合は省略形が使える）
    }
    // accessoryViewの高さ
    let accessoryHeight: CGFloat = 100
    // TableViewのコンテンツの余剰スクロール分（デフォルト値）（transfortしてることに注意）
    let tableViewContentInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    // TableViewのスクロールインジケータの余剰スクロール分（デフォルト値）（transfortしてることに注意）
    let tableViewIndicatorInset: UIEdgeInsets = .init(top: 20, left: 0, bottom: 0, right: 0)
    
    
    lazy var chatInputAccessoryView: ChatInputAccessoryView = {
        let view = ChatInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: accessoryHeight)
        // ChatInputAccessoryViewのChatInputAccessoryViewDelegateをselfで呼び出す
        view.delegate = self
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // NavigationBarにトーク相手のユーザ名を表示
        navigationItem.title = chatRoom.partnerUser?.userName
        // キーボードモニタ
        setupNotification()
        // chatRoomTableViewの設定
        setupChatRoomTableView()
        // レイアウト
        setupViews()
        // ログイン中のユーザ情報を取得
        readUserFromFirestore()
        // メッセージを取得
        readMessageFromFirestore() // リアルタイムなので1度viewDidLoadで呼ぶだけで良い
    }
    
    // chatInputAccessoryViewを追加
    override var inputAccessoryView: UIView? {
        get {
            return chatInputAccessoryView
        }
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // キーボードのshow/hide通知
    func setupNotification() {
        // キーボードが出てくる時の通知を受け取る
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        // キーボードが下がる時の通知を受け取る
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    // キーボードが出てくる時に呼ばれる関数
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}
        // accessoryViewのframe(x,y,width,height)を取得
        if let accessoryFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            // キーボード格納時は以下の処理を行わない．
            if accessoryFrame.height <= accessoryHeight {return}
            // 余剰スクロール分
            let insetDy = accessoryFrame.height - self.bottomSafeArea
            let contentInset = UIEdgeInsets(top: insetDy, left: 0, bottom: 0, right: 0)
            // スクロール分
            let offsetDy = accessoryFrame.height - self.bottomSafeArea - self.chatRoomTableView.contentOffset.y
            print("ああああ", self.chatRoomTableView.contentOffset.y)
            let contentOffset = CGPoint(x: 0, y: -offsetDy)
            // TableViewのコンテンツに余剰スクロール分を挿入（transfortしてることに注意）
            self.chatRoomTableView.contentInset = contentInset
            // TableViewのスクロールインジケータに余剰スクロール分を挿入（transfortしてることに注意）
            self.chatRoomTableView.scrollIndicatorInsets = contentInset
            // TableViewをスクロール（transfortしてることに注意）
            self.chatRoomTableView.contentOffset = contentOffset
        }
    }
    // キーボードが下がる時に呼ばれる関数
    @objc func keyboardWillHide() {
        // TableViewのコンテンツの余剰スクロール分をデフォルト値に戻す（transfortしてることに注意）
        self.chatRoomTableView.contentInset = self.tableViewContentInset
        // TableViewのスクロールインジケータの余剰スクロール分をデフォルト値に戻す（transfortしてることに注意）
        self.chatRoomTableView.scrollIndicatorInsets = self.tableViewIndicatorInset
    }
    // chatRoomTableViewの設定
    func setupChatRoomTableView() {
        // データソースメソッドをselfに任せる
        chatRoomTableView.dataSource = self
        // デリゲートメソッドをselfに任せる
        chatRoomTableView.delegate = self
        // カスタムセルの登録
        let nib = UINib(nibName: "ChatRoomTableViewCell", bundle: Bundle.main)
        chatRoomTableView.register(nib, forCellReuseIdentifier: "Cell")
        // コンテンツに余剰スクロール分（デフォルト値）を挿入（transfortしてることに注意）
        chatRoomTableView.contentInset = self.tableViewContentInset
        // スクロールインジケータの余剰スクロール分（デフォルト値）を挿入（transfortしてることに注意）
        chatRoomTableView.scrollIndicatorInsets = self.tableViewIndicatorInset
        // キーボードを下げる（.interactive:下までスクロール/.onDrag:スクロール開始時）
        chatRoomTableView.keyboardDismissMode = .interactive
        // TableViewを180度回転
        chatRoomTableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
    }
    // レイアウト
    func setupViews() {
        // chatRoomTableView背景色
        chatRoomTableView.backgroundColor = UIColor.init(red: 248/255, green: 248/255, blue: 255/255, alpha: 1) // ghostwhite: rgb(248, 248, 255)
    }
    // アラート
    func errorAlert(error: Error?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    // ブロックアラート
    func blockingAlert() {
        let alert = UIAlertController(title: "ブロック中", message: "あなたはこのユーザーをブロックしています", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // チャットリストに戻る
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    // ブロック機能
    func blockContents(chatRoom: ChatRoom) {
        print("ブロック機能")
        // トーク相手のuidがログイン中ユーザーのブロックリストに含まれる -> true
        let isContain = self.currentUser!.blockList.contains(chatRoom.partnerUser!.uid)
        if isContain { // ブロック中
            // ブロックアラート
            self.blockingAlert()
        }
        print("ブロック機能を完了")
    }
    // ログイン中のユーザ情報を取得
    func readUserFromFirestore() {
        // ログイン中のuserUID（ユーザー個別に割り当てられるID）を取得
        guard let uid = Auth.auth().currentUser?.uid else {return}
        // Firestoreからユーザ情報を取得
        Firestore.firestore().collection("user").document(uid).getDocument { (snapshot, error) in
            if error != nil { // ユーザ情報取得エラー
                self.errorAlert(error: error)
            }
            else { // ユーザ情報取得成功
                guard let docData = snapshot?.data() else {return}
                self.currentUser = User.init(dic: docData)
            }
        }
    }
    // メッセージを取得
    func readMessageFromFirestore() {
        // chatRoomのdocumentID
        guard let chatRoomDocId = chatRoom.documentID else {return}
        // snapshots: chatRoom/messageコレクション内の全message
        // Firestoreからリアルタイムでデータを取得
        Firestore.firestore().collection("chatRoom").document(chatRoomDocId).collection("message").addSnapshotListener { (snapshots, error) in
            if error != nil { // メッセージ取得エラー
                self.errorAlert(error: error)
            }
            else { // メッセージ取得成功
                // documentChanges: snapshotsの内，前回のsnapshotsから変更があったドキュメント(message)の配列
                // 各documentChange(message)について
                snapshots?.documentChanges.forEach({ (documentChange) in
                    // documentChange(message)のタイプ別処理
                    switch documentChange.type {
                    case .added: // 追加されたドキュメント(message)
                        // 新規メッセージ
                        let docData = documentChange.document.data()
                        let message = Message.init(dic: docData)
                        // 新規メッセージにチャット相手のユーザ情報を格納
                        message.partnerUser = self.chatRoom.partnerUser
                        // メッセージの配列に新規メッセージを追加
                        self.messages.append(message)
                        // createdAt順にソート（m1Date < m2Date:昇順/m1Date > m2Date:降順）
                        self.messages.sort { (m1, m2) -> Bool in
                            let m1Date = m1.createdAt.dateValue()
                            let m2Date = m2.createdAt.dateValue()
                            return m1Date > m2Date
                        }
                        // chatRoomTableViewをリロード
                        self.chatRoomTableView.reloadData()
                        // 最新のメッセージまでスクロール
//                        self.chatRoomTableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
                    case .modified, .removed:
                        print("nothing to do")
                    }
                })
            }
        }
    }
    

}

// 自作デリゲートの中で宣言した関数はこのクラスで宣言しなければならない
extension ChatRoomViewController: ChatInputAccessoryViewDelegate {
    
    // 送信ボタンが押されたときに呼ばれる関数
    func tappedSendButton(text: String) {
        addMessageToFirestore(text: text)
    }
    // メッセージをFirebaseに保存
    func addMessageToFirestore(text: String) {
        // chatRoomのdocumentID
        guard let chatRoomDocID = chatRoom.documentID else {return}
        // chatInputAccessoryView.chatTextViewを空にする
        chatInputAccessoryView.removeText()
        // MessageのdocumentIDを生成（ランダム文字列）
        let messageID = randomString(length: 20)
        // 辞書型
        let docData = [
            "userUID": currentUser?.uid,
            "userID": currentUser?.userID,
            "createdAt": Timestamp(),
            "message": text
        ] as [String : Any]
        // Firestoreにメッセージを格納
        Firestore.firestore().collection("chatRoom").document(chatRoomDocID).collection("message").document(messageID).setData(docData) { (error) in
            if error != nil { // メッセージ保存エラー
                self.errorAlert(error: error)
            }
            else { // メッセージ保存成功
                // 辞書型
                let latestMessageData = [
                    "latestMessageID": messageID
                ]
                // ドキュメント内に既に存在するフィールドに値を上書き
                Firestore.firestore().collection("chatRoom").document(chatRoomDocID).updateData(latestMessageData) { (error) in
                    if error != nil { // 最新メッセージ保存エラー
                        self.errorAlert(error: error)
                    }
                    else { // 最新メッセージ保存成功
                        
                    }
                }
            }
        }
    }
    // MessageのdocumentIDをランダムで自動生成
    func randomString(length: Int) -> String {
            let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let len = UInt32(letters.length)

            var randomString = ""
            for _ in 0 ..< length {
                let rand = arc4random_uniform(len)
                var nextChar = letters.character(at: Int(rand))
                randomString += NSString(characters: &nextChar, length: 1) as String
            }
            return randomString
    }
    
}

extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource {
    
    // セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        chatRoomTableView.estimatedRowHeight = 20 // セルの高さの下限
        return UITableView.automaticDimension // セルの高さをmessageTextViewの高さに応じて変更
    }
    // セルの個数を決めるデータソースメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    // セルの内容を決めるデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! ChatRoomTableViewCell
        //cell.messageTextView.text = messages[indexPath.row]
        // セルを180度回転（TableViewに対して）
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        cell.message = messages[indexPath.row]
        return cell
    }
    
}
