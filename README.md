# Oblivion - Unofficial Warp Client for Android

"Internet, for everyone or no one."

Oblivion provides secure, optimized internet access through a user-friendly Android app. 

Leveraging `bepass-sdk` and a custom Go implementation of WireGuard, it's designed for fast and private online experiences.

## Features

- **Secure VPN**: Custom WireGuard implementation in Go.
- **Optimized Speeds**: Enhanced with `bepass-sdk` for minimal latency.
- **User-Friendly**: Simple, intuitive interface.

## Quick Start

1. **Download**: Grab the APK from our [Releases](https://github.com/bepass-org/oblivion/releases) page.
2. **Install**: Open the APK file to install.
3. **Connect**: Launch Oblivion and hit the switch button.

## Building the Project

### Prerequisites
- Java 17
- Gradle 8
- Android Gradle Plugin (AGP) 8.1.2
- NDK r26b (26.1.10909125)
- Go 1.20.0

Follow the steps below to build the Oblivion:

### Building Go libraries
Open the Terminal tab at the bottom of Android Studio.

Navigate to the libs directory:

```bash
cd app/libs
```
Initialize Go modules and install required packages:

```bash
go mod tidy
go install golang.org/x/mobile/cmd/gomobile@latest
go install golang.org/x/mobile/cmd/gobind@latest
go get golang.org/x/mobile/cmd/gobind
go get golang.org/x/mobile/cmd/gomobile
go get golang.org/x/mobile
```
Initialize Go mobile:

```bash
gomobile init
```
Bind the Go package to Android:

```bash
gomobile bind -ldflags '-s -w' -o tun2socks.aar -androidapi 21 -target android .
```
### Generate Signed Bundle/APK:
- In Android Studio, navigate to "Build" in the menu bar.
- Select "Generate Signed Bundle/APK..."
- Choose "APK" and proceed.

#### Select Keystore:
- Click on "Choose existing..." or "Create new..." to locate your keystore file.
- Enter the keystore password when prompted.

#### Configure APK Signature:
- Select the appropriate key alias from the dropdown menu.
- Input the key password.
- Continue to the next step.

#### Select APK Destination:
- Choose the destination folder for the signed APK.
- Finalize by clicking "Finish" to generate the signed APK.

## Get Involved

We're a community-driven project, aiming to make the internet accessible for all. Whether you want to contribute code, suggest features, or need some help, we'd love to hear from you! Check out our [GitHub Issues](https://github.com/bepass-org/oblivion/issues) or submit a pull request.

## Disclaimer

Think of this as your new buddy in the digital realm. Like all friends, it comes with no warranties, but it promises to make your internet experience a lot more fun. Just remember, with great power comes great responsibility. Use it wisely!
