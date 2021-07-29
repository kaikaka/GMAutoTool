//
//  ViewController.swift
//  CrownName
//
//  Created by Yoon on 2021/7/23.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let read = FilesRead()
//        read.readProject()
        let path = "/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone.xcodeproj"
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            let target = TargetChanged()
//            target.duplicateTarget()
//            target.newTargetInfoChanged(path)
//            target.copySource()
            target.addNewGroup(path)
//            target.addNewFileReference(path)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

