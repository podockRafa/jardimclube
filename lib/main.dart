import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

// Importando as telas necessárias
import 'telas/tela_login.dart'; // Mantemos importado caso precise referenciar
import 'telas/roteador_telas.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'telas/tela_landing.dart'; // <--- Importante estar aqui

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MeuCondominioApp());
}

class MeuCondominioApp extends StatelessWidget {
  const MeuCondominioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jardim Clube',
      debugShowCheckedModeBanner: false,
      
      // --- SEU TEMA VISUAL ---
      theme: ThemeData(
        primaryColor: const Color(0xFF1B4D3E),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4D3E)),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
      ),

      // --- CONFIGURAÇÃO DE IDIOMA ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Define Português Brasil
      ],

      // --- O NOVO DIRECIONAMENTO INTELIGENTE ---
      home: StreamBuilder<User?>(
        // Fica ouvindo: O usuário está logado ou deslogado?
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          // Se estiver carregando (ex: verificando login salvo)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // CASO 1: Se tiver usuário logado -> Manda para o Sistema (Roteador)
          // Assim o morador não precisa ver a Landing Page toda vez que abrir o app
          if (snapshot.hasData && snapshot.data != null) {
            return const RoteadorTelas();
          }

          // CASO 2: Se NÃO tiver usuário logado -> Manda para a Landing Page (Vitrine)
          // Antes estava: return const TelaLogin();
          return const TelaLandingPage(); 
        },
      ),
    );
  }
}