**LeafSheep**
# The NEXT XUL platform & Meta web browser
> Sorry, due to the limitations of our equipment, currently, for those not compatible with Windows or Linux or FreeBSD and X86_64, you will need to build it yourself by running leafsheep_build.sh.

* * *

## Update Rules

**_a_._b_._c_._d_ = M._a_ SP _b_ -_d_ (_c_)**

1. **a:** Main version number.
2. **b:** Function update version number.
3. **c:** Service Pack update version number.
4. **d:** 0 indicates that this is the first kernel binary of this SP. 1 means that this version's kernel binary will be continuously updated. _(In some third-party releases, 'd' usually indicates the number of platform updates.)_

| Update | Third-party Release | Official Release | Official Appimage |
|----|----|----|----|
| LSVAPI Update | ✗ | ✓ | ✓ |
| Automation Update | ⚠ | ✗ | ✗ |
| Difference Update | ⚠ | ✗ | ✓ |
| Main Version Update | ✓ | ✓ | ✓ |
| Service Pack Update | ✗ | ✓ | ✓ |
| Platform Update | ✗ | ⚠ | ✓ |

* * *

## Prerequisites:
### Windows
**At least Windows 11 64-bit (32-bit build environments is not supported)**

**Microsoft Visual Studio 2026 (Community Edition (free) or Pro/Paid version -- Express won't work).**

We're assuming you're using the Community Edition for this document.
Select the following components during install:
- **Desktop development with C++**
- **Game development with C++**
- Verify you have also selected **Windows 11 SDK 10.0.26100.0** in the right pane under "Installation details"

You may also want to consider installing the IDE in a different location with a shorter path, but please do leave the SDK paths to default when you do (only change the top option).
Screenshot for clarity.

**MozillaBuild 3.4 (4.0+ is not recommended as it relies on recent Mozilla changes for clang building and won't work for MSVC out of the box!).**

This is an all-in-one build package with software licensed under various Open Source and permissive licenses. See the individual components in the package after extraction for details.

**Important note: Do not install the build tools in a path with spaces in the name! Some of the build tools don't work properly if the installation path has spaces.**

**At least 8 GB RAM (16 GB or more strongly recommended, especially if building with parallel tasks)**

**Plenty of freer/runtime issue leading to browser instability, that you need to work around by using an older version of the compiler and runtimes.**

In this case you need to go into "individual components" of the Visual Studio installer, and select the following components in addition:

- **MSVC v143 - VS 2022 C++ x64/x86 build tools (v14.33-17.3) (Out of Support)**
- **C++ 14.33 (17.3) ATL for v143 build tools (x86 & x64) (Out of support)**
- **C++ 14.33 (17.3) ATL for v143 build tools with Spectre mitigations (x86 & x64) (Out of support)**
- **C++/CLI support for v143 build tools (x86 & x64) (Out of support)**
- **C++ 14.33 (17.3) MFC for v143 build tools with Spectre mitigations (x86 & x64) (Out of support)**
- **Windows 11 SDK (10.0.22621.0)**

### Linux

- **GNU Compiler Collection (see below)**
- **Python 2.7.18 & 3.14.x**
- **Yasm 1.2.0 or higher**
- **XZ**
- **Plenty of free disk space**
- **At least 6 GB RAM free depending on number of processor cores**
  (limit using the mk_add_options MOZ_MAKE_FLAGS="-jN" option)
- **Various distribution specific development packages**
- **General system requirements for running the application itself**

### illumos

- **GCC version 10.x**
- **Python 2.7.18 & 3.14.x**
- **Exactly Autoconf 2.13**
- **Yasm 1.2.0 or higher**
- **GTK 3.x**
- **X.Org**
- **XZ**
- **Motif**
- **Sun Workshop/Sunpro libc**
- **Audio Header files**
- **pkg-config**
- **Plenty of free disk space**
- **At least 6 GB RAM free depending on number of processor cores** (limit using the mk_add_options MOZ_MAKE_FLAGS="-jN" option)
- **Various distribution specific development packages**
- **General system requirements for running the application itself**

### BSD
Same as Linux.


## Build
**Run `leafsheep_build.sh`**

* * *
### RheoEcho_Studio
### 2026.02.24 - Forever