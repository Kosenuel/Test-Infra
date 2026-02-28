 # This script is used to fix the helmfile issue related to DNS resolution in Go.
 # To apply the fix, run this script (source fix-helmfile-issue.sh) before running helmfile commands.
 export GODEBUG=netdns=go,ipv6=0
 echo "GODEBUG set to: $GODEBUG"