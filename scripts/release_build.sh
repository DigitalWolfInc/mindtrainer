#!/bin/bash

# Release build script for Mind Trainer
# Usage: ./scripts/release_build.sh [dev|prod]

# Check for flavor argument
FLAVOR=${1:-prod}
if [[ "$FLAVOR" != "dev" && "$FLAVOR" != "prod" ]]; then
    echo "Error: Invalid flavor. Use 'dev' or 'prod'"
    exit 1
fi

# Clean environment
echo "Cleaning build environment..."
flutter clean
rm -rf ~/.gradle/caches
./android/gradlew --stop

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Run tests
echo "Running tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "Error: Tests failed"
    exit 1
fi

# Build debug APK first (faster fail)
echo "Building debug APK for testing..."
flutter build apk --flavor $FLAVOR --debug
if [ $? -ne 0 ]; then
    echo "Error: Debug build failed"
    exit 1
fi

# Build release AAB
echo "Building release AAB..."
flutter build appbundle \
    --release \
    --flavor $FLAVOR \
    --split-debug-info=build/symbols \
    --obfuscate
if [ $? -ne 0 ]; then
    echo "Error: Release build failed"
    exit 1
fi

# Optional APK for testing
echo "Building release APK for testing..."
flutter build apk \
    --release \
    --flavor $FLAVOR \
    --split-debug-info=build/symbols \
    --obfuscate

# Archive artifacts
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="build/releases/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

# Copy artifacts
cp build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab "$OUTPUT_DIR/"
cp build/app/outputs/apk/${FLAVOR}/release/app-${FLAVOR}-release.apk "$OUTPUT_DIR/"
cp build/app/outputs/mapping/${FLAVOR}Release/mapping.txt "$OUTPUT_DIR/"
cp -r build/symbols "$OUTPUT_DIR/"

echo "Build artifacts archived to: $OUTPUT_DIR"
echo ""
echo "AAB: $OUTPUT_DIR/app-${FLAVOR}-release.aab"
echo "APK: $OUTPUT_DIR/app-${FLAVOR}-release.apk"
echo "Mapping: $OUTPUT_DIR/mapping.txt"
echo "Symbols: $OUTPUT_DIR/symbols/"
echo ""
echo "Build complete!"