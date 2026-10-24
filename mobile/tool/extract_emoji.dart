import 'dart:convert';
import 'dart:io';

final _unsafeName = RegExp(r'[\\/:*?"<>|]');

void main() {
  final source = File('../docs/project/ui/prototype_v3/2_fe.js')
      .readAsStringSync();
  final start = source.indexOf('{');
  final end = source.lastIndexOf('}');
  if (start < 0 || end <= start) {
    stderr.writeln('Could not find the FE object.');
    exitCode = 1;
    return;
  }
  final decoded = jsonDecode(source.substring(start, end + 1));
  if (decoded is! Map) {
    stderr.writeln('FE is not an object.');
    exitCode = 1;
    return;
  }
  Directory('assets/emoji').createSync(recursive: true);
  var count = 0;
  for (final entry in decoded.entries) {
    final name = entry.key;
    final body = entry.value;
    if (name is! String || body is! String || _unsafeName.hasMatch(name)) {
      stderr.writeln('Skipped an emoji entry.');
      continue;
    }
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">$body</svg>\n';
    File('assets/emoji/$name.svg').writeAsStringSync(svg);
    count += 1;
  }
  if (count == 0) {
    stderr.writeln('No emoji were written.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Wrote $count emoji files.');
}
