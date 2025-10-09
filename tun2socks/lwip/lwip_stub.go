//go:build !android
// +build !android

package lwip

type Tun2socksStartOptions struct {
	TunFd        int
	Socks5Server string
	FakeIPRange  string
	MTU          int
	EnableIPv6   bool
	AllowLan     bool
}

// Start is a no-op on non-Android platforms; returns -1 to indicate unsupported.
func Start(opt *Tun2socksStartOptions) int { return -1 }

// Stop is a no-op on non-Android platforms.
func Stop() {}
