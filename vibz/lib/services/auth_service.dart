import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
  final googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    throw Exception('Google sign-in canceled.');
  }

  final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

  final OAuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final userCred = await _auth.signInWithCredential(credential);

  await _ensureUserDocument(userCred.user!);
  return userCred;
}


  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _ensureUserDocument(cred.user!);
    return cred;
  }

  Future<UserCredential> createUserWithEmail(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    await _ensureUserDocument(cred.user!);
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _ensureUserDocument(User user) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'spotifyLinked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
