# safarisettingsdd

safari settings for dopamine.

version: 2.0.0

target: ios 16.3.1 dopamine (rootless)

## options

all options are **off by default**.

settings → safarisettingsdd

- hide favicons
- disable pull to refresh

after a toggle, force-quit safari.

the toolbar reload button still reloads the page.

## install

1. install preferenceloader from sileo if missing
2. install the `*_iphoneos-arm64.deb`
3. respring
4. search settings for safarisettingsdd
5. enable a toggle, force-quit safari

## build

github actions: `.github/workflows/build.yml`

local:

```
export THEOS=~/theos
make clean package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1
```

## notes

safari is sandboxed. the tweak reads prefs from
`/var/jb/var/mobile/Library/Preferences/com.safarisettingsdd.safarisettingsdd.plist`
so toggles work inside safari on dopamine.

## license

mit
