#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
core_source="$root/aetherproject/aether/src/psiphon.rs"
target="$root/assets/psiphon/servers.dat"

python=""
for candidate in python3 python; do
  if "$candidate" -c "import zlib" >/dev/null 2>&1; then
    python="$candidate"
    break
  fi
done
if [[ -z "$python" ]]; then
  echo "python is needed to check the psiphon server list" >&2
  exit 1
fi
if [[ ! -f "$core_source" ]]; then
  echo "the core sources are missing; run git submodule update --init --recursive" >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

"$python" - "$core_source" "$work" <<'PY'
import re, sys
source = open(sys.argv[1], encoding="utf-8").read()
url = re.search(r'const SERVER_LIST_URL: &str =\s*"([^"]+)"', source)
key = re.search(r'SERVER_LIST_SIGNATURE_KEY: &str = concat!\((.*?)\);', source, re.S)
if not url or not key:
    sys.exit("the server list address or its key was not found in " + sys.argv[1])
open(sys.argv[2] + "/url", "w").write(url.group(1))
open(sys.argv[2] + "/key", "w").write("".join(re.findall(r'"([^"]*)"', key.group(1))))
PY

url="$(cat "$work/url")"
echo "fetching the psiphon server list from $url"
curl -fsSL --retry 3 --retry-delay 5 --max-time 180 -o "$work/list" "$url"

"$python" - "$work" <<'PY'
import base64, hashlib, json, sys, zlib
work = sys.argv[1]
key = open(work + "/key").read()
package = json.loads(zlib.decompress(open(work + "/list", "rb").read()))
if base64.b64decode(package["signingPublicKeyDigest"]) != hashlib.sha256(key.encode()).digest():
    sys.exit("the list is signed with a key the core does not carry")
data = package["data"]
entries = [line for line in data.split("\n") if line.strip()]
if len(entries) < 50:
    sys.exit("only %d server entries came down, which is not the list" % len(entries))
open(work + "/data", "wb").write(data.encode("utf-8"))
open(work + "/signature", "wb").write(base64.b64decode(package["signature"]))
lines = [key[i:i + 64] for i in range(0, len(key), 64)]
with open(work + "/key.pem", "w", newline="\n") as pem:
    pem.write("-----BEGIN PUBLIC KEY-----\n" + "\n".join(lines) + "\n-----END PUBLIC KEY-----\n")
print("%d server entries" % len(entries))
PY

openssl dgst -sha256 -verify "$work/key.pem" -signature "$work/signature" "$work/data"

mkdir -p "$(dirname "$target")"
cp "$work/list" "$target"
echo "staged $target"
