#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build
xcrun swiftc -swift-version 6 -parse-as-library Wordle/GameEngine.swift Wordle/WordLibrary.swift Wordle/GameStore.swift Tests/CoreTests.swift -o build/encore-core-tests
./build/encore-core-tests
