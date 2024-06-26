import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/src/MonthSelector.dart';
import 'package:month_picker_dialog/src/YearSelector.dart';
import 'package:month_picker_dialog/src/common.dart';
import 'package:month_picker_dialog/src/locale_utils.dart';
import 'package:rxdart/rxdart.dart';

/// Displays month picker dialog.
/// [initialDate] is the initially selected month.
/// [firstDate] is the optional lower bound for month selection.
/// [lastDate] is the optional upper bound for month selection.
Future<DateTime?> showMonthPicker({
  required Color selectorColor,
  required Color selectedTExtColor,
  required Color backgroundColor,
  required Color bottomButtonsColors,
  required Color textColor,
  required double fontSize,
  required String fontFamily,
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  Locale? locale,
}) async {
  final localizations = locale == null
      ? MaterialLocalizations.of(context)
      : await GlobalMaterialLocalizations.delegate.load(locale);
  return await showDialog<DateTime>(
    context: context,
    builder: (context) => _MonthPickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: locale,
      localizations: localizations,
      bottomButtonsColors: bottomButtonsColors,
      backgroundColor: backgroundColor,
      selectorColor: selectorColor,
      selectedTExtColor: selectedTExtColor,
      textColor: textColor,
      fontSize: fontSize,
        fontFamily : fontFamily
    ),
  );
}

class _MonthPickerDialog extends StatefulWidget {
  final Color selectorColor;
  final Color selectedTExtColor;
  final Color backgroundColor;
  final Color bottomButtonsColors;
  final Color textColor;
  final double fontSize;
  final String fontFamily;
  final DateTime? initialDate, firstDate, lastDate;
  final MaterialLocalizations localizations;
  final Locale? locale;

  const _MonthPickerDialog({
    Key? key,
    required this.initialDate,
    required this.localizations,
    this.firstDate,
    this.lastDate,
    this.locale,
    required this.selectorColor,
    required this.selectedTExtColor,
    required this.backgroundColor,
    required this.bottomButtonsColors,
    required this.textColor,
    required this.fontSize,
    required this.fontFamily,
  }) : super(key: key);

  @override
  _MonthPickerDialogState createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  final GlobalKey<YearSelectorState> _yearSelectorState = new GlobalKey();
  final GlobalKey<MonthSelectorState> _monthSelectorState = new GlobalKey();

  PublishSubject<UpDownPageLimit>? _upDownPageLimitPublishSubject;
  PublishSubject<UpDownButtonEnableState>?
  _upDownButtonEnableStatePublishSubject;

  Widget? _selector;
  DateTime? selectedDate, _firstDate, _lastDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime(widget.initialDate!.year, widget.initialDate!.month);
    if (widget.firstDate != null)
      _firstDate = DateTime(widget.firstDate!.year, widget.firstDate!.month);
    if (widget.lastDate != null)
      _lastDate = DateTime(widget.lastDate!.year, widget.lastDate!.month);

    _upDownPageLimitPublishSubject = new PublishSubject();
    _upDownButtonEnableStatePublishSubject = new PublishSubject();

