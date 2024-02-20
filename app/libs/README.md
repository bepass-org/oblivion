# How To build?

## Go Version "MUST be exactly go 1.20" because of psiphon library then you can run

```sh
go run golang.org/x/mobile/cmd/gomobile init
go run golang.org/x/mobile/cmd/gomobile bind -ldflags="-w -s" -target=android -androidapi=21 -o=tun2socks.aar .
```
