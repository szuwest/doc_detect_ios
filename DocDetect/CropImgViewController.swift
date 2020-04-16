//
//  CropImgViewController.swift
//  DocDetect
//
//  Created by kk on 2020/4/3.
//  Copyright © 2020 wegene. All rights reserved.
//

import UIKit

class CropImgViewController: UIViewController {

    private lazy var cropImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    private lazy var closeBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("关闭", for: .normal)
        button.backgroundColor = UIColor.blue
        button.setTitleColor(UIColor.white, for: .normal)
        return button
    }()
    
    var cropImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(cropImageView)
        self.view.addSubview(closeBtn)
        
        if (cropImage != nil) {
            self.cropImageView.image = cropImage
        }
        
        self.closeBtn.addTarget(self, action: #selector(closeView), for: .touchUpInside)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.cropImageView.frame = self.view.frame
        cropImageView.center = self.view.center
        self.closeBtn.frame = CGRect(x: (self.view.frame.width-60)/2, y: self.view.frame.size.height - 35, width: 60, height: 30)
    }
    
    @objc func closeView() {
        self.dismiss(animated: true, completion: nil)
    }
}
