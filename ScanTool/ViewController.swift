//
//  ViewController.swift
//  ScanTool
//
//  Created by 向远波 on 2018/11/20.
//  Copyright © 2018 向远波. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {
    
    var reader:QrScanTool!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.white
//        let readView = QrScanView(framea: self.view.bounds)
//        reader = QrScanTool(preView: self.view, scanDisplayView: readView)
        reader = QrScanTool(completeHandler: { (result) in
            print(result)
        })
        QrScanView(superView: self.view, reader: reader)


    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }


}

