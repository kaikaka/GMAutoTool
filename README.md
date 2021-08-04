## 使用须知
- 需要XcodeProj依赖，请先执行`gem install xcodeproj`

- 如果执行报错，说明安装的ruby环境不是默认的系统环境，请检测你的ruby环境：
- `which ruby` eg:/Users/Yoon/.rvm/rubies/ruby-2.6.0/bin/ruby
- `gem env` 找到SHELL PATH，替换路径 eg:/Users/Yoon/.rvm/rubies/ruby-2.6.0/lib/ruby/gems/2.6.0/wrappers/pod
- 然后将这两个路径分别放到execDuplicteTarget方法和execCocoaPods方法