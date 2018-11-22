//
//  ExtensionColor.swift
//  ScanTool
//
//  Created by 向远波 on 2018/11/22.
//  Copyright © 2018 向远波. All rights reserved.
//

import Foundation
import UIKit
extension UIColor{
    class func color(netValue:UInt = 0xfff,alpha:CGFloat = 1)->UIColor{
        return UIColor(red: CGFloat(((netValue & 0xff0000) >> 16)) / 255.0, green: CGFloat(((netValue & 0xff00) >> 8)) / 255.0, blue: CGFloat(((netValue & 0xff) >> 16)) / 255.0, alpha: alpha)
    }
    class func color(netstr:String = "#FFFFFF",alpha:CGFloat = 1) -> UIColor{
        let unprefixStr = netstr.replacingOccurrences(of: "#", with: "").replacingOccurrences(of: "0x", with: "")
        var p:UnsafeMutablePointer<Int8>?
        let netValue = strtoul(unprefixStr.cString(using: .utf8), &p, 16)
        return UIColor.color(netValue: netValue, alpha: 1)
    }
}
