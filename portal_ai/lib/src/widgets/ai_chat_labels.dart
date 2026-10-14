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
    this.speak = 'Speak',
    this.stopListening = 'Stop listening',
    this.listening = 'Listening…',
    this.speaking = 'Speaking…',
    this.captionsOn = 'Show captions',
    this.captionsOff = 'Hide captions',
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
    this.offline =
        'No connection. The assistant needs one to answer — try again once '
        'you are back online.',
    this.youSaid = 'You said',
    this.assistantSaid = 'Assistant said',
    this.searchInChat = 'Find in conversation',
    this.searchInChatHint = 'Find a message',
    this.searchMatches = '@current of @total',
    this.searchNoMatches = 'No matches',
    this.searchPrevious = 'Previous match',
    this.searchNext = 'Next match',
    this.share = 'Share',
    this.copyAsMarkdown = 'Copy as markdown',
    this.copyAsJson = 'Copy as JSON',
    this.jumpToLatest = 'Jump to latest',
    this.attached = 'Attached',
    this.readingFile = 'Reading the file…',
    this.removeAttachment = 'Remove attachment',
    this.rewind = 'Go back',
    this.rewindWarning =
        'Going back to this message drops the @count messages after it.',
    this.copy = 'Copy',
    this.copied = 'Copied',
    this.deleted = 'Chat deleted',
    this.undo = 'Undo',
    this.writing = 'Writing',
    this.waitingForYou = 'Waiting for you',
    this.notSent = 'Not sent',
    this.cantReach = "Can't reach",
    this.copyReply = 'Copy reply',
    this.regenerate = 'Regenerate reply',
    this.typeAChange = 'Type a change…',
    this.accept = 'Accept',
    this.decline = 'Decline',
    this.changeModel = 'Change model',
    this.aiSettings = 'AI settings',
    this.aiProvider = 'AI provider',
    this.assistantRole = 'Assistant role',
    this.autoRole = 'Auto',
    this.micDeniedTitle = 'Portal Assistant needs the microphone to listen',
    this.micDeniedMessage = 'Allow it in Settings, then come back to talk.',
    this.micDeniedNoSettings = 'Allow it in Settings, or close this and type.',
    this.openSettings = 'Open settings',
    this.voiceErrorTitle = "Voice isn't available right now",
    this.incognitoChip = "Incognito: this chat isn't saved",
    this.leaveIncognito = 'Leave incognito',
    this.incognitoEmpty = 'Not saved to history, and gone when you leave.',
  });

  /// Voice page, microphone refused: [micDeniedMessage] when the host can open
  /// settings, [micDeniedNoSettings] when it can only point the way back.
  final String micDeniedTitle;
  final String micDeniedMessage;
  final String micDeniedNoSettings;
  final String openSettings;

  /// Voice page, session failed; the session's own error is the message.
  final String voiceErrorTitle;

  /// Incognito: the chip over the composer, its dismiss tooltip, and the
  /// opening line.
  final String incognitoChip;
  final String leaveIncognito;
  final String incognitoEmpty;

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

  /// The microphone, drawn only when the device can hear and talk back
  /// without a server. [listening] replaces the hint while it hears.
  final String speak;
  final String stopListening;
  final String listening;
  final String speaking;
  final String captionsOn;
  final String captionsOff;

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

  /// Read out before a turn, since who is speaking is otherwise only the
  /// bubble's side and colour.
  final String youSaid;
  final String assistantSaid;

  /// Find-in-conversation, the export menu, the jump-to-latest button and the
  /// attachment chip.
  final String searchInChat;
  final String searchInChatHint;

  /// Match counter: `@current` and `@total` are replaced.
  final String searchMatches;
  final String searchNoMatches;
  final String searchPrevious;
  final String searchNext;
  final String share;
  final String copyAsMarkdown;
  final String copyAsJson;
  final String jumpToLatest;
  final String attached;
  final String readingFile;
  final String removeAttachment;

  /// Confirming a rewind past the last exchange. `@count` is the number of
  /// messages that would be dropped.
  final String rewind;
  final String rewindWarning;

  /// Shown instead of a raw socket error when the network is the problem.
  final String offline;

  /// Per-message copy, and what the snackbar says once it lands.
  final String copy;
  final String copied;

  /// The line under a reply: its state while it is coming, and the actions
  /// once it is here.
  final String writing;
  final String waitingForYou;
  final String copyReply;
  final String regenerate;

  /// Under the question when the network was down before anything came back,
  /// and the header's status until the next send gets through.
  final String notSent;
  final String cantReach;

  /// Composer hint while a proposed change waits on the user: typing declines
  /// it and says what to do instead.
  final String typeAChange;

  /// The proposed-change card's answers.
  final String accept;
  final String decline;

  /// Header tooltip, the settings entry and the provider sheet's title.
  final String changeModel;
  final String aiSettings;
  final String aiProvider;

  /// The role-picker chip row: [assistantRole] names the mutually-exclusive
  /// group for a screen reader; [autoRole] is the default chip that lets the
  /// router choose per message.
  final String assistantRole;
  final String autoRole;
}
