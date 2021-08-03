//
//  ViewController.swift
//  GMAutoTool
//
//  Created by Yoon on 2021/7/23.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var prjectPathTextFiled: NSTextField!
    @IBOutlet var imagePathTextFiled: NSTextField!

    @IBOutlet var logTextView: NSTextView!
    @IBOutlet var targetPopupItems: NSPopUpButton!
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet var targetCnName: NSTextField!
    @IBOutlet var targetEnName: NSTextField!
    @IBOutlet var colorTextFiled: NSTextField!
    @IBOutlet var appIdTextFiled: NSTextField!
    @IBOutlet var baiduIdTextField: NSTextField!
    @IBOutlet var companyInfoTextField: NSTextField!

    var projectProperty: ProjVariable = ProjVariable()
    let projTools: ReProjTools = ReProjTools()
    var logString: String = "------开始冠名------\n"

    override func viewDidLoad() {
        super.viewDidLoad()
        projTools.logBlock = { str in
            self.logString = self.logString + str
            self.showLogInView()
        }
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

    func duplicateTarget() {
        if let target = projectProperty.newEnNameTarget, target.isEmpty {
            showAlert("请填写Target的英文拼写")
            return
        }
        logString = logString + "开始Copy  \(projectProperty.sourceNameTarget.or(""))"
        showLogInView()
        projTools.execDuplicteTarget(projectProperty)
    }

    // MARK: - Actions

    @IBAction func onActionProjectChoose(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.begin { [weak self] (result) -> Void in
            guard let self = self else { return }
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = openPanel.url else { return }
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
            guard let self = self else { return }
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = openPanel.url else { return }
                self.projectProperty.imagePath = url.path
                self.imagePathTextFiled.stringValue = url.path
            }
        }
    }

    @IBAction func onActionGMAutoTool(_ sender: NSButton) {
        projectProperty.newEnNameTarget = targetEnName.stringValue
        projectProperty.sourceNameTarget = targetPopupItems.selectedItem?.title
        projectProperty.newCnNameTarget = targetCnName.stringValue
        projectProperty.mainColor = colorTextFiled.stringValue
        projectProperty.appID = appIdTextFiled.stringValue
        projectProperty.baiduSkdId = baiduIdTextField.stringValue
        projectProperty.companyInfo = companyInfoTextField.stringValue

        if projectProperty.projectPath.isNone {
            showAlert("请选择项目路径")
            return
        }
        if projectProperty.imagePath.isNone {
            showAlert("请选择图片素材路径")
            return
        }
        if projectProperty.sourceNameTarget.isNone {
            showAlert("请选择要复制的target")
            return
        }
        if projectProperty.newCnNameTarget.or("").count == 0 {
            showAlert("请填写应用名称")
            return
        }
        if projectProperty.newEnNameTarget.or("").count == 0 {
            showAlert("请填写target名称,eg:\(projectProperty.sourceNameTarget.or("DaiShu"))")
            return
        }
        if targetPopupItems.itemTitles.contains(projectProperty.newEnNameTarget.or("")) {
            showAlert("不能添加重复的冠名")
            return
        }
        if projectProperty.mainColor.or("").count == 0 {
            showAlert("请填写十六进制mainColor,eg:000000")
            return
        }
        if projectProperty.mainColor?.count != 6 {
            showAlert("请填写6位mainColor,eg:000000")
            return
        }
        if projectProperty.appID.or("").count == 0 {
            showAlert("请填写App id,eg:702222")
            return
        }
        if projectProperty.appID?.count != 6 {
            showAlert("请填写6位appID,eg:702222")
            return
        }
        if projectProperty.baiduSkdId.or("").count == 0 {
            showAlert("请填写百度地图sdk id")
            return
        }
        if projectProperty.companyInfo.or("").count == 0 {
            showAlert("请填写公司简介")
            return
        }
        beginCrown()
    }

    func beginCrown() {
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "exec_queue")

        group.enter()
        serialQueue.async {
            self.duplicateTarget()
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.remResourceFileRef(self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.copySource(self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.addGroupFileReference(vable: self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.modifyInfoSettings(self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.modifyInfoPlistFile(self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.modifyColorPlistFile(self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.replaceImages(self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.reChooseLaunchStoryBoard(self.projectProperty)
            group.leave()
        }
        group.enter()
        serialQueue.async {
            self.projTools.execCocoaPods(self.projectProperty)
            self.logString.append("------冠名结束------\n")
            group.leave()
            
        }
    }

    func showLogInView() {
        logString.append("\n")
        DispatchQueue.main.async {
            self.logTextView.string = self.logString
            self.scrollView.scrollToBottom()
        }
    }

    func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
