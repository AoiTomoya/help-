//
//  PostViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/10.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import PKHUD
import CoreLocation // 位置情報

class PostViewController: UIViewController {
    
    // 投稿タイトル
    @IBOutlet var titleTextField: UITextField!
    // 投稿詳細
    @IBOutlet var detailTextView: UITextView!
    // 投稿キャンセルボタン
    @IBOutlet var cancelBarButton: UIBarButtonItem!
    // 投稿ボタン
    @IBOutlet var postBarButton: UIBarButtonItem!
    
    // タイトルの状態
    var titleTextFieldIsEmpty = true
    // 詳細の状態
    var detailTextViewIsEmpty = true
    // ロケーションマネージャ
    var locationManager: CLLocationManager!
    // ログイン中ユーザーの位置情報
    var userLocation: CLLocation!
    // 測位精度
    let locationAccuaracy: [Double] = [
        kCLLocationAccuracyBestForNavigation,
        kCLLocationAccuracyBest,
        kCLLocationAccuracyNearestTenMeters,
        kCLLocationAccuracyHundredMeters,
        kCLLocationAccuracyKilometer,
        kCLLocationAccuracyThreeKilometers
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // デリゲートメソッドをselfに任せる
        titleTextField.delegate = self
        // デリゲートメソッドをselfに任せる
        detailTextView.delegate = self
        // 投稿ボタン無効
        postBarButton.isEnabled = false
        // レイアウト
        setupViews()
    }
    override func viewWillAppear(_ animated: Bool) {
        print("*******新規投稿画面******")
        // 位置情報を取得
        setupLocationManager()
    }
    
    // 他のViewをタッチした時にキーボードが下がる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // レイアウト
    func setupViews() {
        // NavigationBar背景色
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBarタイトル色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        // BarButtonItemキャンセルボタン色
        cancelBarButton.tintColor = UIColor.white
        // BarButtonItem投稿ボタン色
        postBarButton.tintColor = UIColor.white
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
    
    // 投稿キャンセルアラート
    func cancelAlert() {
        let alert = UIAlertController(title: "新規投稿を破棄", message: "本当によろしいですか?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            self.titleTextField.text = nil // タイトル削除
            self.detailTextView.text = nil // 詳細削除
            self.postBarButton.isEnabled = false // 投稿ボタン無効
            self.dismiss(animated: true, completion: nil) // 画面遷移
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alert.dismiss(animated: true, completion: nil) // アラートを閉じる
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    // 投稿のdocumentIDをランダムで自動生成
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
    
    // 新規投稿
    @IBAction func addPostToFirestore() {
        HUD.show(.progress)
        // postのdocumentID(postID)をランダム文字列で自動生成
        let postID = randomString(length: 20)
        // ログイン中のuserUID（ユーザー個別に割り当てられるID）を取得
        guard let uid = Auth.auth().currentUser?.uid else {return}
        // titleTextFieldからtitleを取得
        guard let title = self.titleTextField.text else {return}
        // detailTextViewからdetailを取得
        guard let detail = self.detailTextView.text else {return}
        // ログイン中ユーザーの位置情報を投稿の位置情報とする
        guard let postLocation = self.userLocation else {return}
        // 緯度
        let latitude = postLocation.coordinate.latitude
        // 経度
        let longitude = postLocation.coordinate.longitude
        // 辞書型
        let docData = [
                        "postID": postID,
                        "userUID": uid,
                        "title": title,
                        "detail": detail,
                        "createdAt": Timestamp(),
                        "latitude": String(latitude),
                        "longitude": String(longitude)
                    ] as [String : Any]
        // Firestoreにデータを格納
        Firestore.firestore().collection("post").document(postID).setData(docData) { (error) in
            if error != nil { // 保存エラー
                HUD.hide { (_) in
                    self.errorAlert(error: error)
                }
            }
            else { // 保存成功
                HUD.hide { (_) in
                    HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                        self.dismiss(animated: true, completion: nil) // 画面遷移
                    }
                }
            }
        }
    }
    // 新規投稿画面を閉じる
    @IBAction func closePostViewController() {
        if titleTextField.isFirstResponder == true { // titleTextFieldを編集中
            titleTextField.resignFirstResponder() // キーボードを閉じる
        }
        if detailTextView.isFirstResponder == true { // detailTextViewを編集中
            detailTextView.resignFirstResponder() // キーボードを閉じる
        }
        if titleTextFieldIsEmpty && detailTextViewIsEmpty { // 全部true（=nil）
            self.dismiss(animated: true, completion: nil) // 画面遷移
        }
        else { // 1つでもfalse（!=nil）
            // 投稿キャンセルアラート
            self.cancelAlert()
        }
    }

}

extension PostViewController: CLLocationManagerDelegate {
    
    // ロケーションマネージャのセットアップ
    func setupLocationManager() {
        locationManager = CLLocationManager()
        // 位置情報取得許可ダイアログの表示（権限をリクエスト）
        guard let locationManager = locationManager else {return}
        locationManager.requestWhenInUseAuthorization()
        // マネージャの設定
        let status = CLLocationManager.authorizationStatus()
        // ステータスごとの処理
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.delegate = self
            // 測位精度の設定
            locationManager.desiredAccuracy = locationAccuaracy[3]
            // 10m毎に管理マネージャが位置情報を更新
            locationManager.distanceFilter = 10
            // 位置情報取得を開始
            locationManager.startUpdatingLocation()
            print("位置情報取得を開始")
        }
    }
    // 位置情報が取得・更新される度に呼ばれる関数
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.first
        print("自分（投稿）の緯度", self.userLocation?.coordinate.latitude)
        print("自分（投稿）の経度", self.userLocation?.coordinate.longitude)
    }
    // 位置情報取得に失敗したときに呼ばれる関数
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorAlert(error: error)
    }
    
}

extension PostViewController: UITextFieldDelegate, UITextViewDelegate {
    
    // キーボードの改行（完了）キーが押された時に呼ばれるデリゲートメソッド(TextField)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // キーボードを閉じる
        return true
    }
    // 編集中のtextFieldが引数
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // nilだったらtrueが入る
        self.titleTextFieldIsEmpty = titleTextField.text?.isEmpty ?? true
        confirmContent()
    }
    // 編集中のtextViewが引数
    func textViewDidChangeSelection(_ textView: UITextView) {
        // nilだったらtrueが入る
        self.detailTextViewIsEmpty = detailTextView.text?.isEmpty ?? true
        confirmContent()
    }
    // コンテンツモニタ
    func confirmContent() {
        if self.titleTextFieldIsEmpty || self.detailTextViewIsEmpty { // 1つでもtrue（=nil）
            postBarButton.isEnabled = false // 投稿ボタン無効
        }
        else { // 全部false（!=nil）
            postBarButton.isEnabled = true // 投稿ボタン有効
        }
    }
    
}
