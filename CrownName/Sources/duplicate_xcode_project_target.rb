#!/usr/bin/env ruby

require 'rubygems'
require 'xcodeproj'

name = 'GuanMing'

proj = Xcodeproj::Project.open('/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone.xcodeproj')
src_target = proj.targets.find { |item| item.to_s == 'XinMing' }

# create target
target = proj.new_target(src_target.symbol_type, name, src_target.platform_name, src_target.deployment_target)
target.product_name = name

# create scheme
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(proj.path, name)

# copy build_configurations
target.build_configurations.map do |item|
  item.build_settings.update(src_target.build_settings(item.name))
end

# copy build_phases
src_target.build_phases.each do |phase|
  target.build_phases << phase
end

# add files
#classes = proj.main_group.groups.find { |x| x.to_s == 'Group' }.groups.find { |x| x.name == 'Assets' }
#sources = target.build_phases.find { |x| x.instance_of? Xcodeproj::Project::Object::PBXSourcesBuildPhase }
#file_ref = classes.new_file('GuanMing/ColorConfig.plist')
#build_file = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
#build_file.file_ref = file_ref
#sources.files << build_file
#projTargetGroup = proj.main_group.groups.find { |x| x.path == 'Assets' }
#targetGroup =  projTargetGroup.new_group(name, name)

# 添加资源文件引用，注意和代码文件引用方式不同
#target.add_resources(
#  [
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

#                     targetGroup.new_reference("foowwphone/Assets/Guanming/ColorConfig.plist")
#    supportingGroup.new_reference("Supporting Files/Info.plist"),
#    supportingGroup.new_reference("Supporting Files/Images.xcassets"),
#    supportingGroup.new_reference("Supporting Files/InfoPlist.strings"),
#    supportingGroup.new_reference("Supporting Files/Localizable.strings")
#  ])


proj.save
