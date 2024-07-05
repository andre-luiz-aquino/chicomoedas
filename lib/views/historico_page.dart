import 'package:chicomoedas/dataBase/historico_db.dart';
import 'package:chicomoedas/dataBase/usuario_db.dart';
import 'package:chicomoedas/views/conversor_page.dart';
import 'package:chicomoedas/views/historico_cotacao.dart';
import 'package:chicomoedas/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../dto/usuario_dto.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  _HistoricoPageState createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Map<String, dynamic>>> _historicoFuture;
  String _nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _loadHistorico();
    _loadUsuario();
  }

  Future<void> _loadHistorico() async {
    setState(() {
      _historicoFuture = DatabaseHelper().getHistorico();
    });
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

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper().deleteHistorico(id);
    _loadHistorico();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => SafeArea(
        child: Scaffold(
          key: _scaffoldKey,
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
              'Histórico de Conversões',
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
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _historicoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar histórico'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Nenhum histórico disponível'));
              } else {
                final historico = snapshot.data!;
                return ListView.builder(
                  itemCount: historico.length,
                  itemBuilder: (context, index) {
                    final item = historico[index];
                    final data = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(item['data']));
                    return Dismissible(
                      key: Key(item['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteItem(item['id']);
                      },
                      child: ListTile(
                        title:
                            Text('${item['valor']} BRL para ${item['moeda']}'),
                        subtitle: Text(data),
                      ),
                    );
                  },
                );
              }
            },
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
