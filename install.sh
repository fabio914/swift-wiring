#!/bin/sh

swift build -c release
mv .build/release/swift-wiring /usr/local/bin
