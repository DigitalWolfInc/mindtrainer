import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart scripts/bump_version.dart <major|minor|patch|build>');
    exit(1);
  }

  final type = args[0].toLowerCase();
  final pubspecFile = File('pubspec.yaml');
  final lines = pubspecFile.readAsLinesSync();

  var versionLine = lines.firstWhere((line) => line.startsWith('version:'));
  final versionIndex = lines.indexOf(versionLine);
  
  final parts = versionLine.split(':');
  if (parts.length != 2) {
    print('Invalid version line in pubspec.yaml');
    exit(1);
  }

  final version = parts[1].trim();
  final versionParts = version.split('+');
  if (versionParts.length != 2) {
    print('Invalid version format. Expected format: x.y.z+n');
    exit(1);
  }

  final semver = versionParts[0].split('.');
  if (semver.length != 3) {
    print('Invalid semantic version format. Expected format: x.y.z');
    exit(1);
  }

  var major = int.parse(semver[0]);
  var minor = int.parse(semver[1]);
  var patch = int.parse(semver[2]);
  var build = int.parse(versionParts[1]);

  switch (type) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      build++;
      break;
    case 'minor':
      minor++;
      patch = 0;
      build++;
      break;
    case 'patch':
      patch++;
      build++;
      break;
    case 'build':
      build++;
      break;
    default:
      print('Invalid version type. Use major, minor, patch, or build');
      exit(1);
  }

  final newVersion = '$major.$minor.$patch+$build';
  lines[versionIndex] = 'version: $newVersion';

  pubspecFile.writeAsStringSync(lines.join('\n'));
  print('Version bumped to $newVersion');
}