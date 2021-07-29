#!/usr/bin/env ruby
require 'rubygems'
require 'xcodeproj'
require 'fileutils'

#----------------------------------- 目标项目配置内容----------------------------#
name = "newyorktoon"
displayname = "纽约通"
target_toonType = 10001
target_pushType = "hello"
target_channel = "hello"
target_mapKey = "hello"
target_schemeType = "hello"
#----------------------------------- 目标项目配置内容----------------------------#

# 模板项目                   
 srcname = "XinMing"
# srcdisplayname = "后勤通"                                                 

#project
project_path = '/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone.xcodeproj'
# 复制资源文件，注意：
# 1. 复制资源文件时需要排除源资源文件
# 2. 在此文件的最后面将复制出来的资源文件添加到目标target
targetdir = "TNTarget/#{name}"
srcroot = "TNTarget/#{srcname}"

# 复制资源文件夹,将源target下的图片资源文件夹复制到目标target目录
if !Dir.exists?(targetdir)
  Dir.mkdir(targetdir)
end
codeDirs = [
  "#{srcroot}/foowwphone/Assets/XinMing"
]
#复制源target目录下的定制化代码目录到目标target目录
hasAllListFiles = false
codeDirs.each do |d|
  hasAllListFiles = Dir.exists?(d)#-> 此处假设所有的code file为一个整体，一有具有
  if hasAllListFiles
    FileUtils.cp_r  d, targetdir
  end
end

# 寻找模板target
proj = Xcodeproj::Project.open(project_path)
src_target = proj.targets.find { |item| item.to_s == srcname }
# 创建目标target
target = proj.new_target(src_target.symbol_type, name, src_target.platform_name, src_target.deployment_target)
target.product_name = name

# create scheme
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project_path, name)

#  build_configurations
target.build_configurations.map do |item|

#设置target相关配置
  item.build_settings.update(src_target.build_settings(item.name))
  # puts "-"*30 + "#{item.build_settings}" +"_"*30
  item.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.fooww.#{name}"
  item.build_settings["PRODUCT_NAME"] = displayname

  targetInfoPlist = item.build_settings["INFOPLIST_FILE"]
  item.build_settings["INFOPLIST_FILE"] = targetInfoPlist.sub(srcname, name)

  puts "-"*30 + "#{item.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}" +"_"*30
  puts "-"*30 + "#{item.build_settings['PRODUCT_NAME']}" +"_"*30
end

# build_phases
phases = src_target.build_phases.reject { |x| x.instance_of? Xcodeproj::Project::Object::PBXShellScriptBuildPhase }.collect(&:class)

#复制源target引用的source和resource文件引用
phases.each do |klass|
puts "||---------------------> copy phases #{klass}--------------------||"
  src = src_target.build_phases.find { |x| x.instance_of? klass }
  dst = target.build_phases.find { |x| x.instance_of? klass }

  unless dst
    dst ||= proj.new(klass)
    target.build_phases << dst
  end
  dst.files.map { |x| x.remove_from_project }

idx = 1
  src.files.each do |f|
# 排除文件，将源target中的文件排除，不引用该文件
    if f.file_ref and f.file_ref.hierarchy_path.index(srcroot) != nil
      puts "\n................... ignore file:  #{f.file_ref}, #{f.file_ref.hierarchy_path}...................\n"
        next
    end

    file_ref = proj.new(Xcodeproj::Project::Object::PBXFileReference)
    if f.settings
      puts ">>file.settings:  #{idx} > file: " + f.file_ref.to_s + " settings: " + f.settings.to_s
    end

    idx = idx+1
    if f.file_ref
      if f.file_ref.name
        puts ">> file_ref name: #{f.file_ref.name} path: #{f.file_ref.path} source_tree: #{f.file_ref.source_tree}"
      end
      # puts ">> file path: #{f.file_ref.hierarchy_path}-- #{f.file_ref.real_path}"

      file_ref.name = f.file_ref.name
      file_ref.path = f.file_ref.path
      file_ref.source_tree = f.file_ref.source_tree
      file_ref.last_known_file_type = f.file_ref.last_known_file_type
      # file_ref.fileEncoding = f.file_ref.fileEncoding
      begin
        file_ref.move(f.file_ref.parent)
      rescue
    end

    end

    build_file = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.file_ref = f.file_ref
# 文件属性配置，如no-arc   
 if f.settings
    build_file.settings = f.settings
  end
    dst.files << build_file
  end
end

#设置目标target文件组
projTargetGroup = proj.main_group.groups.find { |x| x.path == 'TNTarget' }
targetGroup =  projTargetGroup.new_group(name, name)
# resource
resourceGroup = targetGroup.new_group("Resources", "./Resources")
supportingGroup=resourceGroup.new_group("Supporting Files")

