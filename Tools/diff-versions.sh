#! /bin/bash
# ------------------------------------------------------------------------
# Calculates the difference of two versions of a paper using the PaperShell
# template
#
# (C) 2024  Sylvain Hallé
#
# Usage: ./diff-versions.sh <old> <new> <target>
# where:
# - old is the root PaperShell folder of the "old" version of the paper
# - new is the root PaperShell folder of the "old" version of the paper
# - target is the name of the target folder that will contain the diff
#   document (created if does not exist)
# ------------------------------------------------------------------------

# PaperShell default names; change only if you override these defaults
EXPORT=Export
PAPER=paper.tex

# Create target directory if it does not exist
mkdir -p $3

# Flatten "old" version as a stand-alone PDF
pushd $1
php export.php
popd

# Flatten "new" version as a stand-alone PDF
pushd $2
php export.php
popd

# Copy "flattened" folder of new version into target directory
rsync -av --exclude=".*" $2/$EXPORT/ $3/$EXPORT/

# Create diff document
latexdiff --encoding=utf8 $1/$EXPORT/$PAPER $2/$EXPORT/$PAPER > $3/$EXPORT/$PAPER

# Compile (3 times as usual for LaTeX); bulldowse through any errors
pushd $3/Export
pdflatex -interaction=batchmode $PAPER
pdflatex -interaction=batchmode $PAPER
pdflatex -interaction=batchmode $PAPER

# Rename to avoid confusion
mv $PAPER changes.pdf
popd