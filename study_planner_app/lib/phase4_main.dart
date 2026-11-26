import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 4 — Second Screen
//
// Builds on Phase 3. New requirements:
//   • AddGoalScreen with two TextFields (subject, hours) + TextEditingControllers
//   • FAB now opens AddGoalScreen via Navigator.push
//   • Validate: subject non-empty; hours a positive integer; show error messages
//   • On Save: return new goal to HomeScreen with Navigator.pop
//   • HomeScreen awaits the result with await Navigator.push; ignores null
//   • Dispose controllers when AddGoalScreen closes
// ─────────────────────────────────────────────────────────────────────────────

void main() {
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
// STATIC: reusable StatCard widget — identical to Phase 3
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
// PHASE 4 NEW: AddGoalScreen — the second screen with the input form
// ─────────────────────────────────────────────────────────────────────────────
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // LOGIC: controllers read text typed into each TextField
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _hoursController   = TextEditingController();

  // LOGIC: error messages shown below each field; null = no error
  String? _subjectError;
  String? _hoursError;

  // LOGIC: free controller memory when this screen is destroyed
  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // ── LOGIC: validate then return the new goal to HomeScreen ────────────
  void _saveGoal() {
    final String subject   = _subjectController.text.trim();
    final String hoursText = _hoursController.text.trim();

    // LOGIC: clear old errors before re-validating
    setState(() {
      _subjectError = null;
      _hoursError   = null;
    });

    bool isValid = true;

    // LOGIC: subject must not be empty
    if (subject.isEmpty) {
      setState(() => _subjectError = 'Subject name cannot be empty.');
      isValid = false;
    }

    // LOGIC: hours must parse to a positive integer
    final int? hours = int.tryParse(hoursText);
    if (hoursText.isEmpty || hours == null || hours <= 0) {
      setState(() => _hoursError = 'Please enter a number greater than 0.');
      isValid = false;
    }

    if (!isValid) return;

    // CONNECTION: Navigator.pop passes the validated goal back to HomeScreen.
    // HomeScreen awaits this call and receives the Map as the result.
    Navigator.pop(context, {'subject': subject, 'hours': hours});
  }

  // ── STATIC: build the form screen ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // STATIC: AppBar for the second screen
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
            // STATIC: form heading
            const Text(
              'Enter your study goal details:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // STATIC: subject text field
            TextField(
              controller: _subjectController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Mathematics',
                prefixIcon: const Icon(Icons.book_outlined),
                border: const OutlineInputBorder(),
                // STATIC: error message shown below the field on bad input
                errorText: _subjectError,
              ),
            ),
            const SizedBox(height: 16),

            // STATIC: hours text field
            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Planned Hours',
                hintText: 'e.g. 3',
                prefixIcon: const Icon(Icons.timer_outlined),
                border: const OutlineInputBorder(),
                // STATIC: error message shown below the field on bad input
                errorText: _hoursError,
              ),
            ),
            const SizedBox(height: 32),

            // STATIC: Save button
            ElevatedButton.icon(
              onPressed: _saveGoal,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Goal',
                  style: TextStyle(fontSize: 16)),
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
// STATIC + LOGIC: HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // LOGIC: goal list
  final List<Map<String, dynamic>> _goals = [
    {'subject': 'Mathematics', 'hours': 3, 'done': false},
    {'subject': 'Physics',     'hours': 5, 'done': false},
    {'subject': 'Programming', 'hours': 4, 'done': false},
  ];

  // ── LOGIC: getters ────────────────────────────────────────────────────
  int get _totalHours =>
      _goals.fold(0, (sum, g) => sum + (g['hours'] as int));

  int get _completedGoals =>
      _goals.where((g) => g['done'] as bool).length;

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
    setState(() => _goals.removeAt(index));
  }

  // ── LOGIC: open AddGoalScreen and await the result ────────────────────
  // CONNECTION: FAB tap  →  Navigator.push(AddGoalScreen)
  //             AddGoalScreen.Save  →  Navigator.pop(goal)
  //             result received here  →  setState adds goal to list
  Future<void> _openAddGoalScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );

    // LOGIC: user pressed back — result is null; nothing to add
    if (result == null) return;

    // LOGIC: add the validated goal returned by AddGoalScreen
    setState(() {
      _goals.add({
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

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATIC: stats row
          _buildStatsRow(),

          // STATIC: heading
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

      // STATIC: FAB now navigates to AddGoalScreen
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
