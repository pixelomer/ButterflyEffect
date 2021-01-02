#!/usr/bin/env bash

if [ -z "${APPLE_CERTIFICATE}" ]; then
  echo "Environment variable APPLE_CERTIFICATE is not set!"
  exit 1
fi

set -e

if [ "$1" == "ios" ]; then
  export GREED_TARGET="iOS_Simulator"
  resim="resim_ios"
  SIMJECT_DIR="/opt/simject"
elif [ "$1" == "tvos" ]; then
  export GREED_TARGET="tvOS_Simulator"
  resim="resim_tvos"
  SIMJECT_DIR="/opt/simjectTV"
else
  echo "No target supplied!"
  exit 1
fi

FINALPACKAGE=1 DEBUG=0 make clean all
rm -f ${SIMJECT_DIR}/Greed.*
rm -rf ${SIMJECT_DIR}/Greed
cp -r "layout/Library/ButterflyEffect" ${SIMJECT_DIR}/ButterflyEffect
cp .theos/obj/iphone_simulator/Greed.dylib ${SIMJECT_DIR}/
cp Greed.plist ${SIMJECT_DIR}/
"${resim}" all
