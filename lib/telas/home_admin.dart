import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ==========================================
// TELA PRINCIPAL (MENU)
// ==========================================
class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Síndico"),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _cardMenu(
            icon: Icons.campaign,
            color: Colors.orange,
            label: "Gerenciar\nAvisos",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminAvisos())),
          ),
          _cardMenu(
            icon: Icons.event_available, // Ícone de agenda/reserva
            color: Colors.purple,
            label: "Gerenciar\nReservas",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminReservas())),
          ),
          _cardMenu(
            icon: Icons.build_circle,
            color: Colors.redAccent,
            label: "Gerenciar\nOcorrências",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminOcorrencias())),
          ),
          _cardMenu(
            icon: Icons.storefront,
            color: Colors.blue,
            label: "Gerenciar\nClassificados",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminClassificados())),
          ),
          _cardMenu(
            icon: Icons.feedback,
            color: Colors.teal,
            label: "Sugestões &\nReclamações",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminSugestoes())),
          ),
        ],
      ),
    );
  }

  Widget _cardMenu({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const[BoxShadow(color: Colors.black12, blurRadius: 6, offset:  Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 16),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. TELA DE AVISOS (COM BOTÃO FLUTUANTE)
// ==========================================
class TelaAdminAvisos extends StatefulWidget {
  const TelaAdminAvisos({super.key});

  @override
  State<TelaAdminAvisos> createState() => _TelaAdminAvisosState();
}

class _TelaAdminAvisosState extends State<TelaAdminAvisos> {
  // Movemos os controladores para dentro do Dialog ou mantemos aqui se preferir limpar a cada abertura
  final _tituloCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController();
  
  String _alcance = 'TODOS';
  String _blocoAlvo = '1';

  // Função para abrir o formulário
  void _abrirFormularioPublicacao() {
    // Reseta os campos
    _tituloCtrl.clear();
    _msgCtrl.clear();
    _unidadeCtrl.clear();
    setState(() {
      _alcance = 'TODOS';
      _blocoAlvo = '1';
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Necessário para o Dropdown funcionar dentro do Dialog
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Novo Comunicado"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _alcance,
                      decoration: const InputDecoration(labelText: "Quem deve ver?", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'TODOS', child: Text("Todos os Moradores")),
                        DropdownMenuItem(value: 'BLOCO', child: Text("Apenas um Bloco")),
                        DropdownMenuItem(value: 'UNIDADE', child: Text("Apenas um Apto")),
                      ],
                      onChanged: (v) => setStateDialog(() => _alcance = v!),
                    ),
                    const SizedBox(height: 10),
                    
                    // Seletores Condicionais
                    if (_alcance != 'TODOS')
                      Row(
                        children: [
                          const Text("Bloco: "),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: _blocoAlvo,
                            items: ['1','2','3','4','5','6','7','8','9'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (v) => setStateDialog(() => _blocoAlvo = v!),
                          ),
                        ],
                      ),
                    
                    if (_alcance == 'UNIDADE')
                      TextField(
                        controller: _unidadeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Número do Apto (Ex: 201)", border: OutlineInputBorder()),
                      ),
                    
                    const SizedBox(height: 15),
                    TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: "Título", border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: _msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Mensagem", border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () {
                    _publicarAviso();
                    Navigator.pop(context);
                  }, 
                  child: const Text("PUBLICAR")
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _publicarAviso() async {
    if (_tituloCtrl.text.isEmpty || _msgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha título e mensagem")));
      return;
    }
    await FirebaseFirestore.instance.collection('avisos').add({
      'titulo': _tituloCtrl.text,
      'mensagem': _msgCtrl.text,
      'alcance_tipo': _alcance,
      'alcance_bloco': _alcance != 'TODOS' ? _blocoAlvo : null,
      'alcance_unidade': _alcance == 'UNIDADE' ? _unidadeCtrl.text : null,
      'data_postagem': FieldValue.serverTimestamp(),
      'autor': 'Administração',
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aviso publicado!")));
  }

  void _excluirAviso(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Aviso?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('avisos').doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestão de Avisos"), backgroundColor: const Color(0xFF1B4D3E), // Verde Padronizado
        foregroundColor: Colors.white,
      ),
      
      // BOTÃO FLUTUANTE (FAB)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("NOVO COMUNICADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _abrirFormularioPublicacao,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('avisos').orderBy('data_postagem', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey),
                  Text("Nenhum aviso ativo.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var dados = doc.data() as Map<String, dynamic>;
              
              // Formata o texto do alcance
              String alcanceTexto = "Todos";
              if (dados['alcance_tipo'] == 'BLOCO') alcanceTexto = "Bloco ${dados['alcance_bloco']}";
              if (dados['alcance_tipo'] == 'UNIDADE') alcanceTexto = "Bloco ${dados['alcance_bloco']} - Apto ${dados['alcance_unidade']}";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withValues(alpha:0.2),
                    child: const Icon(Icons.campaign, color: Colors.orange),
                  ),
                  title: Text(dados['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dados['mensagem'] ?? ''),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: Text("Alcance: $alcanceTexto", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                      )
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _excluirAviso(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. TELA DE OCORRÊNCIAS (COM ABAS)
// ==========================================
class TelaAdminOcorrencias extends StatelessWidget {
  const TelaAdminOcorrencias({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // <--- 3 ABAS AGORA
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ocorrências"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "NOVAS", icon: Icon(Icons.new_releases)),
              Tab(text: "ANDAMENTO", icon: Icon(Icons.build)),
              Tab(text: "CONCLUÍDAS", icon: Icon(Icons.check_circle)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _listaOcorrencias(context, 'ABERTO'),
            _listaOcorrencias(context, 'EM_ANDAMENTO'),
            _listaOcorrencias(context, 'CONCLUIDO'), // Inclui CANCELADO via filtro se quiser
          ],
        ),
      ),
    );
  }

  Widget _listaOcorrencias(BuildContext context, String filtroStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ocorrencias').orderBy('data_abertura', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Filtragem Manual para garantir flexibilidade
        var lista = snapshot.data!.docs.where((doc) {
          String statusDb = doc['status'] ?? 'ABERTO';
          if (filtroStatus == 'CONCLUIDO') {
            return statusDb == 'CONCLUIDO' || statusDb == 'CANCELADO';
          }
          return statusDb == filtroStatus;
        }).toList();

        if (lista.isEmpty) return Center(child: Text("Nenhuma ocorrência em: $filtroStatus"));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            var doc = lista[index];
            var dados = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: _iconeStatus(dados['status']),
                title: Text(dados['titulo'] ?? ''),
                subtitle: Text("Por: ${dados['autor_nome']}\nLocal: ${dados['local'] ?? 'Geral'}\n${dados['descricao']}"),
                isThreeLine: true,
                onTap: () => _mostrarOpcoes(context, doc.id, dados['status']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _iconeStatus(String? status) {
    if (status == 'ABERTO') return const Icon(Icons.error_outline, color: Colors.red);
    if (status == 'EM_ANDAMENTO') return const Icon(Icons.timelapse, color: Colors.blue);
    return const Icon(Icons.check_circle, color: Colors.green);
  }

  void _mostrarOpcoes(BuildContext context, String docId, String atual) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.blue), 
            title: const Text("Marcar Em Andamento"), 
            onTap: () { _atualizar(docId, 'EM_ANDAMENTO'); Navigator.pop(ctx); }
          ),
          ListTile(
            leading: const Icon(Icons.check, color: Colors.green), 
            title: const Text("Concluir"), 
            onTap: () { _atualizar(docId, 'CONCLUIDO'); Navigator.pop(ctx); }
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red), 
            title: const Text("Cancelar"), 
            onTap: () { _atualizar(docId, 'CANCELADO'); Navigator.pop(ctx); }
          ),
        ],
      ),
    );
  }

  void _atualizar(String docId, String status) {
    FirebaseFirestore.instance.collection('ocorrencias').doc(docId).update({'status': status});
  }
}

// ==========================================
// 3. TELA DE CLASSIFICADOS (Moderação com Abas)
// ==========================================
class TelaAdminClassificados extends StatelessWidget {
  const TelaAdminClassificados({super.key});

  void _aprovar(String docId) {
    FirebaseFirestore.instance.collection('classificados').doc(docId).update({'status': 'ATIVO'});
  }

  void _reprovar(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reprovar Anúncio?"),
        content: const Text("O anúncio será excluído permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection('classificados').doc(docId).delete();
              Navigator.pop(ctx);
            }, 
            child: const Text("EXCLUIR")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Moderar Classificados"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "PENDENTES (Aprovar)", icon: Icon(Icons.gavel)),
              Tab(text: "ATIVOS (No Ar)", icon: Icon(Icons.check_circle)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: PENDENTES (Precisa Aprovar)
            _listaAnuncios(context, status: 'PENDENTE'),
            
            // ABA 2: ATIVOS (Já estão visíveis)
            _listaAnuncios(context, status: 'ATIVO'),
          ],
        ),
      ),
    );
  }

  Widget _listaAnuncios(BuildContext context, {required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classificados')
          .where('status', isEqualTo: status)
          .orderBy('data_publicacao', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erro de Índice (Verificar Console)"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Nenhum anúncio $status."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var dados = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    title: Text(dados['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${dados['tipo']} - Por: ${dados['autor_nome']}\n${dados['descricao']}"),
                    trailing: Text(
                      dados['valor_ou_contato'] ?? '',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  // BOTÕES DE AÇÃO
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      // Se for PENDENTE, mostra botão de Aprovar
                      if (status == 'PENDENTE')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check),
                          label: const Text("APROVAR"),
                          onPressed: () => _aprovar(doc.id),
                        ),
                      
                      // Botão de Excluir serve para ambos os casos
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(status == 'PENDENTE' ? "REJEITAR" : "EXCLUIR", style: const TextStyle(color: Colors.red)),
                        onPressed: () => _reprovar(context, doc.id),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 4. TELA DE SUGESTÕES (Resposta do Síndico)
// ==========================================
class TelaAdminSugestoes extends StatelessWidget {
  const TelaAdminSugestoes({super.key});

  void _responder(BuildContext context, String docId, String atualDescricao) {
    final respostaCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Responder Morador"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text("Morador disse:\n$atualDescricao", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: respostaCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Sua Resposta", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('sugestoes').doc(docId).update({
                'resposta_admin': respostaCtrl.text,
                'status': 'RESPONDIDO',
                'data_resposta': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
            },
            child: const Text("ENVIAR RESPOSTA"),
          )
        ],
      ),
    );
  }

  void _marcarLido(String docId) {
    FirebaseFirestore.instance.collection('sugestoes').doc(docId).update({'status': 'LIDO'});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mensagens dos moradores"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "PENDENTES"),
              Tab(text: "RESPONDIDAS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _listaSugestoes(pendentes: true),
            _listaSugestoes(pendentes: false),
          ],
        ),
      ),
    );
  }

  Widget _listaSugestoes({required bool pendentes}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sugestoes').orderBy('data_envio', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Filtra na memória para simplificar (já que status pode variar entre PENDENTE, LIDO, RESPONDIDO)
        var lista = snapshot.data!.docs.where((doc) {
          String st = doc['status'] ?? 'PENDENTE';
          bool foiRespondido = st == 'RESPONDIDO' || st == 'CONCLUIDO';
          return pendentes ? !foiRespondido : foiRespondido;
        }).toList();

        if (lista.isEmpty) return const Center(child: Text("Nenhum registro aqui."));

        return ListView.builder(
          itemCount: lista.length,
          itemBuilder: (context, index) {
            var doc = lista[index];
            var dados = doc.data() as Map<String, dynamic>;
            bool ehSugestao = dados['tipo'] == 'SUGESTAO';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ExpansionTile(
                leading: Icon(
                  ehSugestao ? Icons.lightbulb : Icons.warning,
                  color: ehSugestao ? Colors.teal : Colors.red,
                ),
                title: Text(dados['titulo'] ?? ''),
                subtitle: Text("${dados['autor_nome']} - ${dados['unidade']}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("Mensagem Completa:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(dados['descricao'] ?? ''),
                        const SizedBox(height: 10),
                        
                        // SE JÁ FOI RESPONDIDO
                        if (dados['resposta_admin'] != null)
                           Container(
                             padding: const EdgeInsets.all(8),
                             color: Colors.teal[50],
                             child: Text("Sua resposta: ${dados['resposta_admin']}", style: TextStyle(color: Colors.teal[900])),
                           ),

                        const SizedBox(height: 10),
                        
                        // AÇÕES (Se estiver na aba pendentes)
                        if (pendentes)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _marcarLido(doc.id), 
                                child: const Text("MARCAR COMO LIDO")
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.reply),
                                label: const Text("RESPONDER"),
                                onPressed: () => _responder(context, doc.id, dados['descricao']),
                              ),
                            ],
                          )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
// ==========================================
// 5. TELA DE GESTÃO DE RESERVAS
// ==========================================
class TelaAdminReservas extends StatelessWidget {
  const TelaAdminReservas({super.key});

  // Função para Aprovar
  void _aprovar(String docId) {
    FirebaseFirestore.instance.collection('reservas').doc(docId).update({
      'status': 'APROVADO',
      'resposta_admin': 'Sua reserva foi confirmada!',
    });
  }

  // Função para Rejeitar (com motivo)
  void _rejeitar(BuildContext context, String docId) {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Rejeitar Reserva"),
        content: TextField(
          controller: motivoCtrl,
          decoration: const InputDecoration(labelText: "Motivo (Ex: Manutenção)", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection('reservas').doc(docId).update({
                'status': 'REJEITADO',
                'resposta_admin': motivoCtrl.text.isEmpty ? 'Data indisponível.' : motivoCtrl.text,
              });
              Navigator.pop(ctx);
            },
            child: const Text("REJEITAR"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestão de Reservas"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "PENDENTES", icon: Icon(Icons.access_time)),
              Tab(text: "HISTÓRICO", icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: Pendentes (Precisa de ação)
            _listaReservas(context, apenasPendentes: true),
            
            // ABA 2: Histórico (Aprovados e Rejeitados)
            _listaReservas(context, apenasPendentes: false),
          ],
        ),
      ),
    );
  }

  Widget _listaReservas(BuildContext context, {required bool apenasPendentes}) {
    return StreamBuilder<QuerySnapshot>(
      // Ordena por data da reserva (mais longe primeiro para planejamento, ou mais perto?)
      // Vamos colocar descending: false para ver as próximas datas primeiro.
      stream: FirebaseFirestore.instance.collection('reservas').orderBy('data_reserva_timestamp').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var lista = snapshot.data!.docs.where((doc) {
          String status = doc['status'] ?? 'PENDENTE';
          return apenasPendentes ? status == 'PENDENTE' : status != 'PENDENTE';
        }).toList();

        if (lista.isEmpty) {
          return Center(
            child: Text(
              apenasPendentes ? "Nenhuma solicitação pendente." : "Histórico vazio.",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            var doc = lista[index];
            var dados = doc.data() as Map<String, dynamic>;
            
            String dataTexto = dados['data_reserva'] ?? '?'; // Ex: 25/10/2026
            String area = dados['local'] ?? 'Área Comum';
            String morador = dados['autor_nome'] ?? 'Morador';
            String unidade = dados['unidade'] ?? '?';
            String status = dados['status'] ?? 'PENDENTE';

            Color corStatus = Colors.grey;
            if (status == 'APROVADO') corStatus = Colors.green;
            if (status == 'REJEITADO') corStatus = Colors.red;
            if (status == 'PENDENTE') corStatus = Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: corStatus.withValues(alpha:0.2),
                  child: Icon(Icons.event, color: corStatus),
                ),
                title: Text("$area - $dataTexto"),
                subtitle: Text("Solicitado por: $morador\nUnidade: $unidade"),
                trailing: apenasPendentes 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          tooltip: "Aprovar",
                          onPressed: () => _aprovar(doc.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                          tooltip: "Rejeitar",
                          onPressed: () => _rejeitar(context, doc.id),
                        ),
                      ],
                    )
                  : Chip(
                      label: Text(status),
                      backgroundColor: corStatus.withValues(alpha:0.2),
                      labelStyle: TextStyle(color: corStatus, fontWeight: FontWeight.bold),
                    ),
              ),
            );
          },
        );
      },
    );
  }
}