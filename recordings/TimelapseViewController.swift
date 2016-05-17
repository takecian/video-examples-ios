//
//  TimelapseViewController.swift
//  recordings
//
//  Created by Fujiki Takeshi on 5/12/16.
//  Copyright © 2016 takecian. All rights reserved.
//

import UIKit
import AVFoundation

class TimelapseViewController: UIViewController {

    var startButton, stopButton, backButton: UIButton!
    var isRecording = false
    let cameraEngine = TimelapseCameraEngine()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        cameraEngine.startup()
        let videoLayer = AVCaptureVideoPreviewLayer(session: cameraEngine.captureSession)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(videoLayer)
        
        setupButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    func setupButton(){
        startButton = UIButton(frame: CGRectMake(20, view.bounds.height - 70, 60 ,50))
        startButton.backgroundColor = UIColor.redColor()
        startButton.layer.masksToBounds = true
        startButton.setTitle("start", forState: .Normal)
        startButton.layer.cornerRadius = 20.0
        startButton.addTarget(self, action: #selector(TimelapseViewController.onClickStartButton(_:)), forControlEvents: .TouchUpInside)
        
        stopButton = UIButton(frame: CGRectMake(100, view.bounds.height - 70, 60, 50))
        stopButton.backgroundColor = UIColor.grayColor()
        stopButton.layer.masksToBounds = true
        stopButton.setTitle("stop", forState: .Normal)
        stopButton.layer.cornerRadius = 20.0
        stopButton.addTarget(self, action: #selector(TimelapseViewController.onClickStopButton(_:)), forControlEvents: .TouchUpInside)
        
        backButton = UIButton(frame: CGRectMake(20, 50, 60, 50))
        backButton.backgroundColor = UIColor.grayColor()
        backButton.layer.masksToBounds = true
        backButton.setTitle("back", forState: .Normal)
        backButton.layer.cornerRadius = 20.0
        backButton.addTarget(self, action: #selector(TimelapseViewController.onClickBackButton(_:)), forControlEvents: .TouchUpInside)
        
        view.addSubview(startButton)
        view.addSubview(stopButton);
        view.addSubview(backButton);
    }
    
    func onClickStartButton(sender: UIButton){
        if !cameraEngine.isCapturing {
            cameraEngine.start()
            changeButtonColor(startButton, color: UIColor.grayColor())
            changeButtonColor(stopButton, color: UIColor.redColor())
        }
    }
    
    func onClickBackButton(sender: UIButton){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onClickStopButton(sender: UIButton){
        if cameraEngine.isCapturing {
            cameraEngine.stop()
            changeButtonColor(startButton, color: UIColor.redColor())
            changeButtonColor(stopButton, color: UIColor.grayColor())
        }
    }
    
    func changeButtonColor(target: UIButton, color: UIColor){
        target.backgroundColor = color
    }
}
