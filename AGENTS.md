<!--
  AGENTS.md
  DuGo-iOS

  Created by 김승원 on 8/10/26.
-->

# Project conventions

## File headers

- Every newly created source file must begin with the standard Xcode-style header.
- Use `김승원` as the author and the file's actual creation date in `d/M/yy` format.
- Use the owning target name, such as `DuGo-iOS` or `ShareExtension`, on the project line.
- Do not omit the header when creating files through scripts, patches, or generators.

```swift
//
//  FileName.swift
//  DuGo-iOS
//
//  Created by 김승원 on d/M/yy.
//
```

For non-Swift files, preserve the same information in that file format's native comment syntax.
