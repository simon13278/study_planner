import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 2 — Working List
//
// Goals:
//   • Convert HomeScreen to a StatefulWidget
//   • Store goals in a List<Map> with keys: subject, hours, done
//   • Build the list with ListView.builder (no hard-coded cards)
//   • Checkbox / tile tap marks a goal done (strike-through visual)
//   • Delete icon removes a goal
//   • FloatingActionButton adds a sample goal
//   • Every data change goes through setState()
//   • LOGIC comments on data and functions
//   • CONNECTION comments on the two UI ↔ data join points
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  runApp(const StudyPlannerApp());
}

// STATIC: root of the app — identical to Phase 1
class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // STATIC: MaterialApp provides navigation and theme
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

// STATIC: HomeScreen is now a StatefulWidget so setState() can rebuild the UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── LOGIC: goal list — the single source of truth for the UI ──────────
  // Each Map has three keys:
  //   subject (String)  — name of the subject
  //   hours   (int)     — planned study hours
  //   done    (bool)    — whether the goal is completed
  List<Map<String, dynamic>> _goals = [
    {'subject': 'Mathematics', 'hours': 3, 'done': false},
    {'subject': 'Physics',     'hours': 5, 'done': false},
    {'subject': 'Programming', 'hours': 4, 'done': false},
  ];

  // ── LOGIC: toggle the done field of the goal at [index] ───────────────
  // CONNECTION: checkbox / ListTile tap  →  _toggleDone()  →  setState()
  void _toggleDone(int index) {
    // LOGIC: flip the current bool value
    setState(() {
      _goals[index] = {
        ..._goals[index],
        'done': !(_goals[index]['done'] as bool),
      };
    });
  }

  // ── LOGIC: remove the goal at [index] from the list ───────────────────
  // CONNECTION: delete icon tap  →  _deleteGoal()  →  setState()
  void _deleteGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
  }

  // ── LOGIC: add a sample goal to the list ──────────────────────────────
  // In Phase 4 this will be replaced by Navigator.push to AddGoalScreen.
  void _addSampleGoal() {
    setState(() {
      _goals.add({'subject': 'English', 'hours': 2, 'done': false});
    });
  }

  // ── STATIC: build the full screen ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // STATIC: AppBar with app title
      appBar: AppBar(
        title: const Text('My Study Planner'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // STATIC: body holds the heading and the dynamic goal list
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATIC: heading above the list
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'My Study Goals',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),

          // STATIC: the goal list fills the remaining space
          Expanded(child: _buildGoalList()),
        ],
      ),

      // STATIC: FAB adds a sample goal (Phase 2 wires it up)
      // CONNECTION: FAB tap  →  _addSampleGoal()  →  setState()
      floatingActionButton: FloatingActionButton(
        onPressed: _addSampleGoal,
        tooltip: 'Add Sample Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  // STATIC: build the scrollable goal list, or an empty-state message
  Widget _buildGoalList() {
    // STATIC: show a friendly message when the list is empty
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

    // STATIC: ListView.builder creates one Card per entry in _goals
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        // LOGIC: read the current goal data for this row
        final goal  = _goals[index];
        final isDone = goal['done'] as bool;

        // STATIC: Card + ListTile for one goal row
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            // STATIC: checkbox on the left reflects the done state
            // CONNECTION: checkbox change  →  _toggleDone  →  setState
            leading: Checkbox(
              value: isDone,
              onChanged: (_) => _toggleDone(index),
            ),

            // STATIC: subject name; struck through when done
            title: Text(
              goal['subject'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                // STATIC: strike-through decoration for completed goals
                decoration: isDone ? TextDecoration.lineThrough : null,
                // STATIC: grey colour for completed goals
                color: isDone ? Colors.grey : null,
              ),
            ),

            // STATIC: hours subtitle
            subtitle: Text('${goal['hours']} hours planned'),

            // STATIC: delete icon on the right
            // CONNECTION: icon tap  →  _deleteGoal  →  setState
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete goal',
              onPressed: () => _deleteGoal(index),
            ),

            // Tapping anywhere on the tile also toggles done
            // CONNECTION: tile tap  →  _toggleDone  →  setState
            onTap: () => _toggleDone(index),
          ),
        );
      },
    );
  }
}
