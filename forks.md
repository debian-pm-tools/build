# List of forked packages

## [ofono](https://gitlab.com/debian-pm/ofono):
- added ofono-voicecall patches (required for modem and calling on mainline)

## [qtwebengine](https://gitlab.com/debian-pm/qtwebengine):
- added EGL fallback patch (makes QtWebEngine based browsers work)

## [qtbase](https://gitlab.com/debian-pm/qtbase):
- enabled GL es on i386 and arm64
- disabled features depending on kernel 3.16+ (we support devices with older kernels)

## [qtmultimedia](https://gitlab.com/debian-pm/qtmultimedia):
- Changed and recompiled to work with GL es qtbase

## [kaidan](https://gitlab.com/debian-pm/kaidan)
- Not really a fork, just provides git snapshot for our ci

## [pulseaudio](https://gitlab.com/debian-pm/pulseaudio):
- Add support for out of tree modules, fork isn't neccesary at runtime

## [kwin](https://gitlab.com/debian-pm/kwin):
- Enabled hwcomposer backend for Halium devices

