#!/usr/bin/env bash

################################### SETUP ######################################

# go to repo root
cd $(git rev-parse --show-toplevel)

# load env vars
set -o allexport
source .env
set +o allexport

# check if solana is installed
if ! command -v solana &> /dev/null; then
  echo "Solana CLI not found"
  exit 1
fi

# check if cargo is installed
if ! command -v cargo &> /dev/null; then
  echo "Cargo not found"
  exit 1
fi

# check that test validator is running if needed
if [ "${NETWORK}" == "local" ] \
	&& ! command solana genesis-hash &> /dev/null; then
	echo "Local solana test validator not found"
	exit 1
fi

# exit on error and print commands
set -e
set -x

############################## CONFIGURE SOLANA ################################

# set solana network
case "${NETWORK}" in
  local)
    echo "Running solana locally"
	solana config set --url localhost
    ;;
  devnet)
    echo "Running solana on devnet"
    solana config set --url https://api.devnet.solana.com
    ;;
  testnet)
    echo "Running solana on testnet"
    solana config set --url https://api.testnet.solana.com
    ;;
  mainnet)
    echo "Running solana on mainnet"
    solana config set --url https://api.mainnet-beta.solana.com
    ;;
  *)
    echo "Unknown network: ${NETWORK}"
    exit 1
    ;;
esac

# configure new wallet if needed
if [ ! -f ${WALLET_FILE} ]; then
  solana-keygen new --outfile ${WALLET_FILE}
fi

# set wallet as default
solana config set --keypair ${WALLET_FILE}

# get some lamports
[ "${NETWORK}" != "mainnet" ] && solana airdrop 2

########################### BUILD AND DEPLOY PROGRAM ###########################

cd code/

# build program
cargo build-bpf

# deploy program
solana program deploy ./target/deploy/quantix42.so
