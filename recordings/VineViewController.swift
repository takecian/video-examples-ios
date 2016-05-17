//
//  ViewController.swift
//  VineVideo
//
//  Created by FUJIKI TAKESHI on 2014/11/13.
//  Copyright (c) 2014年 Takeshi Fujiki. All rights reserved.
//

import UIKit
import AVFoundation

class VineViewController: UIViewController {

    var startButton, stopButton, pauseResumeButton, backButton: UIButton!
    var isRecording = false
    let cameraEngine = VineCameraEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraEngine.startup()
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: cameraEngine.captureSession)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(videoLayer)
        
        setupButton()
    }
    
    func setupButton(){
        startButton = UIButton(frame: CGRectMake(0,0,60,50))
        startButton.backgroundColor = UIColor.redColor()
        startButton.layer.masksToBounds = true
        startButton.setTitle("start", forState: .Normal)
        startButton.layer.cornerRadius = 20.0
        startButton.layer.position = CGPoint(x: view.bounds.width/5, y:view.bounds.height-50)
        startButton.addTarget(self, action: #selector(VineViewController.onClickStartButton(_:)), forControlEvents: .TouchUpInside)
        
        stopButton = UIButton(frame: CGRectMake(0,0,60,50))
        stopButton.backgroundColor = UIColor.grayColor()
        stopButton.layer.masksToBounds = true
        stopButton.setTitle("stop", forState: .Normal)
        stopButton.layer.cornerRadius = 20.0
        stopButton.layer.position = CGPoint(x: view.bounds.width/5 * 2, y:view.bounds.height-50)
        stopButton.addTarget(self, action: #selector(VineViewController.onClickStopButton(_:)), forControlEvents: .TouchUpInside)
        
        pauseResumeButton = UIButton(frame: CGRectMake(0,0,60,50))
        pauseResumeButton.backgroundColor = UIColor.grayColor()
        pauseResumeButton.layer.masksToBounds = true
        pauseResumeButton.setTitle("pause", forState: .Normal)
        pauseResumeButton.layer.cornerRadius = 20.0
        pauseResumeButton.layer.position = CGPoint(x: view.bounds.width/5 * 3, y:view.bounds.height-50)
        pauseResumeButton.addTarget(self, action: #selector(VineViewController.onClickPauseButton(_:)), forControlEvents: .TouchUpInside)
        
        backButton = UIButton(frame: CGRectMake(20, 50, 60, 50))
        backButton.backgroundColor = UIColor.grayColor()
        backButton.layer.masksToBounds = true
        backButton.setTitle("back", forState: .Normal)
        backButton.layer.cornerRadius = 20.0
        backButton.addTarget(self, action: #selector(VineViewController.onClickBackButton(_:)), forControlEvents: .TouchUpInside)

        view.addSubview(startButton)
        view.addSubview(stopButton);
        view.addSubview(pauseResumeButton);
        view.addSubview(backButton);
    }
    
    func onClickStartButton(sender: UIButton){
        if !cameraEngine.isCapturing {
            cameraEngine.start()
            changeButtonColor(startButton, color: UIColor.grayColor())
            changeButtonColor(stopButton, color: UIColor.redColor())
        }
    }
    
    func onClickPauseButton(sender: UIButton){
        if cameraEngine.isCapturing {
            if cameraEngine.isPaused {
                cameraEngine.resume()
                pauseResumeButton.setTitle("pause", forState: .Normal)
                pauseResumeButton.backgroundColor = UIColor.grayColor()
            }else{
                cameraEngine.pause()
                pauseResumeButton.setTitle("resume", forState: .Normal)
                pauseResumeButton.backgroundColor = UIColor.blueColor()
            }
        }
    }
    
    func onClickStopButton(sender: UIButton){
        if cameraEngine.isCapturing {
            cameraEngine.stop()
            changeButtonColor(startButton, color: UIColor.redColor())
            changeButtonColor(stopButton, color: UIColor.grayColor())
        }
    }
    
    func onClickBackButton(sender: UIButton){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func changeButtonColor(target: UIButton, color: UIColor){
        target.backgroundColor = color
    }}

