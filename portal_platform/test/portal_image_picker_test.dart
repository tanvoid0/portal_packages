import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// Returns canned results, and records every query it was asked for so the
/// debounce/race behaviour is observable.
/// Stands in for the server's media store. Records what it was asked to keep
/// so a test can prove the raw CDN link never reaches the caller.
class _FakeMedia implements PortalMediaService {
  final imported = <String>[];
  final uploaded = <String>[];

  @override
  Future<String> importUrl(String url) async {
    imported.add(url);
    return 'https://media.portal.test/stored-${imported.length}.jpg';
  }

  @override
  Future<String> uploadBytes(Uint8List bytes, String filename) async {
    uploaded.add(filename);
    return 'https://media.portal.test/upload-${uploaded.length}.jpg';
  }
}

class _FakeSearch implements PortalImageSearchService {
  _FakeSearch(this.results);

  final List<PortalImageResult> results;
  final queries = <String>[];

  @override
  Future<List<PortalImageResult>> search(String query, {int perPage = 24}) async {
    queries.add(query);
    return results;
  }
}

PortalImageResult _photo(String id) => PortalImageResult(
      id: id,
      fullUrl: 'https://img.test/$id/full',
      regularUrl: 'https://img.test/$id/regular',
      smallUrl: 'https://img.test/$id/small',
      thumbUrl: 'https://img.test/$id/thumb',
      authorName: 'Ada',
      authorUsername: 'ada',
      width: 100,
      height: 100,
      color: '#112233',
    );

void main() {
  group('isUsableImageLink', () {
    test('accepts absolute http(s) URLs without an extension', () {
      expect(isUsableImageLink('https://images.unsplash.com/photo-123'), isTrue);
      expect(isUsableImageLink('  http://cdn.test/a.jpg  '), isTrue);
    });

    test('rejects blanks, relative paths and non-web schemes', () {
      expect(isUsableImageLink(''), isFalse);
      expect(isUsableImageLink('not a url'), isFalse);
      expect(isUsableImageLink('/local/a.jpg'), isFalse);
      expect(isUsableImageLink('ftp://host/a.jpg'), isFalse);
      expect(isUsableImageLink('https://'), isFalse);
    });
  });

  group('parseHexColor', () {
    test('parses #rrggbb as fully opaque', () {
      expect(parseHexColor('#112233'), const Color(0xFF112233));
      expect(parseHexColor('112233'), const Color(0xFF112233));
    });

    test('returns null rather than throwing on junk', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor('#abc'), isNull);
      expect(parseHexColor('#gggggg'), isNull);
    });
  });

  testWidgets('a chosen photo is stored on the server, not linked to the CDN',
      (tester) async {
    final fake = _FakeSearch([_photo('a')]);
    final media = _FakeMedia();
    String? picked = '';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => PortalImageField(
            value: picked,
            searchQuery: 'pasta',
            service: fake,
            mediaService: media,
            onChanged: (url) => setState(() => picked = url),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Add image'));
    // Not pumpAndSettle: the grid's network images never resolve under test,
    // so the tree never reaches a settled frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(fake.queries, ['pasta']);

    // The grid renders network images, which never resolve under test; the
    // author credit is painted regardless, and tapping it hits the tile.
    await tester.tap(find.text('Ada'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The CDN link went to the server, and the server's URL is what the form
    // keeps. Storing the Unsplash link directly is the bug this guards.
    expect(media.imported, ['https://img.test/a/regular']);
    expect(picked, 'https://media.portal.test/stored-1.jpg');
  });

  testWidgets('a pasted link is fetched by the server, not stored raw',
      (tester) async {
    final fake = _FakeSearch(const []);
    final media = _FakeMedia();
    String? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await PortalImagePickerSheet.show(
                context,
                service: fake,
                mediaService: media,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Nothing searched yet, so "Use" is disabled until the link parses.
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Use')).onPressed,
        isNull);

    await tester.enterText(
        find.widgetWithText(TextField, 'Or paste an image link'),
        'https://cdn.test/x.png');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Use'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(media.imported, ['https://cdn.test/x.png']);
    expect(result, 'https://media.portal.test/stored-1.jpg');
    expect(fake.queries, isEmpty);
  });
}
