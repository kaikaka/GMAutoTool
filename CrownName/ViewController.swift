//
//  ViewController.swift
//  CrownName
//
//  Created by Yoon on 2021/7/23.
//

import Cocoa
import XcodeProj

class ViewController: NSViewController {

    @IBOutlet weak var prjectPathTextFiled: NSTextField!
    @IBOutlet weak var imagePathTextFiled: NSTextField!
    
    @IBOutlet var logTextView: NSTextView!
    @IBOutlet weak var targetPopupItems: NSPopUpButton!
    
    @IBOutlet weak var targetCnName: NSTextField!
    @IBOutlet weak var targetEnName: NSTextField!
    @IBOutlet weak var buildIdTextFiled: NSTextField!
    @IBOutlet weak var colorTextFiled: NSTextField!
    @IBOutlet weak var appIdTextFiled: NSTextField!
    @IBOutlet weak var baiduIdTextField: NSTextField!
    @IBOutlet weak var companyInfoTextField: NSTextField!
    
    var projectProperty:ProjVariable = ProjVariable.init()
    let projTools:ReProjTools = ReProjTools()
    var logString:String = "------开始冠名------\n"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: - Tool Methods
    
    func assionToTarget() {
        targetPopupItems.removeAllItems()
        let targets = projTools.readTargets(projectProperty.projectTruePath)
        targetPopupItems.addItems(withTitles: targets)
    }
    
    func duplicateTarget(dupBlock:(Bool) -> ()) {
        if let target = self.projectProperty.newEnNameTarget , target.isEmpty {
            self.showAlert("请填写Target的英文拼写")
            return
        }
        self.logString = self.logString + "开始Copy  \(self.projectProperty.sourceNameTarget.or("")) \n"
        self.projTools.execDuplicteTarget(self.projectProperty, execHander: dupBlock)
//        if isSuccess {
//            logString = logString + "Copy 成功!\n"
//        } else {
//            logString = logString + "Copy 失败!\n"
//        }
//        self.logTextView.string = self.logString
    }
    
    
    // MARK: - Actions
    
    @IBAction func onActionProjectChoose(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.begin { [weak self] (result) -> Void in
            guard let self = self else { return}
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = openPanel.url else { return  }
                self.projectProperty.projectPath = url.path
                let truePath = url.path + "/" + self.projectProperty.projectName + ".xcodeproj"
                self.prjectPathTextFiled.stringValue = truePath
                self.projectProperty.projectTruePath = truePath
                
                self.logString.append("\(self.projectProperty.projectPath.or("")) \n")
                self.logString.append("读取项目路径成功！\n")
                self.logTextView.string = self.logString
                self.assionToTarget()
            }
        }
    }
    
    @IBAction func onActionImages(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.begin { [weak self] (result) -> Void in
            guard let self = self else { return}
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = openPanel.url else { return  }
                self.projectProperty.imagePath = url.path
                self.imagePathTextFiled.stringValue = url.path
            }
        }
    }
    
    
    @IBAction func onActionCrownName(_ sender: NSButton) {
        if projectProperty.projectPath.isNone {
            self.showAlert("请选择项目路径")
            return
        }
        self.projectProperty.newEnNameTarget = self.targetEnName.stringValue
        self.projectProperty.sourceNameTarget = self.targetPopupItems.selectedItem?.title
        self.projectProperty.newCnNameTarget = targetCnName.stringValue
        self.projectProperty.buildId = buildIdTextFiled.stringValue
        self.projectProperty.mainColor = colorTextFiled.stringValue
        self.projectProperty.appID = appIdTextFiled.stringValue
        self.projectProperty.baiduSkdId = baiduIdTextField.stringValue
        self.projectProperty.companyInfo = companyInfoTextField.stringValue
        
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "exec_queue")

//        group.enter()
//        serialQueue.async {
//            self.duplicateTarget { suc in
//                if suc {
//                    print("11111")
//                    group.leave()
//                }
//            }
//        }
//        group.enter()
//        serialQueue.async {
//            self.projTools.copySource(self.projectProperty)
//
//            self.projTools.deleteTargetFileReference(self.projectProperty) { suc in
//                if suc {
//                    print("22222")
//                    group.leave()
//                }
//            }
//        }
//                group.enter()
//                serialQueue.async {
//                    self.projTools.remResourceFileRef(self.projectProperty) { suc in
//                        if suc {
//                            print("44444")
//                            group.leave()
//                        }
//                    }
//                }

//        group.enter()
//        serialQueue.async {
//            self.projTools.addGroupFileReference(vable: self.projectProperty) { suc in
//                if suc {
//                    print("3333")
//                    group.leave()
//                }
//            }
//        }
        
//        group.enter()
//        serialQueue.async {
//            self.projTools.modifyInfoSettings(self.projectProperty) { suc in
//                if suc {
//                    print("66666")
//                    group.leave()
//                }
//            }
//        }
//        self.projTools.modifyInfoPlistFile(self.projectProperty)
//        self.projTools.modifyColorPlistFile(self.projectProperty)
//        self.projTools.replaceImages(self.projectProperty)
        self.projTools.reChooseLaunchStoryBoard(self.projectProperty)
//        group.notify(queue: DispatchQueue.main) {
//            print("55555")
//        }
        
//        projTools.modifyTargetSettings(projectProperty)
//        guard let xcodeproj = try? XcodeProj(pathString: projectProperty.projectTruePath) else { return  }
//        projTools.deleteTargetFileReference(xcodeproj, targetName: projectProperty.newEnNameTarget.or(""))
//
//        projTools.copySource(projectProperty)
//        projTools.addGroupFileReference(vable:projectProperty)
//
//        projTools.addResourceFileRef(xcodeproj, vable: projectProperty)

        

    }
    
    
    func showAlert(_ message:String) {
        let alert = NSAlert.init()
        alert.messageText = message
        alert.runModal()
    }
    
}

