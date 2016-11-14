#!/bin/bash
if test `uname` = 'Darwin'; then
  sed -i '' -e "s;github.build.ge.com/adoption;github.com/PredixDev;" ./bash/scripts/variables.sh
else
  sed -i -e "s;github.build.ge.com/adoption;github.com/PredixDev;" ./bash/scripts/variables.sh
fi
