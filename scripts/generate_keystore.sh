#!/bin/bash

# Define paths
KEYSTORE_PATH="android/app/mindtrainer-upload.jks"
KEY_PROPERTIES_PATH="android/key.properties"

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo "Error: Keystore already exists at $KEYSTORE_PATH"
    exit 1
fi

# Generate keystore
keytool -genkeypair -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storepass mind_trainer_store_password \
  -keypass mind_trainer_key_password \
  -dname "CN=Mind Trainer,OU=Development,O=Mind Trainer,L=Unknown,ST=Unknown,C=US"

# Check if keystore was created successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate keystore"
    exit 1
fi

echo "Keystore generated successfully at $KEYSTORE_PATH"

# Create base64 encoded version for CI
KEYSTORE_BASE64=$(base64 -i "$KEYSTORE_PATH")
echo "Base64 encoded keystore for CI:"
echo "$KEYSTORE_BASE64"

# Print key.properties content for verification
echo -e "\nVerify key.properties content:"
cat "$KEY_PROPERTIES_PATH"