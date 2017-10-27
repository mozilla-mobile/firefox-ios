

# Add a link to the Bugzilla bug

# for debugging uncomment out these 2 lines
# require 'pry'
# binding.pry

# Run swiftlint
swiftlint.lint_files

# Localized Strings check
changedFiles = (git.added_files + git.modified_files).select{|file| file.end_with?(".swift")}
changedFiles.select{|file| file != "Client/Frontend/Strings.swift" }.each do |changed_file|
  addedLines = git.diff_for_file(changed_file).patch.lines.select{ |line| line.start_with?("+") }
  if addedLines.select{ |line| line.include?("NSLocalizedString") }.count != 0
    warn("NSLocalizedString should only be added to Strings.swift")
    break # We only need to show the warning once
  end
end

# Add a friendly reminder for Sentry
changedFiles.each do |changed_file|
  addedLines = git.diff_for_file(changed_file).patch.lines.select{ |line| line.start_with?("+") }
  if addedLines.select{ |line| line.include?("Sentry.shared.send") }.count != 0 
    markdown("### Sentry check list")
    markdown("- [ ] I understand that only .fatal events will be reported on release")
    markdown("- [ ] The message param contains a string that will not create multiple events")
    break
  end
end

# Add a friendly reminder for LeanPlum
changedFiles.each do |changed_file|
  addedLines = git.diff_for_file(changed_file).patch.lines.select{ |line| line.start_with?("+") }
  if addedLines.select{ |line| line.include?("LeanplumIntegration.sharedInstance.track") }.count != 0 
    markdown("### LeanPlum checklist")
    markdown("- [ ] I have updated the MMA.md doc")
    markdown("- [ ] I have gone through the data privacy review")
    break
  end
end

# Fail if diff contains !try or as!
changedFiles.each do |changed_file|
  # filter out only the lines that were added
  addedLines = git.diff_for_file(changed_file).patch.lines.select{ |line| line.start_with?("+") }
  fail("No new force try! or as!") if addedLines.select{ |line| (line.include?("as!") || line.include?("try!")) }.count != 0 
end


#limit the number of new lines added to BVC to less than 10
