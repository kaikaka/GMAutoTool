#!/usr/bin/env ruby

require 'rubygems'
require 'xcodeproj'
require 'fileutils'

name = 'GuanMing'

project = Xcodeproj::Project.open('/Users/Yoon/Desktop/live/fooww-mobile-ios/Foowwphone.xcodeproj')
target = project.targets.find { |item| item.to_s == 'GuanMing' }

new_path = File.join("Foowwphone/Supporting Files/Assets","GuanMing5")
group = project.main_group.find_subpath(new_path, true )
group.set_source_tree("<group>")
group.set_path("GuanMing5")

file_ref1 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GuanMing/ColorConfig.plist"))
file_ref2 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GuanMing/Only.xcassets"))
file_ref3 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GuanMing/Launch Screen.storyboard"))
file_ref4 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GuanMing/Info.plist"))

target.add_file_references([file_ref1,file_ref2,file_ref3,file_ref4])

project.save
