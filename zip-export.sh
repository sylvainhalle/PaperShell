#! /bin/bash

# The name of the output archive
outarchive=paper.zip

# The name of the generated PDF (we won't include it)
papername=paper.pdf

echo "Zipping contents of folder Export into $outarchive"
pushd Export > /dev/null
zip -9 -r --exclude=\*~ --exclude=$papername --exclude=\*.log --exclude=\*.out ../$outarchive .
popd > /dev/null
