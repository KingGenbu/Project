//
//  StoryHistoryVC.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 08/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
class StoryHistoryVC: UIViewController {

    @IBOutlet var imgLogo: UIImageView!
    
    @IBOutlet var imgRecentStory: UIImageView!
    @IBOutlet weak var collectionHistory: UICollectionView!
    
    var arrRecentStories : [RecentStory]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.WSRecentStories()
        DispatchQueue.main.async {
            self.imgRecentStory.layer.cornerRadius = self.imgRecentStory.frame.size.width/2.0
            self.imgRecentStory.clipsToBounds = true
        }
        self.imgLogo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rightBarButtonAction)))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
        
    }
    func setUpNavigationBar()  {
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        let rightBarBackButton = UIBarButtonItem(image: #imageLiteral(resourceName: "img_close"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.rightBarButtonAction))
        self.navigationItem.rightBarButtonItem = rightBarBackButton
    }
    
    func WSRecentStories() {
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.recentStories, onComplete: { (json, error, response) in
            if error == nil {
                if let arrStories = json.arrayObject as NSArray? {
                    self.arrRecentStories = RecentStory.Populate(list: arrStories as NSArray)
                    if self.arrRecentStories!.count > 0 {
                        if let firstImageUrl = self.arrRecentStories?[0].media.thumbs[0].path {
                            self.imgRecentStory.sd_setShowActivityIndicatorView(true)
                            self.imgRecentStory.sd_setIndicatorStyle(.whiteLarge)
                            self.imgRecentStory.sd_setImage(with: URL(string: firstImageUrl), completed: nil)
                        }
                        self.collectionHistory.reloadData()
                    }
                }
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print(error ?? "error alamofire")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
    
    @objc func rightBarButtonAction(){
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - UICollectionViewDataSource & UICollectionViewDelegate
//extension StoryHistoryVC: UICollectionViewDataSource,UICollectionViewDelegate ,UICollectionViewDelegateFlowLayout{
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        guard let data = arrRecentStories else {
//            return 0
//        }
//        return data.count - 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let data = self.arrRecentStories![indexPath.row + 1]
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HistroyImageView", for: indexPath) as! HistroyImageView
//
//        DispatchQueue.main.async {
//            cell.imgRecentStory.layer.cornerRadius = cell.imgRecentStory.frame.size.width/2
//            cell.imgRecentStory.clipsToBounds = true
//        }
//        cell.imgRecentStory.sd_setShowActivityIndicatorView(true)
//        cell.imgRecentStory.sd_setIndicatorStyle(.whiteLarge)
//        cell.imgRecentStory.sd_setImage(with: URL(string: data.media.thumbs[0].path), placeholderImage: nil, completed: nil)
//
//        return cell
//
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//
//        return CGSize(width: ScreenSize.SCREEN_WIDTH*0.3125 , height: ScreenSize.SCREEN_WIDTH*0.3125)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//
//        return 0
//    }
//
//}
//class HistroyImageView: UICollectionViewCell {
//    @IBOutlet weak var imgRecentStory: UIImageView!
//
//}

