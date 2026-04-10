import 'dart:io';

void main() async {
  final file = File('uat_build_number.txt');

  // Step 1: Read last number (create file if it doesn't exist)
  if (!file.existsSync()) {
    file.writeAsStringSync('100'); // starting build number
  }
  int lastNumber = int.parse(file.readAsStringSync().trim());

  // Step 2: Increment
  int newNumber = lastNumber + 1;

  // Step 3: Save new number
  file.writeAsStringSync(newNumber.toString());

  print('UAT Build Number: $newNumber');

  // Step 4: Start Flutter build with live output
  var process = await Process.start(
    'flutter',
    [
      'build',
      'apk',
      '--flavor', 'uat',
      '--dart-define=FLAVOR=uat',               // ensures UAT backend
      '--dart-define=UAT_BUILD_NUMBER=$newNumber'
    ],
    runInShell: true,
  );

  // Step 5: Print logs live
  process.stdout.transform(SystemEncoding().decoder).listen((data) => stdout.write(data));
  process.stderr.transform(SystemEncoding().decoder).listen((data) => stderr.write(data));

  // Step 6: Wait for completion
  int exitCode = await process.exitCode;
  print('\nFlutter build finished with exit code $exitCode');
  print('APK location: build/app/outputs/flutter-apk/app-uat-release.apk');
}
