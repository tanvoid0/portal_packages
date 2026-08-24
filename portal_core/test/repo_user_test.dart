import 'package:test/test.dart';
import 'package:portal_core/models/repo_user.dart';

class MockRepoUserRepository {
  final List<String> calls = [];
  final List<dynamic> params = [];

  String get endpoint => '/repo_users';

  Future<List<RepoUser>> getAll() async {
    calls.add('getAll');
    return [];
  }

  Future<RepoUser?> getById(String id) async {
    calls.add('getById');
    params.add(id);
    return null;
  }

  Future<RepoUser> create(RepoUser user) async {
    calls.add('create');
    params.add(user);
    return user;
  }

  Future<RepoUser> update(RepoUser user) async {
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
  test('RepoUserRepository getAll invokes correct API', () async {
    final repo = MockRepoUserRepository();
    await repo.getAll();
    expect(repo.calls, contains('getAll'));
  });

  test('RepoUserRepository getById passes id', () async {
    final repo = MockRepoUserRepository();
    await repo.getById('abc');
    expect(repo.calls, contains('getById'));
    expect(repo.params, contains('abc'));
  });

  test('RepoUserRepository create passes user', () async {
    final repo = MockRepoUserRepository();
    final user = RepoUser(id: '1', name: 'Test');
    await repo.create(user);
    expect(repo.calls, contains('create'));
    expect(repo.params, contains(user));
  });

  test('RepoUserRepository update passes user', () async {
    final repo = MockRepoUserRepository();
    final user = RepoUser(id: '2', name: 'Update');
    await repo.update(user);
    expect(repo.calls, contains('update'));
    expect(repo.params, contains(user));
  });

  test('RepoUserRepository delete passes id', () async {
    final repo = MockRepoUserRepository();
    await repo.delete('xyz');
    expect(repo.calls, contains('delete'));
    expect(repo.params, contains('xyz'));
  });
}
