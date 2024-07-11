import 'dart:convert';

import 'package:chicomoedas/dataBase/usuario_db.dart';
import 'package:chicomoedas/dto/usuario_dto.dart';
import 'package:chicomoedas/views/conversor_page.dart';
import 'package:chicomoedas/views/historico_page.dart';
import 'package:chicomoedas/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Moeda {
  final String nome;
  final String imagem;

  Moeda(this.nome, this.imagem);
}

class HistoricoCotacao extends StatefulWidget {
  const HistoricoCotacao({Key? key}) : super(key: key);

  @override
  State<HistoricoCotacao> createState() => _HistoricoCotacaoState();
}

class CotacaoData {
  final DateTime data;
  final double valor;

  CotacaoData(this.data, this.valor);
}

class _HistoricoCotacaoState extends State<HistoricoCotacao> {
  late Usuario usuarioLogado;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _nomeUsuario = '';
  Moeda _moedaSelecionada = moedas[0];
  static List<Moeda> moedas = [
    Moeda('Dólar', 'assets/usa.png'),
    Moeda('Libra', 'assets/libra.jpeg'),
    Moeda('Pesos', 'assets/argentina.jpeg'),
  ];

  List<CotacaoData> _dolarValues = [];
  List<CotacaoData> _euroValues = [];
  List<CotacaoData> _pesosValues = [];

  @override
  void initState() {
    super.initState();
    _loadUsuario();
    _fetchAndSetCurrencyValues();
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

  Future<void> _fetchAndSetCurrencyValues() async {
    List<CotacaoData> dolarValues =
        await fetchCurrencyValues('http://172.210.138.201:8000/items/dolar');
    List<CotacaoData> euroValues =
        await fetchCurrencyValues('http://172.210.138.201:8000/items/euro');
    List<CotacaoData> pesosValues =
        await fetchCurrencyValues('http://172.210.138.201:8000/items/peso');
    setState(() {
      _dolarValues = dolarValues;
      _euroValues = euroValues;
      _pesosValues = pesosValues;
    });
  }

  Future<List<CotacaoData>> fetchCurrencyValues(String apiUrl) async {
    List<CotacaoData> values = [];

    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as List<dynamic>;
        values = data.map((item) {
          double value = double.tryParse(item['maxima'] ?? '0.0') ?? 0.0;
          DateTime date = DateTime.parse(item['data']);
          return CotacaoData(date, value);
        }).toList();
      } else {
        throw Exception('Failed to load currency values');
      }
    } catch (e) {
      print('Erro na requisição: $e');
    }

    return values;
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

  List<CartesianSeries<CotacaoData, DateTime>> _createChartData(Moeda moeda) {
    List<CotacaoData> dataSource;
    Color color;

    switch (moeda.nome) {
      case 'Dólar':
        dataSource = _dolarValues;
        color = Colors.blue;
        break;
      case 'Libra':
        dataSource = _euroValues;
        color = Colors.red;
        break;
      case 'Pesos':
        dataSource = _pesosValues;
        color = Colors.green;
        break;
      default:
        dataSource = [];
        color = Colors.black;
        break;
    }

    return [
      LineSeries<CotacaoData, DateTime>(
        dataSource: dataSource,
        xValueMapper: (CotacaoData data, _) => data.data,
        yValueMapper: (CotacaoData data, _) => data.valor,
        color: color,
        name: moeda.nome,
      ),
    ];
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
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                                  width: 150.w,
                                  height: 60.h,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: DropdownButton<Moeda>(
                                    value: _moedaSelecionada,
                                    onChanged: (Moeda? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _moedaSelecionada = newValue;
                                        });
                                      }
                                    },
                                    items: moedas.map((Moeda moeda) {
                                      return DropdownMenuItem<Moeda>(
                                        value: moeda,
                                        child: Row(
                                          children: <Widget>[
                                            Image.asset(
                                              moeda.imagem,
                                              width: 50.sp,
                                              height: 50.sp,
                                            ),
                                            SizedBox(width: 10.w),
                                            Text(
                                              moeda.nome,
                                              style: TextStyle(fontSize: 20.sp),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 30.h,
                              ),
                              SizedBox(
                                height: 300.h,
                                child: SfCartesianChart(
                                  primaryXAxis: DateTimeAxis(),
                                  series: _createChartData(_moedaSelecionada),
                                ),
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
