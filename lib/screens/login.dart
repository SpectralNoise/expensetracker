import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '90043983853-68ntr6s5vm3kk8fhbs0n0j0pvb6uru5s.apps.googleusercontent.com',
  );
  final Function toggleTheme;
  final bool isDarkTheme;

  LoginScreen({Key? key, required this.toggleTheme, required this.isDarkTheme})
      : super(key: key);

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inicio de sesión cancelado por el usuario')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print('Usuario autenticado: ${user.email}');

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Dashboard(
              toggleTheme: toggleTheme,
              isDarkTheme: isDarkTheme,
            ),
          ),
        );
      } else {
        throw Exception('No se pudo obtener la información del usuario');
      }
    } catch (error) {
      print('Error al iniciar sesión: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDarkTheme ? Colors.blue.shade200 : Colors.blue.shade900;
    final backgroundColor =
        isDarkTheme ? Colors.grey.shade900 : Colors.blue.shade400;
    final textColor = isDarkTheme ? Colors.white : Colors.white;
    final secondaryTextColor = isDarkTheme ? Colors.white70 : Colors.white70;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, primaryColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 100,
                      color: textColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bienvenido a ExpenseApp',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Inicia sesión para gestionar tus finanzas',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => _signInWithGoogle(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            isDarkTheme ? Colors.white : Colors.black87,
                        backgroundColor:
                            isDarkTheme ? Colors.grey.shade800 : Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 1,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/google_logo.png',
                              height: 24.0,
                              width: 24.0,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Iniciar sesión con Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDarkTheme ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Al iniciar sesión, aceptas nuestros Términos de Servicio y Política de Privacidad',
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
