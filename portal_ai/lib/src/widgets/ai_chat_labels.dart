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
    this.thinking = 'Thought process',
    this.retry = 'Retry',
    this.moreIdeas = 'More ideas',
    this.shuffle = 'Shuffle',
    this.attach = 'Attach a photo',
    this.consentBlocked = 'Accept the notice above to start',
    this.searchHint = 'Search chats',
    this.today = 'Today',
    this.yesterday = 'Yesterday',
    this.earlier = 'Earlier',
    this.noMatches = 'No chats match that.',
    this.pinned = 'Pinned',
    this.pin = 'Pin',
    this.unpin = 'Unpin',
    this.rename = 'Rename',
    this.renameTitle = 'Rename chat',
    this.cancel = 'Cancel',
    this.save = 'Save',
    this.deleted = 'Chat deleted',
    this.undo = 'Undo',
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

  /// Header of the collapsed reasoning block, for models that report any.
  final String thinking;

  /// Re-sends the last question, after a failure or an edit.
  final String retry;

  /// Asks the model for a fresh set of suggestion cards.
  final String moreIdeas;

  /// Re-picks the deck from the prompts already loaded.
  final String shuffle;

  final String attach;

  /// Composer hint while the consent card is still unanswered.
  final String consentBlocked;

  final String searchHint;

  /// Date group headers in the thread list.
  final String today;
  final String yesterday;
  final String earlier;

  /// Shown when a search matches no thread.
  final String noMatches;

  /// History list: the pinned group, the row menu, the rename dialog and the
  /// snackbar that undoes a delete.
  final String pinned;
  final String pin;
  final String unpin;
  final String rename;
  final String renameTitle;
  final String cancel;
  final String save;
  final String deleted;
  final String undo;
}
