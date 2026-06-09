#! /bin/bash
from=$(pwd)
(
  cd $HOME/.local/share/papershell/Tools
  texlua psmod.lua --from "$from" "$@"
)