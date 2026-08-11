# Oblivion - Unofficial Warp Client

"Internet, for all or none!"

Oblivion provides secure, optimized internet access through a user-friendly app
using Cloudflare Warp technology.

It is built on [Aether](https://github.com/CluvexStudio/Aether), a user-space
Warp core written in Rust that speaks MASQUE and WireGuard, and runs on Android,
Windows and Linux from one codebase.

![oblivion3.jpg](media/oblivion3.jpg)

## Features

- **Two transports**: MASQUE over QUIC/HTTP-3 or HTTP/2, and classic WireGuard.
- **Zero Trust**: connect as a managed device on your organization's Cloudflare
  account, signing in with an emailed code, a service token, or a token you hold.
- **Traffic rules**: block a destination outright, or send it straight out and
  bypass the tunnel, which is what banking apps and domestic sites need.
- **Split tunnelling**: choose which Android apps stay off the tunnel.
- **Obfuscation**: profiles that reshape the handshake for networks that
  fingerprint it.
- **User-Friendly**: simple, intuitive interface in Persian and English.

## Quick Start

1. **Download**: Grab the build for your platform from our
   [Releases](https://github.com/bepass-org/oblivion/releases) page and install it.

2. **Connect**: Launch Oblivion and hit the switch button.

On Android the app runs as a VPN service and needs no root. On Windows and Linux
it exposes a local SOCKS5 proxy, and full device routing needs administrator
rights.

## Building the Project

### Prerequisites

- Flutter 3.44 or newer
- Rust (stable) for the Aether core and the FFI bridge
- Android NDK r27 or newer, and JDK 17, for Android builds
- CMake, Ninja, Clang and `libgtk-3-dev` for Linux builds

### Clone with the submodules

The Aether core and hev-socks5-tunnel live in their own repositories and are
linked here as submodules, so clone recursively:

```sh
git clone --recursive https://github.com/bepass-org/oblivion.git
```

If you already cloned without `--recursive`:

```sh
git submodule update --init --recursive
```

### Build

```sh
flutter pub get

flutter build apk --release --split-per-abi
flutter build apk --release
flutter build linux --release
flutter build windows --release
```

The Android build cross compiles the Aether core for each ABI on the fly, so the
first build takes a while. Add `--target-platform android-arm64` to build for one
ABI only.

Release APKs are signed when `android/key.properties` exists, and fall back to
the debug key when it does not.

## Get Involved

We're a community-driven project, aiming to make the internet accessible for all. Whether you want to contribute code, suggest features, or need some help, we'd love to hear from you! Check out our [GitHub Issues](https://github.com/bepass-org/oblivion/issues) or submit a pull request.

## Acknowledgements and Credits

This project makes use of several open-source tools and libraries, and we are grateful to the developers and communities behind these projects. In particular, we would like to acknowledge:

### Cloudflare Warp

- **Project**: Cloudflare Warp
- **Website**: [Cloudflare Warp](https://www.cloudflare.com/products/warp/)
- **License**: [License information](https://www.cloudflare.com/application/terms/)
- **Description**: Cloudflare Warp is a technology that enhances the security and performance of Internet applications. We use it in our project for its efficient and secure network traffic routing capabilities.

### Aether

- **Project**: Aether
- **GitHub Repository**: [Aether on GitHub](https://github.com/CluvexStudio/Aether)
- **License**: [GNU Affero General Public License v3.0](https://github.com/CluvexStudio/Aether/blob/main/LICENSE)
- **Description**: Aether is the Warp core this app is built on. It implements MASQUE over QUIC and HTTP/2, WireGuard, endpoint discovery, obfuscation and Cloudflare Zero Trust enrolment, and exposes the tunnel as a local proxy.

### quiche

- **Project**: quiche
- **GitHub Repository**: [quiche on GitHub](https://github.com/cloudflare/quiche)
- **License**: [BSD 2-Clause](https://github.com/cloudflare/quiche/blob/master/COPYING)
- **Description**: Cloudflare's QUIC and HTTP/3 implementation. Aether uses it to carry the MASQUE tunnel.

### hev-socks5-tunnel

- **Project**: hev-socks5-tunnel
- **GitHub Repository**: [hev-socks5-tunnel on GitHub](https://github.com/heiher/hev-socks5-tunnel)
- **License**: [MIT](https://github.com/heiher/hev-socks5-tunnel/blob/master/LICENSE)
- **Description**: A tun to socks5 forwarder. On Android it turns the packets from the VPN interface into proxy connections that the core carries.

### BoringTun

- **Project**: BoringTun
- **GitHub Repository**: [BoringTun on GitHub](https://github.com/cloudflare/boringtun)
- **License**: [BSD 3-Clause](https://github.com/cloudflare/boringtun/blob/master/LICENSE)
- **Description**: A user-space WireGuard implementation in Rust, used for the WireGuard transport.

Please note that the use of these tools is governed by their respective licenses, and you should consult those licenses for terms and conditions of use.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License - see the [CC BY-NC-SA 4.0 License](https://creativecommons.org/licenses/by-nc-sa/4.0/) for details.

### Summary of License

The CC BY-NC-SA 4.0 License is a free, copyleft license suitable for non-commercial use. Here's what it means for using this project:

- **Attribution (BY)**: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

- **NonCommercial (NC)**: You may not use the material for commercial purposes.

- **ShareAlike (SA)**: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

This summary is only a brief overview. For the full legal text, please visit the provided link.
