#!/bin/bash
set -e
cd ..
SCRIPT="-script build-basic-app.sh -script-readargs build-basic-app-readargs.sh"
QUICKSTART_ARGS="-pxclimin 0.6.18 $SCRIPT --help"
source predix-scripts/bash/quickstart.sh $QUICKSTART_ARGS
