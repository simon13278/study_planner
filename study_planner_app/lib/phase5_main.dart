import 'package:flutter/material.dart';
import 'phase5_database_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 5 — Database Persistence
//
// Builds on Phase 4. New requirements:
//   • Goals saved in SQLite (sqflite) — survive app restart
//   • DatabaseHelper in a separate file (phase5_database_helper.dart)
//   • main() initialises the database before runApp()
//   • initState() loads saved goals via a separate async helper
//   • Add: insertGoal() → returns new id → stored in Map
//   • Toggle: updateGoal(id, done) updates the database row
//   • Delete: deleteGoal(id) removes the database row
//   • bool ↔ int conversion at every save / load point
//   • DatabaseHelper functions use async / await throughout
// ─────────────────────────────────────────────────────────────────────────────

// ── Entry point ───────────────────────────────────────────────────────────────
void main() async {
  // Required before calling any native (database) code before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // LOGIC: open or create goals.db before the UI is shown
  await DatabaseHelper.instance.initDatabase();

  runApp(const StudyPlannerApp());
}

// STATIC: root widget
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

// ─────────────────────────────────────────────────────────────────────────────
// STATIC: reusable StatCard — same as Phase 3 & 4
// ─────────────────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AddGoalScreen — same as Phase 4
// ─────────────────────────────────────────────────────────────────────────────
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // LOGIC: controllers for the two text fields
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _hoursController   = TextEditingController();

  String? _subjectError;
  String? _hoursError;

  // LOGIC: free controller memory when the screen is removed
  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    final String subject   = _subjectController.text.trim();
    final String hoursText = _hoursController.text.trim();

    setState(() {
      _subjectError = null;
      _hoursError   = null;
    });

    bool isValid = true;

    if (subject.isEmpty) {
      setState(() => _subjectError = 'Subject name cannot be empty.');
      isValid = false;
    }

    final int? hours = int.tryParse(hoursText);
    if (hoursText.isEmpty || hours == null || hours <= 0) {
      setState(() => _hoursError = 'Please enter a number greater than 0.');
      isValid = false;
    }

    if (!isValid) return;

    // CONNECTION: return the validated goal to HomeScreen
    Navigator.pop(context, {'subject': subject, 'hours': hours});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Study Goal'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter your study goal details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            TextField(
              controller: _subjectController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Mathematics',
                prefixIcon: const Icon(Icons.book_outlined),
                border: const OutlineInputBorder(),
                errorText: _subjectError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Planned Hours',
                hintText: 'e.g. 3',
                prefixIcon: const Icon(Icons.timer_outlined),
                border: const OutlineInputBorder(),
                errorText: _hoursError,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saveGoal,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Goal', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATIC + LOGIC: HomeScreen with full database persistence
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── LOGIC: in-memory goal list ────────────────────────────────────────
  // Each Map has keys: id (int), subject (String), hours (int), done (bool).
  // 'id' is the SQLite row id — stored so updateGoal and deleteGoal can
  // target the exact row.
  List<Map<String, dynamic>> _goals = [];

  // LOGIC: controls the loading spinner while the first DB read runs
  bool _loading = true;

  // ── LOGIC: getters ────────────────────────────────────────────────────
  int get _totalHours =>
      _goals.fold(0, (sum, g) => sum + (g['hours'] as int));

  int get _completedGoals =>
      _goals.where((g) => g['done'] as bool).length;

  int get _remainingGoals =>
      _goals.where((g) => !(g['done'] as bool)).length;

  // ── LOGIC: load goals on startup ──────────────────────────────────────
  // initState cannot be async — a separate async helper is called instead.
  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // LOGIC: fetch all rows from SQLite and populate _goals
  Future<void> _loadGoals() async {
    setState(() => _loading = true);

    final rows = await DatabaseHelper.instance.getGoals();

    setState(() {
      _goals = rows.map((row) {
        return {
          'id':      row['id']      as int,
          'subject': row['subject'] as String,
          'hours':   row['hours']   as int,
          // LOGIC: SQLite stores done as INTEGER (0 or 1) — convert to bool
          'done': (row['done'] as int) == 1,
        };
      }).toList();
      _loading = false;
    });
  }

  // ── LOGIC: toggle done ────────────────────────────────────────────────
  // CONNECTION: checkbox / tile tap  →  _toggleDone()  →  DB + setState()
  Future<void> _toggleDone(int index) async {
    final goal    = _goals[index];
    final newDone = !(goal['done'] as bool);

    // LOGIC: update the SQLite row (bool → int happens inside updateGoal)
    await DatabaseHelper.instance.updateGoal(goal['id'] as int, newDone);

    // LOGIC: mirror the change in the in-memory list
    setState(() {
      _goals[index] = {...goal, 'done': newDone};
    });
  }

  // ── LOGIC: delete goal ────────────────────────────────────────────────
  // CONNECTION: delete icon tap  →  _deleteGoal()  →  DB + setState()
  Future<void> _deleteGoal(int index) async {
    final goal = _goals[index];

    // LOGIC: remove from SQLite first
    await DatabaseHelper.instance.deleteGoal(goal['id'] as int);

    // LOGIC: then remove from the in-memory list
    setState(() => _goals.removeAt(index));
  }

  // ── LOGIC: add goal via second screen ────────────────────────────────
  // CONNECTION: FAB tap  →  Navigator.push(AddGoalScreen)
  //             Save button  →  Navigator.pop(goal)
  //             result received  →  insertGoal()  →  setState()
  Future<void> _openAddGoalScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );

    // LOGIC: user pressed back — result is null; nothing to add
    if (result == null) return;

    // LOGIC: insert into SQLite; insert() returns the new row's id
    final newId = await DatabaseHelper.instance.insertGoal({
      'subject': result['subject'],
      'hours':   result['hours'],
      // LOGIC: convert bool → int for SQLite (false → 0)
      'done': 0,
    });

    // LOGIC: add the goal with its database id to the in-memory list
    setState(() {
      _goals.add({
        'id':      newId,              // int id from SQLite insert
        'subject': result['subject'],
        'hours':   result['hours'],
        'done':    false,
      });
    });
  }

  // ── STATIC: build full screen ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Study Planner'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: _loading
          // STATIC: spinner while the first database read completes
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'My Study Goals',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                ),
                Expanded(child: _buildGoalList()),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddGoalScreen,
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
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

  Widget _buildGoalList() {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal   = _goals[index];
        final isDone = goal['done'] as bool;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Checkbox(
              value: isDone,
              onChanged: (_) => _toggleDone(index),
            ),
            title: Text(
              goal['subject'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : null,
              ),
            ),
            subtitle: Text('${goal['hours']} hours planned'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete goal',
              onPressed: () => _deleteGoal(index),
            ),
            onTap: () => _toggleDone(index),
          ),
        );
      },
    );
  }
}
