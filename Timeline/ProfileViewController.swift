//
//  ProfileViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/10/07.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import Nuke

class ProfileViewController: UIViewController {
    
    // アイコン
    @IBOutlet var userImageView: UIImageView!
    // ユーザ名
    @IBOutlet var userNameLabel: UILabel!
    // ユーザID
    @IBOutlet var userIDLabel: UILabel!
    // 自己紹介
    @IBOutlet var introductionTextView: UITextView!
    // メニューボタン
    @IBOutlet var menuBarButton: UIBarButtonItem!
    // 戻るボタン
    @IBOutlet var backBarButton: UIBarButtonItem!
    
    // 投稿者のuid
    var uid: String? { // DetailViewController.selectedPost.userUIDを値渡しで受け取る
        didSet {
            if let uid = uid {
                // uidからユーザ情報を取得
                readUserFromFirestore(uid: uid)
            }
        }
    }
    // 投稿者のユーザ情報
    var postUser: User! {
        didSet {
            print("投稿者のユーザ情報を取得完了")
            if let postUser = postUser {
                // 投稿者のユーザ情報をセット
                setUserInfo(user: postUser)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // レイアウト
        setupViews()
    }
    
    // レイアウト
    func setupViews() {
        // アイコン角丸
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.layer.masksToBounds = true
        // NavigationBar背景色
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBarタイトル色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        // BarButtonItemメニューボタン色
        menuBarButton.tintColor = UIColor.white
        // BarButtonItem戻るボタン色
        backBarButton.tintColor = UIColor.white
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
    // uidから投稿者情報を取得
    func readUserFromFirestore(uid: String) {
        // Firestoreからデータを取得
        Firestore.firestore().collection("user").document(uid).getDocument { (snapshot, error) in
            if error != nil { // データ取得エラー
                self.errorAlert(error: error)
            }
            else { // データ取得成功
                guard let docData = snapshot?.data() else {return}
                self.postUser = User.init(dic: docData)
            }
        }
    }
    // 投稿者のユーザ情報をセット
    func setUserInfo(user: User) {
        print("投稿者のユーザ情報をセット")
        // プロフィール画像のURL取得（nilだったら空文字列）
        if let url = URL(string: user.imageURL ?? "") {
            // URLからプロフィール画像取得（Nuke）
            Nuke.loadImage(with: url, into: self.userImageView) // Nuke：URLから画像取得
        }
        // ユーザ名
        self.userNameLabel.text = user.userName
        // ユーザID
        self.userIDLabel.text = user.userID
        // 自己紹介
        self.introductionTextView.text = user.introduction
        print("投稿者のユーザ情報をセット完了")
    }
    // 投稿者のプロフィール画面を閉じる
    @IBAction func closeProfileViewController() {
        self.dismiss(animated: true, completion: nil)
    }


}
