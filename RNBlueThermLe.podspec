
Pod::Spec.new do |s|
  s.name         = "RNBlueThermLe"
  s.version      = "1.0.0"
  s.summary      = "RNBlueThermLe"
  s.description  = <<-DESC
                  RNBlueThermLe
                   DESC
  s.homepage     = "https://github.com/blanketinc/blue-therm-le.git"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/blanketinc/blue-therm-le.git", :tag => "master" }
  s.source_files = 'ios/**/*.{h,m,a}'

  s.dependency "React"
  #s.dependency "others"

end

