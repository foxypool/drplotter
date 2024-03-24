#!/bin/bash

./drchia start harvester

trap "echo Shutting down ...; ./drchia stop all -d; exit 0" SIGINT SIGTERM

tail -F "$CHIA_ROOT/log/debug.log"
