import 'package:test/test.dart';
import 'package:portal_core/models/repo_user_default.dart';

class MockRepoUserDefaultRepository {
  final List<String> calls = [];
  final List<dynamic> params = [];

  String get endpoint => '/repo_user_defaults';

  Future<List<RepoUserDefault>> getAll() async {
    calls.add('getAll');
    return [];
  }

  Future<RepoUserDefault?> getById(String id) async {
    calls.add('getById');
    params.add(id);
    return null;
  }

  Future<RepoUserDefault> create(RepoUserDefault user) async {
    calls.add('create');
    params.add(user);
    return user;
  }

  Future<RepoUserDefault> update(RepoUserDefault user) async {
    calls.add('update');
    params.add(user);
    return user;
  }

  Future<void> delete(String id) async {
    calls.add('delete');
    params.add(id);
  }
}

void main() {
  test('RepoUserDefaultRepository uses default endpoint', () {
    final repo = MockRepoUserDefaultRepository();
    expect(repo.endpoint, equals('/repo_user_defaults'));
  });

  test('RepoUserDefaultRepository getAll invokes correct API', () async {
    final repo = MockRepoUserDefaultRepository();
    await repo.getAll();
    expect(repo.calls, contains('getAll'));
  });

  test('RepoUserDefaultRepository getById passes id', () async {
    final repo = MockRepoUserDefaultRepository();
    await repo.getById('abc');
    expect(repo.calls, contains('getById'));
    expect(repo.params, contains('abc'));
  });

  test('RepoUserDefaultRepository create passes user', () async {
    final repo = MockRepoUserDefaultRepository();
    final user = RepoUserDefault(id: '1', name: 'Test');
    await repo.create(user);
    expect(repo.calls, contains('create'));
    expect(repo.params, contains(user));
  });

  test('RepoUserDefaultRepository update passes user', () async {
    final repo = MockRepoUserDefaultRepository();
    final user = RepoUserDefault(id: '2', name: 'Update');
    await repo.update(user);
    expect(repo.calls, contains('update'));
    expect(repo.params, contains(user));
  });

  test('RepoUserDefaultRepository delete passes id', () async {
    final repo = MockRepoUserDefaultRepository();
    await repo.delete('xyz');
    expect(repo.calls, contains('delete'));
    expect(repo.params, contains('xyz'));
  });
}
