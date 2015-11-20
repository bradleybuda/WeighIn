//
//  ViewController.swift
//  Weigh In
//
//  Created by Bradley Buda on 11/16/15.
//  Copyright © 2015 Bradley Buda. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var weightField: UITextField!
    
    @IBAction func weightValueChanged(sender: AnyObject) {
        if (weightField.text != nil) {
            NSLog(weightField.text!);
        }
    }
    
    @IBAction func recordWeight(sender: AnyObject) {
        NSLog("Hello!");
        if (weightField.text != nil) {
            NSLog(weightField.text!)
        }
    }
}