    _selector = new MonthSelector(
      textColor: widget.textColor,
      key: _monthSelectorState,
      openDate: selectedDate!,
      selectedDate: selectedDate!,
      upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject!,
      upDownButtonEnableStatePublishSubject:
      _upDownButtonEnableStatePublishSubject!,
      firstDate: _firstDate,
      lastDate: _lastDate,
      onMonthSelected: _onMonthSelected,
      locale: widget.locale,
      selectorColor: widget.selectorColor,
      selectedTExtColor: widget.selectedTExtColor,
      fontFamily: widget.fontFamily
    );
  }

  void dispose() {
    _upDownPageLimitPublishSubject!.close();
    _upDownButtonEnableStatePublishSubject!.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = getLocale(context, selectedLocale: widget.locale);
    var header = buildHeader(theme, locale);
    var pager = buildPager(theme, locale);
    var content = Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [pager, buildButtonBar(context)],
      ),
      color: theme.dialogBackgroundColor,
    );
    return Theme(
      data:
      Theme.of(context).copyWith(dialogBackgroundColor: Colors.transparent),
      child: Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(builder: (context) {
              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                return IntrinsicWidth(
                  child: Column(children: [header, content]),
                );
              }
              return IntrinsicHeight(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [header, content]),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildButtonBar(
      BuildContext context,
      ) {
    return ButtonBar(
      children: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(widget.localizations.cancelButtonLabel, style: TextStyle(color: widget.bottomButtonsColors),),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedDate),
          child: Text(widget.localizations.okButtonLabel,  style: TextStyle(color: widget.bottomButtonsColors)),
        )
      ],
    );
  }

  Widget buildHeader(ThemeData theme, String locale) {
    return Material(
      color: widget.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${DateFormat.yMMM(locale).format(selectedDate!)}',
              style: TextStyle(color: widget.selectedTExtColor, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _selector is MonthSelector
                    ? GestureDetector(
                  onTap: _onSelectYear,
                  child: new StreamBuilder<UpDownPageLimit>(
                    stream: _upDownPageLimitPublishSubject,
                    initialData: const UpDownPageLimit(0, 0),
                    builder: (_, snapshot) => Text(
                      '${DateFormat.y(locale).format(DateTime(snapshot.data!.upLimit))}',
                      style: TextStyle(color: widget.selectedTExtColor, fontSize: 22, fontWeight: FontWeight.w300),
                    ),
                  ),
                )
                    : new StreamBuilder<UpDownPageLimit>(
                  stream: _upDownPageLimitPublishSubject,
                  initialData: const UpDownPageLimit(0, 0),
                  builder: (_, snapshot) => Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${DateFormat.y(locale).format(DateTime(snapshot.data!.upLimit))}',
                        style: TextStyle(color: widget.selectedTExtColor),
                      ),
                      Text(
                        '-',
                        style: TextStyle(color: widget.selectedTExtColor),
                      ),
                      Text(
                        '${DateFormat.y(locale).format(DateTime(snapshot.data!.downLimit))}',
                        style: TextStyle(color: widget.selectedTExtColor),
                      ),
                    ],
                  ),
                ),
                new StreamBuilder<UpDownButtonEnableState>(
                  stream: _upDownButtonEnableStatePublishSubject,
                  initialData: const UpDownButtonEnableState(true, true),
                  builder: (_, snapshot) => Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          color: snapshot.data!.upState
                              ? widget.selectedTExtColor
                              : widget.selectedTExtColor.withOpacity(0.5),
                        ),
                        onPressed:
                        snapshot.data!.upState ? _onUpButtonPressed : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: snapshot.data!.downState
                              ? widget.selectedTExtColor
                              : widget.selectedTExtColor.withOpacity(0.5),
                        ),
                        onPressed: snapshot.data!.downState
                            ? _onDownButtonPressed
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPager(ThemeData theme, String locale) {
    return SizedBox(
      height: 230.0,
      width: 300.0,
      child: Theme(
        data: theme.copyWith(
          buttonTheme: ButtonThemeData(
            padding: EdgeInsets.all(2.0),
            shape: CircleBorder(),
            minWidth: 4.0,
          ),
        ),
        child: new AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(child: child, scale: animation),
          child: _selector,
        ),
      ),
    );
  }

  void _onSelectYear() => setState(() => _selector = new YearSelector(
    key: _yearSelectorState,
    initialDate: selectedDate!,
    firstDate: _firstDate,
    lastDate: _lastDate,
    onYearSelected: _onYearSelected,
    upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject!,
    upDownButtonEnableStatePublishSubject:
    _upDownButtonEnableStatePublishSubject!,
      textColor: widget.textColor,
      fontFamily: widget.fontFamily,
    fontSize: widget.fontSize, selectorColor: widget.selectorColor, selectedTExtColor: widget.selectedTExtColor,
  ));

  void _onYearSelected(final int year) =>
      setState(() => _selector = new MonthSelector(
        key: _monthSelectorState,
        openDate: DateTime(year),
        selectedDate: selectedDate!,
        upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject!,
        upDownButtonEnableStatePublishSubject:
        _upDownButtonEnableStatePublishSubject!,
        firstDate: _firstDate,
        lastDate: _lastDate,
        onMonthSelected: _onMonthSelected,
        locale: widget.locale,
        selectorColor: widget.selectorColor,
        selectedTExtColor: widget.selectedTExtColor,
        textColor: widget.textColor,
          fontFamily: widget.fontFamily
      ));

  void _onMonthSelected(final DateTime date) => setState(() {
    selectedDate = date;
    _selector = new MonthSelector(
      selectorColor: widget.selectorColor,
      selectedTExtColor: widget.selectedTExtColor,
      key: _monthSelectorState,
      openDate: selectedDate!,
      selectedDate: selectedDate!,
      upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject!,
      upDownButtonEnableStatePublishSubject:
      _upDownButtonEnableStatePublishSubject!,
      firstDate: _firstDate,
      lastDate: _lastDate,
      onMonthSelected: _onMonthSelected,
      locale: widget.locale,
      textColor: widget.textColor,
        fontFamily: widget.fontFamily
    );
  });

  void _onUpButtonPressed() {
    if (_yearSelectorState.currentState != null) {
      _yearSelectorState.currentState!.goUp();
    } else {
      _monthSelectorState.currentState!.goUp();
    }
  }

  void _onDownButtonPressed() {
    if (_yearSelectorState.currentState != null) {
      _yearSelectorState.currentState!.goDown();
    } else {
      _monthSelectorState.currentState!.goDown();
    }
  }
}
