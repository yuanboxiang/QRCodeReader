//
//  QrScanTool.swift
//  ScanTool
//
//  Created by 向远波 on 2018/11/20.
//  Copyright © 2018 向远波. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


protocol QRreaderLifeCycleDelegate:class {
    func readerBeginScaning()
    func readerEndScaning()
}


class QrScanTool:NSObject{

    private let sessionQueue = DispatchQueue(label: "session queue")
    private let metadataObjectsQueue = DispatchQueue(label: "com.xyb.qe", attributes: [],  target: nil)
    var scanCompleteBlock:((_ result:String)->Void)?
    weak var lifeCycleDelegate:QRreaderLifeCycleDelegate?
    public var isTorchAvailable: Bool {
        return device?.isTorchAvailable ?? false
    }
    private let device = AVCaptureDevice.default(for: .video)
    lazy var input: AVCaptureDeviceInput = {
        return try! AVCaptureDeviceInput.init(device: device!)
    }()
    lazy var lightOutPut: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        return output
    }()
    
    lazy var outputDevice: AVCaptureMetadataOutput = {
        let output = AVCaptureMetadataOutput.init()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return output
    }()

    lazy var session: AVCaptureSession = {
        let _session = AVCaptureSession()
            _session.sessionPreset = .high
        if let input = try? AVCaptureDeviceInput(device: self.device!),_session.canAddInput(input){
            _session.addInput(input)
        }
        if _session.canAddOutput(self.outputDevice){
            _session.addOutput(self.outputDevice)
            let allTypes = Set(self.outputDevice.availableMetadataObjectTypes)
            let filtered = metadataObjectTypes.filter({ allTypes.contains($0)
            })
            self.outputDevice.metadataObjectTypes = filtered
        }
        if _session.canAddOutput(self.lightOutPut){
            _session.addOutput(self.lightOutPut)
        }
        _session.commitConfiguration()
        return _session
    }()
    lazy var previewlLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
            layer.videoGravity = .resizeAspectFill
        return layer
    }()

    var metadataObjectTypes:[AVMetadataObject.ObjectType]
    var shoulOnTorch:Bool = false
    /*
     初始化
     -parameter types 扫描类型
     -parameter completeHandler 扫描结束回调
     */
    required init(metadataObjectTypes types:[AVMetadataObject.ObjectType] = [.qr],completeHandler :@escaping ((_ result:String)->Void)) {
        self.metadataObjectTypes = types
        self.scanCompleteBlock = completeHandler
        super.init()
    }
    //开始扫描
    func startScan(){
        sessionQueue.async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.lifeCycleDelegate?.readerBeginScaning()
            }
        }
    }
    //扫描结束
    func stopScan(){
        sessionQueue.async {
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.lifeCycleDelegate?.readerEndScaning()
            }
        }
    }
    /*
     扫描区域
     -
    */
    func updateRectOfInterSet(_ preRect:CGRect,inRect:CGRect){
        let x = inRect.minX / preRect.width
        let y = inRect.minY / preRect.height
        let width = inRect.width / preRect.width
        let height = inRect.height / preRect.height
        outputDevice.rectOfInterest = CGRect(x: y, y: x, width: height, height: width)
    }
    
    
    func toggleTorch() {
        do {
            try device?.lockForConfiguration()
            device?.torchMode = device?.torchMode == .on ? .off : .on
            device?.unlockForConfiguration()
        } catch _ {
            
        }
    }
    func switchTorch(type:AVCaptureDevice.TorchMode){
        do{
            try device?.lockForConfiguration()
            device?.torchMode = type
            device?.unlockForConfiguration()
        }catch _{
            
        }
    }
 
}
//MARK:AVCaptureMetadataOutputObjectsDelegate
extension QrScanTool:AVCaptureMetadataOutputObjectsDelegate{
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        sessionQueue.async {
           
            self.stopScan()
            for item in metadataObjects{
                if  self.metadataObjectTypes.contains(item.type){
                    if self.scanCompleteBlock != nil {
                        self.scanCompleteBlock!((item as! AVMetadataMachineReadableCodeObject).stringValue!)
                    }
                    break
                }
            }
        }
    }
}
//MARK:AVCaptureVideoDataOutputSampleBufferDelegate
extension QrScanTool:AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let metadataDic = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [String:AnyObject]
        let exifdic = metadataDic![kCGImagePropertyExifDictionary as String] as? [String:AnyObject]
        let brightnessValue = exifdic![kCGImagePropertyExifBrightnessValue as String] as? CGFloat
        self.shoulOnTorch = brightnessValue! <= 0
    }
   
}

