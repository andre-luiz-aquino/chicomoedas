import 'dart:developer';

import 'package:chicomoedas/conversao/currency_converter.dart';
import 'package:chicomoedas/dataBase/historico_db.dart';
import 'package:chicomoedas/dataBase/usuario_db.dart';
import 'package:chicomoedas/dto/usuario_dto.dart';
import 'package:chicomoedas/format/input_format.dart';
import 'package:chicomoedas/views/historico_page.dart';
import 'package:chicomoedas/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class ConversorPage extends StatefulWidget {
  const ConversorPage({super.key});

  @override
  State<ConversorPage> createState() => _ConversorPageState();
}

class _ConversorPageState extends State<ConversorPage> {
  final dbHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _valueController = TextEditingController();
  double? _exchangeRate;
  double? _convertedValue;

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

  @override
  void initState() {
    super.initState();
    _buscarTaxaCambio();
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
    } catch (error) {
      log('Falha ao buscar taxa de câmbio: $error');
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final dbHelper = DatabaseUser();
    Usuario? usuarioLogado = await dbHelper.getLogado();

    if (usuarioLogado != null) {
      await dbHelper.updateLogado(usuarioLogado.nomeUsuario, false);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _calcularConversao() {
    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (value != null && _exchangeRate != null) {
      setState(() {
        _convertedValue = value * _exchangeRate!;
      });

      dbHelper.insertHistorico(value, _selectedCurrency);
    }
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
                        onPressed: () {},
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
                          await _buscarTaxaCambio();
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
