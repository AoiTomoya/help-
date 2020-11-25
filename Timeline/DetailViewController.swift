//
//  DetailViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/10.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import Nuke
import PKHUD
import CoreLocation // 位置情報

class DetailViewController: UIViewController {
    
    //@IBOutlet var iconButton: UIButton!
    // アイコン
    @IBOutlet var userImageView: UIImageView!
    // ユーザ名
    @IBOutlet var userNameLabel: UILabel!
    // ユーザID
    @IBOutlet var userIDLabel: UILabel!
    // 投稿タイトル
    @IBOutlet var titleTextView: UITextView!
    // 投稿詳細
    @IBOutlet var detailTextView: UITextView!
    // タイムラベル
    @IBOutlet var timeLabel: UILabel!
    // 距離ラベル
    @IBOutlet var distanceLabel: UILabel!
    // チャット開始ボタン
    @IBOutlet var mailButton: UIButton!
    // 投稿者プロフィールボタン
    @IBOutlet var profileButton: UIButton!
    // 投稿削除ボタン
    @IBOutlet var deleteButton: UIButton!
    // メニューボタン
    @IBOutlet var menuBarButton: UIBarButtonItem!
    
    
    // 投稿情報
    var selectedPost: Post! { // TimelineViewControllerから値渡しで受け取る
        didSet {
            print("投稿情報を取得完了")
            if let selectedPost = selectedPost {
                // 投稿者のuid
                let uid = selectedPost.userUID
                // 投稿者のユーザ情報を取得
                self.readUserFromFirestore(uid: uid)
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
    // ログイン中ユーザー
    var currentUser: User! {
        didSet {
            if let currentUser = currentUser { // nilチェック
                if currentUser.uid == selectedPost.userUID { // ログイン中のuidと投稿者のuidが一致
                    // 削除ボタン表示
                    self.deleteButton.isHidden = false
                    // 削除ボタン有効
                    self.deleteButton.isEnabled = true
                }
                else { // ログイン中のuidと投稿者のuidが異なる
                    // チャット開始ボタン表示
                    self.mailButton.isHidden = false
                    // チャット開始ボタン有効
                    self.mailButton.isEnabled = true
                    // メニューボタン有効
                    self.menuBarButton.isEnabled = true
                }
            }
        }
    }
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
        // レイアウト
        setupViews()
        // チャット開始ボタン無効
        mailButton.isEnabled = false
        // チャット開始ボタン非表示
        mailButton.isHidden = true
        // 投稿削除ボタン無効
        deleteButton.isEnabled = false
        // 投稿削除ボタン非表示
        deleteButton.isHidden = true
        // メニューボタン無効
        menuBarButton.isEnabled = false
        // メニューボタン非表示
//        menuBarButton.isHidden = true
    }
    override func viewWillAppear(_ animated: Bool) {
        print("*****詳細画面******")
        // 位置情報を取得
        setupLocationManager()
        // ログイン中のユーザ情報を取得
        readUserFromFirestore()
        // 投稿情報をセット
        setContentsFromSelectedPost()
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    // レイアウト
    func setupViews() {
        // アイコン角丸
        //iconButton.layer.cornerRadius = iconButton.bounds.width / 2.0
        //iconButton.layer.masksToBounds = true
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.layer.masksToBounds = true
        // プロフィールボタン色
        profileButton.tintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // メールボタン色
        mailButton.tintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBar背景色
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBarタイトル色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
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
    // タイムラベルフォーマット
    func dataFormatterForTimeLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    // ログイン中のユーザ情報を取得
    func readUserFromFirestore() {
        print("ログイン中のユーザ情報を取得")
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
                print("ログイン中のユーザ情報を取得成功")
                // ブロック機能
                self.blockContents()
            }
        }
    }
    // 投稿者のユーザ情報を取得
    func readUserFromFirestore(uid: String) {
        print("投稿者のユーザ情報を取得")
        // Firestoreからデータを取得
        Firestore.firestore().collection("user").document(uid).getDocument { (snapshot, error) in
            if error != nil { // データ取得エラー
                self.errorAlert(error: error)
            }
            else { // データ取得成功
                guard let docData = snapshot?.data() else {return}
                self.postUser = User.init(dic: docData)
                print("投稿者のユーザ情報を取得成功")
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
        // アイコンに画像を設定
        //self.iconButton.setImage(self.userImageView.image, for: .normal)
        // ユーザ名
        self.userNameLabel.text = user.userName
        // ユーザID
        self.userIDLabel.text = "@" + user.userID
        print("投稿者のユーザ情報をセット完了")
    }
    // ブロック機能
    func blockContents() {
        print("ブロック機能")
        // 投稿者のuidがログイン中ユーザーのブロックリストに含まれる -> true
        let isContain = self.currentUser.blockList.contains(self.selectedPost.userUID)
        if isContain { // ブロック中
            self.titleTextView.text = "ブロック中です"
            self.detailTextView.text = "ブロック中です"
        }
        print("ブロックを完了")
    }
    // 投稿情報をセット
    func setContentsFromSelectedPost() {
        print("投稿情報をセット")
        // selectedPostから取得
        self.titleTextView.text = self.selectedPost.title
        self.detailTextView.text = self.selectedPost.detail
        self.timeLabel.text = self.dataFormatterForTimeLabel(date: self.selectedPost.createdAt.dateValue())
        print("投稿情報をセット完了")
    }
    // 投稿削除アラート
    func deletePostAlert() {
        let alert = UIAlertController(title: "この投稿を削除します", message: "本当によろしいですか?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            HUD.show(.progress)
            // Firestoreからドキュメント(post)を削除
            Firestore.firestore().collection("post").document(self.selectedPost.postID).delete { (error) in
                if error != nil { // 削除エラー
                    self.errorAlert(error: error)
                }
                // 削除成功
                HUD.hide { (_) in
                    HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                        // タイムラインに戻る
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alert.dismiss(animated: true, completion: nil) // アラートを閉じる
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    // 投稿者をログイン中ユーザのブロックリストに追加
    func addPostUserToCurrentBlockList() {
        HUD.show(.progress)
        // ログイン中のuserUID
        let currentUID = self.currentUser.uid
        // 投稿者のuserUID
        let postUID = self.postUser.uid
        // ブロックリストを取得
        var blockList = self.currentUser.blockList
        // ブロックリストに投稿者のuserUIDを追加
        blockList.append(postUID)
        // 辞書型
        let updateData = [
                        "blockList": blockList
                        ] as [String: Any]
        // ドキュメント内に既に存在するフィールドに値を上書き
        Firestore.firestore().collection("user").document(currentUID).updateData(updateData) { (error) in
            if error != nil { // アップデートエラー
                self.errorAlert(error: error)
            }
            else { // アップデート成功
                HUD.hide { (_) in
                    HUD.flash(.labeledSuccess(title: nil, subtitle: self.userIDLabel.text! + "さんをブロックしました"), onView: self.view, delay: 1) { (_) in
                        // タイムラインに戻る
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }
    // 投稿者をログイン中ユーザのブロックリストから削除
    func removePostUserFromCurrentBlockList() {
        HUD.show(.progress)
        // ログイン中のuserUID
        let currentUID = self.currentUser.uid
        // 投稿者のuserUID
        let postUID = self.postUser.uid
        // ブロックリストを取得
        var blockList = self.currentUser.blockList
        // ブロックリストから投稿者のuserUIDのインデックスを取得
        guard let index = blockList.firstIndex(of: postUID) else {return}
        // ブロックリストから投稿者のuserUIDを削除
        blockList.remove(at: index)
        // 辞書型
        let updateData = [
                        "blockList": blockList
                        ] as [String: Any]
        // ドキュメント内に既に存在するフィールドに値を上書き
        Firestore.firestore().collection("user").document(currentUID).updateData(updateData) { (error) in
            if error != nil { // アップデートエラー
                self.errorAlert(error: error)
            }
            else { // アップデート成功
                HUD.hide { (_) in
                    HUD.flash(.labeledSuccess(title: nil, subtitle: self.userIDLabel.text! + "さんをブロックを解除しました"), onView: self.view, delay: 1) { (_) in
                        // タイムラインに戻る
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }
    // 投稿者の通報リストにログイン中のユーザーを追加
    func signInPostUserReportList() {
        HUD.show(.progress)
        // ログイン中のuserUID
        let uid = self.currentUser.uid
        // 投稿者のuserUID
        let uid2 = self.postUser.uid
        // 通報リストを取得
        var reportedBy: [String] = self.postUser.reportedBy
        // 通報リストにログイン中のuserUIDを追加
        reportedBy.append(uid)
        // 辞書型
        let updateData = [
                        "reportedBy": reportedBy
                        ] as [String: Any]
        // ドキュメント内に既に存在するフィールドに値を上書き
        Firestore.firestore().collection("user").document(uid2).updateData(updateData) { (error) in
            if error != nil { // アップデートエラー
                self.errorAlert(error: error)
            }
            else { // アップデート成功
                HUD.hide { (_) in
                    HUD.flash(.labeledSuccess(title: self.userIDLabel.text! + "さんを通報しました", subtitle: "ご協力ありがとうございます"), onView: self.view, delay: 1) { (_) in
                        self.dismiss(animated: true, completion: nil) // 画面切り替え
                    }
                }
            }
        }
    }
    
    // チャットを開始
    @IBAction func toChatListViewController() {
        // ログイン中のuserUID
        let uid = currentUser.uid
        // 投稿者（トーク相手）のuserUID
        let partnerUid = postUser.uid
        // チャットルームのメンバー
        let members = [uid, partnerUid] // userUID(String)の配列
        // 辞書型
        let docData = [
                        "members": members,
                        "latestMessageID": "",
                        "createdAt": Timestamp()
        ] as [String: Any]
        // Firestoreにデータを格納（チャットルームのID(documentID)は自動割り当て）
        Firestore.firestore().collection("chatRoom").addDocument(data: docData) { (error) in
            if error != nil { // アップデートエラー
                self.errorAlert(error: error)
            }
            else { // 保存成功
                // 画面遷移
                let UINavigationController = self.tabBarController?.viewControllers?[1]
                self.tabBarController?.selectedViewController = UINavigationController
            }
        }
        
    }
    // 投稿者プロフィール画面に遷移
    @IBAction func showProfileViewController() {
        // NavigationControllerへの値渡し
        let storyboard: UIStoryboard = self.storyboard!
        let navigationController: UINavigationController = storyboard.instantiateViewController(withIdentifier: "profileNavigationController") as! UINavigationController
        let profileViewController = navigationController.topViewController as! ProfileViewController
        profileViewController.uid = self.selectedPost?.userUID
        // 画面遷移
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController, animated: true, completion: nil)
        //self.performSegue(withIdentifier: "toProfile", sender: nil)
    }
    // 投稿を削除
    @IBAction func removePostFromFirebase() {
        // 投稿削除アラート
        self.deletePostAlert()
    }
    // メニューを表示
    @IBAction func showMenu() {
        // アラート
        let alertController = UIAlertController(title: "メニュー", message: "", preferredStyle: .actionSheet)
        // ブロックする
        let blockAction = UIAlertAction(title: "ブロックする", style: .default) { (action) in
            // アラート2
            let alertController2 = UIAlertController(title: self.userIDLabel.text! + "さんをブロックします．よろしいですか？", message: self.userIDLabel.text! + "さんの投稿内容があなたのタイムラインに表示されなくなります．", preferredStyle: .alert)
            // ブロックする -> OK
            let okAction2 = UIAlertAction(title: "OK", style: .default) { (action) in
                // 投稿者をログイン中ユーザのブロックリストに追加
                self.addPostUserToCurrentBlockList()
            }
            // ブロックする -> キャンセル
            let cancelAction2 = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
                alertController2.dismiss(animated: true, completion: nil)
            }
            // アクション追加2
            alertController2.addAction(okAction2)
            alertController2.addAction(cancelAction2)
            // アラート2表示
            self.present(alertController2, animated: true, completion: nil)
        }
        // ブロックを解除する
        let unblockAction = UIAlertAction(title: "ブロックを解除する", style: .default) { (action) in
            // 投稿者をログイン中ユーザのブロックリストから削除
            self.removePostUserFromCurrentBlockList()
        }
        // 通報する
        let reportAction = UIAlertAction(title: "通報する", style: .default) { (action) in
            // アラート2
            let alertController2 = UIAlertController(title: self.userIDLabel.text! + "さんを通報します．よろしいですか？", message: "", preferredStyle: .alert)
            // 通報する -> OK
            let okAction2 = UIAlertAction(title: "OK", style: .default) { (action) in
                // 投稿者の通報リストにログイン中のユーザーを追加
                self.signInPostUserReportList()
            }
            // 通報する -> キャンセル
            let cancelAction2 = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
                alertController2.dismiss(animated: true, completion: nil)
            }
            // アクション追加2
            alertController2.addAction(okAction2)
            alertController2.addAction(cancelAction2)
            // アラート2表示
            self.present(alertController2, animated: true, completion: nil)
        }
        // メニューを閉じる
        let closeMenuAction = UIAlertAction(title: "メニューを閉じる", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        // アクション追加
        // 投稿者のuidがログイン中ユーザーのブロックリストに含まれる -> true
        let isContain = self.currentUser.blockList.contains(self.selectedPost.userUID)
        if isContain { // ブロック中
            // ブロックを解除する
            alertController.addAction(unblockAction)
        }
        else { // ブロック中ではない
            // ブロックする
            alertController.addAction(blockAction)
        }
        // 通報する
        alertController.addAction(reportAction)
        // メニューを閉じる
        alertController.addAction(closeMenuAction)
        // アラート表示
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension DetailViewController: CLLocationManagerDelegate {
    
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
        print("自分の緯度", self.userLocation?.coordinate.latitude)
        print("自分の経度", self.userLocation?.coordinate.longitude)
        setDistance(post: selectedPost)
    }
    // 位置情報取得に失敗したときに呼ばれる関数
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorAlert(error: error)
    }
    // 距離をセット
    func setDistance(post: Post) {
        // 投稿の位置情報
        let postLocation = CLLocation(latitude: Double(selectedPost.latitude)!, longitude: Double(selectedPost.longitude)!)
        print("投稿の緯度", postLocation.coordinate.latitude)
        print("投稿の経度", postLocation.coordinate.longitude)
        // ログイン中ユーザーと投稿の距離
        print("距離をセット")
        if userLocation != nil {
            // [m]
            var distance = postLocation.distance(from: self.userLocation!)
            // [m] -> [km]
            distance = distance / 1000
            // 小数点以下1桁指定でStringに変換
            let distanceText = String(format: "%.1f", distance)
            print("距離", distanceText)
            self.distanceLabel.text = distanceText
        }
    }
    
}
