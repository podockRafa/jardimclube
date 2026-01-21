import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaSugestoes extends StatefulWidget {
  const TelaSugestoes({super.key});

  @override
  State<TelaSugestoes> createState() => _TelaSugestoesState();
}

class _TelaSugestoesState extends State<TelaSugestoes> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _tipoSelecionado = 'SUGESTAO'; // ou RECLAMACAO
  bool _enviando = false;

  // --- FUNÇÃO DE ENVIAR ---
  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      // Pega dados do usuário para identificar quem mandou
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String nome = userDoc.data()?['nome'] ?? 'Anônimo';
      String unidade = userDoc.data()?['unidade_vinculada'] ?? '?';
      String bloco = userDoc.data()?['bloco'] ?? '?';

      await FirebaseFirestore.instance.collection('sugestoes').add({
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'tipo': _tipoSelecionado, // SUGESTAO ou RECLAMACAO
        'autor_uid': user.uid,
        'autor_nome': nome,
        'unidade': "$bloco-$unidade",
        'data_envio': FieldValue.serverTimestamp(),
        'status': 'PENDENTE', // Status inicial
        'resposta_admin': null, // Campo para o síndico responder depois
      });

      if (!mounted) return;

      // Limpa tudo e avisa
      _tituloController.clear();
      _descricaoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enviado com sucesso! Acompanhe na aba Histórico."), backgroundColor: Colors.green),
      );
      
      // (Opcional) Volta para a aba de histórico se quiser, mas aqui só limpei.

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Fale com o Síndico"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "NOVA MENSAGEM", icon: Icon(Icons.edit_note)),
              Tab(text: "MEUS REGISTROS", icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- ABA 1: FORMULÁRIO ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "O que você deseja fazer?",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Sugestão", style: TextStyle(fontSize: 14)),
                            value: 'SUGESTAO',
                            groupValue: _tipoSelecionado,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => setState(() => _tipoSelecionado = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Reclamação", style: TextStyle(fontSize: 14)),
                            value: 'RECLAMACAO',
                            groupValue: _tipoSelecionado,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => setState(() => _tipoSelecionado = v!),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: "Assunto (Resumo)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v!.isEmpty ? "Digite um assunto" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: "Descreva detalhadamente...",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true, // Texto começa no topo da caixa
                      ),
                      validator: (v) => v!.isEmpty ? "Escreva sua mensagem" : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoSelecionado == 'SUGESTAO' ? Colors.teal : Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _enviando ? null : _enviarFormulario,
                        child: _enviando 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("ENVIAR ${_tipoSelecionado}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Sua mensagem será enviada diretamente para a administração.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // --- ABA 2: HISTÓRICO ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sugestoes')
                  .where('autor_uid', isEqualTo: user!.uid)
                  .orderBy('data_envio', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Dica para erro de índice
                  return const Center(child: Text("Erro ao carregar (Verificar Índice no Firebase)"));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_chat_read_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Você ainda não enviou nada.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var dados = docs[index].data() as Map<String, dynamic>;
                    
                    String tipo = dados['tipo'] ?? 'SUGESTAO';
                    String status = dados['status'] ?? 'PENDENTE';
                    String? resposta = dados['resposta_admin']; // Se o síndico respondeu
                    
                    Timestamp? ts = dados['data_envio'];
                    String dataFmt = ts != null 
                        ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate()) 
                        : '--/--';

                    // Cores baseadas no status
                    Color corStatus = Colors.grey;
                    if (status == 'PENDENTE') corStatus = Colors.orange;
                    if (status == 'LIDO') corStatus = Colors.blue;
                    if (status == 'RESPONDIDO' || status == 'CONCLUIDO') corStatus = Colors.green;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(tipo),
                                  backgroundColor: tipo == 'SUGESTAO' ? Colors.teal[50] : Colors.red[50],
                                  labelStyle: TextStyle(
                                    color: tipo == 'SUGESTAO' ? Colors.teal : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: corStatus,
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text(
                                    status, 
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(dados['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(dados['descricao'] ?? '', style: TextStyle(color: Colors.grey[800])),
                            const SizedBox(height: 8),
                            Text("Enviado em: $dataFmt", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            
                            // SE TIVER RESPOSTA DO SÍNDICO, MOSTRA AQUI
                            if (resposta != null && resposta.isNotEmpty) ...[
                              const Divider(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFF1B4D3E)),
                                        SizedBox(width: 5),
                                        Text("Resposta da Administração:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B4D3E))),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(resposta, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}