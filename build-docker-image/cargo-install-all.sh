#!/usr/bin/env bash
#
# |cargo install| of the top-level crate will not install binaries for
# other workspace crates or native program crates.
set -e

export rust_version=
if [[ $1 =~ \+ ]]; then
  export rust_version=$1
  shift
fi

if [[ -z $1 ]]; then
  echo Install directory not specified
  exit 1
fi

installDir="$(mkdir -p "$1"; cd "$1"; pwd)"
cargoFeatures="$2"
echo "Install location: $installDir"

cd "$(dirname "$0")"/..
SECONDS=0

(
  set -x
  # shellcheck disable=SC2086 # Don't want to double quote $rust_version
  cargo $rust_version build --all --release --features="$cargoFeatures"
)
mkdir -p "$installDir/bin"
cp -v $PWD/target/release/ncb-bench-tps  "$installDir"/bin/ncb-tester
cp -v $PWD/target/release/ncb-drone "$installDir"/bin/ncb-bootnode
cp -v $PWD/target/release/ncb-fullnode-config "$installDir"/bin/ncb-kingnode-config
cp -v $PWD/target/release/ncb-genesis "$installDir"/bin/ncb-primalblock
cp -v $PWD/target/release/ncb-keygen "$installDir"/bin/ncb-chainmaker
cp -v $PWD/target/release/ncb-ledger-tool "$installDir"/bin/ncb-bookkeeping
cp -v $PWD/target/release/ncb-fullnode "$installDir"/bin/ncb-kingnode

PATH=$PWD/target/release:$PATH
ncb-keygen -V

BIN_CRATES=(
  # buffett-bench-tps
  # buffett-drone
  # buffett-fullnode
  # buffett-fullnode-config
  # buffett-genesis
  # buffett-keygen
  # buffett-ledger-tool
  # buffett-genesis
)

for crate in "${BIN_CRATES[@]}"; do
  (
    set -x
    # shellcheck disable=SC2086 # Don't want to double quote $rust_version
    cargo $rust_version install --force --path "$crate" --root "$installDir" --features="$cargoFeatures"
  )
done

for dir in programs/*; do
  for program in echo target/release/deps/libbuffett_"$(basename "$dir")".{so,dylib,dll}; do
    if [[ -f $program ]]; then
      mkdir -p "$installDir/bin/deps"
      rm -f "$installDir/bin/deps/$(basename "$program")"
      cp -v "$program" "$installDir"/bin/deps
    fi
  done
done

du -a "$installDir"
echo "Done after $SECONDS seconds"
