/// Wraps a left-to-right run (a version, a product name, a time zone) in a
/// Unicode left-to-right isolate (LRI ... PDI). The run keeps its own order
/// even when it has no strong letter ("0.1.0+1"), and the Arabic text and
/// punctuation around it keep theirs.
String isolate(String text) => '\u2066$text\u2069';
