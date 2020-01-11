#!/usr/bin/env bash
dir $PWD
PATH=/usr/bin:$PATH

ncb-tester -V
ncb-bootnode -V
ncb-kingnode-config -V
ncb-primalblock -V
ncb-chainmaker -V
ncb-bookkeeping -V
ncb-kingnode -V

here=$(dirname "$0")
# shellcheck source=multinode-demo/common.sh
source "$here"/common.sh

export RUST_LOG=${RUST_LOG:-ncb=info} # if RUST_LOG is unset, default to info
export RUST_BACKTRACE=1

ip_address_arg=-l
num_tokens=1000000000
node_type_leader=true
node_type_validator=true
node_type_client=true

NCB_CONFIG_DIR=${SNAP_DATA:-$PWD}/config
NCB_CONFIG_PRIVATE_DIR=${SNAP_DATA:-$PWD}/config-private
NCB_CONFIG_VALIDATOR_DIR=${SNAP_DATA:-$PWD}/config-validator
NCB_CONFIG_TESTER_DIR=${SNAP_USER_DATA:-$PWD}/config-client

for i in "$NCB_CONFIG_DIR" "$NCB_CONFIG_VALIDATOR_DIR" "$NCB_CONFIG_PRIVATE_DIR"; do
  echo "Cleaning $i"
  rm -rvf "$i"
  mkdir -p "$i"
done

if $node_type_client; then
  client_id_path="$NCB_CONFIG_PRIVATE_DIR"/client-id.json
  ncb-chainmaker -o "$client_id_path"
  ls -lhR "$NCB_CONFIG_PRIVATE_DIR"/
fi

if $node_type_leader; then
  leader_address_args=("$ip_address_arg")
  leader_id_path="$NCB_CONFIG_PRIVATE_DIR"/leader-id.json
  mint_path="$NCB_CONFIG_PRIVATE_DIR"/mint.json

  ncb-chainmaker -o "$leader_id_path"

  echo "Creating $mint_path with $num_tokens tokens"
  ncb-chainmaker -o "$mint_path"

  echo "Creating $NCB_CONFIG_DIR/ledger"
  ncb-primalblock --tokens="$num_tokens" --ledger "$NCB_CONFIG_DIR"/ledger < "$mint_path"

  echo "Creating $NCB_CONFIG_DIR/leader.json"
  ncb-kingnode-config --keypair="$leader_id_path" "${leader_address_args[@]}" > "$NCB_CONFIG_DIR"/leader.json

  ls -lhR "$NCB_CONFIG_DIR"/
  ls -lhR "$NCB_CONFIG_PRIVATE_DIR"/
fi


if $node_type_validator; then
  validator_address_args=("$ip_address_arg" -b 9000)

  validator_id_path="$ncb_CONFIG_PRIVATE_DIR"/validator-id.json

  ncb-chainmaker -o "$validator_id_path"

  echo "Creating $NCB_CONFIG_VALIDATOR_DIR/validator.json"
  ncb-kingnode-config --keypair="$validator_id_path" "${validator_address_args[@]}" > "$NCB_CONFIG_VALIDATOR_DIR"/validator.json

  ls -lhR "$NCB_CONFIG_VALIDATOR_DIR"/
fi

read -r _ leader_address shift < <(find_kingnode "${@:1:1}")
shift "$shift"

[[ -f "$NCB_CONFIG_PRIVATE_DIR"/mint.json ]] || {
  echo "$NCB_CONFIG_PRIVATE_DIR/mint.json not found, create it by running:"
  echo
  echo "  ${here}/setup.sh -t leader"
  exit 1
}
ncb-bootnode \
  --keypair "$NCB_CONFIG_PRIVATE_DIR"/mint.json \
  --network "$leader_address" &
bootnode=$!


[[ -f "$NCB_CONFIG_DIR"/leader.json ]] || {
  echo "$NCB_CONFIG_DIR/leader.json not found, create it by running:"
  echo
  echo "  ${here}/setup.sh"
  exit 1
}

ncb-kingnode \
  --identity "$NCB_CONFIG_DIR"/leader.json \
  --ledger "$NCB_CONFIG_DIR"/ledger &
leader=$!

abort() {
  set +e
  kill "$bootnode" "$leader"
}
trap abort INT TERM EXIT

wait "$leader"