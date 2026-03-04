// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../services/logger_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notifications;
  bool _initialized = false;

  final List<Map<String, dynamic>> _notificacoes = [];

  List<Map<String, dynamic>> get notificacoes =>
      List.unmodifiable(_notificacoes);

  Function? onNotificationsUpdated;

  // 🔥 INICIALIZAÇÃO SEGURA
  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      _notifications = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      _initialized = true;
      LoggerService.info('✅ Notification service initialized');
    } catch (e) {
      LoggerService.warning(
          '⚠️ Notifications not supported on this platform: $e');
      _notifications = null;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    LoggerService.info('Notification tapped: ${response.payload}');
  }

  // 🔥 ADICIONAR NOTIFICAÇÃO (SEGURA)
  Future<void> addNotification({
    required String titulo,
    required String mensagem,
    String? ticker,
    double? valor,
  }) async {
    try {
      final notificacao = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'titulo': titulo,
        'mensagem': mensagem,
        'data': DateTime.now(),
        'lida': false,
        'ticker': ticker,
        'valor': valor,
      };

      _notificacoes.insert(0, notificacao);

      if (_notificacoes.length > 50) {
        _notificacoes.removeLast();
      }

      // Só tenta notificação nativa se estiver inicializado
      if (_initialized && _notifications != null) {
        try {
          const androidDetails = AndroidNotificationDetails(
            'default_channel',
            'Notificações',
            importance: Importance.high,
            priority: Priority.high,
          );

          const iosDetails = DarwinNotificationDetails();

          const notificationDetails = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
            macOS: iosDetails,
          );

          await _notifications!.show(
            notificacao['id'] as int,
            titulo,
            mensagem,
            notificationDetails,
            payload: ticker,
          );
        } catch (e) {
          LoggerService.info(
              'Native notification failed (expected on Windows)');
        }
      }

      onNotificationsUpdated?.call();
    } catch (e) {
      LoggerService.error('Failed to add notification', e);
    }
  }

  // 🔥 AGENDAR PROVENTO
  Future<void> scheduleProventoNotification({
    required String ticker,
    required DateTime dataPagamento,
    required double valor,
    required int id,
  }) async {
    try {
      await addNotification(
        titulo: '💰 Provento: $ticker',
        mensagem:
            'Você receberá ${_formatCurrency(valor)} em ${_formatDate(dataPagamento)}',
        ticker: ticker,
        valor: valor,
      );
    } catch (e) {
      LoggerService.error('Failed to schedule provento', e);
    }
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // 🔥 MARCAR COMO LIDA
  void marcarComoLida(int id) {
    final index = _notificacoes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notificacoes[index]['lida'] = true;
      onNotificationsUpdated?.call();
    }
  }

  void marcarTodasComoLidas() {
    for (var notif in _notificacoes) {
      notif['lida'] = true;
    }
    onNotificationsUpdated?.call();
  }

  void limparTodas() {
    _notificacoes.clear();
    onNotificationsUpdated?.call();
  }

  int get naoLidas => _notificacoes.where((n) => n['lida'] == false).length;

  void registerUpdateCallback(Function callback) {
    onNotificationsUpdated = callback;
  }

  // 🔥 CANCELAR NOTIFICAÇÃO (SEGURO)
  Future<void> cancelNotification(int id) async {
    try {
      if (_initialized && _notifications != null) {
        await _notifications!.cancel(id);
      }
    } catch (e) {
      LoggerService.warning('Failed to cancel notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      if (_initialized && _notifications != null) {
        await _notifications!.cancelAll();
      }
    } catch (e) {
      LoggerService.warning('Failed to cancel all notifications: $e');
    }
  }
}
