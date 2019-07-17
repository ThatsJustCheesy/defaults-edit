# defaults-edit
A graphical user defaults editor for macOS.

## Features
- Easily browse and search available domains
- Browse defaults in any domain, including contents of arrays and dictionaries
- Filter visible keys within domains
- Add and edit defaults with any primitive property list type:
  - String
  - Boolean
  - Integer
  - Real (float)
  - Date
  - Hex data
- Optionally, view all the defaults currently effective in a domain, regardless of where they are set

## Todos
- UI to edit the global domain
- Ability to add arrays and dictionaries
- Ability to edit contents of arrays and dictionaries
- Implement Rename, which moves value to new key
- Duplicate, which copies value to new key

## Bugs
- `com.apple.finder` doesn’t load properly. Will look into it… sometime.