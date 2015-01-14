#! /bin/bash
# ------------------------------------------------------------------
# Spell checking of the source file (Bash version for Linux)
# Usage: ./aspell-check.sh
# ------------------------------------------------------------------

# Check if Aspell exists, otherwise print instructions and exits
hash foo 2>/dev/null || { cat aspell-check.readme; exit 1; }

# Run Aspell
aspell --home-dir=. --lang=en --mode=tex Source/paper.tex
