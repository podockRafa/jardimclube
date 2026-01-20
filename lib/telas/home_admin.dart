import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_lista_chamados.dart'; 
import 'tela_admin_usuarios.dart'; // <--- IMPORT NOVO
import 'tela_admin_anuncios.dart'; // <--- IMPORT NOVO
import 'tela_criar_aviso.dart';
import 'tela_admin_reservas.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Painel do Síndico", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B4D3E),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestão do Condomínio",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
            ),
            const Text("Selecione uma ferramenta administrativa:", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  
                  // 1. OCORRÊNCIAS (Já funcionava)
                  _botaoCard(
                    icone: Icons.assignment_late_outlined,
                    titulo: "Ocorrências", 
                    subtitulo: "Chamados em aberto",
                    corIcone: Colors.orange,
                    acao: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaListaChamados()));
                    }
                  ),

                  // 2. AVISOS (ATUALIZADO)
                  _botaoCard(
                    icone: Icons.campaign_outlined,
                    titulo: "Novo Aviso", 
                    subtitulo: "Enviar para todos",
                    corIcone: Colors.blue,
                    acao: () {
                      // Leva para a tela de criar aviso
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaCriarAviso()));
                    }
                  ),

                  // 3. APROVAÇÕES (AGORA FUNCIONA!) ✅
                  _botaoCard(
                    icone: Icons.how_to_reg_outlined, 
                    titulo: "Aprovar\nCadastros", 
                    subtitulo: "Novos moradores",
                    corIcone: Colors.green,
                    acao: () {
                       // Navega para a tela de aprovar usuários
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminUsuarios()));
                    }
                  ),

                  // 4. CLASSIFICADOS (AGORA FUNCIONA!) ✅
                  _botaoCard(
                    icone: Icons.storefront_outlined, 
                    titulo: "Moderar\nAnúncios", 
                    subtitulo: "Vendas e Serviços",
                    corIcone: Colors.purple,
                    acao: () {
                       // Navega para a tela de moderar anúncios
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminAnuncios()));
                    }
                  ),

                  // 5. ENCOMENDAS (Pendente)
                  _botaoCard(
                    icone: Icons.local_shipping_outlined, 
                    titulo: "Histórico\nEncomendas", 
                    subtitulo: "Auditoria de entregas",
                    corIcone: Colors.brown,
                    acao: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Em breve: Ver histórico")));
                    }
                  ),
                  _botaoCard(
                    icone: Icons.calendar_month, 
                    titulo: "Gerenciar\nReservas", 
                    subtitulo: "Salão e Churrasqueira",
                    corIcone: Colors.blueGrey,
                    acao: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAdminReservas())),
                  ),

                  // 6. DADOS (Pendente)
                  _botaoCard(
                    icone: Icons.folder_shared_outlined, 
                    titulo: "Banco de\nDados", 
                    subtitulo: "Moradores e Veículos",
                    corIcone: Colors.blueGrey,
                    acao: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Em breve: Lista de unidades")));
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoCard({required IconData icone, required String titulo, required String subtitulo, required Color corIcone, required VoidCallback acao}) {
    return InkWell(
      onTap: acao,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: corIcone.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icone, size: 28, color: corIcone),
              ),
              const Spacer(),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}