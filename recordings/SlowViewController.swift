//
//  TimelapseViewController.swift
//  recordings
//
//  Created by Fujiki Takeshi on 5/12/16.
//  Copyright © 2016 takecian. All rights reserved.
//

import UIKit
import AVFoundation

class SlowViewController: UIViewController {

    var startButton, stopButton, backButton: UIButton!
    var isRecording = false
    let cameraEngine = SlowCameraEngine()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        cameraEngine.startup()
        let videoLayer = AVCaptureVideoPreviewLayer(session: cameraEngine.captureSession)
        videoLayer?.frame = view.bounds
        videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(videoLayer!)
        
        setupButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func setupButton(){
        startButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 70, width: 60 ,height: 50))
        startButton.backgroundColor = UIColor.red
        startButton.layer.masksToBounds = true
        startButton.setTitle("start", for: UIControlState())
        startButton.layer.cornerRadius = 20.0
        startButton.addTarget(self, action: #selector(TimelapseViewController.onClickStartButton(_:)), for: .touchUpInside)
        
        stopButton = UIButton(frame: CGRect(x: 100, y: view.bounds.height - 70, width: 60, height: 50))
        stopButton.backgroundColor = UIColor.gray
        stopButton.layer.masksToBounds = true
        stopButton.setTitle("stop", for: UIControlState())
        stopButton.layer.cornerRadius = 20.0
        stopButton.addTarget(self, action: #selector(TimelapseViewController.onClickStopButton(_:)), for: .touchUpInside)
        
        backButton = UIButton(frame: CGRect(x: 20, y: 50, width: 60, height: 50))
        backButton.backgroundColor = UIColor.gray
        backButton.layer.masksToBounds = true
        backButton.setTitle("back", for: UIControlState())
        backButton.layer.cornerRadius = 20.0
        backButton.addTarget(self, action: #selector(TimelapseViewController.onClickBackButton(_:)), for: .touchUpInside)
        
        view.addSubview(startButton)
        view.addSubview(stopButton);
        view.addSubview(backButton);
    }
    
    func onClickStartButton(_ sender: UIButton){
        if !cameraEngine.isCapturing {
            cameraEngine.start()
            changeButtonColor(startButton, color: UIColor.gray)
            changeButtonColor(stopButton, color: UIColor.red)
        }
    }
    
    func onClickBackButton(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    func onClickStopButton(_ sender: UIButton){
        if cameraEngine.isCapturing {
            cameraEngine.stop()
            changeButtonColor(startButton, color: UIColor.red)
            changeButtonColor(stopButton, color: UIColor.gray)
        }
    }
    
    func changeButtonColor(_ target: UIButton, color: UIColor){
        target.backgroundColor = color
    }
}
