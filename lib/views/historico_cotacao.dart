import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

import 'conversor_page.dart';
import 'historico_page.dart';

class HistoricoCotacao extends StatefulWidget {
  const HistoricoCotacao({Key? key}) : super(key: key);

  @override
  State<HistoricoCotacao> createState() => _HistoricoCotacaoState();
}

class _HistoricoCotacaoState extends State<HistoricoCotacao> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedCurrency = 'USD';
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'Dólar Americano', 'image': 'assets/usa.png'},
    {'code': 'AUD', 'name': 'Dólar Australiano', 'image': 'assets/aud.jpeg'},
    {'code': 'ARS', 'name': 'Pesos Argentinos', 'image': 'assets/argentina.jpeg'}
  ];

  // Dados fictícios para o gráfico de linhas (valores do dólar)
  List<double> _dolarValues = [];

  @override
  void initState() {
    super.initState();
    _fetchAndSetCurrencyValues();
  }

  Future<void> _fetchAndSetCurrencyValues() async {
    // Exemplo para buscar valores do dólar
    List<double> values = await fetchCurrencyValues('USD');
    setState(() {
      _dolarValues = values;
    });
  }

  Future<List<double>> fetchCurrencyValues(String currencyCode) async {
    String apiUrl = 'https://api.exchangerate-api.com/v4/latest/$currencyCode';
    List<double> values = [];

    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        // Parse a resposta JSON
        var data = jsonDecode(response.body);
        // Extrair os valores das cotações
        var rates = data['rates'];
        rates.forEach((key, value) {
          values.add(value.toDouble());
        });
      } else {
        throw Exception('Failed to load currency values');
      }
    } catch (e) {
      print('Erro na requisição: $e');
    }

    return values;
  }

  Future<void> _logout(BuildContext context) async {
    // Lógica de logout aqui, se necessário
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
              'Histórico de Cotação',
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
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Container(
                          height: 300.h, // Altura definida para o gráfico
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _dolarValues
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return FlSpot(entry.key.toDouble(), entry.value);
                                  })
                                      .toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        height: 100.h,
                        width: 330.w,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _dolarValues.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_currencies[index]['name']}',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  SizedBox(height: 5.h),
                                  Text(
                                    '${_dolarValues[index].toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 100.h,
                  left: 60.w,
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 40.r,
                      backgroundImage: AssetImage("assets/br.png"),
                    ),
                  ),
                ),
                Positioned(
                  top: 100.h,
                  left: 160.w,
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/iconTransicao.png',
                        fit: BoxFit.cover, // Ajuste o fit conforme necessário
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 90.h,
                  left: 260.w,
                  child: Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        icon: Icon(Icons.arrow_downward, color: Colors.white),
                        iconSize: 24,
                        elevation: 16,
                        dropdownColor: Colors.white,
                        onChanged: (String? newValue) async {
                          setState(() {
                            _selectedCurrency = newValue!;
                            _fetchAndSetCurrencyValues(); // Atualiza os dados ao mudar a moeda
                          });
                        },
                        items: _currencies.map((Map<String, String> currency) {
                          return DropdownMenuItem<String>(
                            value: currency['code'],
                            child: Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Image.asset(
                                    currency['image']!,
                                    width: 30.w,
                                    height: 30.h,
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
              ],
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  title: Text('Conversor'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/') {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConversorPage(),
                          settings: RouteSettings(name: '/'),
                        ),
                            (Route<dynamic> route) => false,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  title: Text('Histórico'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/historico') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoricoPage(),
                          settings: RouteSettings(name: '/historico'),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  title: Text('Histórico de Cotação'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/historico_cotacao') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoricoCotacao(),
                          settings: RouteSettings(name: '/historico_cotacao'),
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
