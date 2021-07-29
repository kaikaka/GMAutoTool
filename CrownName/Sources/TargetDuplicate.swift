//
//  TargetDuplicate.swift
//  CrownName
//
//  Created by Yoon on 2021/7/27.
//

import Foundation
import PathKit
import XcodeProj
import Fuzi

class TargetChanged {
    /// 复制target
    func duplicateTarget() {
        // 1.读取脚本目录 path 脚本目录
        // 2.launchPath 要执行的脚本路径，ruby\/bin/ls
        let path = "/Users/Yoon/Desktop/CrownName/CrownName/Sources/duplicate_xcode_project_target.rb"
        let res = TargetChanged.shell(launchPath: "/usr/bin/ruby", arguments: [path])
        print("*** ls ***:\n\(res)")
        if res.1 == 0 {
            print("Duplicate Success")
        }
    }

    /// 修改build id name 等，path是项目路径
    func newTargetInfoChanged(_ path: String) {
        guard let xcodeproj = try? XcodeProj(pathString: path) else { return }
        var target: PBXNativeTarget!
        for item in xcodeproj.pbxproj.nativeTargets {
            if item.name == "GuanMing" {
                target = item
            }
        }

        let buildConfigurationList = target.buildConfigurationList!
        let key = "PRODUCT_BUNDLE_IDENTIFIER"
        for buildConfigurations in buildConfigurationList.buildConfigurations {
            if buildConfigurations.buildSettings[key] != nil {
                buildConfigurations.buildSettings[key] = "com.fooww.guanming"
            }
        }
        try? xcodeproj.write(pathString: path, override: true)
    }

    func copySource() {
        do {
            let toPath = "/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone/Assets/GuanMing"
            let fromPath = "/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone/Assets/XinMing"

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: toPath) {
                try fileManager.removeItem(atPath: toPath)
            }

            try fileManager.copyItem(atPath: fromPath, toPath: toPath)

        } catch {}
    }
    
    func addGroupAndFileReference(_ path: String) {
        let path = "/Users/Yoon/Desktop/CrownName/CrownName/Sources/copy_groups.rb"
        let res = TargetChanged.shell(launchPath: "/usr/bin/ruby", arguments: [path])
        print("*** ls ***:\n\(res)")
    }
    
    func readInfo(_ path: String) {
        
//        let openPanel = NSOpenPanel()
//            openPanel.allowsMultipleSelection = false
//            openPanel.canChooseDirectories = false
//            openPanel.canCreateDirectories = false
//            openPanel.canChooseFiles = true
//        openPanel.begin { (result) -> Void in
//            if result.rawValue == NSFileHandlingPanelOKButton {
//                let selectedPath = openPanel.url!.path
//                let data = FileManager.default.contents(atPath: selectedPath)!
//                let readString = String(data: data, encoding: String.Encoding.utf8)
////                print(readString)
//                let newReadString = readString!.replacingOccurrences(of: "鑫铭地产", with: "冠名测试")
//
////                let error = try? newReadString.write(to: URL.init(string: selectedPath)!, atomically: true, encoding: String.Encoding.utf8)
////
////                print(error)
//
//                let savePanel = NSSavePanel()
//
//                // this is a preferred method to get the desktop URL
//                savePanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
//
//                savePanel.message = "My custom message."
//                savePanel.nameFieldStringValue = "MyFile"
//                savePanel.showsHiddenFiles = false
//                savePanel.showsTagField = false
//                savePanel.canCreateDirectories = true
//                savePanel.allowsOtherFileTypes = false
//                savePanel.isExtensionHidden = true
//
//                if let url = savePanel.url, savePanel.runModal().rawValue == NSFileHandlingPanelOKButton {
//
//                    // Do the actual copy:
//                    do {
//                        try FileManager().copyItem(at: URL.init(string: "file:///Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone/Assets/GuanMing5/info.plist")!, to: url)
//                    } catch {
//                        print(error.localizedDescription)
//                    }
//                } else {
//                    print("canceled")
//                }
//            }
//            openPanel.close()
//        }
        
       
        
        let fileManager = FileManager.default

        if let url = URL(string: path) {
            if fileManager.fileExists(atPath: url.path) {
                let data = fileManager.contents(atPath: url.path)!

                let readString = String.init(data: data, encoding: String.Encoding.utf8)
                let newReadString = readString!.replacingOccurrences(of: "鑫铭地产", with: "冠名测试")

                let error = try? newReadString.write(to: URL.init(string: "file://\(url.path)")!, atomically: true, encoding: String.Encoding.utf8)

                print(error)
            } else {
                print("Path loss file is not exists")
            }
        }
    }
    
    /// 静态方法 方便之后脚本调用
    static func shell(launchPath path: String, arguments args: [String]) -> (String, Int) {
        let task = Process()
        task.launchPath = path
        task.arguments = args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()

        return (output!, Int(task.terminationStatus))
    }
}
