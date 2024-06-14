# defaults edit

A graphical user defaults editor for macOS.

## Get it

<a href="https://getovert.app/open?action=overt:brew-cask%3F1=add-source-repository%261[name]=thatsjustcheesy/homebrew-tap%261[url]=https://github.com/thatsjustcheesy/homebrew-tap%262=install%262[name]=defaults-edit"><img src="https://getovert.app/images/overt-badge.png" width="240" alt="Get it on Overt, an open app store"/></a>

Or on the command line:

```sh
brew install thatsjustcheesy/tap/defaults-edit
```

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

### Screenshots

![Viewing a nested dictionary](Screenshots/1.png)
![Defaults effective in domain, with filtering](Screenshots/2.png)
![Adding a default](Screenshots/3.png)
![Available property list types](Screenshots/4.png)

## Todos

- Ability to add items to arrays and dictionaries
- Implement Rename, which moves value to new key
- Duplicate, which copies value to new key
- Relaunch button when editing app defaults
