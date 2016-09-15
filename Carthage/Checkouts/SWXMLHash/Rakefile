def run(command)
  system(command) or raise "RAKE TASK FAILED: #{command}"
end

desc 'Clean, build and test SWXMLHash'
task :test do |t|
  xctool_build_cmd = './scripts/build.sh'

  if system('which xctool')
    run xctool_build_cmd
  else
    if system('which xcpretty')
      run "#{xcode_build_cmd} | xcpretty -c"
    else
      run xcode_build_cmd
    end
  end
end