# 添加资源文件引用，注意和代码文件引用方式不同
target.add_resources(
  [
#    resourceGroup.new_reference("areaCode.plist"),
#    resourceGroup.new_reference("login_toon_bg@2x.png"),
#    resourceGroup.new_reference("login_toon_bg@3x.png"),
#    resourceGroup.new_reference("tab_item_home_highlight@2x.png"),
#    resourceGroup.new_reference("tab_item_home_highlight@3x.png"),
#    resourceGroup.new_reference("tab_item_home_normal@2x.png"),
#    resourceGroup.new_reference("tab_item_home_normal@3x.png"),
#    resourceGroup.new_reference("Toon_logo@2x.png"),
#    resourceGroup.new_reference("Toon_logo@3x.png"),
#    resourceGroup.new_reference("toon_serviceProtocol.html"),
#    resourceGroup.new_reference("user_protocol.html"),
#    resourceGroup.new_reference("NewFunction.html"),

    supportingGroup.new_reference("foowwphone/Assets/XinMing/ColorConfig.plist"),
#    supportingGroup.new_reference("Supporting Files/Info.plist"),
#    supportingGroup.new_reference("Supporting Files/Images.xcassets"),
#    supportingGroup.new_reference("Supporting Files/InfoPlist.strings"),
#    supportingGroup.new_reference("Supporting Files/Localizable.strings")
  ])

#  if hasAllListFiles
## 添加代码文件组
#code1 = targetGroup.new_group("NetWork", "./NetWork")
#code2 = targetGroup.new_group("TabbarSetDataSource", "./TabbarSetDataSource")
#code3 = targetGroup.new_group("TNHQHome", "./TNHQHome")
#
## 添加代码文件引用
#    target.add_file_references(
#      [
#        code1.new_reference("NetworkRequestURL.h"),
#        code1.new_reference("NetworkRequestURL.m"),
#
#        code2.new_reference("TNTabSettingDataSource.h"),
#        code2.new_reference("TNTabSettingDataSource.m"),
#
#        code3.new_reference("TNHomeViewController.m")
#        ])
#  end

  # 修改文件通用内容
#  infoplistfile = "#{targetdir}/Resources/Supporting Files/Info.plist"
#  files = [
#    "#{targetdir}/Resources/areaCode.plist",
#    "#{targetdir}/Resources/toon_serviceProtocol.html",
#    "#{targetdir}/Resources/user_protocol.html",
#    "#{targetdir}/Resources/NewFunction.html",
#    infoplistfile,
#    "#{targetdir}/Resources/Supporting Files/InfoPlist.strings",
#    "#{targetdir}/Resources/Supporting Files/Localizable.strings"
#
#  ]
#  if hasAllListFiles
#     files << "#{targetdir}/TabbarSetDataSource/TNTabSettingDataSource.m"
#  end
#files.each do |f1|
#  File.open(f1) do |fr|
#      buffer = fr.read.gsub(srcdisplayname, displayname)
#      buffer= buffer.gsub("项目名", displayname)
#      buffer= buffer.gsub("大同", displayname)
#       File.open(f1, "w") { |fw| fw.write(buffer) }
#  end
#end

# 修改info.plist
#  File.open(infoplistfile) do |fr|
#    if hasAllListFiles
#      puts "*************************** 1"
#      buffer = fr.read.gsub("<string>10024</string>", "<string>#{target_pushType}</string>")
#      buffer= buffer.gsub("<integer>124</integer>", "<integer>#{target_toonType}</integer>")
#      buffer= buffer.gsub("<string>1241002</string>", "<string>#{target_channel}</string>")
#      buffer= buffer.gsub("<string>8058bda8c0ad5a7cfb8742cfbac4ecb8</string>", "<string>#{target_mapKey}</string>")
#      buffer= buffer.gsub("<string>toon124</string>", "<string>#{target_schemeType}</string>")
#    else
#      puts "*************************** 2"
#      buffer = fr.read.gsub("<string>10016</string>", "<string>#{target_pushType}</string>")
#      buffer= buffer.gsub("<integer>116</integer>", "<integer>#{target_toonType}</integer>")
#      buffer= buffer.gsub("<string>10035</string>", "<string>#{target_channel}</string>")
#      buffer= buffer.gsub("<string>e851d7df83d59f143bff1ad5a3a8e554</string>", "<string>#{target_mapKey}</string>")
#      buffer= buffer.gsub("<string>toon116</string>", "<string>#{target_schemeType}</string>")
#    end
#    puts "*************************** updating InfoPlist"
#
#    File.open(infoplistfile, "w") { |fw| fw.write(buffer) }
#
#  end
proj.save

# 修改Podfile
#puts ">> prepare loading pods ..."
#podTarget = "target '#{name}' do shared_pods  end"
#File.open("Podfile") do |file|
#  if file.read().index(podTarget) ==nil
#    File.open(infoplistfile, "w") { |fw| fw.puts podTarget }
#    puts ">> add pod item"
#  else
#    puts ">> pod has been added"
#  end
#
#end

# file.close

# 更新pod依赖
exec 'pod install'
