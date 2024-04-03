module tun2socks

go 1.21.1

toolchain go1.21.6

replace github.com/Psiphon-Labs/psiphon-tunnel-core => github.com/bepass-org/psiphon-tunnel-core v0.0.0-20240311155012-9c2e10df08e5

replace github.com/eycorsican/go-tun2socks => github.com/trojan-gfw/go-tun2socks v1.16.3-0.20210702214000-083d49176e05

require (
	github.com/bepass-org/warp-plus v1.1.3-0.20240403205252-06b16247e1a5
	github.com/eycorsican/go-tun2socks v1.16.11
	github.com/songgao/water v0.0.0-20200317203138-2b4b6d7c09d8
	github.com/xjasonlyu/tun2socks/v2 v2.5.2
	golang.org/x/mobile v0.0.0-20240213143359-d1f7d3436075
)

require (
	filippo.io/bigmod v0.0.1 // indirect
	filippo.io/keygen v0.0.0-20230306160926-5201437acf8e // indirect
	github.com/AndreasBriese/bbloom v0.0.0-20170702084017-28f7e881ca57 // indirect
	github.com/Psiphon-Labs/bolt v0.0.0-20200624191537-23cedaef7ad7 // indirect
	github.com/Psiphon-Labs/goptlib v0.0.0-20200406165125-c0e32a7a3464 // indirect
	github.com/Psiphon-Labs/psiphon-tls v0.0.0-20240305020009-09f917290799 // indirect
	github.com/Psiphon-Labs/psiphon-tunnel-core v2.0.28+incompatible // indirect
	github.com/Psiphon-Labs/quic-go v0.0.0-20240305203241-7c4a760d03cc // indirect
	github.com/andybalholm/brotli v1.0.5 // indirect
	github.com/armon/go-proxyproto v0.0.0-20180202201750-5b7edb60ff5f // indirect
	github.com/bifurcation/mint v0.0.0-20180306135233-198357931e61 // indirect
	github.com/cheekybits/genny v0.0.0-20170328200008-9127e812e1e9 // indirect
	github.com/cognusion/go-cache-lru v0.0.0-20170419142635-f73e2280ecea // indirect
	github.com/dchest/siphash v1.2.3 // indirect
	github.com/dgraph-io/badger v1.5.4-0.20180815194500-3a87f6d9c273 // indirect
	github.com/dgryski/go-farm v0.0.0-20180109070241-2de33835d102 // indirect
	github.com/djherbis/buffer v1.2.0 // indirect
	github.com/djherbis/nio v2.0.3+incompatible // indirect
	github.com/flynn/noise v1.1.0 // indirect
	github.com/gaukas/godicttls v0.0.4 // indirect
	github.com/go-ini/ini v1.67.0 // indirect
	github.com/go-task/slim-sprig v0.0.0-20230315185526-52ccab3ef572 // indirect
	github.com/golang/protobuf v1.5.3 // indirect
	github.com/google/btree v1.1.2 // indirect
	github.com/google/pprof v0.0.0-20211214055906-6f57359322fd // indirect
	github.com/grafov/m3u8 v0.0.0-20171211212457-6ab8f28ed427 // indirect
	github.com/hashicorp/golang-lru v1.0.2 // indirect
	github.com/juju/ratelimit v1.0.2 // indirect
	github.com/klauspost/compress v1.16.7 // indirect
	github.com/libp2p/go-reuseport v0.4.0 // indirect
	github.com/miekg/dns v1.1.44-0.20210804161652-ab67aa642300 // indirect
	github.com/mroth/weightedrand v1.0.0 // indirect
	github.com/onsi/ginkgo/v2 v2.9.5 // indirect
	github.com/pelletier/go-toml v1.9.5 // indirect
	github.com/pion/dtls/v2 v2.2.7 // indirect
	github.com/pion/logging v0.2.2 // indirect
	github.com/pion/randutil v0.1.0 // indirect
	github.com/pion/sctp v1.8.8 // indirect
	github.com/pion/stun v0.6.1 // indirect
	github.com/pion/transport/v2 v2.2.3 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/quic-go/qpack v0.4.0 // indirect
	github.com/quic-go/qtls-go1-20 v0.4.1 // indirect
	github.com/quic-go/quic-go v0.40.1 // indirect
	github.com/refraction-networking/conjure v0.7.11-0.20240130155008-c8df96195ab2 // indirect
	github.com/refraction-networking/ed25519 v0.1.2 // indirect
	github.com/refraction-networking/gotapdance v1.7.10 // indirect
	github.com/refraction-networking/obfs4 v0.1.2 // indirect
	github.com/refraction-networking/utls v1.3.3 // indirect
	github.com/sergeyfrolov/bsbuffer v0.0.0-20180903213811-94e85abb8507 // indirect
	github.com/sirupsen/logrus v1.9.3 // indirect
	github.com/syndtr/gocapability v0.0.0-20200815063812-42c35b437635 // indirect
	github.com/v2pro/plz v0.0.0-20221028024117-e5f9aec5b631 // indirect
	github.com/wader/filtertransport v0.0.0-20200316221534-bdd9e61eee78 // indirect
	gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/goptlib v1.5.0 // indirect
	go.uber.org/atomic v1.11.0 // indirect
	go.uber.org/mock v0.3.0 // indirect
	golang.org/x/crypto v0.21.0 // indirect
	golang.org/x/exp v0.0.0-20230725093048-515e97ebf090 // indirect
	golang.org/x/mod v0.15.0 // indirect
	golang.org/x/net v0.22.0 // indirect
	golang.org/x/sync v0.6.0 // indirect
	golang.org/x/sys v0.18.0 // indirect
	golang.org/x/text v0.14.0 // indirect
	golang.org/x/time v0.5.0 // indirect
	golang.org/x/tools v0.18.0 // indirect
	golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2 // indirect
	google.golang.org/protobuf v1.32.0 // indirect
	gvisor.dev/gvisor v0.0.0-20240313225113-67a078058255 // indirect
)
