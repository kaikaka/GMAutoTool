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
    ///打印日志
    var logBlock:((String) -> Void)?
    
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
    func execDuplicteTarget(_ vable: ProjVariable, execHander: (Bool) -> Void) {
        guard let rb = Bundle.main.path(forResource: "duplicate_xcode_project_target", ofType: "rb") else { return }
        if replaceTargetValue(vable, rb: rb) {
            // 1.读取脚本目录 path 脚本目录
            // 2.launchPath 要执行的脚本路径，ruby\/bin/ls
            let res = ReProjTools.shell(launchPath: "/usr/bin/ruby", arguments: [rb])
            print(res)
            if res.1 == 0 {
                print("Duplicate Success")
                execHander(true)
            } else {
                execHander(false)
            }
        } else {
            execHander(false)
        }
    }

    /// 修改target相关
    func modifyTargetSettings(_ vable: ProjVariable) {
        // 1.删除索引
        // 2.复制文件夹，并添加目录
        // 3.添加索引
        // 4.修改Build Settings
        guard let xcodeproj = try? XcodeProj(pathString: vable.projectTruePath) else { return }

//        deleteTargetFileReference(xcodeproj, targetName: vable.newEnNameTarget.or(""))

//        copySource(vable)
//        addGroupFileReference(vable: vable)
//
//        addResourceFileRef(xcodeproj, vable: vable)

//        try? xcodeproj.write(pathString: vable.projectTruePath, override: true)
    }

    /// 复制实际文件
    func copySource(_ vable: ProjVariable) {
        do {
            let toPath = "\(vable.projectPath.or(""))/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))"
            let fromPath = "\(vable.projectPath.or(""))/Foowwphone/Assets/\(vable.sourceNameTarget.or(""))"

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: toPath) {
                try fileManager.removeItem(atPath: toPath)
            }

            try fileManager.copyItem(atPath: fromPath, toPath: toPath)

        } catch {}
    }

    /// 添加项目目录索引
    func addGroupFileReference(vable: ProjVariable, finish: (Bool) -> Void) {
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
                            print("Exec Success")
                            finish(true)
                        }
                    }
                } else if error == nil {
                    finish(true)
                } else {
                    finish(false)
                }
            } else {
                print("Path loss file is not exists")
                finish(false)
            }
        }
    }

    /// 移除Frameworks、 Resources 索引
    func remResourceFileRef(_ vable: ProjVariable, finish: (Bool) -> Void) {
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
            finish(true)
        } else if error == nil {
            finish(true)
        } else {
            finish(false)
        }
    }

    /// 修改project 配置
    func modifyInfoSettings(_ vable: ProjVariable, finish: (Bool) -> Void) {
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

        for buildConfigurations in buildConfigurationList.buildConfigurations {
            if buildConfigurations.buildSettings[keyIdentifier] != nil {
                let setsValue = buildConfigurations.buildSettings[keyIdentifier]
                if let buildId = setsValue as? String, buildId.contains("com.fooww") {
                    buildConfigurations.buildSettings[keyIdentifier] = "com.fooww.\(vable.buildId.or(""))"
                } else {
                    buildConfigurations.buildSettings[keyIdentifier] = vable.buildId.or(_:)
                }
            }
            if buildConfigurations.buildSettings[infoPath] != nil {
                let setsValue = buildConfigurations.buildSettings[infoPath]
                if let info = setsValue as? String, info.contains("Foowwphone") {
                    buildConfigurations.buildSettings[infoPath] = "Foowwphone/Assets/\(vable.newEnNameTarget.or(""))/Info.plist"
                }
            }
            if buildConfigurations.buildSettings[marcors] != nil {
                let setsValue = buildConfigurations.buildSettings[marcors] as? Array<String>
                if setsValue != nil {
                    buildConfigurations.buildSettings[marcors] = ["$(inherited)", "COCOAPODS=1", "NDEBUG=1", "\(vable.newEnNameTarget.or(""))=1"]
                }
            }
        }
        let error: ()? = try? xcodeproj.write(pathString: vable.projectTruePath, override: true)
        if let er = error, er == () {
            finish(true)
        } else if error == nil {
            finish(true)
        } else {
            finish(false)
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
        }
    }

    /// 修改颜色配置
    func modifyColorPlistFile(_ vable: ProjVariable) {
        let colorPath = vable.projectPath.or("") + "/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))"
        let fileBundle = Bundle(path: colorPath)
        let newPath = (fileBundle?.path(forResource: "ColorConfig", ofType: "plist"))!

        if let colorDict = NSDictionary(contentsOfFile: newPath) as? NSMutableDictionary {
            colorDict["mainColor"] = vable.mainColor
            let error = colorDict.write(toFile: newPath, atomically: true)
            print(error)
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

                } catch {}
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
            //如果不存在新文件夹 复制一份
            if !fileManager.fileExists(atPath: gToPath) {
                try fileManager.copyItem(atPath: gPath, toPath: gToPath)
            }
            //删除旧文件夹
            if fileManager.fileExists(atPath: gPath) {
                try fileManager.removeItem(atPath: gPath)
            }

            let oldTargetImgName = gToPath + "/bg_splash_\(oldTargetName).png"
            //删除旧的bg_splash图片
            if fileManager.fileExists(atPath: oldTargetImgName) {
                try fileManager.removeItem(atPath: oldTargetImgName)
            }

            toPath = toPath.replacingOccurrences(of: oldTargetName, with: newTargetName)
            newImgName = "ios-bg_splash -2@3x.png"
            let fromPath = "\(vable.imagePath.or(""))/\(newImgName)"
            //移动图片到新目录下
            try fileManager.moveItem(atPath: fromPath, toPath: toPath)
            
            //修改配置文件
            let data = fileManager.contents(atPath: gToPath + "/Contents.json")!
            let readString = String(data: data, encoding: String.Encoding.utf8)
            let newReadString = readString!.replacingOccurrences(of: "boan", with: newTargetName)
            try newReadString.write(to: URL(string: "file://\(gToPath)/Contents.json")!, atomically: true, encoding: String.Encoding.utf8)
        } catch {}
    }

    ///修改Launch 图片名字
    func reChooseLaunchStoryBoard(_ vable: ProjVariable) {
        let sbPath = vable.projectPath.or("") + "/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))"
        let fileBundle = Bundle(path: sbPath)
        guard let url = fileBundle?.url(forResource: "Launch Screen", withExtension: "storyboard") else { return }
        let readString = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        let newReadString = readString!.replacingOccurrences(of: "bg_splash_\(vable.sourceNameTarget.or("").lowercased())", with: "bg_splash_\(vable.newEnNameTarget.or("").lowercased())")
        let error: ()? = try? newReadString.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        if let er = error {
            if er == () {
            }
        } else if error == nil {
        }
    }
    
    func execCocoaPods(_ vable: ProjVariable) {
        let podFilePath = vable.projectPath.or("")
        let fileBundle = Bundle(path: podFilePath)
        guard let url = fileBundle?.url(forResource: "Podfile", withExtension: "") else { return }
        let readString = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        let newReadString = readString!.replacingOccurrences(of: "end\nend\n", with: "end\n  target \'\(vable.newEnNameTarget.or(""))\' do\n  end\nend\n")
        let error: ()? = try? newReadString.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        if let er = error {
            if er == () {
                //执行pods命令
                let res = ReProjTools.shell(launchPath: "/usr/local/bin/pod", arguments: ["install","--project-directory=\(podFilePath)"])
                if res.1 == 0 {
                    print("Exec Success")

                }
            }
        } else if error == nil {
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
    /// 冠名Build Id
    var buildId: String?
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
    /// 返回可选值或默认值
    /// - 参数: 如果可选值为空，将会默认值
    /// 例如. let optional: Int? = nil
    ///      print(optional.or(10)) // 打印 10
    public func or(_ default: Wrapped) -> Wrapped {
        return self ?? `default`
    }

    /// 返回可选值或 `else` 表达式返回的值
    /// 例如. optional.or(else: print("Arrr"))
    public func or(else: @autoclosure () -> Wrapped) -> Wrapped {
        return self ?? `else`()
    }

    /// 返回可选值或者 `else` 闭包返回的值
    /// 例如. optional.or(else: {
    /// ... do a lot of stuff
    /// })
    public func or(else: () -> Wrapped) -> Wrapped {
        return self ?? `else`()
    }

    /// 当可选值不为空时，返回可选值
    /// 如果为空，抛出异常
    public func or(throw exception: Error) throws -> Wrapped {
        guard let unwrapped = self else { throw exception }
        return unwrapped
    }

    /// 可选值为空的时候返回 true
    public var isNone: Bool {
        switch self {
        case .none:
            return true
        case .some:
            return false
        }
    }

    /// 可选值非空返回 true
    public var isSome: Bool {
        return !isNone
    }
}
