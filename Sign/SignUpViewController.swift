//
//  SignUpViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/10.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class SignUpViewController: UIViewController {
    
    // ユーザID
    @IBOutlet var userIDTextField: UITextField!
    // ユーザ名
    @IBOutlet var userNameTextField: UITextField!
    // メールアドレス
    @IBOutlet var emailTextField: UITextField!
    // パスワード
    @IBOutlet var passwordTextField: UITextField!
    // 確認用パスワード
    @IBOutlet var confirmTextField: UITextField!
    // 新規会員登録ボタン
    @IBOutlet var registerButton: UIButton!
    
    // 利用規約が読まれたか確認
    var readTermsOfService = false
    // プライバシーポリシーが読まれたか確認
    var readPrivacyPolicy = false
    // 必要事項が書かれたか確認
    var contentsFilled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // デリゲートをselfに任せる
        userIDTextField.delegate = self
        userNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmTextField.delegate = self
        // 新規会員登録ボタン無効
        registerButton.isEnabled = false
        // レイアウト
        setupViews()
    }
    // 他のViewをタッチした時にキーボードが下がる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // レイアウト
    func setupViews() {
        // 新規会員登録ボタン角丸
        registerButton.layer.cornerRadius = 10
        // 新規会員登録ボタン無効色
        registerButton.backgroundColor = UIColor.init(red: 176/255, green: 196/255, blue: 222/255, alpha: 1) // lightsteelblue: rgb(176,196,222)
        // NavigationBar背景色
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBarタイトル色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        // NavigationBar戻るボタン（利用規約画面，プライバシーポリシー画面の戻るボタン）テキスト
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    // アラート
    func errorAlert(error: Error?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert) // localized->Appの言語設定に応じて
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    // パスワードアラート
    func passwordAlert() {
        let alert = UIAlertController(title: "エラー", message: "パスワードが一致しません", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    // 同意アラート
    func agreementAlert () {
        let alert = UIAlertController(title: "利用規約とプライバシーポリシーをご確認下さい", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    // タイムラインへ画面遷移
    func toMain() {
        // 画面切り替え
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let rootViewController = storyboard.instantiateViewController(identifier: "RootTabBarController")
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
        // ログイン状態の保持
        let ud = UserDefaults.standard
        ud.set(true, forKey: "isLogin")
        ud.synchronize()
    }
    // ユーザ情報をFirestoreに保存
    func addUserToFirestore(email: String, password: String) {
        // userUID（ユーザー個別に割り当てられる）を取得
        guard let uid = Auth.auth().currentUser?.uid else {return}
        // TextFieldからtextを取得
        guard let userID = self.userIDTextField.text else {return}
        guard let userName = self.userNameTextField.text else {return}
        guard let password = self.passwordTextField.text else {return}
        // 以下ユーザページで使用
        let imageURL = String()
        let introduction = String()
        // ブロックリスト
        let blockList = [String]()
        // 通報リスト
        let reportedBy = [String]()
        // 辞書型
        let docData = [
                        "uid": uid,
                        // サインアップ画面
                        "userID": userID,
                        "userName": userName,
                        "email": email,
                        "password": password,
                        "createdAt": Timestamp(),
                        // ユーザーページ
                        "imageURL": imageURL,
                        "introduction": introduction,
                        // ブロックリスト
                        "blockList": blockList,
                        // 通報リスト
                        "reportedBy": reportedBy
                    ] as [String : Any]
        // Firestoreにデータを格納
        let userRef = Firestore.firestore().collection("user").document(uid)
        userRef.setData(docData) { (error) in
            if error != nil { // 保存エラー
                self.errorAlert(error: error)
            }
            else {
                // 保存成功
            }
        }
    }
    
    // 利用規約ボタン
    @IBAction func tappedTermsOfService() {
        // 利用規約が読まれた
        self.readTermsOfService = true
    }
    // プライバシーポリシーボタン
    @IBAction func tappedPrivacyPolicy() {
        // プライバシーポリシーが読まれた
        self.readPrivacyPolicy = true
    }
    // 新規会員登録
    @IBAction func signUp() {
        // 同意確認
        if !self.readTermsOfService || !self.readPrivacyPolicy { // どちらかがfalse
            // 同意アラート
            self.agreementAlert()
            // 以下の処理を行わない
            return
        }
        // guard let : nilだったら{return}
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        if passwordTextField.text != confirmTextField.text {
            passwordAlert()
            return
        }
        HUD.show(.progress)
        // 新しいユーザーを登録
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if error != nil { // サインアップエラー
                HUD.hide { (_) in
                    self.errorAlert(error: error)
                }
            }
            else { // サインアップ成功（画面切り替え）
                self.addUserToFirestore(email: email, password: password)
                HUD.hide { (_) in
                    HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                        self.toMain() // 画面切り替え
                    }
                }
            }
        }
    }
    
}

extension SignUpViewController: UITextFieldDelegate {
    
    // キーボードの改行（完了）キーが押された時に呼ばれるデリゲートメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // キーボードを閉じる
        return true
    }
    // 編集中のtextFieldが引数
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // nilだったらtrueが入る
        let userIDIsEmpty = userIDTextField.text?.isEmpty ?? true
        let userNameIsEmpty = userNameTextField.text?.isEmpty ?? true
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let confirmIsEmpty = confirmTextField.text?.isEmpty ?? true
        
        if userIDIsEmpty || userNameIsEmpty || emailIsEmpty || passwordIsEmpty || confirmIsEmpty { // 1つでもtrue（=nil）
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.init(red: 176/255, green: 196/255, blue: 222/255, alpha: 1) // lightsteelblue: rgb(176,196,222)
        }
        else { // 全部false（!=nil）
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        }
    }
    
}
