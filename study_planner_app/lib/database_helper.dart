import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DatabaseHelper — all Firestore database code lives here and nowhere else.
//
// Replaces SQLite (sqflite) with Cloud Firestore.
// Uses the same singleton pattern and the same five public functions so that
// main.dart needs only minimal changes.
//
// Firestore concepts used:
//   • Collection  — like a database table; ours is called "goals".
//   • Document    — like a row; Firestore auto-generates a string id.
//   • DocumentReference — a pointer to one document (used to update/delete).
// ─────────────────────────────────────────────────────────────────────────────

class DatabaseHelper {
  // LOGIC: private constructor — prevents creating extra instances
  DatabaseHelper._internal();

  // LOGIC: single shared instance used everywhere in the app
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // LOGIC: reference to the "goals" collection in Firestore.
  // FirebaseFirestore.instance is already a singleton managed by the SDK.
  final CollectionReference _goalsCollection =
      FirebaseFirestore.instance.collection('goals');

  // ── LOGIC: initDatabase ───────────────────────────────────────────────────
  // With Firestore there is nothing to "open" — the SDK handles the
  // connection automatically after Firebase.initializeApp() is called in
  // main().  This method is kept so main.dart does not need to change.
  Future<void> initDatabase() async {
    // No-op for Firestore: connection is managed by the Firebase SDK.
  }

  // ── LOGIC: insertGoal ─────────────────────────────────────────────────────
  // Saves a new goal document and returns the Firestore-generated document id.
  // The caller stores this String id in the in-memory Map so later updates
  // and deletes can target the correct document.
  //
  // Input  : Map with keys subject (String), hours (int), done (bool)
  // Returns: String document id assigned by Firestore
  Future<String> insertGoal(Map<String, dynamic> goal) async {
    // LOGIC: add() creates a new document with an auto-generated id.
    final docRef = await _goalsCollection.add({
      'subject': goal['subject'],
      'hours': goal['hours'],
      // LOGIC: Firestore supports native booleans — no int conversion needed.
      'done': goal['done'] ?? false,
      // LOGIC: timestamp lets us order goals consistently across devices.
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ── LOGIC: getGoals ───────────────────────────────────────────────────────
  // Returns all goal documents ordered by creation time as a list of Maps.
  // Each Map includes the Firestore document id under the key 'id'.
  //
  // Returns: List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> getGoals() async {
    final snapshot = await _goalsCollection
        .orderBy('createdAt', descending: false)
        .get();

    // LOGIC: convert each Firestore document into a plain Map.
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,                        // Firestore document id (String)
        'subject': data['subject'] as String,
        'hours': data['hours'] as int,
        // LOGIC: Firestore stores done as a real bool — no conversion needed.
        'done': data['done'] as bool? ?? false,
      };
    }).toList();
  }

  // ── LOGIC: updateGoal ─────────────────────────────────────────────────────
  // Changes the done field of a single goal document.
  //
  // Input: String id  — the Firestore document id
  //        bool done  — the new completion state
  Future<void> updateGoal(String id, bool done) async {
    // LOGIC: update() only changes the specified fields; other fields are kept.
    await _goalsCollection.doc(id).update({'done': done});
  }

  // ── LOGIC: deleteGoal ─────────────────────────────────────────────────────
  // Permanently removes the goal document with the given id.
  //
  // Input: String id — the Firestore document id
  Future<void> deleteGoal(String id) async {
    await _goalsCollection.doc(id).delete();
  }
}
