//
//  ReProjTools.swift
//  CrownName
//
//  Created by Yoon on 2021/7/30.
//

import Cocoa
import XcodeProj
import PathKit

let GUANMING_TEMP_ROOTNAME = "GUANMING-TEMP-ROOTNAME"
let GUANMING_TEMP_PATH = "GUANMING-TEMP-PATH"
let GUANMING_TEMP_SCRNAME = "GUANMING-TEMP-SCRNAME"

/// 冠名相关方法
class ReProjTools: NSObject {
    
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
    
    ///读取项目所有的Targets
    func readTargets(_ path:String) -> [String] {
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
    
    ///执行复制Target脚本
    func execDuplicteTarget(_ vable:ProjVariable, execHander:(Bool) -> ()) {
        guard let rb = Bundle.main.path(forResource: "duplicate_xcode_project_target", ofType: "rb") else { return  }
        if self.replaceTargetValue(vable, rb: rb) {
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
    
    ///修改target相关
    func modifyTargetSettings(_ vable:ProjVariable) {
        //1.删除索引
        //2.复制文件夹，并添加目录
        //3.添加索引
        //4.修改Build Settings
        guard let xcodeproj = try? XcodeProj(pathString: vable.projectTruePath) else { return  }
        
//        deleteTargetFileReference(xcodeproj, targetName: vable.newEnNameTarget.or(""))
        
//        copySource(vable)
//        addGroupFileReference(vable: vable)
//
//        addResourceFileRef(xcodeproj, vable: vable)
        
//        try? xcodeproj.write(pathString: vable.projectTruePath, override: true)
    }
    
    ///删除源文件索引
    func modifyTargetFileReference(_ vable:ProjVariable,finish:(Bool) -> Void) {
        guard let xcodeproj = try? XcodeProj(pathString: vable.projectTruePath) else { return  }
        guard let target = xcodeproj.pbxproj.nativeTargets.compactMap({ target -> PBXNativeTarget? in
            if target.name == vable.sourceNameTarget.or("") {
                return target
            }
            return nil
        }).first else { return }
        
        for file in target.buildPhases {
            if file.name() == "Resources" {
                if var files = file.files, files.count > 0 {
                    for item in files {
                        if let pName = item.file?.path {
                            let array = ["Info.plist","Only.xcassets","Launch Screen.storyboard","ColorConfig.plist"]
                            if array.contains(pName) {
//                                let idx = files.firstIndex(of: item) ?? 0
//                                files.remove(at: idx)
                                
                            }
                        }
                    }
                    file.files = files
                }
                
            }
        }
        let error: ()? = try? xcodeproj.write(pathString: vable.projectTruePath, override: true)
        if let er = error,er == () {
            finish(true)
        } else if error == nil {
            finish(true)
        } else {
            finish(false)
        }
    }
    
    ///复制实际文件
    func copySource(_ vable:ProjVariable) {
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
    
    ///添加项目目录索引
    func addGroupFileReference(vable:ProjVariable,finish:(Bool) -> Void) {
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
    
    ///添加Copy Bundle Resources 索引
    func addResourceFileRef(_ vable:ProjVariable,finish:(Bool) -> Void) {
        guard let xcodeproj = try? XcodeProj(pathString: vable.projectTruePath) else { return  }
        guard let target = xcodeproj.pbxproj.nativeTargets.compactMap({ target -> PBXNativeTarget? in
            if target.name == vable.newEnNameTarget {
                return target
            }
            return nil
        }).first else { return }
        
        for file in target.buildPhases {
            print(file.name())
            if file.name() == "Frameworks" || file.name() == "Resources" {
               
                if let files = file.files, files.count < 10 {
                    let idx = target.buildPhases.firstIndex(of: file) ?? 0
                    target.buildPhases.remove(at: idx)
                }
//                if var files = file.files, files.count > 10 {
//                    for p in files {
////                        print(p.file?.path,p.file?.parent,p.file?.uuid)
//                    }
//                                        let sourecesTree = PBXSourceTree.init(value: "<group>")
//                    let ref = PBXFileElement.init(sourceTree: sourecesTree,
//                                                  path: "\(vable.projectPath.or(""))/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))/ColorConfig.plist",
//                                                  name: "ColorConfig.plist", includeInIndex: nil,usesTabs: nil, indentWidth: nil, tabWidth: nil, wrapsLines: nil)
//
////                    print(ref.name,ref.path,ref.sourceTree)
//                    let m1 = files.first?.file
////                    m1?.name = "Info.plist"
////                    m1?.path = "\(vable.projectPath.or(""))/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))/Info.plist"
////                    try? file.add(file: m1 ?? PBXFileElement())
////                    ref.parent = m1?.parent
//                    let m2 = PBXFileReference.init(sourceTree: sourecesTree, name: "ColorConfig.plist", fileEncoding: nil, explicitFileType: nil, lastKnownFileType: "file", path: "ColorConfig.plist", includeInIndex: nil, wrapsLines: nil, usesTabs: nil, indentWidth: nil, tabWidth: nil, lineEnding: nil, languageSpecificationIdentifier: nil, xcLanguageSpecificationIdentifier: nil, plistStructureDefinitionIdentifier: nil)
//                    m2.parent = m1?.parent
////                    m2.name = m1!.name ?? "1" + "1"
////                    m2.path = m1?.path
//                    print(m2.uuid,m1?.uuid)
//                    try? file.add(file: m2)
////                    try? file.add(file: ref ?? PBXFileElement())
//
//                    let array = ["Info.plist","Only.xcassets","Launch Screen.storyboard","ColorConfig.plist"]
//                    for str in array {
//                        let path = "\(vable.projectPath.or(""))/Foowwphone/Assets/\(vable.newEnNameTarget.or(""))/\(str)"
//                        let ref = PBXFileElement.init(sourceTree: sourecesTree,
//                                                          path: path,
//                                                          name: str, includeInIndex: nil, usesTabs: nil, indentWidth: nil, tabWidth: nil, wrapsLines: nil)
//
//                        let fileRef = PBXBuildFile.init(file: ref, product: nil, settings: nil)
//
////                        files.append(fileRef)
////                        try? file.add(file: ref)
//                    }
////                    file.files = files
//                }
                
            }
            
        }
        let error: ()? = try? xcodeproj.write(pathString: vable.projectTruePath, override: true)
        if let er = error,er == () {
            finish(true)
        } else if error == nil {
            finish(true)
        } else {
            finish(false)
        }
    }
    
    ///替换ruby 变量
    func replaceTargetValue(_ vable: ProjVariable,rb:String) -> Bool {
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
    ///项目路径
    var projectPath:String?
    ///附带.xcodeproj的路径
    var projectTruePath:String = ""
    ///项目名称，默认Foowwphone
    let projectName:String = "Foowwphone"
    ///冠名图片路径
    var imagePath:String?
    ///要复制的冠名Target
    var sourceNameTarget:String?
    ///新的应用名称(中文)
    var newCnNameTarget:String?
    ///新的应用名称(英文)
    var newEnNameTarget:String?
    /// 冠名Build Id
    var buildId:String?
    /// 冠名颜色，十六位颜色字符串
    var mainColor:String?
    /// FwSoftId,冠名公司Id
    var appID:String?
    /// 百度地图开发中心akid
    var baiduSkdId:String?
    /// 公司简介
    var companyInfo:String?
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
