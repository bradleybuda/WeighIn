//
//  ViewController.swift
//  Weigh In
//
//  Created by Bradley Buda on 11/16/15.
//  Copyright © 2015 Bradley Buda. All rights reserved.
//

import UIKit
import HealthKit
import DateTools

class ViewController: UIViewController {

    let defaultUnitKey = "defaultUnit"
    var store: HKHealthStore
    var bodyMassType: HKQuantityType
    var types: Set<HKQuantityType>
    
    required init?(coder aDecoder: NSCoder) {
        store = HKHealthStore.init()
        bodyMassType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
        types = [bodyMassType]
        super.init(coder: aDecoder)
    }
    
    @IBOutlet weak var lastWeightLabel: UILabel!
    @IBOutlet weak var unitField: UISegmentedControl!
    @IBOutlet weak var weightField: UITextField!
    
    func defaults() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // verify healthkit
        if (!HKHealthStore.isHealthDataAvailable()) {
            NSLog("No HealthKit on this device")
            return // TODO alert
        }
        
        // set units to saved preference
        let savedUnit: Int? = defaults().integerForKey(defaultUnitKey)
        if (savedUnit != nil) {
            unitField.selectedSegmentIndex = savedUnit!
        }
        
        // display last weight
        self.store.requestAuthorizationToShareTypes(types, readTypes: types) { (authSuccess: Bool, authError: NSError?) -> Void in
            if (authSuccess) {
                let lastWeightQuery = HKSampleQuery(sampleType: self.bodyMassType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)], resultsHandler: { (query: HKSampleQuery, optionalSamples: [HKSample]?, queryError: NSError?) -> Void in
                    // TODO check queryError
                    
                    guard let samples = optionalSamples else {
                        NSLog("Don't think this is supposed to happen...")
                        return
                    }
                    
                    guard let sample = samples.first as? HKQuantitySample else {
                        NSLog("No historic data")
                        return
                    }
                    
                    let quantity = sample.quantity
                    // TODO handle no data
                    // TODO change if defaultUnit changes
                    // TODO update after weighing in
                    let quantityInDefaultUnit = quantity.doubleValueForUnit(self.unitValue())
                    
                    dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                        self.lastWeightLabel.text = "Last weigh in: \(String(quantityInDefaultUnit)) \(self.unitValue().unitString), \(sample.startDate.timeAgoSinceNow())"
                    }
                })
                
                self.store.executeQuery(lastWeightQuery)
            } else {
                NSLog("Call to requestAuthorizationToShareTypes failed with error")
                NSLog("%@", authError!)
            }
        }
        
        // pop the keyboard
        weightField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        // store?
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

        let now = NSDate()
        
        self.store.requestAuthorizationToShareTypes(types, readTypes: types) { (authSuccess: Bool, authError: NSError?) -> Void in
            if (authSuccess) {
                let sample = HKQuantitySample(type: self.bodyMassType, quantity: self.weightQuantity(), startDate: now, endDate: now)
                self.store.saveObject(sample, withCompletion: { (saveSuccess: Bool, saveError: NSError?) -> Void in
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

