//
//  TargetDuplicate.swift
//  CrownName
//
//  Created by Yoon on 2021/7/27.
//

import CommandLineKit
import Foundation
import PathKit
import RainbowSwift
import XcodeProj

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
    func addNewGroupAndFileReference(_ path: String) {
        let path = "/Users/Yoon/Desktop/CrownName/CrownName/Sources/copy_groups.rb"
        let res = TargetChanged.shell(launchPath: "/usr/bin/ruby", arguments: [path])
        print("*** ls ***:\n\(res)")
    }
    func addNewFileReference(_ path: String) {
        guard let xcodeproj = try? XcodeProj(pathString: path) else { return }
//        for item in xcodeproj.pbxproj.fileReferences {
//            print("fileReferences = \(item.name)\n")
//        }
//        for item in xcodeproj.pbxproj.buildFiles {
//            print("buildFiles = \(item.file?.name)\n")
//        }
//        for item in xcodeproj.pbxproj.buildPhases {
//            print("buildPhases = \(item.files)\n")
//        }
        
//        for item in xcodeproj.pbxproj.copyFilesBuildPhases {
//            print("buildPhases = \(item.name)\n")
//        }
        for item in xcodeproj.pbxproj.groups {
//            print(item.name)
            if let path1 = item.path,path1 == "Assets" {
               
                for child in item.children {
//                    print(child.name,child.path)
                    
                }
                
//                try? item.addFile(at: Path.init( "/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone/Assets/GuanMing/ColorConfig.plist"),
//                             sourceRoot: Path.init("SOURCE_ROOT"))
            }
        }
        
        var target: PBXNativeTarget!
        for item in xcodeproj.pbxproj.nativeTargets {
            if item.name == "GuanMing" {
                target = item
            }
        }
        
        
        for item in target.buildPhases {
//            print(item.files?.count)
//            print(item.name())
            if item.name() == "Resources" {
                for item1 in item.files! {
                    
                    if let pathf = item1.file?.path,pathf == "ColorConfig.plist" {
//                        let idx = item.files?.firstIndex(of: item1) ?? 0
//                        item.files?.remove(at: idx)
//                        print(item1.file?.sourceTree.publisher)
//                        print(item1.file?.parent)
                    }
                    
                }
                /*
                 case none
                 case absolute
                 case group
                 case sourceRoot
                 case buildProductsDir
                 case sdkRoot
                 case developerDir
                 case custom(String)
                 */
//                let sourceTree = PBXSourceTree.init(value: "SOURCE_ROOT")
//                let pb = PBXFileElement.init(sourceTree: sourceTree, path: "/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone/Assets/GuanMing/ColorConfig.plist", name: "ColorConfig", includeInIndex: nil, usesTabs: nil, indentWidth: nil, tabWidth: nil, wrapsLines: nil)
//                let pb1 = PBXBuildFile.init(file: pb, product: nil, settings: nil)
//                try? item.ad
            }
        }
        //Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone/Assets/GuanMing/ColorConfig.plist
        
//        let sourceTree = PBXSourceTree.init(value: "/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone/Assets/GuanMing/ColorConfig.plist")
//
//        let fileReference = PBXFileReference.init(sourceTree: sourceTree, name: "ColorConfig.plist", fileEncoding: nil, explicitFileType: nil, lastKnownFileType: nil, path: nil, includeInIndex: nil, wrapsLines: nil, usesTabs: nil, indentWidth: nil, tabWidth: nil, lineEnding: nil, languageSpecificationIdentifier: nil, xcLanguageSpecificationIdentifier: nil, plistStructureDefinitionIdentifier: nil)
        
        
//        try? xcodeproj.write(pathString: path, override: true)
        
        
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
