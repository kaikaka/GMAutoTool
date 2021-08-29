#!/usr/bin/env ruby

require 'rubygems'
require 'xcodeproj'

name = 'GUANMING-TEMP-ROOTNAME'

project = Xcodeproj::Project.open('GUANMING-TEMP-PATH')
target = project.targets.find { |item| item.to_s == 'GUANMING-TEMP-ROOTNAME' }

new_path = File.join("Foowwphone/Supporting Files/Assets","GUANMING-TEMP-ROOTNAME")
group = project.main_group.find_subpath(new_path, true )
group.set_source_tree("<group>")
group.set_path("GUANMING-TEMP-ROOTNAME")

file_ref1 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GUANMING-TEMP-ROOTNAME/ColorConfig.plist"))
file_ref2 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GUANMING-TEMP-ROOTNAME/Only.xcassets"))
file_ref3 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GUANMING-TEMP-ROOTNAME/Launch Screen.storyboard"))
file_ref4 = group.new_reference(File.join(project.project_dir, "/Foowwphone/Assets/GUANMING-TEMP-ROOTNAME/Info.plist"))

target.add_resources([file_ref1,file_ref2,file_ref3,file_ref4])

project.save
