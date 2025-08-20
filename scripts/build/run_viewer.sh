#!/bin/bash
echo "Starting Parchment..."
./Parchment.app/Contents/MacOS/Parchment test.md 2>&1 | tee viewer.log &
PID=$\!
echo "Started with PID: $PID"
sleep 3
echo "Checking log output:"
cat viewer.log
echo "App should be running now. Check the application window."
