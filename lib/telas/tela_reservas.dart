import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'tela_minhas_reservas.dart';

class TelaReservas extends StatefulWidget {
  const TelaReservas({super.key});

  @override
  State<TelaReservas> createState() => _TelaReservasState();
}

class _TelaReservasState extends State<TelaReservas> {
  DateTime? _dataSelecionada;
  String _localSelecionado = 'Churrasqueira 1';
  bool _aceitouContrato = false; 
  bool _carregando = false;
  
  // Lista para guardar os dias que não podem ser escolhidos
  List<DateTime> _diasBloqueados = [];

  final List<String> _locais = ['Churrasqueira 1', 'Churrasqueira 2', 'Salão de Festas'];

  @override
  void initState() {
    super.initState();
    // Carrega a ocupação assim que a tela abre
    _carregarDiasOcupados();
  }

  // --- FUNÇÃO NOVO: Busca dias ocupados para bloquear no calendário ---
  Future<void> _carregarDiasOcupados() async {
    setState(() => _carregando = true);
    
    // Busca todas as reservas APROVADAS ou PENDENTES do local selecionado
    final query = await FirebaseFirestore.instance
        .collection('reservas')
        .where('local', isEqualTo: _localSelecionado)
        .where('status', whereIn: ['APROVADO', 'PENDENTE']) 
        .get();

    List<DateTime> tempBloqueados = [];

    for (var doc in query.docs) {
      String dataString = doc['data_reserva']; // Formato dd/MM/yyyy
      try {
        // Converte string para DateTime
        DateTime data = DateFormat('dd/MM/yyyy').parse(dataString);
        tempBloqueados.add(data);
      } catch (e) {
        print("Erro ao ler data: $e");
      }
    }

    setState(() {
      _diasBloqueados = tempBloqueados;
      _carregando = false;
    });
  }

  // Função auxiliar para verificar se um dia específico está na lista de bloqueados
  bool _diaEstaLivre(DateTime dia) {
    for (DateTime bloqueado in _diasBloqueados) {
      if (dia.year == bloqueado.year && 
          dia.month == bloqueado.month && 
          dia.day == bloqueado.day) {
        return false; // Está ocupado, bloqueia!
      }
    }
    return true; // Está livre
  }

  Future<void> _solicitarReserva() async {
    if (_dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione uma data!")));
      return;
    }

    if (_localSelecionado == 'Salão de Festas' && !_aceitouContrato) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aceite os termos do contrato.")));
      return;
    }

    setState(() => _carregando = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('reservas').add({
        'autor_uid': user.uid,
        'autor_nome': userData['nome'],
        'autor_unidade': "Bloco ${userData['bloco']} - Apt ${userData['unidade']}",
        'local': _localSelecionado,
        'data_reserva': DateFormat('dd/MM/yyyy').format(_dataSelecionada!),
        'data_reserva_timestamp': _dataSelecionada,
        'data_criacao': FieldValue.serverTimestamp(),
        'status': 'PENDENTE', 
        'resposta_admin': '',
      });

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TelaMinhasReservas()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitação enviada!"), backgroundColor: Colors.orange));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Reserva"), 
        backgroundColor: const Color(0xFF1B4D3E), 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaMinhasReservas())),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("1. Escolha o Espaço", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _localSelecionado,
              items: _locais.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) {
                setState(() {
                  _localSelecionado = v!;
                  _aceitouContrato = false;
                  _dataSelecionada = null; // Limpa a data ao trocar de local
                });
                // Recarrega os dias bloqueados para o novo local
                _carregarDiasOcupados();
              },
            ),
            
            const SizedBox(height: 20),
            const Text("2. Escolha a Data", style: TextStyle(fontWeight: FontWeight.bold)),
            if (_carregando) 
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Atualizando agenda...", style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(_dataSelecionada == null 
                  ? "VER DISPONIBILIDADE" 
                  : DateFormat('dd/MM/yyyy').format(_dataSelecionada!)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 1,
                side: const BorderSide(color: Colors.grey)
              ),
              onPressed: () async {
                // Abre o calendário com regras de bloqueio
                DateTime? picked = await showDatePicker(
                  context: context,
                  locale: const Locale('pt', 'BR'),
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  
                  // A MÁGICA ACONTECE AQUI:
                  // Se retornar false, o dia fica cinza e não dá pra clicar
                  selectableDayPredicate: (DateTime dia) {
                    return _diaEstaLivre(dia);
                  },
                );

                if (picked != null) {
                  setState(() => _dataSelecionada = picked);
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("* Dias em cinza já estão ocupados ou reservados.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            if (_localSelecionado == 'Salão de Festas') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                child: Column(
                  children: [
                    const Text("Termos de Uso do Salão", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 5),
                    const Text("Ao reservar, você concorda em pagar a taxa e assinar o contrato na administração."),
                    CheckboxListTile(
                      title: const Text("Li e concordo."),
                      value: _aceitouContrato,
                      activeColor: const Color(0xFF1B4D3E),
                      onChanged: (v) => setState(() => _aceitouContrato = v!),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
            
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _carregando ? null : _solicitarReserva,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
                child: _carregando ? const CircularProgressIndicator(color: Colors.white) : const Text("ENVIAR SOLICITAÇÃO"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}