import 'package:firebase_auth/firebase_auth.dart';

class Token {

  Future<String?> getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    return idToken;
  }
}