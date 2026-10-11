import 'package:flutter/material.dart';

/// Black or white, whichever reads against [background] — for text/glyphs
/// drawn over a colour the caller picked at runtime (e.g. a user's chosen
/// accent), where no theme token can know the answer in advance.
Color portalOnColorFor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? Colors.white : Colors.black;
