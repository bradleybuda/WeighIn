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

    let defaultUnitKey = "defaultUnit"
    
    @IBOutlet weak var unitField: UISegmentedControl!
    @IBOutlet weak var weightField: UITextField!
    
    func defaults() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set units to saved preference
        let savedUnit: Int? = defaults().integerForKey(defaultUnitKey)
        if (savedUnit != nil) {
            unitField.selectedSegmentIndex = savedUnit!
        }
        
        // pop the keyboard
        weightField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func weightValue() -> String {
        return weightField.text!
    }
    
    func unitIndex() -> Int {
        return unitField.selectedSegmentIndex
    }
    
    func unitValue() -> HKUnit {
        if (unitIndex() == 0) {
            return HKUnit.poundUnit()
        } else if (unitIndex() == 1) {
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo)
        } else {
            assert(false, "Invalid unit");
        }
    }
    
    func weightQuantity() -> HKQuantity {
        return HKQuantity(unit: unitValue(), doubleValue: (weightValue() as NSString).doubleValue)
    }
    
    @IBAction func weightValueChanged(sender: AnyObject) {
        if (weightValue().rangeOfString("^\\d\\d\\d?\\.\\d", options: .RegularExpressionSearch) != nil) {
            NSLog(weightValue())
            self.view.endEditing(true)
        }
    }
    
    @IBAction func unitValueChanged(sender: AnyObject) {
        defaults().setInteger(unitIndex(), forKey: defaultUnitKey)
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

        let now = NSDate()
        let store = HKHealthStore.init();
        let types: Set<HKQuantityType> = [HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!]
        store.requestAuthorizationToShareTypes(types, readTypes: types) { (authSuccess: Bool, authError: NSError?) -> Void in
            if (authSuccess) {
                let bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
                let sample = HKQuantitySample(type: bodyMassType, quantity: self.weightQuantity(), startDate: now, endDate: now)
                store.saveObject(sample, withCompletion: { (saveSuccess: Bool, saveError: NSError?) -> Void in
                    if (saveSuccess) {
                        NSLog("saved data!")
                        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                            self.weightField.text = nil
                        }
                    } else {
                        NSLog("Call to saveObject failed with error")
                        NSLog("%@", saveError!)
                    }
                })
            } else {
                NSLog("Call to requestAuthorizationToShareTypes failed with error")
                NSLog("%@", authError!)
            }
        }
    }
}

