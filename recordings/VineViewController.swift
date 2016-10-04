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
        videoLayer?.frame = view.bounds
        videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(videoLayer!)
        
        setupButton()
    }
    
    func setupButton(){
        startButton = UIButton(frame: CGRect(x: 0,y: 0,width: 60,height: 50))
        startButton.backgroundColor = UIColor.red
        startButton.layer.masksToBounds = true
        startButton.setTitle("start", for: UIControlState())
        startButton.layer.cornerRadius = 20.0
        startButton.layer.position = CGPoint(x: view.bounds.width/5, y:view.bounds.height-50)
        startButton.addTarget(self, action: #selector(VineViewController.onClickStartButton(_:)), for: .touchUpInside)
        
        stopButton = UIButton(frame: CGRect(x: 0,y: 0,width: 60,height: 50))
        stopButton.backgroundColor = UIColor.gray
        stopButton.layer.masksToBounds = true
        stopButton.setTitle("stop", for: UIControlState())
        stopButton.layer.cornerRadius = 20.0
        stopButton.layer.position = CGPoint(x: view.bounds.width/5 * 2, y:view.bounds.height-50)
        stopButton.addTarget(self, action: #selector(VineViewController.onClickStopButton(_:)), for: .touchUpInside)
        
        pauseResumeButton = UIButton(frame: CGRect(x: 0,y: 0,width: 60,height: 50))
        pauseResumeButton.backgroundColor = UIColor.gray
        pauseResumeButton.layer.masksToBounds = true
        pauseResumeButton.setTitle("pause", for: UIControlState())
        pauseResumeButton.layer.cornerRadius = 20.0
        pauseResumeButton.layer.position = CGPoint(x: view.bounds.width/5 * 3, y:view.bounds.height-50)
        pauseResumeButton.addTarget(self, action: #selector(VineViewController.onClickPauseButton(_:)), for: .touchUpInside)
        
        backButton = UIButton(frame: CGRect(x: 20, y: 50, width: 60, height: 50))
        backButton.backgroundColor = UIColor.gray
        backButton.layer.masksToBounds = true
        backButton.setTitle("back", for: UIControlState())
        backButton.layer.cornerRadius = 20.0
        backButton.addTarget(self, action: #selector(VineViewController.onClickBackButton(_:)), for: .touchUpInside)

        view.addSubview(startButton)
        view.addSubview(stopButton);
        view.addSubview(pauseResumeButton);
        view.addSubview(backButton);
    }
    
    func onClickStartButton(_ sender: UIButton){
        if !cameraEngine.isCapturing {
            cameraEngine.start()
            changeButtonColor(startButton, color: UIColor.gray)
            changeButtonColor(stopButton, color: UIColor.red)
        }
    }
    
    func onClickPauseButton(_ sender: UIButton){
        if cameraEngine.isCapturing {
            if cameraEngine.isPaused {
                cameraEngine.resume()
                pauseResumeButton.setTitle("pause", for: UIControlState())
                pauseResumeButton.backgroundColor = UIColor.gray
            }else{
                cameraEngine.pause()
                pauseResumeButton.setTitle("resume", for: UIControlState())
                pauseResumeButton.backgroundColor = UIColor.blue
            }
        }
    }
    
    func onClickStopButton(_ sender: UIButton){
        if cameraEngine.isCapturing {
            cameraEngine.stop()
            changeButtonColor(startButton, color: UIColor.red)
            changeButtonColor(stopButton, color: UIColor.gray)
        }
    }
    
    func onClickBackButton(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    func changeButtonColor(_ target: UIButton, color: UIColor){
        target.backgroundColor = color
    }}

