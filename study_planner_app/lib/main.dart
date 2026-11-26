import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'add_goal_screen.dart';
import 'database_helper.dart';
import 'stat_card.dart';

// ─────────────────────────────────────────────
// Entry point — initialises Firebase before the
// Flutter engine renders anything.
// ─────────────────────────────────────────────
void main() async {
  // Required when calling native code (Firebase) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // LOGIC: connect to Firebase using the generated options file.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // LOGIC: initDatabase() is a no-op for Firestore but kept for consistency.
  await DatabaseHelper.instance.initDatabase();

  runApp(const StudyPlannerApp());
}

// ─────────────────────────────────────────────
// STATIC: root widget — sets up MaterialApp
// ─────────────────────────────────────────────
class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Study Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// STATIC + LOGIC: main screen widget
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── LOGIC: in-memory goal list ─────────────────────────────────────────
  // Each goal is a Map with keys: id (String), subject, hours, done.
  // 'id' is the Firestore document id — a String, not an int.
  List<Map<String, dynamic>> _goals = [];

  // LOGIC: true while the first load from Firestore is in progress
  bool _loading = true;

  // ── LOGIC: getters that compute statistics from the list ───────────────

  /// Total planned study hours across all goals.
  int get _totalHours =>
      _goals.fold(0, (sum, g) => sum + (g['hours'] as int));

  /// Number of goals marked as done.
  int get _completedGoals =>
      _goals.where((g) => g['done'] as bool).length;

  /// Number of goals not yet done.
  int get _remainingGoals =>
      _goals.where((g) => !(g['done'] as bool)).length;

  // ── LOGIC: load saved goals from Firestore when the screen first opens ─
  @override
  void initState() {
    super.initState();
    // initState cannot be async itself, so we call a helper.
    _loadGoals();
  }

  // LOGIC: fetch all goals from Firestore and store in the list
  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    final rows = await DatabaseHelper.instance.getGoals();
    setState(() {
      // LOGIC: Firestore returns real bools — no int conversion needed.
      _goals = rows;
      _loading = false;
    });
  }

  // ── LOGIC: toggle the done status of a goal ───────────────────────────
  // CONNECTION: UI checkbox/tile tap → this function → setState + Firestore
  Future<void> _toggleDone(int index) async {
    final goal = _goals[index];
    final newDone = !(goal['done'] as bool);

    // LOGIC: update the Firestore document (id is a String)
    await DatabaseHelper.instance.updateGoal(goal['id'] as String, newDone);

    // LOGIC: update the in-memory list so the UI rebuilds
    setState(() {
      _goals[index] = {...goal, 'done': newDone};
    });
  }

  // ── LOGIC: delete a goal from the list and Firestore ──────────────────
  Future<void> _deleteGoal(int index) async {
    final goal = _goals[index];

    // LOGIC: remove from Firestore first (id is a String)
    await DatabaseHelper.instance.deleteGoal(goal['id'] as String);

    // LOGIC: remove from the in-memory list
    setState(() {
      _goals.removeAt(index);
    });
  }

  // ── LOGIC: open AddGoalScreen, await the returned goal, add it ────────
  // CONNECTION: FAB tap → Navigator.push → AddGoalScreen → Navigator.pop
  //             → result received here → Firestore insert → setState
  Future<void> _openAddGoalScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );

    // If the user pressed back without saving, result is null — ignore it.
    if (result == null) return;

    // LOGIC: insert the new goal into Firestore and get back its document id.
    final newId = await DatabaseHelper.instance.insertGoal({
      'subject': result['subject'],
      'hours': result['hours'],
      'done': false,
    });

    // LOGIC: add the goal (with its Firestore id) to the in-memory list.
    setState(() {
      _goals.add({
        'id': newId,          // String document id from Firestore
        'subject': result['subject'],
        'hours': result['hours'],
        'done': false,
      });
    });
  }

  // ── STATIC: build the full screen ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // STATIC: app bar with the app title
      appBar: AppBar(
        title: const Text('My Study Planner'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Refresh button re-fetches goals from Firestore
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadGoals,
          ),
        ],
      ),

      body: _loading
          // STATIC: loading spinner while fetching from Firestore
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // STATIC: statistics summary row (Phase 3)
                _buildStatsRow(),

                // STATIC: heading above the goal list
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Study Goals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // STATIC: goal list or empty-state message
                Expanded(child: _buildGoalList()),
              ],
            ),

      // STATIC: FAB opens the add-goal screen (Phase 4)
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddGoalScreen,
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  // STATIC: three StatCard widgets in a Row (Phase 3)
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // CONNECTION: StatCard reads computed getter values
          Expanded(
            child: StatCard(
              label: 'Total Hours',
              value: _totalHours.toString(),
              color: Colors.indigo.shade100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              label: 'Completed',
              value: _completedGoals.toString(),
              color: Colors.green.shade100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              label: 'Remaining',
              value: _remainingGoals.toString(),
              color: Colors.orange.shade100,
            ),
          ),
        ],
      ),
    );
  }

  // STATIC: ListView.builder or empty-state message
  Widget _buildGoalList() {
    // STATIC: friendly message when there are no goals yet
    if (_goals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No goals yet!\nTap + to add your first study goal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // STATIC: build one Card per goal using the data list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        final bool isDone = goal['done'] as bool;

        // STATIC: Card wrapping a ListTile for each goal
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            // STATIC: leading checkbox; tap toggles done status
            leading: Checkbox(
              value: isDone,
              // CONNECTION: checkbox tap → _toggleDone → setState
              onChanged: (_) => _toggleDone(index),
            ),

            // STATIC: subject name; strike-through when done
            title: Text(
              goal['subject'] as String,
              style: TextStyle(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : null,
                fontWeight: FontWeight.w600,
              ),
            ),

            // STATIC: hours subtitle
            subtitle: Text('${goal['hours']} hours planned'),

            // STATIC: delete icon on the right
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete goal',
              // CONNECTION: delete icon tap → _deleteGoal → setState
              onPressed: () => _deleteGoal(index),
            ),

            // Tapping the tile itself also toggles done
            onTap: () => _toggleDone(index),
          ),
        );
      },
    );
  }
}
