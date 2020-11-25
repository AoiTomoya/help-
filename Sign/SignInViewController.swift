//
//  SignInViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/10.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class SignInViewController: UIViewController {
    
    // メールアドレス
    @IBOutlet var emailTextField: UITextField!
    // パスワード
    @IBOutlet var passwordTextField: UITextField!
    // ログインボタン
    @IBOutlet var loginButton: UIButton!
    // パスワードをお忘れですかボタン
    @IBOutlet var forgetPasswordButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // デリゲートをselfに任せる
        emailTextField.delegate = self
        // デリゲートをselfに任せる
        passwordTextField.delegate = self
        // ログインボタン無効
        loginButton.isEnabled = false
        // パスワードをお忘れですかボタン無効
        forgetPasswordButton.isEnabled = false
        // パスワードをお忘れですかボタン非表示
        forgetPasswordButton.isHidden = true
        // レイアウト
        setupViews()
    }
    // 他のViewをタッチした時にキーボードが下がる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // レイアウト
    func setupViews() {
        // ログインボタン角丸
        loginButton.layer.cornerRadius = 10
        // ログインボタン無効色
        loginButton.backgroundColor = UIColor.init(red: 176/255, green: 196/255, blue: 222/255, alpha: 1) // lightsteelblue: rgb(176,196,222)
        // NavigationBar背景色
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBarタイトル色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        // NavigationBar戻るボタン（サインアップ画面の戻るボタン）色
        navigationController?.navigationBar.tintColor = UIColor.white
        // NavigationBar戻るボタン（サインアップ画面の戻るボタン）テキスト
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
    
    // ログイン
    @IBAction func signIn() {
        // guard let : nilだったら{return}
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        HUD.show(.progress)
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if error != nil { // ログインエラー
                HUD.hide { (_) in
                    self.errorAlert(error: error)
                }
            }
            else { // ログイン成功（画面切り替え）
                HUD.hide { (_) in
                    HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                        self.toMain() // 画面切り替え
                    }
                }
            }
        }
    }
    // パスワードをお忘れですか
    @IBAction func forgetPassword() {
        
    }

}

extension SignInViewController: UITextFieldDelegate {
    
    // キーボードの改行（完了）キーが押された時に呼ばれるデリゲートメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // キーボードを閉じる
        return true
    }
    // 編集中のtextFieldが引数
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // nilだったらtrueが入る
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        if emailIsEmpty || passwordIsEmpty { // 1つでもtrue（=nil）-> ログインボタン無効
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.init(red: 176/255, green: 196/255, blue: 222/255, alpha: 1) // lightsteelblue: rgb(176,196,222)
        }
        else { // ２つともfalse（=nilがない）-> ログインボタン有効
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        }
    }
    
}
