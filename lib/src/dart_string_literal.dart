// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns a quoted String literal for [value] that can be used in generated
/// Dart code.
///
/// By default `$` is escaped. To leave it unescaped, set [escapeDollar] to
/// `false`.
String dartStringLiteral(String value, {bool escapeDollar: true}) {
  escapeDollar ??= true;

  var hasSingleQuote = false;
  var hasDoubleQuote = false;
  var hasDollar = false;
  var canBeRaw = true;

  var newValue = value.replaceAllMapped(_escapeRegExp, (match) {
    var content = match[0];
    if (content == "'") {
      hasSingleQuote = true;
      return content;
    } else if (content == '"') {
      hasDoubleQuote = true;
      return content;
    } else if (content == r'$') {
      if (escapeDollar) {
        hasDollar = true;
      }
      return content;
    }

    canBeRaw = false;
    return _escapeMap[content] ?? _getHexLiteral(content);
  });

  if (!hasDollar) {
    if (hasSingleQuote) {
      if (!hasDoubleQuote) {
        return '"$newValue"';
      }
    } else {
      // trivial!
      return "'$newValue'";
    }
  }

  if (hasDollar && canBeRaw) {
    if (hasSingleQuote) {
      if (!hasDoubleQuote) {
        // quote it with single quotes!
        return 'r"$newValue"';
      }
    } else {
      // quote it with single quotes!
      return "r'$newValue'";
    }
  }

  // The only safe way to wrap the content is to escape all of the
  // problematic characters - `$`, `'`, and `"`
  var string =
      newValue.replaceAll(escapeDollar ? _dollarQuoteRegexp : _quoteRegexp, r'\');
  return "'$string'";
}

final _dollarQuoteRegexp = new RegExp(r"""(?=[$'"])""");
final _quoteRegexp = new RegExp(r"""(?=['"])""");

/// A [Map] between whitespace characters & `\` and their escape sequences.
const _escapeMap = const {
  '\b': r'\b', // 08 - backspace
  '\t': r'\t', // 09 - tab
  '\n': r'\n', // 0A - new line
  '\v': r'\v', // 0B - vertical tab
  '\f': r'\f', // 0C - form feed
  '\r': r'\r', // 0D - carriage return
  '\x7F': r'\x7F', // delete
  r'\': r'\\' // backslash
};

final _escapeMapRegexp = _escapeMap.keys.map(_getHexLiteral).join();

/// A [RegExp] that matches whitespace characters that should be escaped and
/// single-quote, double-quote, and `$`
final _escapeRegExp =
    new RegExp('[\$\'"\\x00-\\x07\\x0E-\\x1F$_escapeMapRegexp]');

/// Given single-character string, return the hex-escaped equivalent.
String _getHexLiteral(String input) {
  var rune = input.runes.single;
  var value = rune.toRadixString(16).toUpperCase().padLeft(2, '0');
  return '\\x$value';
}
