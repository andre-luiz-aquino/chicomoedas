import 'dart:convert';

import 'package:chicomoedas/dataBase/usuario_db.dart';
import 'package:chicomoedas/dto/usuario_dto.dart';
import 'package:chicomoedas/views/conversor_page.dart';
import 'package:chicomoedas/views/historico_page.dart';
import 'package:chicomoedas/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

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

  List<CotacaoData> _dolarValues = [];

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
    List<CotacaoData> values = await fetchCurrencyValues();
    setState(() {
      _dolarValues = values;
    });
  }

  Future<List<CotacaoData>> fetchCurrencyValues() async {
    String apiUrl = 'http://172.210.138.201:8000/items';
    List<CotacaoData> values = [];

    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as List<dynamic>;
        values = data.map((item) {
          double value = double.tryParse(item['valor'] ?? '0.0') ?? 0.0;
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

  List<CartesianSeries<CotacaoData, DateTime>> _createChartData() {
    return [
      LineSeries<CotacaoData, DateTime>(
        dataSource: _dolarValues,
        xValueMapper: (CotacaoData data, _) => data.data,
        yValueMapper: (CotacaoData data, _) => data.valor,
        color: Colors.blue,
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
                        child: SizedBox(
                          height: 300.h, // Altura definida para o gráfico
                          child: SfCartesianChart(
                            primaryXAxis: DateTimeAxis(),
                            series: _createChartData(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
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
                    if (ModalRoute.of(context)?.settings.name != '/historico_cotacao') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoricoCotacao(),
                          settings: const RouteSettings(name: '/historico_cotacao'),
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
