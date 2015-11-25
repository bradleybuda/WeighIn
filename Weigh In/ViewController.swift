//
//  ViewController.swift
//  Weigh In
//
//  Created by Bradley Buda on 11/16/15.
//  Copyright © 2015 Bradley Buda. All rights reserved.
//

import UIKit
import HealthKit

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
    
    func weightValue() -> String {
        return weightField.text!
    }
    
    @IBAction func weightValueChanged(sender: AnyObject) {
        if (weightValue().rangeOfString("^\\d\\d\\d?\\.\\d", options: .RegularExpressionSearch) != nil) {
            NSLog(weightValue() )
            self.view.endEditing(true)
        }
    }
    
    @IBAction func recordWeight(sender: AnyObject) {
        if (weightField.text == nil) {
            NSLog("No weight recorded")
            return
        }
        
        if (!HKHealthStore.isHealthDataAvailable()) {
            NSLog("No HealthKit on this device")
            return
        }
        
        let store = HKHealthStore.init();
        let types: Set<HKQuantityType> = [HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!]
        store.requestAuthorizationToShareTypes(types, readTypes: types) { (b: Bool, e: NSError?) -> Void in
            let objType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
            let quantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: (self.weightValue() as NSString).doubleValue)
            let sample = HKQuantitySample(type: objType, quantity: quantity, startDate: NSDate(), endDate: NSDate())
            store.saveObject(sample, withCompletion: { (b: Bool, e: NSError?) -> Void in
                NSLog("saved data!")
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.weightField.text = nil
                }
            })
        }
    }
}

