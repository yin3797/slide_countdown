import 'package:flutter/material.dart';
import 'package:slide_countdown/src/utils/slide_countdown_base.dart';
import 'package:slide_countdown/src/utils/utils.dart';
import 'package:stream_duration/stream_duration.dart';
import 'separated/separated.dart';

import 'utils/countdown_mixin.dart';
import 'utils/duration_title.dart';
import 'utils/enum.dart';
import 'utils/extensions.dart';
import 'utils/notifiy_duration.dart';

/// {@template slide_countdown_separated}
/// The SlideCountdownSeparated is a StatefulWidget that
/// creates a countdown timer that slides up or down to display
/// the remaining time and each duration will be separated.
///
/// Example usage:
///
/// ```dart
/// SlideCountdownSeparated(
///   duration: const Duration(days: 2),
/// );
/// ```
/// {@endtemplate}
class SlideCountdownSeparated extends SlideCountdownBase {
  /// {@macro slide_countdown_separated}
  const SlideCountdownSeparated({
    super.key,
    super.duration,
    this.height = 30,
    this.width = 30,
    super.textStyle = kDefaultTextStyle,
    super.separatorStyle = kDefaultSeparatorTextStyle,
    super.icon,
    super.suffixIcon,
    super.separator,
    super.replacement,
    super.onDone,
    super.durationTitle,
    super.separatorType = SeparatorType.symbol,
    super.slideDirection = SlideDirection.down,
    super.padding = const EdgeInsets.all(5),
    super.separatorPadding = const EdgeInsets.symmetric(horizontal: 3),
    super.showZeroValue = false,
    super.decoration = kDefaultSeparatedBoxDecoration,
    super.curve = Curves.easeOut,
    super.countUp = false,
    super.infinityCountUp = false,
    super.countUpAtDuration,
    super.slideAnimationDuration = kDefaultAnimationDuration,
    super.digitsNumber,
    super.streamDuration,
    super.onChanged,
    super.shouldShowDays,
    super.shouldShowHours,
    super.shouldShowMinutes,
    super.shouldShowSeconds,
    super.isShowDurationTitleBelow = false,
    super.durationTitleStyle = kDefaultDurationTitleTextStyle,
    super.durationTitlePadding = 20,
  });

  /// height to set the size of height each [Container]
  /// [Container] will be the background of each a duration
  /// to decorate the [Container] on the [decoration] property
  final double height;

  /// width to set the size of width each [Container]
  /// [Container] will be the background of each a duration
  /// to decorate the [Container] on the [decoration] property
  final double width;

  @override
  _SlideCountdownSeparatedState createState() => _SlideCountdownSeparatedState();
}

