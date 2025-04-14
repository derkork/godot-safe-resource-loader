# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-04-14
### Fixed
- Fixed a security issue where an attacker could circumvent the safe resource loading by adding more than one `path` attribute into an `ext_resource` declaration. A huge thanks goes to [Typed SIGTERM](https://github.com/typed-sigterm) for reporting this and helping me to provide a fix and set up some vulnerability reporting for this repo ([GHSA-5vf5-j43p-g226](https://github.com/derkork/godot-safe-resource-loader/security/advisories/GHSA-5vf5-j43p-g226))! **Please update your plugin version as soon as possible!**


## [0.1.0] - 2023-11-19
### Breaking change
- Added a scan for any kind of resource that is outside of res://. If resources now contain any reference to another resource that is outside of res:// they will not be loaded. This prevents injecting scripts by putting script files next to the resource. 

## [0.0.1] - 2023-10-12
- Initial release.
