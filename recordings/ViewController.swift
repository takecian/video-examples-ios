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

        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let path = tableview.indexPathForSelectedRow {
            tableview.deselectRow(at: path, animated: true)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "Cell")!
        
        switch (indexPath as NSIndexPath).row {
        case 0:
            cell.textLabel?.text = "Timelapse"
        case 1:
            cell.textLabel?.text = "Slow motion"
        default:
            cell.textLabel?.text = "Vine style"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch (indexPath as NSIndexPath).row {
        case 0:
            let vc = TimelapseViewController()
            present(vc, animated: true, completion: nil)
        case 1:
            let vc = SlowViewController()
            present(vc, animated: true, completion: nil)
        default:
            let vc = VineViewController()
            present(vc, animated: true, completion: nil)
        }
    }
}
