import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

class Row {
  const Row(this.id, this.name);
  final String id;
  final String name;
}

List<Row> resolve(List<String> keys, {List<Row>? pool}) => resolveAiRows(
  keys: keys,
  pool:
      pool ?? const [Row('a1', 'Milk'), Row('b2', 'Eggs'), Row('c3', 'Bread')],
  idOf: (r) => r.id,
  nameOf: (r) => r.name,
  noun: 'shopping items',
  listTool: 'list_items',
);

void main() {
  group('resolveAiRows', () {
    test('matches on id and on name, in the order asked for', () {
      expect(resolve(['b2', 'bread']).map((r) => r.name), ['Eggs', 'Bread']);
    });

    test('is case and whitespace insensitive on names', () {
      expect(resolve(['  MILK ']).single.id, 'a1');
    });

    test('collapses duplicates, however they were named', () {
      expect(resolve(['a1', 'Milk', 'milk']), hasLength(1));
    });

    test('keeps the rows it found when only some keys miss', () {
      expect(resolve(['Milk', 'Caviar']).single.name, 'Milk');
    });

    test('an id wins over another row that happens to be named that', () {
      const rows = [Row('Milk', 'Bread'), Row('x9', 'Milk')];
      expect(resolve(['Milk'], pool: rows).single.name, 'Bread');
    });

    test(
      'names the list tool when nothing matched, so the model can retry',
      () {
        expect(
          () => resolve(['Caviar']),
          throwsA(
            isArgumentError.having(
              (e) => e.message,
              'message',
              allOf(contains('Caviar'), contains('list_items')),
            ),
          ),
        );
      },
    );

    test('an empty ask is an error, not an empty result', () {
      expect(() => resolve([]), throwsArgumentError);
      expect(() => resolve(const [], pool: const []), throwsArgumentError);
    });
  });
}
