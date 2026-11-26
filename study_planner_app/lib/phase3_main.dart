import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 3 — Statistics & Cards
//
// Builds on Phase 2. New requirements:
//   • Summary row at the top: Total Hours, Completed, Remaining
//   • Getters use fold() for the sum and where() for counting
//   • ONE reusable StatCard StatelessWidget, used three times
//   • Row + Expanded so the three cards share width evenly
//   • Friendly empty-state message when the list is empty
//   • Statistics update immediately on every add / toggle / delete
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  runApp(const StudyPlannerApp());
}

// STATIC: root widget — sets up MaterialApp
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
// STATIC: reusable summary card — StatelessWidget used three times in the row.
// Receives its label, value, and colour from the parent; holds no state.
// ─────────────────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  // STATIC: descriptive label shown below the number
  final String label;

  // STATIC: computed value shown as a large number
  final String value;

  // STATIC: background colour makes each card visually distinct
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // STATIC: Card with a coloured Container and two Text widgets
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
            // STATIC: large number at the top of the card
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // STATIC: label below the number
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATIC + LOGIC: main screen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── LOGIC: goal list — single source of truth ─────────────────────────
  List<Map<String, dynamic>> _goals = [
    {'subject': 'Mathematics', 'hours': 3, 'done': false},
    {'subject': 'Physics',     'hours': 5, 'done': false},
    {'subject': 'Programming', 'hours': 4, 'done': false},
  ];

  // ── LOGIC: getters — computed live from _goals ─────────────────────────

  /// Total planned hours: fold() starts at 0 and adds each goal's hours.
  int get _totalHours =>
      _goals.fold(0, (sum, g) => sum + (g['hours'] as int));

  /// Count of completed goals: where() filters to done==true, .length counts.
  int get _completedGoals =>
      _goals.where((g) => g['done'] as bool).length;

  /// Count of remaining goals: where() filters to done==false, .length counts.
  int get _remainingGoals =>
      _goals.where((g) => !(g['done'] as bool)).length;

  // ── LOGIC: toggle done ────────────────────────────────────────────────
  // CONNECTION: checkbox / tile tap  →  _toggleDone()  →  setState()
  void _toggleDone(int index) {
    setState(() {
      _goals[index] = {
        ..._goals[index],
        'done': !(_goals[index]['done'] as bool),
      };
    });
  }

  // ── LOGIC: delete goal ────────────────────────────────────────────────
  // CONNECTION: delete icon tap  →  _deleteGoal()  →  setState()
  void _deleteGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
  }

  // ── LOGIC: add a sample goal ──────────────────────────────────────────
  void _addSampleGoal() {
    setState(() {
      _goals.add({'subject': 'English', 'hours': 2, 'done': false});
    });
  }

  // ── STATIC: build full screen ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // STATIC: AppBar
      appBar: AppBar(
        title: const Text('My Study Planner'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATIC: statistics row — three StatCard widgets sharing the width
          _buildStatsRow(),

          // STATIC: heading above the goal list
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'My Study Goals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),

          // STATIC: scrollable goal list
          Expanded(child: _buildGoalList()),
        ],
      ),

      // STATIC: FAB adds a sample goal
      floatingActionButton: FloatingActionButton(
        onPressed: _addSampleGoal,
        tooltip: 'Add Sample Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  // STATIC: Row of three StatCard widgets, each wrapped in Expanded
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // CONNECTION: getter value passed into StatCard as a String
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
    // STATIC: empty-state message when no goals exist
    if (_goals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No goals yet!\nTap + to add a sample goal.',
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

        // STATIC: one Card per goal
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Checkbox(
              value: isDone,
              // CONNECTION: checkbox  →  _toggleDone  →  setState
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
              // CONNECTION: delete icon  →  _deleteGoal  →  setState
              onPressed: () => _deleteGoal(index),
            ),
            onTap: () => _toggleDone(index),
          ),
        );
      },
    );
  }
}
