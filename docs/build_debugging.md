# Build Debugging Guide

## Build Issue Resolution Flow

1. **Clean Environment**
   ```bash
   flutter clean
   ./android/gradlew --stop
   rm -rf ~/.gradle/caches
   ```

2. **Check Flutter Setup**
   ```bash
   flutter doctor -v
   ```
   - Verify JDK 17 is active
   - Confirm Android SDK and build tools match Step 1/2

3. **Debug Build First**
   ```bash
   flutter run --debug
   ```
   - Faster iteration for AAPT/asset issues
   - Confirms basic configuration

4. **Release Without Shrinker**
   ```bash
   flutter build apk --release --no-shrink
   ```
   - Isolate R8/ProGuard issues
   - Check error output for missing classes

5. **Enable Shrinker**
   ```bash
   flutter build apk --release
   ```
   - Add keep rules for reflection issues
   - Check mapping.txt for obfuscation

6. **Final AAB Build**
   ```bash
   flutter build appbundle --release
   ```
   - Verify splits and compression
   - Check bundle tool output

## Common Issues & Solutions

### Build Failed to Produce APK/AAB
- Re-run with `-v` for detailed output
- Check AGP/Gradle/JDK versions from Step 1
- Clear caches with `rm -rf ~/.gradle/caches`
- Verify asset naming in `assets/`

### R8 Minification Failures
- Set `minifyEnabled false` temporarily
- Add specific keep rules for reported classes
- Check obfuscation exceptions in logs

### Duplicate Classes
- Find overlapping plugins
- Remove older duplicate dependencies
- Use `exclude group:` in Gradle if needed

### Keystore/Signing Issues
- Verify keystore exists: `keytool -list -v -keystore path/to/keystore.jks`
- Check key.properties paths and passwords
- Confirm signing config in build.gradle

### minSdk Conflicts
- Raise to minSdk 24 (or plugin's minimum)
- Check transitive dependencies
- Use `tools:overrideLibrary` as last resort

### Manifest Merge Conflicts
- Review all plugin manifests
- Check for permission conflicts
- Verify activity/service declarations

## Diagnostics Commands

### Check Dependencies
```bash
flutter pub deps
./android/gradlew :app:dependencies
```

### Analyze APK
```bash
bundletool build-apks --bundle=app.aab --output=app.apks
unzip -l app.apks
```

### View ProGuard Config
```bash
./android/gradlew :app:dumpProguardConfiguration
```

### Check Resource Usage
```bash
./android/gradlew :app:assembleRelease --info
```

## File Validation

### Asset Names
- No spaces or special characters
- Lowercase with hyphens
- Valid extensions only

### Resource IDs
- No duplicates across libraries
- Valid XML resource names
- No missing references

### Native Libraries
- Check ABI compatibility
- Verify .so file presence
- Confirm loading paths

## Build Environment

### JDK Version
```bash
java -version
echo $JAVA_HOME
```

### Android SDK
```bash
sdkmanager --list
flutter doctor -v
```

### Gradle Settings
```bash
cat android/gradle.properties
./android/gradlew --version
```

## Debug Output Locations

- APK: `build/app/outputs/apk/`
- AAB: `build/app/outputs/bundle/`
- Mapping: `build/app/outputs/mapping/`
- Resources: `build/app/intermediates/`
- Native libs: `build/app/intermediates/merged_native_libs/`