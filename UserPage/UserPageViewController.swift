//
//  UserPageViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/12.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import Nuke

class UserPageViewController: UIViewController {
    
    // ログイン中ユーザーのアイコン
    @IBOutlet var userImageView: UIImageView!
    // ログイン中のユーザ名
    @IBOutlet var userNameLabel: UILabel!
    // ログイン中のユーザID
    @IBOutlet var userIDLabel: UILabel!
    // ログイン中ユーザの自己紹介
    @IBOutlet var introductionTextView: UITextView!
    // メニューボタン
    @IBOutlet var menuBarButton: UIBarButtonItem!
    
    // ログイン中のユーザ情報
    var currentUser: User? {
        didSet {
            if let currentUser = currentUser {
                // プロフィール画像のURL取得（nilだったら空文字列）
                if let url = URL(string: currentUser.imageURL ?? "") {
                    // URLからプロフィール画像取得（Nuke）
                    Nuke.loadImage(with: url, into: self.userImageView) // Nuke：URLから画像取得
                }
                // ログイン中のユーザ名
                self.userNameLabel.text = currentUser.userName
                // ログイン中のユーザID
                self.userIDLabel.text = currentUser.userID
                // ログイン中ユーザの自己紹介
                self.introductionTextView.text = currentUser.introduction
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // レイアウト
        setupViews()
    }
    override func viewWillAppear(_ animated: Bool) {
        // ログイン中のユーザ情報を取得
        readUserFromFirestore()
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
    // サインイン画面へ遷移
    func toSignIn() {
        // 画面切り替え
        let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
        let rootViewController = storyboard.instantiateViewController(identifier: "RootNavigationController")
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
        // ログイン状態からログアウト状態へ
        let ud = UserDefaults.standard
        ud.set(false, forKey: "isLogin")
        ud.synchronize()
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
    
    // メニューを表示
    @IBAction func showMenu() {
        // アラート
        let alertController = UIAlertController(title: "メニュー", message: "", preferredStyle: .actionSheet)
        // プロフィールを編集
        let editProfileAction = UIAlertAction(title: "プロフィールを編集", style: .default) { (action) in
            // NavigationControllerへの値渡し
            /*let storyboard: UIStoryboard = self.storyboard!
            let navigationController: UINavigationController = storyboard.instantiateViewController(withIdentifier: "editProfileNavigationController") as! UINavigationController
            let editProfileViewController = navigationController.topViewController as! EditProfileViewController
            editProfileViewController.currentUser = self.currentUser*/
            // 画面遷移
            /*navigationController.modalPresentationStyle = .fullScreen
            self.present(navigationController, animated: true, completion: nil)*/
            self.performSegue(withIdentifier: "toEditProfile", sender: nil)
        }
        // ログアウト
        let signOutAction = UIAlertAction(title: "ログアウト", style: .default) { (action) in
            do { // ログアウト（画面切り替え）
                try Auth.auth().signOut() // ログアウト
                self.toSignIn() // 画面切り替え
            }
            catch (let error) { // ログアウトエラー
                self.errorAlert(error: error)
            }
        }
        // メニューを閉じる
        let closeMenuAction = UIAlertAction(title: "メニューを閉じる", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        // アクション追加
        alertController.addAction(editProfileAction)
        alertController.addAction(signOutAction)
        alertController.addAction(closeMenuAction)
        // アラート表示
        self.present(alertController, animated: true, completion: nil)
    }
    
}
