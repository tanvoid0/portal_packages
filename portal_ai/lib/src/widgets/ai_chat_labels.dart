/// The handful of strings the shared chat surface shows.
///
/// portal_ai ships no localisation, and the apps that embed this do: portal_task
/// runs everything through GetX `.tr`. So the strings are a parameter with
/// English defaults rather than constants, which is what lets a localised app
/// adopt the sheet without losing its translations.
class AiChatLabels {
  const AiChatLabels({
    this.inputHint = 'What should I do?',
    this.empty = '',
    this.working = 'Working…',
    this.stop = 'Stop',
    this.add = 'Add',
    this.edit = 'Edit',
    this.discard = 'Discard',
    this.addAll = 'Add all',
    this.historyTitle = 'History',
    this.historyEmpty = 'No chats yet.',
    this.newChat = 'New chat',
    this.messages = 'messages',
    this.delete = 'Delete',
    this.close = 'Close',
  });

  final String inputHint;

  /// Shown when there is nothing at all yet. Empty by default so the sheet's
  /// suggestion chips stay the empty state for apps that pass some.
  final String empty;

  final String working;
  final String stop;
  final String add;
  final String edit;
  final String discard;

  /// Rendered with the pending count appended: `Add all (3)`.
  final String addAll;

  final String historyTitle;
  final String historyEmpty;
  final String newChat;

  /// Unit for a thread's turn count in the history list.
  final String messages;

  final String delete;
  final String close;
}
