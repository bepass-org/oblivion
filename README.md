# Oblivion - Unofficial Warp Client for Android

"Internet, for all or none!"

Oblivion provides secure, optimized internet access through a user-friendly Android app using cloudflare warp technology

It's leveraging `bepass-sdk` and a custom Go implementation of WireGuard, it's designed for fast and private online experiences.

![oblivion3.jpg](media/oblivion3.jpg)

## Features

- **Secure VPN**: Custom WireGuard implementation in Go.
- **Optimized Speeds**: Enhanced with `bepass-sdk` for minimal latency.
- **User-Friendly**: Simple, intuitive interface.

## Quick Start

1. **Download**: Grab the APK from our [Releases](https://github.com/bepass-org/oblivion/releases) page or [Google play store](https://play.google.com/store/apps/details?id=org.bepass.oblivion) and install it.
   <a href="https://play.google.com/store/apps/details?id=org.bepass.oblivion">
   <img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png" width="165" height="64" />
   </a>

2. **Connect**: Launch Oblivion and hit the switch button.

## Building the Project

### Prerequisites
- NDK r26b (26.1.10909125)
- Go 1.22

### Follow the steps below to build the Oblivion:
- In Android Studio, navigate to "Build" in the menu bar.
- Select "Generate Signed Bundle/APK..."
- Choose "APK" and proceed.

## Get Involved

We're a community-driven project, aiming to make the internet accessible for all. Whether you want to contribute code, suggest features, or need some help, we'd love to hear from you! Check out our [GitHub Issues](https://github.com/bepass-org/oblivion/issues) or submit a pull request.

## Acknowledgements and Credits

This project makes use of several open-source tools and libraries, and we are grateful to the developers and communities behind these projects. In particular, we would like to acknowledge:

### Cloudflare Warp

- **Project**: Cloudflare Warp
- **Website**: [Cloudflare Warp](https://www.cloudflare.com/products/warp/)
- **License**: [License information](https://www.cloudflare.com/application/terms/)
- **Description**: Cloudflare Warp is a technology that enhances the security and performance of Internet applications. We use it in our project for its efficient and secure network traffic routing capabilities.

### WireGuard-go

- **Project**: WireGuard-go
- **GitHub Repository**: [WireGuard-go on GitHub](https://github.com/WireGuard/wireguard-go)
- **License**: [GNU General Public License v2.0](https://github.com/WireGuard/wireguard-go/blob/master/COPYING)
- **Description**: WireGuard-go is an implementation of the WireGuard secure network tunnel. It's used in our project to provide fast, modern, and secure VPN tunneling.

Please note that the use of these tools is governed by their respective licenses, and you should consult those licenses for terms and conditions of use.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License - see the [CC BY-NC-SA 4.0 License](https://creativecommons.org/licenses/by-nc-sa/4.0/) for details.

### Summary of License

The CC BY-NC-SA 4.0 License is a free, copyleft license suitable for non-commercial use. Here's what it means for using this project:

- **Attribution (BY)**: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

- **NonCommercial (NC)**: You may not use the material for commercial purposes.

- **ShareAlike (SA)**: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

This summary is only a brief overview. For the full legal text, please visit the provided link.
