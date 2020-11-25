//
//  ViewController.swift
//  help!
//
//  Created by 青井智弥 on 2020/09/10.
//  Copyright © 2020 net.aoi. All rights reserved.
//

import UIKit
import Firebase
import Nuke
import CoreLocation // 位置情報

class TimelineViewController: UIViewController {
    
    // timelineTableView
    @IBOutlet var timelineTableView: UITableView!
    // 投稿ボタン
    @IBOutlet var postBarButton: UIBarButtonItem!
    
    // 投稿の配列
    var posts = [Post]()
    // ログイン中のユーザ情報
    var currentUser: User!
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
        // データソースメソッドをselfに任せる
        timelineTableView.dataSource = self
        // デリゲートメソッドをselfに任せる
        timelineTableView.delegate = self
        // カスタムセルの登録
        let nib = UINib(nibName: "TimelineTableViewCell", bundle: Bundle.main)
        timelineTableView.register(nib, forCellReuseIdentifier: "Cell")
        // TableViewの不要な線を消す
        timelineTableView.tableFooterView = UIView()
        // レイアウト
        setupViews()
        // ログイン中のユーザ情報を取得
        readUserFromFirestore()
    }
    override func viewWillAppear(_ animated: Bool) {
        print("********タイムライン*********")
        // ログインステータスを確認
        confirmLoginStatus()
        // ログイン中のユーザ情報を取得
        readUserFromFirestore()
    }
    override func viewDidAppear(_ animated: Bool) {
        // 投稿を取得
        readPostFromFirestore()
        // 位置情報を取得
        setupLocationManager()
    }
    
    // 値渡し
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let selectedIndexPath = timelineTableView.indexPathForSelectedRow!
            detailViewController.selectedPost = posts[selectedIndexPath.row]
        }
    }
    
    // レイアウト
    func setupViews() {
        print("レイアウトを設定")
        // NavigationBar背景色
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // NavigationBarタイトル色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        // NavigationBar戻るボタン（詳細画面の戻るボタン）色
        navigationController?.navigationBar.tintColor = UIColor.white
        // NavigationBar戻るボタン（詳細画面の戻るボタン）テキスト
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        // BarButtonItem新規投稿ボタン色
        postBarButton.tintColor = UIColor.white
        // TabBar背景色
        tabBarController?.tabBar.barTintColor = UIColor.init(red: 30/255, green: 144/255, blue: 255/255, alpha: 1) // dodgerblue: rgb(30, 144, 255)
        // TabBarアイコン
        self.setTabBarItem(index: 0, image: UIImage(named: "tabbar_icon_help!@2x")!, selectedImage: UIImage(named: "tabbar_icon_help!_filled@2x")!, offColor: UIColor.white, onColor: UIColor.white)
        self.setTabBarItem(index: 1, image: UIImage(named: "tabbar_icon_DM@2x")!, selectedImage: UIImage(named: "tabbar_icon_DM_filled@2x")!, offColor: UIColor.white, onColor: UIColor.white)
        self.setTabBarItem(index: 2, image: UIImage(named: "tabbar_icon_user@2x")!, selectedImage: UIImage(named: "tabbar_icon_user_filled@2x")!, offColor: UIColor.white, onColor: UIColor.white)
        print("レイアウトを設定完了")
    }
    // TabBarアイコン
    func setTabBarItem(index: Int, image: UIImage, selectedImage: UIImage, offColor: UIColor, onColor: UIColor) {
        let tabBarItem = self.tabBarController?.tabBar.items![index]
        // 非選択時画像
        tabBarItem?.image = image.withRenderingMode(.alwaysOriginal).withTintColor(offColor)
        // 選択時画像
        tabBarItem?.selectedImage = selectedImage.withRenderingMode(.alwaysOriginal).withTintColor(onColor)
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
    // サインイン画面へ遷移
    func toSignIn() {
        print("画面遷移")
        // 画面切り替え
        let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
        let rootViewController = storyboard.instantiateViewController(identifier: "RootNavigationController")
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
        // ログイン状態からログアウト状態へ
        let ud = UserDefaults.standard
        ud.set(false, forKey: "isLogin")
        ud.synchronize()
    }
    // ログインステータスを確認
    func confirmLoginStatus() {
        print("ログインステータスを確認")
        if Auth.auth().currentUser?.uid == nil {
            self.toSignIn()
        }
        print("ログインステータスを確認完了")
    }
    // ブロック機能
    func blockContents(postUser: User, cell: TimelineTableViewCell) {
        print("ブロック機能")
        // 投稿者のuidがログイン中ユーザーのブロックリストに含まれる -> true
        let isContain = self.currentUser.blockList.contains(postUser.uid)
        if isContain { // ブロック中
            cell.titleTextView.text = "ブロック中です"
        }
        print("ブロック機能を完了")
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
            }
        }
    }
    // 投稿者のユーザ情報をセット
    func setUserInfo(user: User, cell: TimelineTableViewCell) {
        print("投稿者のユーザ情報をセット")
        // プロフィール画像のURL取得（nilだったら空文字列）
        if let url = URL(string: user.imageURL ?? "") {
            // URLからプロフィール画像取得（Nuke）
            Nuke.loadImage(with: url, into: cell.userImageView) // Nuke：URLから画像取得
        }
        // アイコンに画像を設定
        //self.iconButton.setImage(self.userImageView.image, for: .normal)
        // 投稿者のユーザ名
        cell.userNameLabel.text = user.userName
        // 投稿者のユーザID
        cell.userIDLabel.text = "@" + user.userID
        print("投稿者のユーザ情報をセット完了")
    }
    // 投稿を取得
    func readPostFromFirestore() {
        print("投稿を読み込み")
        // snapshots: postコレクション内の全post
        // Firebaseからデータを取得
        Firestore.firestore().collection("post").getDocuments { (snapshots, error) in
            // クロージャ内は通信後に処理される
            if error != nil { // データ取得エラー
                self.errorAlert(error: error)
            }
            else { // データ取得成功
                // 投稿の配列を初期化（重複append防止）
                self.posts = []
                // snapshot: 全postの各post
                snapshots?.documents.forEach({ (snapshot) in
                    // 各投稿
                    let docData = snapshot.data()
                    let post = Post.init(dic: docData)
                    // 各投稿を投稿の配列に追加
                    self.posts.append(post)
                    // createdAt順にソート（m1Date < m2Date:昇順/m1Date > m2Date:降順）
                    self.posts.sort { (m1, m2) -> Bool in
                        let m1Date = m1.createdAt.dateValue()
                        let m2Date = m2.createdAt.dateValue()
                        return m1Date > m2Date
                    }
                    // timelineTableViewをリロード
                    self.timelineTableView.reloadData()
                })
            }
        } // クロージャ1
        print("投稿を読み込み完了")
    }

}

