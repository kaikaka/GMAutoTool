//
//  ReProjTools.swift
//  CrownName
//
//  Created by Yoon on 2021/7/30.
//

import Cocoa
import PathKit
import XcodeProj

let GUANMING_TEMP_ROOTNAME = "GUANMING-TEMP-ROOTNAME"
let GUANMING_TEMP_PATH = "GUANMING-TEMP-PATH"
let GUANMING_TEMP_SCRNAME = "GUANMING-TEMP-SCRNAME"

/// 冠名相关方法
class ReProjTools: NSObject {
    /// 打印日志
    var logBlock: ((String) -> Void)?

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

    /// 读取项目所有的Targets
    func readTargets(_ path: String) -> [String] {
        guard let xcodeproj = try? XcodeProj(pathString: path) else { return [] }

        let targets = xcodeproj.pbxproj.nativeTargets.compactMap { target in
            target.name
        }

        let filterTargets = targets.compactMap { target -> String? in
            if target.contains("Foowwphone") || target.contains("DaiShu") {
                return nil
            }
            return target
        }
        return filterTargets
    }

    /// 执行复制Target脚本
    func execDuplicteTarget(_ vable: ProjVariable) {
        guard let rb = Bundle.main.path(forResource: "duplicate_xcode_project_target", ofType: "rb") else { return }
        if replaceTargetValue(vable, rb: rb) {
            // 1.读取脚本目录 path 脚本目录
            // 2.launchPath 要执行的脚本路径，ruby\/bin/ls
            let res = ReProjTools.shell(launchPath: "/usr/bin/ruby", arguments: [rb])
//            print(res)
            if res.1 == 0 {
//                print("Duplicate Success")
                blockExec("复制 \(vable.sourceNameTarget.or("Target")) 成功~")
            } else {
                blockExec("复制 \(vable.sourceNameTarget.or("Target")) 失败~")
            }
        } else {
            blockExec("复制 \(vable.sourceNameTarget.or("Target")) 失败~")
        }
    }

    /// 执行block回调 刷新日志
    func blockExec(_ str: String) {
        if let block = logBlock {
            block(str)
        }
    }

