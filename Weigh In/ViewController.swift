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

    @IBOutlet weak var unitField: UISegmentedControl!
    @IBOutlet weak var weightField: UITextField!
    
    func defaults() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    override func viewDidLoad() {
        var savedUnit: Int? = defaults().integerForKey("defaultUnit")
        if (savedUnit == nil) {
            savedUnit = 0 // meta-default
        }
        unitField.selectedSegmentIndex = savedUnit!
        super.viewDidLoad()
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
    
    @IBAction func weightValueChanged(sender: AnyObject) {
        if (weightValue().rangeOfString("^\\d\\d\\d?\\.\\d", options: .RegularExpressionSearch) != nil) {
            NSLog(weightValue() )
            self.view.endEditing(true)
        }
    }
    
    @IBAction func unitValueChanged(sender: AnyObject) {
        defaults().setInteger(unitIndex(), forKey: "defaultUnit")
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
            
            // TODO factor out to base class
            let quantity = HKQuantity(unit: self.unitValue(), doubleValue: (self.weightValue() as NSString).doubleValue)
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

