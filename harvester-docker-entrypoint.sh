#!/bin/bash

if [[ -n "${TZ}" ]]; then
  echo "Timezone set to ${TZ}"
fi

./drchia init --fix-ssl-permissions

if [[ -n ${CHIA_HOSTNAME} ]]; then
  yq -i '.self_hostname = env(CHIA_HOSTNAME)' "$CHIA_ROOT/config/config.yaml"
else
  yq -i '.self_hostname = "127.0.0.1"' "$CHIA_ROOT/config/config.yaml"
fi

if [[ -n "${CHIA_LOG_LEVEL}" ]]; then
  ./drchia configure --log-level "${CHIA_LOG_LEVEL}"
fi

for p in ${CHIA_PLOTS//:/ }; do
  mkdir -p "${p}"
  if [[ ! $(ls -A "$p") ]]; then
    echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
  fi
  ./drchia plots add -d "${p}"
done

if [[ -n ${CHIA_FARMER_ADDRESS} && -n ${CHIA_FARMER_PORT} && -n ${CHIA_CA} ]]; then
  ./drchia init -c "${CHIA_CA}" && ./drchia configure --set-farmer-peer "${CHIA_FARMER_ADDRESS}:${CHIA_FARMER_PORT}"
fi

exec "$@"
