# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2023-11-19
### Breaking change
- Added a scan for any kind of resource that is outside of res://. If resources now contain any reference to another resource that is outside of res:// they will not be loaded. This prevents injecting scripts by putting script files next to the resource. 

## [0.0.1] - 2023-10-12
- Initial release.
