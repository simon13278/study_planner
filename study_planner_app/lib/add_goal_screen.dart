import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AddGoalScreen — Phase 4: second screen where the user types a new goal.
//
// Navigation flow:
//   HomeScreen FAB → Navigator.push(AddGoalScreen)
//   Save button    → Navigator.pop(newGoal)   [returns Map to HomeScreen]
//   Back button    → Navigator.pop()           [returns null; HomeScreen ignores it]
// ─────────────────────────────────────────────────────────────────────────────

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // LOGIC: controllers read text from the two input fields
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  // LOGIC: validation error messages; null means no error
  String? _subjectError;
  String? _hoursError;

  // LOGIC: dispose controllers when the screen is removed from the tree
  // to free memory and avoid listener leaks.
  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // ── LOGIC: validate inputs and save the goal ──────────────────────────────
  void _saveGoal() {
    final String subject = _subjectController.text.trim();
    final String hoursText = _hoursController.text.trim();

    // LOGIC: reset previous error messages before re-validating
    setState(() {
      _subjectError = null;
      _hoursError = null;
    });

    bool isValid = true;

    // LOGIC: subject must not be empty
    if (subject.isEmpty) {
      setState(() => _subjectError = 'Subject name cannot be empty.');
      isValid = false;
    }

    // LOGIC: hours must be a positive integer
    final int? hours = int.tryParse(hoursText);
    if (hoursText.isEmpty || hours == null || hours <= 0) {
      setState(() => _hoursError = 'Please enter a number greater than 0.');
      isValid = false;
    }

    // LOGIC: only return data if both fields are valid
    if (!isValid) return;

    // CONNECTION: pass the new goal back to HomeScreen via Navigator.pop.
    // HomeScreen awaits this result and adds it to the list.
    Navigator.pop(context, {
      'subject': subject,
      'hours': hours,
    });
  }

  // ── STATIC: build the add-goal form ───────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // STATIC: app bar for the second screen
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
            // STATIC: heading on the form screen
            const Text(
              'Enter your study goal details:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // STATIC: subject text field
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Mathematics',
                prefixIcon: const Icon(Icons.book_outlined),
                border: const OutlineInputBorder(),
                // STATIC: show validation error message below the field
                errorText: _subjectError,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // STATIC: hours text field (numbers only)
            TextField(
              controller: _hoursController,
              decoration: InputDecoration(
                labelText: 'Planned Hours',
                hintText: 'e.g. 3',
                prefixIcon: const Icon(Icons.timer_outlined),
                border: const OutlineInputBorder(),
                // STATIC: show validation error message below the field
                errorText: _hoursError,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // STATIC: Save button
            ElevatedButton.icon(
              onPressed: _saveGoal,
              icon: const Icon(Icons.save_outlined),
              label: const Text(
                'Save Goal',
                style: TextStyle(fontSize: 16),
              ),
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
