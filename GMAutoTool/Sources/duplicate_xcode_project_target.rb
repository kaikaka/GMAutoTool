#!/usr/bin/env ruby

require 'rubygems'
require 'xcodeproj'

# 新target
name = 'GUANMING-TEMP-ROOTNAME'

# 文件路径
proj = Xcodeproj::Project.open('GUANMING-TEMP-PATH')

# 源target
src_target = proj.targets.find { |item| item.to_s == 'GUANMING-TEMP-SCRNAME' }

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


proj.save
