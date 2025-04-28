# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

If a release contains security fixes, it is strongly recommended to update to the latest version as soon as possible!

## [0.1.4] - 2025-04-28
### Fixed
- The resource loader now properly loads resources which have properties ending in `path` in sub-resources ([#9](https://github.com/derkork/godot-safe-resource-loader/issues/9)).

## [0.1.3] - 2025-04-23
### Security fixes
- Fixed a security issue where the attacker could circumvent the safe resource loading by using `NodePath`s ([GHSA-9hrm-6m9q-36jx](https://github.com/derkork/godot-safe-resource-loader/security/advisories/GHSA-9hrm-6m9q-36jx)).
- Fixed a security issue where the attacker could circumvent the safe resource loading by using `StringName`s ([GHSA-pv3c-c5qh-vx2h](https://github.com/derkork/godot-safe-resource-loader/security/advisories/GHSA-pv3c-c5qh-vx2h))
- Another huge thanks goes out to [Patou](https://github.com/xorblo-doitus) for reporting these issues and helping me to provide a fix!

## [0.1.2] - 2025-04-18
### Improved
- Added an automated test suite to check that previously reported vulnerabilities remain fixed when doing changes to the code.

### Fixed
- Updated version number in the `plugin.cfg` file to match the version number in the `CHANGELOG.md` file ([#5](https://github.com/derkork/godot-safe-resource-loader/issues/5)).

### Security fixes 
- Fixed a security issue where an attacker could circumvent the safe resource loading by inserting comments into the file that would trip up the detector ([GHSA-x58g-598w-5px4](https://github.com/derkork/godot-safe-resource-loader/security/advisories/GHSA-x58g-598w-5px4)). 
- Fixed a security issue where an attacker could circumvent the safe resource loading by inserting extra line breaks into the file that would trip up the detector ([GHSA-3jm6-vgw3-j54p](https://github.com/derkork/godot-safe-resource-loader/security/advisories/GHSA-3jm6-vgw3-j54p)).
- A huge thanks goes out to [Patou](https://github.com/xorblo-doitus) for reporting these issues and helping me to provide a fix!

## [0.1.1] - 2025-04-14
### Security fixes
- Fixed a security issue where an attacker could circumvent the safe resource loading by adding more than one `path` attribute into an `ext_resource` declaration. A huge thanks goes to [Typed SIGTERM](https://github.com/typed-sigterm) for reporting this and helping me to provide a fix and set up some vulnerability reporting for this repo ([GHSA-5vf5-j43p-g226](https://github.com/derkork/godot-safe-resource-loader/security/advisories/GHSA-5vf5-j43p-g226))!


## [0.1.0] - 2023-11-19
### Breaking change
- Added a scan for any kind of resource that is outside of res://. If resources now contain any reference to another resource that is outside of res:// they will not be loaded. This prevents injecting scripts by putting script files next to the resource. 

## [0.0.1] - 2023-10-12
- Initial release.
