//
//  ViewController.swift
//  recordings
//
//  Created by Fujiki Takeshi on 5/12/16.
//  Copyright © 2016 takecian. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableview.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let path = tableview.indexPathForSelectedRow {
            tableview.deselectRowAtIndexPath(path, animated: true)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCellWithIdentifier("Cell")!
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Timelapse"
        case 1:
            cell.textLabel?.text = "Slow motion"
        default:
            cell.textLabel?.text = "Vine style"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.row {
        case 0:
            let vc = TimelapseViewController()
            presentViewController(vc, animated: true, completion: nil)
        case 1:
            let vc = SlowViewController()
            presentViewController(vc, animated: true, completion: nil)
        default:
            let vc = VineViewController()
            presentViewController(vc, animated: true, completion: nil)
        }
    }
}