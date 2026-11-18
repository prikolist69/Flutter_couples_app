import 'package:home_widget/home_widget.dart';

class WidgetSyncService {
  static const String androidWidgetName = 'OurSpaceWidget';

  // Метод передачи свежих данных в рабочий стол
  static Future<void> updateWidgetData({
    required String noteText,
    required String emoji,
    required String counterText,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('note_text', noteText);
      await HomeWidget.saveWidgetData<String>('note_emoji', emoji);
      await HomeWidget.saveWidgetData<String>('counter_text', counterText);

      // Принудительно вызываем нативную перерисовку виджета
      await HomeWidget.updateWidget(name: androidWidgetName);
    } catch (_) {}
  }
}
