package tun2socks

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/netip"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"
	"tun2socks/lwip"

	"github.com/bepass-org/warp-plus/app"
	"github.com/bepass-org/warp-plus/wiresocks"
	L "github.com/xjasonlyu/tun2socks/v2/log"
)

// Variables to hold flag values.
var (
	logMessages []string
	mu          sync.Mutex
	ctx         context.Context
	cancelFunc  context.CancelFunc
	l           *slog.Logger
)

type StartOptions struct {
	TunFd          int
	Path           string
	FakeIPRange    string
	Verbose        bool
	BindAddress    string
	Endpoint       string
	License        string
	Country        string
	PsiphonEnabled bool
	Gool           bool
	DNS            string
	EndpointType   int
}

var global StartOptions

type logWriter struct{}

func (writer logWriter) Write(bytes []byte) (int, error) {
	mu.Lock()
	defer mu.Unlock()
	logMessages = append(logMessages, string(bytes))
	return len(bytes), nil
}

func Start(opt *StartOptions) {
	global = *opt

	ctx, cancelFunc = signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)

	if err := os.Chdir(global.Path); err != nil {
		l.Error("error changing to 'main' directory", "error", err.Error())
		os.Exit(1)
	}

	logger := logWriter{}

	lOpts := slog.HandlerOptions{
		Level: func() slog.Level {
			if global.Verbose {
				return slog.LevelDebug
			}
			return slog.LevelInfo
		}(),
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if (a.Key == slog.TimeKey || a.Key == slog.LevelKey) && len(groups) == 0 {
				return slog.Attr{} // remove excess keys
			}
			return a
		},
	}

	l = slog.New(slog.NewTextHandler(logger, &lOpts))
	r, w, _ := os.Pipe()
	os.Stdout = w
	os.Stderr = w
	L.SetLevel(L.DebugLevel)
	L.SetOutput(logger)

	go func(reader io.Reader) {
		scanner := bufio.NewScanner(reader)
		for scanner.Scan() {
			logger.Write([]byte(scanner.Text()))
		}
		if err := scanner.Err(); err != nil {
			fmt.Fprintln(os.Stderr, "There was an error with the scanner", err)
		}
	}(r)
    l.Info(fmt.Sprintf("%+v", *opt))
	var scanOpts *wiresocks.ScanOptions
	if global.Endpoint == "" {
		scanOpts = &wiresocks.ScanOptions{
			V4:     false,
			V6:     false,
			MaxRTT: 1500 * time.Millisecond,
		}
		switch global.EndpointType {
		case 0:
			scanOpts.V4 = true
			scanOpts.V6 = true
		case 1:
			scanOpts.V4 = true
		case 2:
			scanOpts.V6 = true
		}
	}

	var psiphonOpts *app.PsiphonOptions
	if global.PsiphonEnabled {
		psiphonOpts = &app.PsiphonOptions{
			Country: global.Country,
		}
	}

	err := app.RunWarp(ctx, l, app.WarpOptions{
		Bind:     netip.MustParseAddrPort(global.BindAddress),
		DnsAddr:  netip.MustParseAddr(opt.DNS),
		Endpoint: global.Endpoint,
		License:  global.License,
		Psiphon:  psiphonOpts,
		Gool:     global.Gool,
		Scan:     scanOpts,
	})
	if err != nil {
		l.Error(err.Error())
		os.Exit(1)
	}

	tun2socksStartOptions := &lwip.Tun2socksStartOptions{
		TunFd:        global.TunFd,
		Socks5Server: strings.Replace(global.BindAddress, "0.0.0.0", "127.0.0.1", -1),
		FakeIPRange:  "24.0.0.0/8",
		MTU:          0,
		EnableIPv6:   true,
		AllowLan:     true,
	}
	if ret := lwip.Start(tun2socksStartOptions); ret != 0 {
		l.Error("failed to start LWIP")
		os.Exit(1)
	}

	go func() {
		<-ctx.Done()
		lwip.Stop()

		l.Info("server shut down gracefully")
	}()
}

func Stop() {
	os.Exit(0)
}

func GetLogMessages() string {
	mu.Lock()
	defer mu.Unlock()
	if len(logMessages) == 0 {
		return ""
	}
	logs := strings.Join(logMessages, "\n")
	logMessages = nil // Clear logMessages for better memory management
	return logs
}
