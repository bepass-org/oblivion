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

## Prerequisites
- Java 17
- Gradle 8
- Android Gradle Plugin (AGP) 7.4.2
- NDK r26b (26.1.10909125)
- Go 1.20.0

## Building the Project
Follow the steps below to build the Android project:

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
Navigate back to the project root:

```bash
cd ../..
```
Make gradlew script executable:

```bash
chmod +x ./gradlew
```
Build the project:

```bash
./gradlew build
```
Assemble release build:

```bash
./gradlew assembleRelease
```
Once the above steps are completed successfully, the Android project will be built, and the release APK will be assembled.

## Get Involved

We're a community-driven project, aiming to make the internet accessible for all. Whether you want to contribute code, suggest features, or need some help, we'd love to hear from you! Check out our [GitHub Issues](https://github.com/bepass-org/oblivion/issues) or submit a pull request.

## Disclaimer

Think of this as your new buddy in the digital realm. Like all friends, it comes with no warranties, but it promises to make your internet experience a lot more fun. Just remember, with great power comes great responsibility. Use it wisely!
