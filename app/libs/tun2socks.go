package tun2socks

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"

	"github.com/bepass-org/wireguard-go/app"
	"tun2socks/gvisor"
)

// Variables to hold flag values.
var (
	verbose        *bool
	bindAddress    *string
	endpoint       *string
	license        *string
	country        *string
	psiphonEnabled *bool
	gool           *bool
	scan           *bool
)

// Cancel function to stop the server.
var cancelFunc context.CancelFunc

// A WaitGroup for the main goroutine to wait for the shutdown to complete.
var wg sync.WaitGroup

func RunWarp(argStr, fd, path string) {
	// Parse command-line arguments.
	args := strings.Split(argStr, " ")
	fs := flag.NewFlagSet("tun2socks", flag.ExitOnError)
	verbose = fs.Bool("v", false, "verbose")
	bindAddress = fs.String("b", "127.0.0.1:8086", "socks bind address")
	endpoint = fs.String("e", "notset", "warp clean ip")
	license = fs.String("k", "notset", "license key")
	country = fs.String("country", "", "psiphon country code in ISO 3166-1 alpha-2 format")
	psiphonEnabled = fs.Bool("cfon", false, "enable psiphonEnabled over warp")
	gool = fs.Bool("gool", false, "enable warp gooling")
	scan = fs.Bool("scan", false, "enable warp scanner(experimental)")
	err := fs.Parse(args)
	if err != nil {
		log.Fatalf("Failed to parse flags: %v", err)
	}

	// Setup context with cancellation.
	ctx, cancel := context.WithCancel(context.Background())
	cancelFunc = cancel
	wg.Add(1)

	// Start your long-running process.
	go runServer(ctx, fd)

	// Wait for interrupt signal.
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	select {
	case <-sigCh:
		// Received an interrupt signal, shut down.
		log.Println("Shutting down server...")
		cancelFunc()
	case <-ctx.Done():
		// Context was cancelled, perhaps from another part of the app calling Shutdown().
	}

	// Wait for the server goroutine to finish.
	wg.Wait()
	log.Println("Server shut down gracefully.")
}

func runServer(ctx context.Context, fd string) {
	defer wg.Done()

	// Start wireguard-go and gvisor-tun2socks.
	go app.RunWarp(*psiphonEnabled, *gool, *scan, *verbose, *country, *bindAddress, *endpoint, *license)

	key := &gvisor.Key{
		Mark:                     0,
		MTU:                      0,
		Device:                   "fd://" + fd,
		Interface:                "",
		LogLevel:                 "debug",
		Proxy:                    "socks5://" + *bindAddress,
		RestAPI:                  "",
		TCPSendBufferSize:        "",
		TCPReceiveBufferSize:     "",
		TCPModerateReceiveBuffer: false,
	}
	gvisor.Insert(key)
	gvisor.Start()

	// Wait for context cancellation.
	<-ctx.Done()

	// Perform cleanup and exit.
	gvisor.Stop()
	log.Println("Cleanup done, exiting runServer goroutine.")
}

// Shutdown can be called to stop the server from another part of the app.
func Shutdown() {
	if cancelFunc != nil {
		cancelFunc()
	}
}
