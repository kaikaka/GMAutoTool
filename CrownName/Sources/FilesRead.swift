//
//  FileRead.swift
//  CrownName
//
//  Created by Yoon on 2021/7/27.
//

import Foundation
import PathKit
import RainbowSwift
import CommandLineKit
import XcodeProj

class FilesRead {
    func readProject() {
        let path = "/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone.xcodeproj"
//        let path = "file:///Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone.xcodeproj"
        
        guard let xcodeproj = try? XcodeProj.init(pathString: path) else { return}
        let targetName = "GuanMing"
        
        for item in xcodeproj.pbxproj.projects {
            print(item.name)
        }
        var oldTarget:PBXNativeTarget!
        for item in xcodeproj.pbxproj.nativeTargets {
            print(item.name)
            if item.name == "XinMing" {
                oldTarget = item
            }
        }
        let newTarget = PBXNativeTarget.init(name: targetName)
        newTarget.buildConfigurationList = oldTarget.buildConfigurationList
        newTarget.buildPhases = oldTarget.buildPhases
        newTarget.buildRules = oldTarget.buildRules
        newTarget.dependencies = oldTarget.dependencies
        newTarget.productName = oldTarget.productName
        newTarget.productType = oldTarget.productType
        xcodeproj.pbxproj.add(object: newTarget)
        
        var oldScheme:XCScheme!
        if let schemes = xcodeproj.sharedData?.schemes {
            for item in schemes.enumerated() {
                if item.element.name == "XinMing" {
                    oldScheme = item.element
                }
            }
        }
        
        let newScheme = XCScheme.init(name: targetName,
                                      lastUpgradeVersion: oldScheme.lastUpgradeVersion,
                                      version: oldScheme.version,
                                      buildAction: oldScheme.buildAction,
                                      testAction: oldScheme.testAction,
                                      launchAction: oldScheme.launchAction,
                                      profileAction: oldScheme.profileAction,
                                      analyzeAction: oldScheme.analyzeAction,
                                      archiveAction: oldScheme.archiveAction,
                                      wasCreatedForAppExtension: oldScheme.wasCreatedForAppExtension)
        xcodeproj.sharedData?.schemes.append(newScheme)
        try? xcodeproj.writeSchemes(path: Path.init(path))
        
        var oldFileReference:PBXFileReference!
        for item in xcodeproj.pbxproj.fileReferences {
            if let noNullItem = item.path ,noNullItem.contains("XinMing") {
                oldFileReference = item
            }
        }
        if oldFileReference != nil {
            let newFileReference = PBXFileReference.init(name: targetName)
            newFileReference.explicitFileType = oldFileReference.explicitFileType
            newFileReference.path = "\(targetName).app"
            newFileReference.sourceTree = oldFileReference.sourceTree
            newFileReference.lastKnownFileType = oldFileReference.lastKnownFileType
            newFileReference.path = oldFileReference.path
            xcodeproj.pbxproj.add(object: newFileReference)
        }
        
        let debugGuanMing = XCBuildConfiguration.init(name: targetName)
        let releaseGuanMing = XCBuildConfiguration.init(name: targetName)
        
        let oldConfigurationList:XCConfigurationList = XCConfigurationList.init(buildConfigurations: [debugGuanMing,releaseGuanMing],
                                                                                defaultConfigurationName: "Release", defaultConfigurationIsVisible: false)
        
//        var oldGroup:PBXGroup!
//        for item in xcodeproj.pbxproj.groups {
//            if item.name == "XinMing" {
//                oldGroup = item
//            }
//        }
//
//        var oldPBXFileElement:PBXFileElement!
//        for item in oldGroup.children {
//            if item.name == "XinMing" {
//                oldPBXFileElement = item
//            }
//        }
//
//        var childrens = oldGroup.children
//        let newElement = PBXFileElement.init(sourceTree: oldPBXFileElement.sourceTree,
//                                             path: oldPBXFileElement.path,
//                                             name: oldTarget.name,
//                                             includeInIndex: oldPBXFileElement.includeInIndex,
//                                             usesTabs: oldPBXFileElement.usesTabs,
//                                             indentWidth: oldPBXFileElement.indentWidth,
//                                             tabWidth: oldPBXFileElement.tabWidth,
//                                             wrapsLines: oldPBXFileElement.wrapsLines)
//        childrens.append(newElement)
//
//        let newGroup = PBXGroup.init(children: childrens,
//                                     sourceTree: oldGroup.sourceTree,
//                                     name: targetName,
//                                     path: oldGroup.path,
//                                     includeInIndex: oldGroup.includeInIndex,
//                                     wrapsLines: oldGroup.wrapsLines,
//                                     usesTabs: oldGroup.usesTabs,
//                                     indentWidth: oldGroup.indentWidth,
//                                     tabWidth: oldGroup.tabWidth)
        
        xcodeproj.pbxproj.add(object: newTarget)
        
        xcodeproj.pbxproj.add(object: oldConfigurationList)
//        xcodeproj.pbxproj.add(object: newGroup)
        
        try? xcodeproj.write(pathString: path, override: true)
        
//        if let content: String = try? projectFilePath.read() {
//            let lines = content.components(separatedBy: .newlines)
//            var results:[String] = []
//            for line in lines {
//                var containImage = true
//                outerLoop: for file in deletedFiles {
//                    if line.contains(file.fileName) {
//                        containImage = false
//                        continue outerLoop
//                    }
//                }
//                if containImage {
//                    results.append(line)
//                }
//            }
            
//            let resultString = results.joined(separator: "\n")
//
//            do {
//                try projectFilePath.write(resultString)
//            } catch {
//                print(error)
//            }
//
//        }
        
    }
}