class _SlideCountdownSeparatedState extends State<SlideCountdownSeparated> with CountdownMixin {
  late StreamDuration _streamDuration;
  late NotifiyDuration _notifiyDuration;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _notifiyDuration = NotifiyDuration(duration);
    _disposed = false;
    _streamDurationListener();
    _updateConfigurationNotifier(widget.duration);
  }

  @override
  void didUpdateWidget(covariant SlideCountdownSeparated oldWidget) {
    if (widget.countUp != oldWidget.countUp ||
        widget.infinityCountUp != oldWidget.infinityCountUp) {
      _streamDuration.dispose();
      _streamDurationListener();
    }
    if (widget.duration != oldWidget.duration) {
      _streamDuration.change(duration);
    }

    if (oldWidget.shouldShowDays != widget.shouldShowDays ||
        oldWidget.shouldShowHours != widget.shouldShowHours ||
        oldWidget.shouldShowMinutes != widget.shouldShowMinutes ||
        oldWidget.shouldShowSeconds != widget.shouldShowSeconds ||
        oldWidget.showZeroValue != widget.showZeroValue) {
      _updateConfigurationNotifier();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _streamDurationListener() {
    _streamDuration = widget.streamDuration ??
        StreamDuration(
          duration,
          onDone: () => widget.onDone?.call(),
          countUp: widget.countUp,
          countUpAtDuration: widget.countUpAtDuration ?? false,
          infinity: widget.infinityCountUp,
        );

    if (!_disposed) {
      try {
        _streamDuration.durationLeft.listen(
          (duration) {
            _notifiyDuration.streamDuration(duration);
            updateValue(duration);
            if (widget.onChanged != null) {
              widget.onChanged!(duration);
            }
          },
        );
      } catch (ex) {
        debugPrint(ex.toString());
      }
    }
  }

  void _updateConfigurationNotifier([Duration? duration]) {
    final remainingDuration = duration ?? _streamDuration.remainingDuration;
    final defaultShowDays = remainingDuration.inDays < 1 && !widget.showZeroValue ? false : true;
    final defaultShowHours = remainingDuration.inHours < 1 && !widget.showZeroValue ? false : true;
    final defaultShowMinutes =
        remainingDuration.inMinutes < 1 && !widget.showZeroValue ? false : true;
    final defaultShowSeconds =
        remainingDuration.inSeconds < 1 && !widget.showZeroValue ? false : true;

    /// cal func from CountdownMixin
    updateConfigurationNotifier(
      updateDaysNotifier: widget.shouldShowDays != null
          ? widget.shouldShowDays!(remainingDuration)
          : defaultShowDays,
      updateHoursNotifier: widget.shouldShowHours != null
          ? widget.shouldShowHours!(remainingDuration)
          : defaultShowHours,
      updateMinutesNotifier: widget.shouldShowMinutes != null
          ? widget.shouldShowMinutes!(remainingDuration)
          : defaultShowMinutes,
      updateSecondsNotifier: widget.shouldShowSeconds != null
          ? widget.shouldShowSeconds!(remainingDuration)
          : defaultShowSeconds,
    );
  }

  Duration get duration => widget.duration ?? widget.streamDuration!.duration;

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
    _streamDuration.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durationTitle = widget.durationTitle ?? DurationTitle.en();
    final separator = widget.separator ?? ':';
    final textDirection = Directionality.of(context);

    final leadingIcon = Visibility(
      visible: widget.icon != null,
      child: widget.icon ?? const SizedBox.shrink(),
    );

    final suffixIcon = Visibility(
      visible: widget.suffixIcon != null,
      child: widget.suffixIcon ?? const SizedBox.shrink(),
    );

    return ValueListenableBuilder(
      valueListenable: _notifiyDuration,
      builder: (BuildContext context, Duration duration, Widget? child) {
        if (duration.inSeconds <= 0 && child != null) return child;

        final defaultShowDays = duration.inDays < 1 && !widget.showZeroValue ? false : true;
        final defaultShowHours = duration.inHours < 1 && !widget.showZeroValue ? false : true;
        final defaultShowMinutes = duration.inMinutes < 1 && !widget.showZeroValue ? false : true;
        final defaultShowSeconds = duration.inSeconds < 1 && !widget.showZeroValue ? false : true;

        final showDays =
            widget.shouldShowDays != null ? widget.shouldShowDays!(duration) : defaultShowDays;
        final showHours =
            widget.shouldShowHours != null ? widget.shouldShowHours!(duration) : defaultShowHours;
        final showMinutes = widget.shouldShowMinutes != null
            ? widget.shouldShowMinutes!(duration)
            : defaultShowMinutes;
        final showSeconds = widget.shouldShowSeconds != null
            ? widget.shouldShowSeconds!(duration)
            : defaultShowSeconds;

        final isSeparatorTitle = widget.separatorType == SeparatorType.title;

        final days = DigitSeparatedItem(
          height: widget.height,
          width: widget.width,
          decoration: widget.decoration,
          firstDigit: daysFirstDigitNotifier,
          secondDigit: daysSecondDigitNotifier,
          textStyle: widget.textStyle,
          separatorStyle: widget.separatorStyle,
          initValue: 0,
          slideDirection: widget.slideDirection,
          showZeroValue: widget.showZeroValue,
          curve: widget.curve,
          countUp: widget.countUp,
          slideAnimationDuration: widget.slideAnimationDuration,
          separatorPadding: widget.separatorPadding,
          separator: widget.separatorType == SeparatorType.title ? durationTitle.days : separator,
          textDirection: textDirection,
          durationTitle: durationTitle.days,
          durationTitleStyle: widget.durationTitleStyle,
          durationTitlePadding: widget.durationTitlePadding,
          isShowDurationTitleBelow: widget.isShowDurationTitleBelow,
          digitsNumber: widget.digitsNumber,
          showSeparator:
              (showHours || showMinutes || showSeconds) || (isSeparatorTitle && showDays),
        );

        final hours = DigitSeparatedItem(
          height: widget.height,
          width: widget.width,
          decoration: widget.decoration,
          firstDigit: hoursFirstDigitNotifier,
          secondDigit: hoursSecondDigitNotifier,
          textStyle: widget.textStyle,
          separatorStyle: widget.separatorStyle,
          initValue: 0,
          slideDirection: widget.slideDirection,
          showZeroValue: widget.showZeroValue,
          curve: widget.curve,
          countUp: widget.countUp,
          slideAnimationDuration: widget.slideAnimationDuration,
          separatorPadding: widget.separatorPadding,
          separator: widget.separatorType == SeparatorType.title ? durationTitle.hours : separator,
          textDirection: textDirection,
          durationTitle: durationTitle.hours,
          durationTitleStyle: widget.durationTitleStyle,
          durationTitlePadding: widget.durationTitlePadding,
          isShowDurationTitleBelow: widget.isShowDurationTitleBelow,
          digitsNumber: widget.digitsNumber,
          showSeparator: showMinutes || showSeconds || (isSeparatorTitle && showHours),
        );

        final minutes = DigitSeparatedItem(
          height: widget.height,
          width: widget.width,
          decoration: widget.decoration,
          firstDigit: minutesFirstDigitNotifier,
          secondDigit: minutesSecondDigitNotifier,
          textStyle: widget.textStyle,
          separatorStyle: widget.separatorStyle,
          initValue: 0,
          slideDirection: widget.slideDirection,
          showZeroValue: widget.showZeroValue,
          curve: widget.curve,
          countUp: widget.countUp,
          slideAnimationDuration: widget.slideAnimationDuration,
          separatorPadding: widget.separatorPadding,
          separator:
              widget.separatorType == SeparatorType.title ? durationTitle.minutes : separator,
          textDirection: textDirection,
          durationTitle: durationTitle.minutes,
          durationTitleStyle: widget.durationTitleStyle,
          durationTitlePadding: widget.durationTitlePadding,
          isShowDurationTitleBelow: widget.isShowDurationTitleBelow,
          digitsNumber: widget.digitsNumber,
          showSeparator: showSeconds || (isSeparatorTitle && showMinutes),
        );

        final seconds = DigitSeparatedItem(
          height: widget.height,
          width: widget.width,
          decoration: widget.decoration,
          firstDigit: secondsFirstDigitNotifier,
          secondDigit: secondsSecondDigitNotifier,
          textStyle: widget.textStyle,
          separatorStyle: widget.separatorStyle,
          initValue: 0,
          slideDirection: widget.slideDirection,
          showZeroValue: widget.showZeroValue,
          curve: widget.curve,
          countUp: widget.countUp,
          slideAnimationDuration: widget.slideAnimationDuration,
          separatorPadding: widget.separatorPadding,
          separator:
              widget.separatorType == SeparatorType.title ? durationTitle.seconds : separator,
          textDirection: textDirection,
          durationTitle: durationTitle.seconds,
          durationTitleStyle: widget.durationTitleStyle,
          durationTitlePadding: widget.durationTitlePadding,
          isShowDurationTitleBelow: widget.isShowDurationTitleBelow,
          digitsNumber: widget.digitsNumber,
          showSeparator: isSeparatorTitle && showSeconds,
        );

        final daysWidget = showDays ? days : const SizedBox.shrink();

        final hoursWidget = showHours ? hours : const SizedBox.shrink();

        final minutesWidget = showMinutes ? minutes : const SizedBox.shrink();

        final secondsWidget = showSeconds ? seconds : const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: textDirection.isRtl
              ? [
                  suffixIcon,
                  secondsWidget,
                  minutesWidget,
                  hoursWidget,
                  daysWidget,
                  leadingIcon,
                ]
              : [
                  leadingIcon,
                  daysWidget,
                  hoursWidget,
                  minutesWidget,
                  secondsWidget,
                  suffixIcon,
                ],
        );
      },
      child: widget.replacement,
    );
  }
}
