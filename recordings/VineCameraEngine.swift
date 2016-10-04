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

class VineCameraEngine : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{

    class VineVideoWriter : NSObject {
        var fileWriter: AVAssetWriter!
        var videoInput: AVAssetWriterInput!
        var audioInput: AVAssetWriterInput!
        
        init(fileUrl:URL!, height:Int, width:Int, channels:Int, samples:Float64){
            fileWriter = try? AVAssetWriter(outputURL: fileUrl, fileType: AVFileTypeQuickTimeMovie)
            
            let videoOutputSettings: Dictionary<String, AnyObject> = [
                AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
                AVVideoWidthKey : width as AnyObject,
                AVVideoHeightKey : height as AnyObject
            ]
            videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            videoInput.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI)/2)
            fileWriter.add(videoInput)
            
            let audioOutputSettings: Dictionary<String, AnyObject> = [
                AVFormatIDKey : Int(kAudioFormatMPEG4AAC) as AnyObject,
                AVNumberOfChannelsKey : channels as AnyObject,
                AVSampleRateKey : samples as AnyObject,
                AVEncoderBitRateKey : 128000 as AnyObject
            ]
            audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
            audioInput.expectsMediaDataInRealTime = true
            fileWriter.add(audioInput)
        }
        
        func write(_ sample: CMSampleBuffer, isVideo: Bool){
            if CMSampleBufferDataIsReady(sample) {
                if fileWriter.status == AVAssetWriterStatus.unknown {
                    Logger.log("Start writing, isVideo = \(isVideo), status = \(fileWriter.status.rawValue)")
                    let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                    fileWriter.startWriting()
                    fileWriter.startSession(atSourceTime: startTime)
                }
                if fileWriter.status == AVAssetWriterStatus.failed {
                    Logger.log("Error occured, isVideo = \(isVideo), status = \(fileWriter.status.rawValue), \(fileWriter.error!.localizedDescription)")
                    return
                }
                if isVideo {
                    if videoInput.isReadyForMoreMediaData {
                        videoInput.append(sample)
                    }
                }else{
                    if audioInput.isReadyForMoreMediaData {
                        audioInput.append(sample)
                    }
                }
            }
        }
        
        func finish(_ callback: @escaping (Void) -> Void){
            fileWriter.finishWriting(completionHandler: callback)
        }
    }

    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    var videoWriter : VineVideoWriter?

    var height:Int?
    var width:Int?
    
    var isCapturing = false
    var isPaused = false
    var isDiscontinue = false
    var fileIndex = 0
    
    var timeOffset = CMTimeMake(0, 0)
    var lastAudioPts: CMTime?

    let lockQueue = DispatchQueue(label: "com.takecian.LockQueue", attributes: [])
    let recordingQueue = DispatchQueue(label: "com.takecian.RecordingQueue", attributes: [])

    func startup(){
        // video input
        videoDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        
      
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
            kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        captureSession.addOutput(videoDataOutput)
        
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
        lockQueue.sync {
            if !self.isCapturing{
                Logger.log("in")
                self.isPaused = false
                self.isDiscontinue = false
                self.isCapturing = true
                self.timeOffset = CMTimeMake(0, 0)
            }
        }
    }
    
    func stop(){
        self.lockQueue.sync {
            if self.isCapturing{
                self.isCapturing = false
                DispatchQueue.main.async(execute: { () -> Void in
                    Logger.log("in")
                    self.videoWriter!.finish { () -> Void in
                        Logger.log("Recording finished.")
                        self.videoWriter = nil
                        let assetsLib = ALAssetsLibrary()
                        assetsLib.writeVideoAtPath(toSavedPhotosAlbum: self.filePathUrl(), completionBlock: {
                            (nsurl, error) -> Void in
                            Logger.log("Transfer video to library finished.")
                            self.fileIndex += 1
                        })
                    }
                })
            }
        }
    }
    
    func pause(){
        self.lockQueue.sync {
            if self.isCapturing{
                Logger.log("in")
                self.isPaused = true
                self.isDiscontinue = true
            }
        }
    }
    
    func resume(){
        self.lockQueue.sync {
            if self.isCapturing{
                Logger.log("in")
                self.isPaused = false
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!){
        self.lockQueue.sync {
            if !self.isCapturing || self.isPaused {
                return
            }
            
            let isVideo = captureOutput is AVCaptureVideoDataOutput
            
            if self.videoWriter == nil && !isVideo {
                let fileManager = FileManager()
                if fileManager.fileExists(atPath: self.filePath()) {
                    do {
                        try fileManager.removeItem(atPath: self.filePath())
                    } catch _ {
                    }
                }
                
                let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
                let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt!)
                
                Logger.log("setup video writer")
                self.videoWriter = VineVideoWriter(
                    fileUrl: self.filePathUrl(),
                    height: self.height!, width: self.width!,
                    channels: Int((asbd?.pointee.mChannelsPerFrame)!),
                    samples: (asbd?.pointee.mSampleRate)!
                )
            }
            
            if self.isDiscontinue {
                if isVideo {
                    return
                }

                var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

                let isAudioPtsValid = self.lastAudioPts!.flags.intersection(CMTimeFlags.valid)
                if isAudioPtsValid.rawValue != 0 {
                    Logger.log("isAudioPtsValid is valid")
                    let isTimeOffsetPtsValid = self.timeOffset.flags.intersection(CMTimeFlags.valid)
                    if isTimeOffsetPtsValid.rawValue != 0 {
                        Logger.log("isTimeOffsetPtsValid is valid")
                        pts = CMTimeSubtract(pts, self.timeOffset);
                    }
                    let offset = CMTimeSubtract(pts, self.lastAudioPts!);

                    if (self.timeOffset.value == 0)
                    {
                        Logger.log("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = offset;
                    }
                    else
                    {
                        Logger.log("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = CMTimeAdd(self.timeOffset, offset);
                    }
                }
                self.lastAudioPts!.flags = CMTimeFlags()
                self.isDiscontinue = false
            }
            
            var buffer = sampleBuffer
            if self.timeOffset.value > 0 {
                buffer = self.ajustTimeStamp(sampleBuffer, offset: self.timeOffset)
            }

            if !isVideo {
                var pts = CMSampleBufferGetPresentationTimeStamp(buffer!)
                let dur = CMSampleBufferGetDuration(buffer!)
                if (dur.value > 0)
                {
                    pts = CMTimeAdd(pts, dur)
                }
                self.lastAudioPts = pts
            }
            
            self.videoWriter?.write(buffer!, isVideo: isVideo)
        }
    }
    
    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/video\(self.fileIndex).mp4"
        return filePath
    }
    
    func filePathUrl() -> URL! {
        return URL(fileURLWithPath: self.filePath())
    }
    
    func ajustTimeStamp(_ sample: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, count, &info, &count);

        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }

        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, &info, &out);
        return out!
    }
}
