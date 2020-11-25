//
//  ChatListViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/18.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase

class ChatListViewController: UIViewController {
    
    // chatListTableView
    @IBOutlet var chatListTableView: UITableView!
    
    // チャットルームの配列
    var chatRooms = [ChatRoom]()
    // チャットルームのIDの配列
    var IDarray = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // データソースメソッドをselfに任せる
        chatListTableView.dataSource = self
        // デリゲートメソッドをselfに任せる
        chatListTableView.delegate = self
        // カスタムセルの登録
        let nib = UINib(nibName: "ChatListTableViewCell", bundle: Bundle.main)
        chatListTableView.register(nib, forCellReuseIdentifier: "Cell")
        // TableViewの不要な線を消す
        chatListTableView.tableFooterView = UIView()
        // レイアウト
        setupViews()
        // チャットルームを取得
        readChatRoomFromFirestore() // リアルタイムなので1度viewDidLoadで呼ぶだけで良い
    }
    
    // 値渡し
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatRoom" {
            let chatRoomViewController = segue.destination as! ChatRoomViewController
            let selectedIndexPath = chatListTableView.indexPathForSelectedRow!
            chatRoomViewController.chatRoom = chatRooms[selectedIndexPath.row]
        }
    }
    
    // レイアウト
    func setupViews() {
        // NavigationBar背景色
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBarタイトル色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        // NavigationBar戻るボタン（チャットルームの戻るボタン）色
        navigationController?.navigationBar.tintColor = UIColor.white
        // NavigationBar戻るボタン（チャットルームの戻るボタン）テキスト
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
    // チャットルームを取得
    func readChatRoomFromFirestore() {
        // snapshots: chatRoomコレクション内の全chatRoom
        // Firestoreからリアルタイムでデータを取得
        Firestore.firestore().collection("chatRoom").addSnapshotListener { (snapshots, error) in
            if error != nil { // データ取得エラー
                self.errorAlert(error: error)
            }
            else { // データ取得成功
                // documentChanges: snapshotsの内，前回のsnapshotsから変更があったドキュメント(documentChange)の配列
                // 各documentChange(chatRoom)について
                snapshots?.documentChanges.forEach({ (documentChange) in
                    // documentChange(chatRoom)のタイプ別処理
                    switch documentChange.type {
                    case .added: // 追加されたドキュメント(chatRoom)
                        // 追加されたドキュメント(chatRoom)をチャットルームの配列に追加する
                        self.handleAddedDocumentChange(documentChange: documentChange)
                    case .modified: // 変更されたドキュメント(chatRoom)
                        // 変更されたドキュメント(chatRoom)をチャットルームの配列に追加する
                        self.handleModifiedDocumentChange(documentChange: documentChange)
                    case .removed:
                        print("nothing to do")
                    }
                })
            }
        }
    }
    // コレクションに新しく追加されたドキュメント(chatRoom)をチャットルームの配列に追加する
    func handleAddedDocumentChange(documentChange: DocumentChange) {
        // 変更があったドキュメント(chatRoom)
        let dic = documentChange.document.data()
        let chatRoom = ChatRoom.init(dic: dic)
        // チャットルームのdocumentIDをチャットルームに格納
        chatRoom.documentID = documentChange.document.documentID
        // ログイン中のuserUIDを取得
        guard let uid = Auth.auth().currentUser?.uid else {return}
        // チャットルームのメンバーの確認
        // ログイン中のuserUIDが含まれる -> true / ログイン中のuserUIDが含まれない -> falese
        let currrentUserIsContain = chatRoom.members.contains(uid)
        // ログイン中のuserUIDが含まれない -> return
        if !currrentUserIsContain {return}
        // チャットルームの各メンバーについて
        chatRoom.members.forEach { (memberUID) in
            // memberUIDとログイン中のuserUIDが一致 -> return
            if memberUID == uid {return}
            // Firestoreからユーザ情報を取得
            Firestore.firestore().collection("user").document(memberUID).getDocument { (userSnapshot, error) in
                if error != nil { // ユーザ情報取得エラー
                    self.errorAlert(error: error)
                    return
                }
                // ユーザ情報取得成功
                // チャット相手のユーザ情報
                guard let data = userSnapshot?.data() else {return}
                let partnerUser = User.init(dic: data)
                // チャットルームにチャット相手のユーザ情報を格納
                chatRoom.partnerUser = partnerUser
                // チャットルームのID
                guard let chatRoomID = chatRoom.documentID else {return}
                // 最新メッセージのID
                let latestMessageID = chatRoom.latestMessageID
                // 最新メッセージがない場合
                if latestMessageID == "" {
                    // チャットルームをチャットルームの配列の先頭に挿入
                    self.chatRooms.insert(chatRoom, at: 0)
                    // チャットルームIDをチャットルームIDの配列の先頭に挿入
                    self.IDarray.insert(chatRoom.documentID!, at: 0)
                    // chatListTableViewをリロード
                    self.chatListTableView.reloadData()
                    return
                }
                // Firestoreから最新メッセージの情報を取得
                Firestore.firestore().collection("chatRoom").document(chatRoomID).collection("message").document(latestMessageID).getDocument { (messageSnapshot, error) in
                    if error != nil { // 最新メッセージの情報取得エラー
                        self.errorAlert(error: error)
                    }
                    // 最新メッセージの情報成功
                    // 最新メッセージ
                    guard let docData = messageSnapshot?.data() else {return}
                    let message = Message.init(dic: docData)
                    // チャットルームに最新メッセージの情報を格納
                    chatRoom.latestMessage = message
                    // チャットルームをチャットルームの配列の先頭に挿入
                    self.chatRooms.insert(chatRoom, at: 0)
                    // チャットルームIDをチャットルームIDの配列の先頭に挿入
                    self.IDarray.insert(chatRoom.documentID!, at: 0)
                    // chatListTableViewをリロード
                    self.chatListTableView.reloadData()
                }
            }
        }
    }
    // コレクション内の変更されたドキュメント(chatRoom)をチャットルームの配列に追加する
    func handleModifiedDocumentChange(documentChange: DocumentChange) {
        // 変更があったドキュメント(chatRoom)
        let dic = documentChange.document.data()
        let chatRoom = ChatRoom.init(dic: dic)
        // チャットルームのdocumentIDをチャットルームに格納
        chatRoom.documentID = documentChange.document.documentID
        // ログイン中のuserUIDを取得
        guard let uid = Auth.auth().currentUser?.uid else {return}
        // チャットルームのメンバーの確認
        // ログイン中のuserUIDが含まれる -> true / ログイン中のuserUIDが含まれない -> falese
        let currrentUserIsContain = chatRoom.members.contains(uid)
        // ログイン中のuserUIDが含まれない -> return
        if !currrentUserIsContain {return}
        // チャットルームの各メンバーについて
        chatRoom.members.forEach { (memberUID) in
            // memberUIDとログイン中のuserUIDが一致 -> return
            if memberUID == uid {return}
            // Firestoreからユーザ情報を取得
            Firestore.firestore().collection("user").document(memberUID).getDocument { (userSnapshot, error) in
                if error != nil { // ユーザ情報取得エラー
                    self.errorAlert(error: error)
                    return
                }
                // ユーザ情報取得成功
                // チャット相手のユーザ情報
                guard let data = userSnapshot?.data() else {return}
                let partnerUser = User.init(dic: data)
                // チャットルームにチャット相手のユーザ情報を格納
                chatRoom.partnerUser = partnerUser
                // チャットルームのID
                guard let chatRoomID = chatRoom.documentID else {return}
                // 最新メッセージのID
                let latestMessageID = chatRoom.latestMessageID
                // 最新メッセージがない場合
                if latestMessageID == "" {
                    // 各チャットルームのIDについて
                    self.IDarray.forEach { (ID) in
                        // 変更があったチャットルームのIDと一致
                        if ID == chatRoomID {
                            // 変更があったチャットルームのIDの配列のインデックスを取得
                            let changedIndex = self.IDarray.firstIndex(of: chatRoomID)
                            // 変更があったチャットルームを配列から削除
                            self.chatRooms.remove(at: changedIndex!)
                            // 変更があったチャットルームのIDを配列から削除
                            self.IDarray.remove(at: changedIndex!)
                        }
                    }
                    // チャットルームをチャットルームの配列の先頭に挿入
                    self.chatRooms.insert(chatRoom, at: 0)
                    // チャットルームIDをチャットルームIDの配列の先頭に挿入
                    self.IDarray.insert(chatRoom.documentID!, at: 0)
                    // chatListTableViewをリロード
                    self.chatListTableView.reloadData()
                    return
                }
                // Firestoreから最新メッセージの情報を取得
                Firestore.firestore().collection("chatRoom").document(chatRoomID).collection("message").document(latestMessageID).getDocument { (messageSnapshot, error) in
                    if error != nil { // 最新メッセージの情報取得エラー
                        self.errorAlert(error: error)
                    }
                    // 最新メッセージの情報成功
                    guard let docData = messageSnapshot?.data() else {return}
                    let message = Message.init(dic: docData)
                    chatRoom.latestMessage = message
                    // 各チャットルームのIDについて
                    self.IDarray.forEach { (ID) in
                        // 変更があったチャットルームのIDと一致
                        if ID == chatRoomID {
                            // 変更があったチャットルームのIDの配列のインデックスを取得
                            let changedIndex = self.IDarray.firstIndex(of: chatRoomID)
                            // 変更があったチャットルームを配列から削除
                            self.chatRooms.remove(at: changedIndex!)
                            // 変更があったチャットルームのIDを配列から削除
                            self.IDarray.remove(at: changedIndex!)
                        }
                    }
                    // チャットルームをチャットルームの配列の先頭に挿入
                    self.chatRooms.insert(chatRoom, at: 0)
                    // チャットルームIDをチャットルームIDの配列の先頭に挿入
                    self.IDarray.insert(chatRoom.documentID!, at: 0)
                    // chatListTableViewをリロード
                    self.chatListTableView.reloadData()
                }
            }
        }
    }
    
}

extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // セルの個数を決めるデータソースメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    // セルの内容を決めるデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! ChatListTableViewCell
        cell.chatRoom = chatRooms[indexPath.row]
        return cell
    }
    // セルが押された時に呼ばれる関数
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toChatRoom", sender: nil) // 画面遷移
        tableView.deselectRow(at: indexPath, animated: true) // 選択解除
    }
    
}
