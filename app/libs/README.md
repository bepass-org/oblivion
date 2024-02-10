# How To build?

## Go Version "MUST be exactly go 1.20" because of psiphon library then you can run

```bash
gomobile bind  -ldflags '-s -w' -o tun2socks.aar -target android .
```