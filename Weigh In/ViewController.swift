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
        bodyMassType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        types = [bodyMassType]
        super.init(coder: aDecoder)
    }
    
    @IBOutlet weak var lastWeightLabel: UILabel!
    @IBOutlet weak var unitField: UISegmentedControl!
    @IBOutlet weak var weightField: UITextField!
    
    func defaults() -> UserDefaults {
        return UserDefaults.standard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // verify healthkit
        if (!HKHealthStore.isHealthDataAvailable()) {
            NSLog("No HealthKit on this device")
            return // TODO alert
        }
        
        // set units to saved preference
        let savedUnit: Int? = defaults().integer(forKey: defaultUnitKey)
        if (savedUnit != nil) {
            unitField.selectedSegmentIndex = savedUnit!
        }
        
        // display last weight
        self.store.requestAuthorization(toShare: types, read: types) { (authSuccess: Bool, authError: NSError?) -> Void in
            if (authSuccess) {
                let lastWeightQuery = HKSampleQuery(sampleType: self.bodyMassType, predicate: nil, limit: 1, sortDescriptors: [SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)], resultsHandler: { (query: HKSampleQuery, optionalSamples: [HKSample]?, queryError: NSError?) -> Void in
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
                    let quantityInDefaultUnit = quantity.doubleValue(for: self.unitValue())
                    
                    let date = sample.startDate as NSDate
                    
                    DispatchQueue.main.async { [unowned self] in
                        self.lastWeightLabel.text = "Last weigh in: \(String(quantityInDefaultUnit)) \(self.unitValue().unitString), \(date.timeAgoSinceNow())"
                    }
                })
                
                self.store.execute(lastWeightQuery)
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
            return HKUnit.pound()
        } else if (unitIndex() == 1) {
            return HKUnit.gramUnit(with: HKMetricPrefix.kilo)
        } else {
            assert(false, "Invalid unit");
        }
    }
    
    func weightQuantity() -> HKQuantity {
        return HKQuantity(unit: unitValue(), doubleValue: (weightValue() as NSString).doubleValue)
    }
    
    @IBAction func weightValueChanged(_ sender: AnyObject) {
        if (weightValue().range(of: "^\\d\\d\\d?\\.\\d", options: .regularExpressionSearch) != nil) {
            NSLog(weightValue())
            self.view.endEditing(true)
        }
    }
    
    @IBAction func unitValueChanged(_ sender: AnyObject) {
        defaults().set(unitIndex(), forKey: defaultUnitKey)
    }
    
    @IBAction func recordWeight(_ sender: AnyObject) {
        if (weightField.text == nil) {
            NSLog("No weight recorded")
            return
        }

        let now = Date()
        
        self.store.requestAuthorization(toShare: types, read: types) { (authSuccess: Bool, authError: NSError?) -> Void in
            if (authSuccess) {
                let sample = HKQuantitySample(type: self.bodyMassType, quantity: self.weightQuantity(), start: now, end: now)
                self.store.save(sample, withCompletion: { (saveSuccess: Bool, saveError: NSError?) -> Void in
                    if (saveSuccess) {
                        NSLog("saved data!")
                        DispatchQueue.main.async { [unowned self] in
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

