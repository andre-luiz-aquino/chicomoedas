import 'dart:async';
import 'dart:developer';
import 'package:chicomoedas/conversao/currency_converter.dart';
import 'package:chicomoedas/dataBase/historico_db.dart';
import 'package:chicomoedas/dataBase/usuario_db.dart';
import 'package:chicomoedas/dto/usuario_dto.dart';
import 'package:chicomoedas/format/input_format.dart';
import 'package:chicomoedas/service/background_service.dart';
import 'package:chicomoedas/views/historico_cotacao.dart';
import 'package:chicomoedas/views/historico_page.dart';
import 'package:chicomoedas/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ConversorPage extends StatefulWidget {
  const ConversorPage({super.key});

  @override
  State<ConversorPage> createState() => _ConversorPageState();
}

class _ConversorPageState extends State<ConversorPage> {
  final dbHelper = DatabaseHelper();
  final dbHelperU = DatabaseUser();
  late Usuario usuarioLogado;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _valueController = TextEditingController();
  double? _exchangeRate;
  double? _cotaAtual;
  double? _convertedValue;
  Timer? _timer;
  bool _emailSent = false;
  String _nomeUsuario = '';

  bool _showAlertModal = false;
  double _alertValue = 0;

  String _selectedCurrency = 'USD';
  bool _isFetching = false;

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'Dólar Americano', 'image': 'assets/usa.png'},
    {'code': 'AUD', 'name': 'Dólar Australiano', 'image': 'assets/aud.jpeg'},
    {
      'code': 'ARS',
      'name': 'Pesos Argentinos',
      'image': 'assets/argentina.jpeg'
    }
  ];

  late BackgroundService _backgroundService;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
    _startTimer();
    _getUsuarioLogado();

  }

  Future<void> _startBackgroundService() async {
    await BackgroundService().start(_alertValue,usuarioLogado.email);
  }

  Future<void> _loadUsuario() async {
    final dbHelper = DatabaseUser();
    Usuario? usuarioLogado = await dbHelper.getLogado();

    if (usuarioLogado != null) {
      setState(() {
        _nomeUsuario = usuarioLogado.nomeCompleto;
      });
    }
  }

  Future<void> _getUsuarioLogado() async {
    usuarioLogado = (await dbHelperU.getLogado())!;
    _startBackgroundService();
  }

  Future<void> _buscarTaxaCambio() async {
    setState(() {
      _isFetching = true;
    });
    try {
      final rate =
          await CurrencyConverter().getExchangeRate('BRL', _selectedCurrency);
      setState(() {
        _exchangeRate = rate;
      });

      if (_exchangeRate == _alertValue) {
        _sendEmail();
      }
    } catch (error) {
      log('Falha ao buscar taxa de câmbio: $error');
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _calcularConversao() async {
    await _buscarTaxaCambio();

    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (value != null && _exchangeRate != null) {
      setState(() {
        _convertedValue = value * _exchangeRate!;
      });

      dbHelper.insertHistorico(value, _selectedCurrency);
    }
  }

  void _sendEmail() async {
    _cotaAtual = await CurrencyConverter().getExchangeRate('USD', "BRL");
    if (_cotaAtual == null) {
      log('Taxa de câmbio não disponível.');
      return;
    }

    final String formattedDate =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    final String body = 'O valor atual do dólar é $_cotaAtual BRL.\n\n'
        '\n'
        'Att. Chico Moedas Company @2024'
        '\n'
        '$formattedDate';

    String username = 'andreaquino@ucl.br';
    String password = 'vmir amdi ppro vfpl';

    final smtpServer = gmail(username, password);
    log(usuarioLogado.email);
    final message = Message()
      ..from = Address(username, "Chico Moedas APP")
      ..recipients.add(usuarioLogado.email)
      ..subject = 'Valor do Dólar Atual'
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      log('Email enviado: $sendReport');
    } on MailerException catch (e) {
      log('Falha ao enviar email: ${e.toString()}');
    }
  }

  void _startTimer() {
    const Duration interval1Minute = Duration(minutes: 1);
    const Duration interval10Minutes = Duration(minutes: 10);

    // Inicia o timer de 1 minuto
    _timer = Timer.periodic(interval1Minute, (timer) async {
      _cotaAtual = await CurrencyConverter().getExchangeRate('USD', "BRL");
      if (_cotaAtual != null && _cotaAtual! == _alertValue && !_emailSent) {
        _sendEmail();
        _emailSent = true;
        timer.cancel(); // Cancela o timer de 1 minuto

        // Inicia o timer de 10 minutos
        _timer = Timer.periodic(interval10Minutes, (timer) {
          _timer
              ?.cancel(); // Cancela o timer de 10 minutos antes de iniciar um novo

          // Inicia novamente o timer de 1 minuto
          _startTimer();
        });
      } else {
        log('Dólar ainda não atingiu R\$$_alertValue.'
            '\n'
            '$_cotaAtual');
      }
    });
  }

  Future<void> _openAlertModal() async {
    setState(() {
      _showAlertModal = true;
    });
    _cotaAtual = await CurrencyConverter().getExchangeRate('USD', "BRL");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Alerta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Digite o valor:'),
              SizedBox(height: 10.h),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  setState(() {
                    _alertValue = double.tryParse(value) ?? 0.0;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Digite aqui Ex:. $_cotaAtual',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _saveAlertValue();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alerta criado. Valor: $_alertValue')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF323232),
                padding: EdgeInsets.symmetric(
                  horizontal: 90.w,
                  vertical: 10.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
              child: Text(
                'Salvar',
                style: TextStyle(
                  fontSize: 20.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveAlertValue() {
    setState(() {
      _showAlertModal = false;
    });
    // _sendEmail();
    Navigator.pop(context);
    log('Valor do alerta salvo: $_alertValue');
  }

  Future<void> _logout(BuildContext context) async {
    final dbHelper = DatabaseUser();
    usuarioLogado = (await dbHelper.getLogado())!;
    if (usuarioLogado != null) {
      await dbHelper.updateLogado(usuarioLogado.nomeUsuario, false);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _backgroundService.stop();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => SafeArea(
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Image.asset(
                'assets/menu.png',
                width: 33.sp,
                height: 33.sp,
                fit: BoxFit.fill,
              ),
              onPressed: () {
                _scaffoldKey.currentState!.openDrawer();
              },
            ),
            title: Text(
              'Conversor',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Image.asset(
                  'assets/voltar.png',
                  width: 33.sp,
                  height: 33.sp,
                  fit: BoxFit.fill,
                ),
                onPressed: () => _logout(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 750.h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 300.w,
                        child: TextFormField(
                          controller: _valueController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 30),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                            DecimalTextInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.r),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 20.h),
                            hintText: 'VALOR',
                          ),
                        ),
                      ),
                      Image.asset('assets/iconTransicao.png', height: 100.h),
                      SizedBox(
                        width: 300.w,
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 30),
                          readOnly: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.r),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 20.h),
                            hintText:
                                _convertedValue?.toStringAsFixed(2) ?? 'VALOR',
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        onPressed: _calcularConversao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF323232),
                          padding: EdgeInsets.symmetric(
                              horizontal: 110.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        child: Text(
                          'Calcular',
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      ElevatedButton(
                        onPressed: () {
                          _openAlertModal();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF323232),
                          padding: EdgeInsets.symmetric(
                              horizontal: 100.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        child: Text(
                          'Criar Alerta',
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 190.h,
                  left: 10.w,
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    padding: EdgeInsets.all(2.5.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 40.r,
                      backgroundImage: const AssetImage("assets/br.png"),
                    ),
                  ),
                ),
                Positioned(
                  top: 190.h,
                  left: 305.w,
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    padding: EdgeInsets.all(2.5.w),
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'BRL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 365.h,
                  left: 10.w,
                  child: Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        icon:
                            const Icon(Icons.arrow_downward, color: Colors.red),
                        iconSize: 0,
                        elevation: 16,
                        dropdownColor: Colors.transparent,
                        onChanged: (String? newValue) async {
                          setState(() {
                            _selectedCurrency = newValue!;
                            _exchangeRate = null;
                            _convertedValue = null;
                          });
                          _calcularConversao();
                        },
                        items: _currencies.map<DropdownMenuItem<String>>(
                            (Map<String, String> currency) {
                          return DropdownMenuItem<String>(
                            value: currency['code'],
                            child: Row(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    currency['image']!,
                                    width: 50.w,
                                    height: 50.h,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 370.h,
                  left: 305.w,
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    padding: EdgeInsets.all(2.5.w),
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _currencies.firstWhere((currency) =>
                            currency['code'] == _selectedCurrency)['code']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF323232),
                  ),
                  child: Text(
                    'Bem-vindo, $_nomeUsuario!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Conversor'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/') {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConversorPage(),
                          settings: const RouteSettings(name: '/'),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Histórico'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/historico') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoricoPage(),
                          settings: const RouteSettings(name: '/historico'),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Histórico de Cotação'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name !=
                        '/historico_cotacao') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoricoCotacao(),
                          settings:
                              const RouteSettings(name: '/historico_cotacao'),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
