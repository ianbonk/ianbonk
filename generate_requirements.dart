import 'dart:convert';
import 'dart:io';

void main() async {
  // Baca JSON dari file deps.json
  final file = File('deps.json');
  final content = await file.readAsString();
  final data = jsonDecode(content);

  // Buat list requirements
  final buffer = StringBuffer();

  for (final pkg in data['packages']) {
    buffer.writeln('${pkg['name']} ${pkg['version']}');
  }

  buffer.writeln('');
  for (final sdk in data['sdks']) {
    buffer.writeln('${sdk['name']} SDK ${sdk['version']}');
  }

  // Simpan ke file requirements-flutter.txt
  final outFile = File('requirements-flutter.txt');
  await outFile.writeAsString(buffer.toString());

  print('requirements-flutter.txt berhasil dibuat!');
}