    /// 复制实际文件
    func copySource(_ vable: ProjVariable) {
        do {
            let toPath = "\(vable.projectPath.or(""))/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))"
            let fromPath = "\(vable.projectPath.or(""))/Foowwphone/Assets/\(vable.sourceNameTarget.or(""))"
            
            blockExec("开始复制 Assets 文件夹~")
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: toPath) {
                try fileManager.removeItem(atPath: toPath)
            }

            try fileManager.copyItem(atPath: fromPath, toPath: toPath)
            blockExec("复制 Assets 文件夹 成功~")
        } catch {
            blockExec("复制 Assets 文件夹 失败~")
        }
    }

    /// 添加项目目录索引
    func addGroupFileReference(vable: ProjVariable) {
        guard let rb = Bundle.main.path(forResource: "copy_groups", ofType: "rb") else { return }
        let fileManager = FileManager.default
        if let url = URL(string: rb) {
            if fileManager.fileExists(atPath: url.path) {
                let data = fileManager.contents(atPath: url.path)!
                let readString = String(data: data, encoding: String.Encoding.utf8)
                var newReadString = readString!.replacingOccurrences(of: GUANMING_TEMP_ROOTNAME, with: vable.newEnNameTarget.or(""))
                newReadString = newReadString.replacingOccurrences(of: GUANMING_TEMP_PATH, with: vable.projectTruePath)

                let error: ()? = try? newReadString.write(to: URL(string: "file://\(url.path)")!, atomically: true, encoding: String.Encoding.utf8)
                if let er = error {
                    if er == () {
                        let res = ReProjTools.shell(launchPath: "/usr/bin/ruby", arguments: [rb])
                        if res.1 == 0 {
//                            print("Exec Success")
                            blockExec("添加目录文件 成功~")
                        }
                    }
                } else if error == nil {
                    blockExec("添加目录文件 成功~")
                } else {
                    blockExec("添加目录文件 失败~")
                }
            } else {
//                print("Path loss file is not exists")
                blockExec("添加目录文件 失败~")
            }
        }
    }

    /// 移除Frameworks 索引
    func remResourceFileRef(_ vable: ProjVariable) {
        guard let xcodeproj = try? XcodeProj(pathString: vable.projectTruePath) else { return }
        guard let target = xcodeproj.pbxproj.nativeTargets.compactMap({ target -> PBXNativeTarget? in
            if target.name == vable.newEnNameTarget {
                return target
            }
            return nil
        }).first else { return }

        for file in target.buildPhases {
            if file.name() == "Frameworks" {
                if let files = file.files, files.count < 10 {
                    let idx = target.buildPhases.firstIndex(of: file) ?? 0
                    target.buildPhases.remove(at: idx)
                }
            }
        }
        let error: ()? = try? xcodeproj.write(pathString: vable.projectTruePath, override: true)
        if let er = error, er == () {
            blockExec("移除多余的Frameworks 成功~")
        } else if error == nil {
            blockExec("移除多余的Frameworks 成功~")
        } else {
            blockExec("移除多余的Frameworks 失败~")
        }
    }

    /// 修改project 配置
    func modifyInfoSettings(_ vable: ProjVariable) {
        guard let xcodeproj = try? XcodeProj(pathString: vable.projectTruePath) else { return }
        var target: PBXNativeTarget!
        for item in xcodeproj.pbxproj.nativeTargets {
            if item.name == vable.newEnNameTarget {
                target = item
            }
        }

        let buildConfigurationList = target.buildConfigurationList!
        let keyIdentifier = "PRODUCT_BUNDLE_IDENTIFIER"
        let infoPath = "INFOPLIST_FILE"
        let marcors = "GCC_PREPROCESSOR_DEFINITIONS"
        
        blockExec("开始修改InfoSettings~")
        
        for buildConfigurations in buildConfigurationList.buildConfigurations {
            if buildConfigurations.buildSettings[keyIdentifier] != nil {
                buildConfigurations.buildSettings[keyIdentifier] = "com.fooww.\(vable.newEnNameTarget.or("").lowercased())"
                blockExec("修改bundle id~")
            }
            if buildConfigurations.buildSettings[infoPath] != nil {
                let setsValue = buildConfigurations.buildSettings[infoPath]
                if let info = setsValue as? String, info.contains("Foowwphone") {
                    buildConfigurations.buildSettings[infoPath] = "Foowwphone/Assets/\(vable.newEnNameTarget.or(""))/Info.plist"
                }
                blockExec("修改Info.plist路径~")
            }
            if buildConfigurations.buildSettings[marcors] != nil {
                let setsValue = buildConfigurations.buildSettings[marcors] as? Array<String>
                if setsValue != nil {
                    buildConfigurations.buildSettings[marcors] = ["$(inherited)", "COCOAPODS=1", "NDEBUG=1", "\(vable.newEnNameTarget.or(""))=1"]
                }
                blockExec("修改Macros宏定义~")
            }
        }
        let error: ()? = try? xcodeproj.write(pathString: vable.projectTruePath, override: true)
        if let er = error, er == () {
            blockExec("修改project 配置 成功~")
        } else if error == nil {
            blockExec("修改project 配置 成功~")
        } else {
            blockExec("修改project 配置 失败~")
        }
    }

    /// 修改info.plist文件
    func modifyInfoPlistFile(_ vable: ProjVariable) {
        let infoUpPath = vable.projectPath.or("") + "/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))"
        let fileBundle = Bundle(path: infoUpPath)
        let newPath = (fileBundle?.path(forResource: "Info", ofType: "plist"))!

        if let colorDict = NSDictionary(contentsOfFile: newPath) as? NSMutableDictionary {
            colorDict["AppAbstract"] = vable.companyInfo
            colorDict["FWSoftID"] = vable.appID
            colorDict["BaiduMapAk"] = vable.baiduSkdId
            colorDict["CFBundleDisplayName"] = vable.newCnNameTarget
            let error = colorDict.write(toFile: newPath, atomically: true)
            print(error)
            if error {
                blockExec("修改info.plist成功~")
            } else {
                blockExec("修改info.plist失败~")
            }
            
        }
    }

    /// 修改颜色配置
    func modifyColorPlistFile(_ vable: ProjVariable) {
        let colorPath = vable.projectPath.or("") + "/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))"
        let fileBundle = Bundle(path: colorPath)
        let newPath = (fileBundle?.path(forResource: "ColorConfig", ofType: "plist"))!

        if let colorDict = NSDictionary(contentsOfFile: newPath) as? NSMutableDictionary {
            colorDict["mainColor"] = vable.mainColor
            colorDict["mainNavColor"] = vable.mainColor
            let error = colorDict.write(toFile: newPath, atomically: true)
            if error {
                blockExec("修改ColorConfig成功~")
            } else {
                blockExec("修改ColorConfig失败~")
            }
        }
    }

    /// 替换图片
    func replaceImages(_ vable: ProjVariable) {
        let imagePath = vable.projectPath.or("") + "/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))/Only.xcassets"

        func findImg(_ newPath: String, imgName: String) {
            guard let arrays = FileManager.default.enumerator(atPath: vable.imagePath.or("")) else { return }

            let hadImg = arrays.allObjects.contains { res in
                if imgName == "1024x1024pt.png"
                    || imgName == "icon_mobile_mark@2x.png"
                    || imgName == "icon_mobile_mark@3x.png" || imgName.contains("bg_splash") {
                    return true
                }
                if let v = res as? String {
                    return v == imgName
                }
                return false
            }

            if hadImg {
                do {
                    let toPath = newPath
                    var newImgName = imgName
                    if imgName == "1024x1024pt.png" {
                        newImgName = "1024x1024pt@2x.png"
                    } else if imgName == "icon_mobile_mark@2x.png" {
                        newImgName = "icon_android_phone_log@2x.png"
                    } else if imgName == "icon_mobile_mark@3x.png" {
                        newImgName = "icon_android_phone_log@3x.png"
                    } else if imgName.contains("bg_splash_\(vable.sourceNameTarget.or("").lowercased())") {
                        replaceImgJson(vable, aPath: toPath, aImgName: newImgName)
                    }

                    let fromPath = "\(vable.imagePath.or(""))/\(newImgName)"

                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: toPath) {
                        try fileManager.removeItem(atPath: toPath)
                    }

                    try fileManager.copyItem(atPath: fromPath, toPath: toPath)
                    blockExec("修改\(newImgName)成功~")
                } catch {
                    blockExec("修改\(imgName)失败~")
                }
            }
        }

        guard let arrays = FileManager.default.enumerator(atPath: imagePath) else { return }
        for obj in arrays.allObjects {
            if let value = obj as? String, value.contains(".png") {
                let newImagePath = imagePath + "/" + value
                if let imgName = newImagePath.split(separator: "/").last {
                    findImg(newImagePath, imgName: String(imgName))
                }
            }
        }
    }

    private func replaceImgJson(_ vable: ProjVariable, aPath: String, aImgName: String) {
        do {
            var toPath = aPath
            var newImgName = aImgName
            let oldTargetName = vable.sourceNameTarget.or("").lowercased()
            let newTargetName = vable.newEnNameTarget.or("").lowercased()

            var gPathArrays = toPath.split(separator: "/")
            gPathArrays.removeLast()
            let gPath = gPathArrays.joined(separator: "/")
            gPathArrays.removeLast()
            let gToPath = gPathArrays.joined(separator: "/") + "/bg_splash_\(newTargetName).imageset"
            let fileManager = FileManager.default
            // 如果不存在新文件夹 复制一份
            if !fileManager.fileExists(atPath: gToPath) {
                try fileManager.copyItem(atPath: gPath, toPath: gToPath)
            }
            // 删除旧文件夹
            if fileManager.fileExists(atPath: gPath) {
                try fileManager.removeItem(atPath: gPath)
            }

            let oldTargetImgName = gToPath + "/bg_splash_\(oldTargetName).png"
            // 删除旧的bg_splash图片
            if fileManager.fileExists(atPath: oldTargetImgName) {
                try fileManager.removeItem(atPath: oldTargetImgName)
            }

            toPath = toPath.replacingOccurrences(of: oldTargetName, with: newTargetName)
            newImgName = "ios-bg_splash -2@2x.png"
            let fromPath = "\(vable.imagePath.or(""))/\(newImgName)"
            // 移动图片到新目录下
            try fileManager.moveItem(atPath: fromPath, toPath: toPath)

            // 修改配置文件
            let data = fileManager.contents(atPath: gToPath + "/Contents.json")!
            let readString = String(data: data, encoding: String.Encoding.utf8)
            let newReadString = readString!.replacingOccurrences(of: "boan", with: newTargetName)
            try newReadString.write(to: URL(string: "file://\(gToPath)/Contents.json")!, atomically: true, encoding: String.Encoding.utf8)
        } catch {}
    }

    /// 修改Launch 图片名字
    func reChooseLaunchStoryBoard(_ vable: ProjVariable) {
        let sbPath = vable.projectPath.or("") + "/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))"
        let fileBundle = Bundle(path: sbPath)
        guard let url = fileBundle?.url(forResource: "Launch Screen", withExtension: "storyboard") else { return }
        let readString = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        let newReadString = readString!.replacingOccurrences(of: "bg_splash_\(vable.sourceNameTarget.or("").lowercased())", with: "bg_splash_\(vable.newEnNameTarget.or("").lowercased())")
        let error: ()? = try? newReadString.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        if let er = error {
            if er == () {
                blockExec("修改bg_splash成功~")
            }
        } else if error == nil {
            blockExec("修改bg_splash成功~")
        } else {
            blockExec("修改bg_splash失败~")
        }
    }
    
    ///执行pod命令
    func execCocoaPods(_ vable: ProjVariable) {
        let podFilePath = vable.projectPath.or("")
        let fileBundle = Bundle(path: podFilePath)
        guard let url = fileBundle?.url(forResource: "Podfile", withExtension: "") else { return }
        let readString = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        let newReadString = readString!.replacingOccurrences(of: "end\nend\n", with: "end\n  target \'\(vable.newEnNameTarget.or(""))\' do\n  end\nend\n")
        let error: ()? = try? newReadString.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        if let er = error {
            if er == () {
                // 执行pods命令
                let res = ReProjTools.shell(launchPath: "/usr/local/bin/pod", arguments: ["install", "--project-directory=\(podFilePath)"])
                if res.1 == 0 {
                    print("Exec Success")
                    blockExec("执行pod install命令成功~")
                }
            }
        } else if error == nil {
            blockExec("执行pod install命令成功~")
        } else {
            blockExec("执行pod install命令失败~")
        }
//        let res1 = ReProjTools.shell(launchPath: "/usr/bin/cd", arguments: [podFilePath])
//        print(res1)
    }

    /// 替换ruby 变量
    func replaceTargetValue(_ vable: ProjVariable, rb: String) -> Bool {
        let fileManager = FileManager.default
        if let url = URL(string: rb) {
            if fileManager.fileExists(atPath: url.path) {
                let data = fileManager.contents(atPath: url.path)!
                let readString = String(data: data, encoding: String.Encoding.utf8)
                var newReadString = readString!.replacingOccurrences(of: GUANMING_TEMP_ROOTNAME, with: vable.newEnNameTarget.or(""))
                newReadString = newReadString.replacingOccurrences(of: GUANMING_TEMP_PATH, with: vable.projectTruePath)
                newReadString = newReadString.replacingOccurrences(of: GUANMING_TEMP_SCRNAME, with: vable.sourceNameTarget.or(""))

                let error: ()? = try? newReadString.write(to: URL(string: "file://\(url.path)")!, atomically: true, encoding: String.Encoding.utf8)
                if let er = error {
                    if er == () {
                        return true
                    }
                } else if error == nil {
                    return true
                }
            } else {
                print("Path loss file is not exists")
                return false
            }
        }
        return false
    }
}

struct ProjVariable {
    /// 项目路径
    var projectPath: String?
    /// 附带.xcodeproj的路径
    var projectTruePath: String = ""
    /// 项目名称，默认Foowwphone
    let projectName: String = "Foowwphone"
    /// 冠名图片路径
    var imagePath: String?
    /// 要复制的冠名Target
    var sourceNameTarget: String?
    /// 新的应用名称(中文)
    var newCnNameTarget: String?
    /// 新的应用名称(英文)
    var newEnNameTarget: String?
    /// 冠名颜色，十六位颜色字符串
    var mainColor: String?
    /// FwSoftId,冠名公司Id
    var appID: String?
    /// 百度地图开发中心akid
    var baiduSkdId: String?
    /// 公司简介
    var companyInfo: String?
}

extension Optional {
    
    public func or(_ default: Wrapped) -> Wrapped {
        return self ?? `default`
    }

    public var isNone: Bool {
        switch self {
        case .none:
            return true
        case .some:
            return false
        }
    }
}
