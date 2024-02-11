package tun2socks

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"tun2socks/lwip"

	"github.com/bepass-org/wireguard-go/app"
	L "github.com/xjasonlyu/tun2socks/v2/log"
)

// Variables to hold flag values.
var (
	logMessages []string
	mu          sync.Mutex
	wg          sync.WaitGroup
	cancelFunc  context.CancelFunc
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
	Scan           bool
	Rtt            int
}

var global StartOptions

type logWriter struct{}

func (writer logWriter) Write(bytes []byte) (int, error) {
	mu.Lock()
	defer mu.Unlock()
	logMessages = append(logMessages, string(bytes))
	return len(bytes), nil
}

func RunWarp(opt *StartOptions) {
	global = *opt
	logger := logWriter{}
	log.SetOutput(logger)
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
	if err := os.Chdir(global.Path); err != nil {
		log.Fatal("Error changing to 'main' directory:", err)
	}

	// Setup context with cancellation.
	ctx, cancel := context.WithCancel(context.Background())
	cancelFunc = cancel
	wg.Add(1)

	// Start your long-running process.
	go runServer(ctx, global.TunFd)

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

func runServer(ctx context.Context, fd int) {
	// Ensuring a cleanup operation even in the case of an error
	defer func() {
		// Perform cleanup and exit.
		lwip.Stop()
		log.Println("Cleanup done, exiting runServer goroutine.")

		defer wg.Done()
	}()

	// Start wireguard-go and gvisor-tun2socks.
	go func() {
		err := app.RunWarp(global.PsiphonEnabled, global.Gool, global.Scan, global.Verbose, global.Country, global.BindAddress, global.Endpoint, global.License, ctx, global.Rtt)
		if err != nil {
			log.Println(err)
		}
	}()

	tun2socksStartOptions := &lwip.Tun2socksStartOptions{
		TunFd:        fd,
		Socks5Server: strings.Replace(global.BindAddress, "0.0.0.0", "127.0.0.1", -1),
		FakeIPRange:  "24.0.0.0/8",
		MTU:          0,
		EnableIPv6:   true,
		AllowLan:     true,
	}
	lwip.Start(tun2socksStartOptions)

	// Wait for context cancellation.
	<-ctx.Done()
}

// Shutdown can be called to stop the server from another part of the app.
func Shutdown() {
	if cancelFunc != nil {
		cancelFunc()
		os.Exit(0)
	}
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
