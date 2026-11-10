fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios bump

```sh
[bundle exec] fastlane ios bump
```

Build-Nummer als Zeitstempel YYYYMMDDHHMM (wie in den anderen Projekten), immer hoeher als die letzte

### ios signing

```sh
[bundle exec] fastlane ios signing
```

Verteilungszertifikat und App-Store-Profile per API-Schluessel (ohne Xcode-Konto)

### ios archive

```sh
[bundle exec] fastlane ios archive
```

Archiv und .ipa unter build/

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build hochladen, auf Verarbeitung warten, interner Gruppe zuweisen

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Store-Texte (und optional Screenshots) hochladen, ohne Einreichung

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
