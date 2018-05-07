import 'dart:async';
import 'dart:convert';
import 'dart:io';

final _blnsJsonRawUrl =
    'https://github.com/minimaxir/big-list-of-naughty-strings/raw/master/blns.json';
final _blnsFilePath = 'test/big-list-of-naughty-strings.json';

Future<Null> main() async {
  var client = new HttpClient();
  List<String> json;
  try {
    var request = await client.getUrl(Uri.parse(_blnsJsonRawUrl));
    var response = await request.close();
    json = jsonDecode(await response.transform(utf8.decoder).join(''))
        as List<String>;
  } finally {
    client.close();
  }

  new File(_blnsFilePath)
      .writeAsStringSync(new JsonEncoder.withIndent(' ').convert(json));
}
