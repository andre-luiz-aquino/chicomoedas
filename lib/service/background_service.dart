import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import '../conversao/currency_converter.dart';

class BackgroundService {
  static BackgroundService? _instance;
  late SendPort _sendPort;
  late Isolate _isolate;
  late double _alertValue;
  late String _email;

  factory BackgroundService() => _instance ??= BackgroundService._();

  BackgroundService._();

  Future<void> start(double alertValue, String email) async {
    _alertValue = alertValue;
    ReceivePort receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    _sendPort = await receivePort.first;
  }

   void _isolateEntry(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    port.listen((message) {
      if (message is Map && message.containsKey('action')) {
        String action = message['action'];
        if (action == 'START') {
          _startBackgroundTask();
        } else if (action == 'STOP') {
          _stopBackgroundTask();
        } else if (action == 'CHECK_EXCHANGE_RATE') {
          _checkExchangeRate();
        } else if (action == 'ALERT') {
          _handleAlert(message);
        }
      }
    });
  }

   void _startBackgroundTask() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      _sendPort.send({
        'action': 'CHECK_EXCHANGE_RATE',
      });
    });
  }

  static void _stopBackgroundTask() {
    print('Tarefa em segundo plano parada.');
  }

   void _checkExchangeRate() async {
    double? currentExchangeRate = await CurrencyConverter().getExchangeRate('USD', 'BRL');
    double alertValue = _instance!._alertValue;

    if (currentExchangeRate! >= alertValue) {
      _sendPort.send({
        'action': 'ALERT',
        'exchangeRate': currentExchangeRate,
      });
    }
  }

  void _handleAlert(Map message) {
    double exchangeRate = message['exchangeRate'];
    _sendEmail(exchangeRate,_email);
  }

  static void _sendEmail(double exchangeRate, String email) async {
    final String formattedDate =
    DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    final String body = 'O valor atual do dólar é $exchangeRate BRL.\n\n'
        '\n'
        'Att. Chico Moedas Company @2024'
        '\n'
        '$formattedDate';

    String username = 'andreaquino@ucl.br';
    String password = 'vmir amdi ppro vfpl';

    final smtpServer = gmail(username, password);
    log(email);
    final message = Message()
      ..from = Address(username, "Chico Moedas APP")
      ..recipients.add(email)
      ..subject = 'Valor do Dólar Atual'
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      log('Email enviado: $sendReport');
    } on MailerException catch (e) {
      log('Falha ao enviar email: ${e.toString()}');
    }
  }

  void stop() {
    _isolate.kill(priority: Isolate.immediate);
  }
}
