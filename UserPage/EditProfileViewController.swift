//
//  EditProfileViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/12.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseUI
import NYXImagesKit // resize(.scale())
import PKHUD
import Nuke

class EditProfileViewController: UIViewController {
    
    // ログイン中ユーザーのアイコン
    @IBOutlet var userImageView: UIImageView!
    // ログイン中のユーザ名
    @IBOutlet var userNameTextField: UITextField!
    // ログイン中のユーザID
    @IBOutlet var userIDLabel: UILabel!
    // ログイン中ユーザの自己紹介
    @IBOutlet var introductionTextView: UITextView!
    // キャンセルボタン
    @IBOutlet var cancelBarButton: UIBarButtonItem!
    // 保存ボタン
    @IBOutlet var saveBarButton: UIBarButtonItem!
    
    // エラー
    var err: Error!
    // プロフィール画像URL
    var imageURL = String() // =""と同値．
    // ログイン中のユーザ情報
    var currentUser: User? {
        didSet {
            if let currentUser = currentUser {
                // プロフィールをセット
                setProfileFromCurrentUser()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // デリゲートをselfに任せる
        userNameTextField.delegate = self
        // デリゲートをselfに任せる
        introductionTextView.delegate = self
        // レイアウト
        setupViews()
        // ログイン中のユーザ情報を取得
        readUserFromFirestore()
    }
    // 他のViewをタッチした時にキーボードが下がる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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
        // BarButtonItemキャンセルボタン色
        cancelBarButton.tintColor = UIColor.white
        // BarButtonItem保存ボタン色
        saveBarButton.tintColor = UIColor.white
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
    // プロフィールをセット
    func setProfileFromCurrentUser() {
        // プロフィール画像のURL取得（nilだったら空文字列）
        if let url = URL(string: self.currentUser?.imageURL ?? "") {
            // URLからプロフィール画像取得（Nuke）
            Nuke.loadImage(with: url, into: self.userImageView) // Nuke：URLから画像取得
        }
        // ユーザ名
        self.userNameTextField.text = self.currentUser?.userName
        // ユーザID
        self.userIDLabel.text = self.currentUser?.userID
        // 自己紹介
        self.introductionTextView.text = self.currentUser?.introduction
    }
    // アイコンをStorageに保存，URLを取得
    func uploadImageToStorage() {
        guard let uploadImage = userImageView.image else {return}
        guard let imageData = uploadImage.pngData() else {return} // データ型に変換
        //let fileName = NSUUID().uuidString // ファイル名を任意に決定して保存する
        // ログイン中のuserUID
        let uid = self.currentUser?.uid
        // 画像をStorageにアップロード
        let storageRef = Storage.storage().reference().child("profile_image").child(uid!)
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if error != nil { // 画像アップロードエラー
                self.err = error
            }
            else { // 画像アップロード成功（URLの取得）
                storageRef.downloadURL { (url, error) in
                    if error != nil { // URL取得エラー
                        self.err = error
                    }
                    else { // URL取得成功（URLをStringに変換->Firestoreに保存）
                        guard let urlString = url?.absoluteString else {return}
                        self.imageURL = urlString
                        // ユーザ情報を更新
                        self.updateUserInFirestore(imageURL: self.imageURL)
                    }
                }
            }
        }
    }
    // ユーザ情報を更新
    func updateUserInFirestore(imageURL: String) {
        guard let userName = userNameTextField.text else {return}
        guard let introduction = introductionTextView.text else {return}
        // 辞書型
        let docData = [
                        "uid": self.currentUser!.uid,
                        // サインアップ画面
                        "userID": self.currentUser!.userID,
                        "userName": userName,
                        "email": self.currentUser!.email,
                        "password": self.currentUser!.password,
                        "createdAt": self.currentUser!.createdAt,
                        // ユーザーページ
                        "imageURL": imageURL,
                        "introduction": introduction,
                        // ブロックリスト
                        "blockList": self.currentUser!.blockList,
                        // 通報リスト
                        "reportedBy": self.currentUser!.reportedBy
                    ] as [String : Any]
        // ログイン中のuserUID
        let uid = self.currentUser?.uid
        // Firestoreにデータを格納
        let userRef = Firestore.firestore().collection("user").document(uid!)
        userRef.setData(docData) { (error) in
            if error != nil { // アップデートエラー
                self.err = error
            }
            else {
                // 保存成功
            }
        }
    }
    
    @IBAction func closeEditViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func saveEditing() {
        HUD.show(.progress)
        uploadImageToStorage()
        if err != nil { // uploadImageToStorage(), updateProfileToFirestore()のどっかしらでエラー
            HUD.hide { (_) in
                self.errorAlert(error: self.err)
            }
        }
        else { // uploadImageToStorage(), updateProfileToFirestore()でエラーなし
            HUD.hide { (_) in
                HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                    self.dismiss(animated: true, completion: nil) // 画面切り替え
                }
            }
        }
    }
    
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // UIImagePickerControllerで画像が選ばれた時に呼ばれる関数
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        var resizedImage = selectedImage.scale(byFactor: 0.1) // NYXImagesKit
        
        // 撮影した画像をデータ化した時に右に90度回転してしまう問題の解消
        UIGraphicsBeginImageContext(resizedImage!.size)
        let rect = CGRect(x: 0, y: 0, width: resizedImage!.size.width, height: resizedImage!.size.height)
        resizedImage!.draw(in: rect)
        resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        picker.dismiss(animated: true, completion: nil)
        userImageView.image = resizedImage
    }
    
    @IBAction func selectImage() {
        let actionController = UIAlertController(title: "画像を選択", message: "", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラを起動", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) { // カメラ起動
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            }
            else {
                print("Failed to activate Camera.")
            }
        }
        let photolibraryAction = UIAlertAction(title: "フォトライブラリから選択", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == true { // フォトライブラリ起動
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            }
            else {
                print("Failed to activate PhotoLibrary")
            }
        }
        let deleteAction = UIAlertAction(title: "現在の画像を削除", style: .default) { (action) in
            self.userImageView.image = UIImage(named: "placehoder_icon@2x")
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            actionController.dismiss(animated: true, completion: nil)
        }
        actionController.addAction(cameraAction)
        actionController.addAction(photolibraryAction)
        actionController.addAction(deleteAction)
        actionController.addAction(cancelAction)
        self.present(actionController, animated: true, completion: nil)
    }
    
}

extension EditProfileViewController: UITextFieldDelegate, UITextViewDelegate {
    
    // キーボードの改行（完了）キーが押された時に呼ばれるデリゲートメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // キーボードを閉じる
        return true
    }
    // キーボードの改行（完了）キーが押された時に呼ばれるデリゲートメソッド
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder() // キーボードを閉じる
        return true
    }
    
}
