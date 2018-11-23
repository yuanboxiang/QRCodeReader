//
//  QrScanView.swift
//  ScanTool
//
//  Created by 向远波 on 2018/11/20.
//  Copyright © 2018 向远波. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
fileprivate let k_Screen_Width = UIScreen.main.bounds.width
fileprivate let k_Screen_Height = UIScreen.main.bounds.height
fileprivate let k_Scan_Width = k_Screen_Width - 60

protocol QRScanDisplayable {
    //扫描框
    var scanRect:CGRect{set get}
    //扫描框边线宽度
    var lineWidth:CGFloat{set get}
    //扫描框边线颜色
    var lineColor:UIColor{set get}
    //扫描框四角线宽度
    var inlineWidth:CGFloat{get set}
    //扫描框四角线颜色
    var inlineColor:UIColor{get set}
    //扫描框四角线长度
    var inlineHeight:CGFloat{get set}
    //遮罩填充颜色
    var maskColor:UIColor{set get}
    var reader:QrScanTool?{set get}
    //开始扫描
    func startScan()
    //结束扫描
    func stopScan()
//    init(frame:CGRect,scanRect:CGRect)
    /*
     初始化
     - parameter superView 父视图
     - parameter scanRect 扫描框
     - parameter reader 扫描工具
    */
    init(superView:UIView,scanRect:CGRect,reader:QrScanTool)
    
}

class QrScanView: UIView,QRScanDisplayable{
 
    var scanRect:CGRect = CGRect(x: 30, y:(k_Screen_Height - k_Scan_Width)/2 , width: k_Scan_Width, height: k_Scan_Width){
        didSet{
            self.setNeedsDisplay()
        }
    }
    var lineWidth:CGFloat = 3{
        didSet{
            self.setNeedsDisplay()
        }
    }
    var lineColor:UIColor = UIColor.color(netValue: 0xf9b615){
        didSet{
            self.setNeedsDisplay()
        }
    }
    var inlineWidth:CGFloat = 6{
        didSet{
            self.setNeedsDisplay()
        }
    }
    var inlineHeight:CGFloat = 80{
        didSet{
            self.setNeedsDisplay()
        }
    }
    var inlineColor:UIColor = UIColor.color(netValue: 0xf9b615){
        didSet{
            self.setNeedsDisplay()
        }
    }
    var maskColor:UIColor = UIColor.color(netValue: 0x464c50, alpha: 0.5){
        didSet{
            self.setNeedsDisplay()
        }
    }
    lazy var scanLine: UIImageView? = {
        let imgV = UIImageView(frame: CGRect(origin: scanRect.origin, size: CGSize(width: scanRect.width, height: 2)))
            imgV.backgroundColor = UIColor.color(netValue: 0xf7b619, alpha: 0.8)
        return imgV
    }()
    var lineMove:CGFloat = 5
    var timer:Timer?
    weak var reader: QrScanTool?
    @discardableResult
    required init(superView: UIView, scanRect: CGRect = CGRect(x: 30, y:(k_Screen_Height - k_Scan_Width)/2 , width: k_Scan_Width, height: k_Scan_Width), reader: QrScanTool) {
        self.scanRect = scanRect
        self.reader = reader
        reader.previewlLayer.frame = superView.bounds
        reader.updateRectOfInterSet(superView.bounds, inRect: scanRect)
        super.init(frame: superView.bounds)
        self.backgroundColor = UIColor.clear
        reader.lifeCycleDelegate = self
        weak var weakSelf = self
        superView.addSubview(weakSelf!)
        superView.layer.insertSublayer(reader.previewlLayer, at: 0)
        addSubview(scanLine!)
        reader.startScan()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(QrScanView.scanAnimate), userInfo: nil, repeats: true)
        timer?.fireDate = Date.distantFuture
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        setNeedsDisplay()
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        //遮罩非扫描区域
        let ctx = UIGraphicsGetCurrentContext()
        let l_width = (k_Screen_Width - scanRect.width)/2
        let l_height = (k_Screen_Height - scanRect.height)/2
        let rectLeft = CGRect(x: 0, y: 0, width: l_width, height: k_Screen_Height)
        let rectTop = CGRect(x: l_width, y: 0, width: scanRect.width, height: l_height)
        let rectRight = CGRect(x: k_Screen_Width - l_width, y: 0 , width: l_width, height: k_Screen_Height)
        let rectBottom = CGRect(x: l_width, y: k_Screen_Height - l_height, width: scanRect.width, height: l_height)
        ctx?.addRects([rectLeft,rectTop,rectRight,rectBottom])
        ctx?.setFillColor(maskColor.cgColor)
        ctx?.fillPath()
        //画扫描框边线
        ctx?.setStrokeColor(lineColor.cgColor)
        ctx?.stroke(CGRect(x: l_width, y: l_height, width: scanRect.width, height: scanRect.height),width:lineWidth)
        ctx?.strokePath()
        
        //画扫描框四角边线
        ctx?.setLineWidth(inlineWidth)
        ctx?.setStrokeColor(inlineColor.cgColor)
        ctx?.move(to: CGPoint(x: l_width+lineWidth, y: l_height+lineWidth + inlineHeight))
        ctx?.addLine(to:CGPoint(x: l_width + lineWidth, y: l_height+lineWidth))
        ctx?.addLine(to: CGPoint(x: l_width + lineWidth + inlineHeight, y: l_height + lineWidth))
        
        ctx?.move(to: CGPoint(x: k_Screen_Width - l_width - inlineHeight - lineWidth, y: l_height + lineWidth))
        ctx?.addLine(to: CGPoint(x: k_Screen_Width - l_width - lineWidth, y: l_height + lineWidth))
          ctx?.addLine(to: CGPoint(x: k_Screen_Width - l_width - lineWidth, y: l_height + lineWidth + inlineHeight))
        
        ctx?.move(to: CGPoint(x: k_Screen_Width - l_width  - lineWidth, y: k_Screen_Height - l_height - lineWidth - inlineHeight))
        ctx?.addLine(to: CGPoint(x: k_Screen_Width - l_width - lineWidth, y: k_Screen_Height - l_height - lineWidth))
        ctx?.addLine(to: CGPoint(x: k_Screen_Width - l_width - lineWidth - inlineHeight, y: k_Screen_Height - l_height - lineWidth))
        
        ctx?.move(to: CGPoint(x: l_width+lineWidth + inlineHeight, y: k_Screen_Height - l_height - lineWidth))
        ctx?.addLine(to:CGPoint(x: l_width + lineWidth, y: k_Screen_Height - lineWidth - l_height))
        ctx?.addLine(to: CGPoint(x: l_width + lineWidth , y: k_Screen_Height  - lineWidth - l_height - inlineHeight))
        
        ctx?.strokePath()
        
    }
    
    //扫描线动画
    @objc func scanAnimate(){
     var rect = scanLine?.frame
        if rect!.origin.y < scanRect.origin.y || rect!.origin.y > scanRect.origin.y + scanRect.height{
            lineMove = -lineMove
        }
        UIView.animate(withDuration: 0.1) {
            rect?.origin.y += self.lineMove
            self.scanLine?.frame = rect!

        }
    }
    
    func startScan() {
        timer?.fire()
    }
    func stopScan() {
        timer?.fireDate = Date.distantFuture
    }
    deinit {
        timer?.invalidate()
    }
    
}
extension QrScanView:QRreaderLifeCycleDelegate{
    func readerBeginScaning() {
        self.timer?.fireDate = Date()
    }
    func readerEndScaning() {
        self.timer?.fireDate = Date.distantFuture
    }
}


