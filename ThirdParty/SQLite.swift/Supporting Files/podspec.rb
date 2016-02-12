$podspec_version = '1.0.0.pre'
$podspec_source_git = 'https://github.com/stephencelis/SQLite.swift.git'

def apply_shared_config spec, name
  spec.version = $podspec_version
  spec.source = { git: $podspec_source_git, tag: $podspec_version }

  spec.homepage = 'https://github.com/stephencelis/SQLite.swift'
  spec.license = { type: 'MIT', file: 'LICENSE.txt' }

  spec.author = { 'Stephen Celis' => 'stephen@stephencelis.com' }
  spec.social_media_url = 'https://twitter.com/stephencelis'

  # TODO: separate SQLiteCipher.swift and share `SQLite` module name
  # spec.module_name = 'SQLite'
  # spec.module_map = 'Supporting Files/module.modulemap'
  spec.module_name = name
  spec.module_map = "Supporting Files/#{name}/module.modulemap"

  spec.source_files = [
    "Supporting Files/#{name}/#{name}.h", 'Source/**/*.{swift,c,h,m}'
  ]

  spec.private_header_files = 'Source/Core/fts3_tokenizer.h'
end
