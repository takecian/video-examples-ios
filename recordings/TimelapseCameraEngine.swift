//
//  CameraEngine.swift
//  naruhodo
//
//  Created by FUJIKI TAKESHI on 2014/11/10.
//  Copyright (c) 2014年 Takeshi Fujiki. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class TimelapseCameraEngine : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{

    class TimeLapseVideoWriter : NSObject {
        var fileWriter: AVAssetWriter!
        var videoInput: AVAssetWriterInput!
        var audioInput: AVAssetWriterInput!
        
        init(fileUrl:NSURL!, height:Int, width:Int, channels:Int, samples:Float64){
            fileWriter = try? AVAssetWriter(URL: fileUrl, fileType: AVFileTypeQuickTimeMovie)
            
            let videoOutputSettings: Dictionary<String, AnyObject> = [
                AVVideoCodecKey : AVVideoCodecH264,
                AVVideoWidthKey : width,
                AVVideoHeightKey : height
            ]
            videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            videoInput.transform = CGAffineTransformMakeRotation(CGFloat(M_PI)/2)
            fileWriter.addInput(videoInput)
            
            let audioOutputSettings: Dictionary<String, AnyObject> = [
                AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey : channels,
                AVSampleRateKey : samples,
                AVEncoderBitRateKey : 128000
            ]
            audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
            audioInput.expectsMediaDataInRealTime = true
            fileWriter.addInput(audioInput)
        }
        
        func write(sample: CMSampleBufferRef, isVideo: Bool){
            if CMSampleBufferDataIsReady(sample) {
                if fileWriter.status == AVAssetWriterStatus.Unknown {
                    Logger.log("Start writing, isVideo = \(isVideo), status = \(fileWriter.status.rawValue)")
                    let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                    fileWriter.startWriting()
                    fileWriter.startSessionAtSourceTime(startTime)
                }
                if fileWriter.status == AVAssetWriterStatus.Failed {
                    Logger.log("Error occured, isVideo = \(isVideo), status = \(fileWriter.status.rawValue), \(fileWriter.error!.localizedDescription)")
                    return
                }
                if isVideo {
                    if videoInput.readyForMoreMediaData {
                        videoInput.appendSampleBuffer(sample)
                    }
                }else{
                    if audioInput.readyForMoreMediaData {
                        audioInput.appendSampleBuffer(sample)
                    }
                }
            }
        }
        
        func finish(callback: Void -> Void){
            fileWriter.finishWritingWithCompletionHandler(callback)
        }
    }
    
    let captureSession = AVCaptureSession()
    var isCapturing = false
    let skipFrameSize = 5

    private let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    private let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
    private var videoWriter : TimeLapseVideoWriter?
    
    private var height = 0
    private var width = 0
    
    private let recordingQueue = dispatch_queue_create("com.takecian.RecordingQueue", DISPATCH_QUEUE_SERIAL)

    private var currentSkipCount = 0
    private var lasttimeStamp = CMTimeMake(0, 0)
    
    private var filePath: String {
        get {
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let documentsDirectory = paths[0] as String
            let filePath : String = "\(documentsDirectory)/video.mov"
            return filePath
        }
    }
    
    private var filePathUrl: NSURL {
        get {
            return NSURL(fileURLWithPath: filePath)
        }
    }
    
    func startup(){
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30)

        do
        {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice) as AVCaptureDeviceInput
            captureSession.addInput(videoInput)
        }
        catch let error as NSError {
            Logger.log(error.localizedDescription)
        }

        do
        {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice) as AVCaptureDeviceInput
            captureSession.addInput(audioInput)
        }
        catch let error as NSError {
            Logger.log(error.localizedDescription)
        }
        
        
        // video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        captureSession.addOutput(videoDataOutput)
        captureSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720
        
        height = videoDataOutput.videoSettings["Height"] as! Int!
        width = videoDataOutput.videoSettings["Width"] as! Int!
        
        // audio output
        let audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        captureSession.addOutput(audioDataOutput)
     
        captureSession.startRunning()
    }
    
    func shutdown(){
        captureSession.stopRunning()
    }

    func start(){
        if !isCapturing{
            Logger.log("in")
            isCapturing = true
        }
    }
    
    func stop(){
        if isCapturing{
            isCapturing = false
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                Logger.log("in")
                self.videoWriter!.finish { () -> Void in
                    Logger.log("Recording finished.")
                    self.videoWriter = nil
                    let assetsLib = ALAssetsLibrary()
                    assetsLib.writeVideoAtPathToSavedPhotosAlbum(self.filePathUrl, completionBlock: {
                        (nsurl, error) -> Void in
                        Logger.log("Transfer video to library finished.")
                    })
                }
            })
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        guard isCapturing else { return }
        
        let isVideo = captureOutput is AVCaptureVideoDataOutput
            
        if videoWriter == nil && !isVideo {
            let fileManager = NSFileManager()
            if fileManager.fileExistsAtPath(filePath) {
                do {
                    try fileManager.removeItemAtPath(filePath)
                } catch _ {
                }
            }
            
            let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt!)
            
            Logger.log("setup writer")
            videoWriter = TimeLapseVideoWriter(
                fileUrl: filePathUrl,
                height: height, width: width,
                channels: Int(asbd.memory.mChannelsPerFrame),
                samples: asbd.memory.mSampleRate
            )
        }
        
        if !isVideo {
            return
        }
        
        currentSkipCount += 1
        guard currentSkipCount == skipFrameSize else { return }
        currentSkipCount = 0
        
        var buffer = sampleBuffer
        if lasttimeStamp.value == 0 {
            lasttimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        } else {
            lasttimeStamp = CMTimeAdd(lasttimeStamp, CMTimeMake(1, 30))
            buffer = setTimeStamp(sampleBuffer, newTime: lasttimeStamp)
        }
        Logger.log("write")
        videoWriter?.write(buffer, isVideo: isVideo)
    }
    
    private func setTimeStamp(sample: CMSampleBufferRef, newTime: CMTime) -> CMSampleBufferRef {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
        var info = [CMSampleTimingInfo](count: count, repeatedValue: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)))
        CMSampleBufferGetSampleTimingInfoArray(sample, count, &info, &count);
        
        for i in 0..<count {
            info[i].decodeTimeStamp = newTime
            info[i].presentationTimeStamp = newTime
        }
        
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, &info, &out);
        return out!
    }
}
