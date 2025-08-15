#!/bin/bash

echo "Docker Build Performance Benchmark"
echo "=================================="
echo ""

# Clean build (no cache)
echo "1. Clean build (no cache):"
docker builder prune -af > /dev/null 2>&1
START=$(date +%s)
docker build --no-cache -t guchio-nvim:benchmark . > /dev/null 2>&1
END=$(date +%s)
CLEAN_TIME=$((END - START))
echo "   Time: ${CLEAN_TIME}s"

# Cached build (no changes)
echo ""
echo "2. Cached build (no changes):"
START=$(date +%s)
docker build -t guchio-nvim:benchmark . > /dev/null 2>&1
END=$(date +%s)
CACHED_TIME=$((END - START))
echo "   Time: ${CACHED_TIME}s"

# Config change build
echo ""
echo "3. Config change build (touch nvim/init.lua):"
touch nvim/init.lua
START=$(date +%s)
docker build -t guchio-nvim:benchmark . > /dev/null 2>&1
END=$(date +%s)
CONFIG_TIME=$((END - START))
echo "   Time: ${CONFIG_TIME}s"

echo ""
echo "Summary:"
echo "--------"
echo "Clean build:    ${CLEAN_TIME}s"
echo "Cached build:   ${CACHED_TIME}s"
echo "Config change:  ${CONFIG_TIME}s"

# Calculate improvements
if [ "$CLEAN_TIME" -gt 0 ]; then
    CACHE_IMPROVEMENT=$(( (CLEAN_TIME - CACHED_TIME) * 100 / CLEAN_TIME ))
    CONFIG_IMPROVEMENT=$(( (CLEAN_TIME - CONFIG_TIME) * 100 / CLEAN_TIME ))
    echo ""
    echo "Cache improvement:  ${CACHE_IMPROVEMENT}%"
    echo "Config change improvement: ${CONFIG_IMPROVEMENT}%"
fi