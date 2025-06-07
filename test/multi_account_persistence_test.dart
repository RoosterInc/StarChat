import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/controllers/multi_account_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MultiAccountController persists multiple accounts', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = MultiAccountController();
    await controller.loadAccounts();

    await controller.addAccount(
      AccountInfo(userId: '1', username: 'user1', sessionId: 's1'),
    );
    await controller.addAccount(
      AccountInfo(userId: '2', username: 'user2', sessionId: 's2'),
    );

    expect(controller.accounts.length, 2);
    expect(controller.activeAccountId.value, '2');

    final controller2 = MultiAccountController();
    await controller2.loadAccounts();

    expect(controller2.accounts.length, 2);
    expect(controller2.activeAccountId.value, '2');
  });
}
