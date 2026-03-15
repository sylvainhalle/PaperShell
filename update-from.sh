#! /bin/bash
# ----------------------------------------------
# Updates the files in a folder with those from a more recent
# version of PaperShell
#
# Usage: ./update-from.sh path
# where path is the path to the root folder of an up-to-date copy of
# PaperShell. The script takes care not to overwrite paper.tex, but
# updates everything else.
# ----------------------------------------------
rsync -aP --exclude 'paper.*' --exclude '*.inc.tex' --exclude '.git' --exclude 'fig' --exclude '*~' --exclude 'authors.txt' --exclude 'Readme.md' --exclude 'Source/abstract.tex' $1/ ./
echo "Update done. Don't forget to manually update paper.tex in case"
echo "its structure has changed in the new version of PaperShell."