extension TimelineViewController: CLLocationManagerDelegate {
    
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
    }
    // 位置情報取得に失敗したときに呼ばれる関数
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorAlert(error: error)
    }
    
}

extension TimelineViewController: UITableViewDelegate, UITableViewDataSource {
    
    // セルの個数を決めるデータソースメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    // セルの内容を決めるデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("セルコンテンツをセット")
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! TimelineTableViewCell
        // 投稿情報
        let post = posts[indexPath.row]
        // 投稿タイトル
        cell.titleTextView.text = post.title
        // 投稿の作成時間
        cell.timeLabel.text = self.dataFormatterForTimeLabel(date: post.createdAt.dateValue())
        // 投稿の位置情報
        let postLocation = CLLocation(latitude: Double(post.latitude)!, longitude: Double(post.longitude)!)
        print("投稿の緯度", postLocation.coordinate.latitude)
        print("投稿の経度", postLocation.coordinate.longitude)
        // ログイン中ユーザーと投稿の距離
        if userLocation != nil {
            // [m]
            var distance = postLocation.distance(from: self.userLocation!)
            // [m] -> [km]
            distance = distance / 1000
            // 小数点以下1桁指定でStringに変換
            let distanceText = String(format: "%.1f", distance)
            print("距離", distanceText)
            cell.distanceLabel.text = distanceText
        }
        // 投稿者のuid
        let uid = post.userUID
        // 投稿者のユーザ情報
        var postUser: User!
        // Firestoreからデータを取得
        Firestore.firestore().collection("user").document(uid).getDocument { (snapshot, error) in
            if error != nil { // データ取得エラー
                self.errorAlert(error: error)
            }
            else { // データ取得成功
                guard let docData = snapshot?.data() else {return}
                postUser = User.init(dic: docData)
                // 投稿者のユーザ情報をセット
                self.setUserInfo(user: postUser, cell: cell)
                // ブロック機能
                self.blockContents(postUser: postUser, cell: cell)
            }
        }
        print("セルコンテンツをセット完了")
        return cell
    }
    // セルが押された時に呼ばれる関数
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toDetail", sender: nil) // 画面遷移
        tableView.deselectRow(at: indexPath, animated: true) // 選択解除
    }
    
}

