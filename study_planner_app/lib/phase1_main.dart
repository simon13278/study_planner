import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 1 — Static Screen
//
// Goals:
//   • App title "My Study Planner" in an AppBar
//   • MaterialApp + Scaffold + StatelessWidget as home
//   • At least three hard-coded goal Cards (subject + hours)
//   • A heading above the list
//   • A FloatingActionButton (does nothing yet)
//   • STATIC comment above every major widget block
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  runApp(const StudyPlannerApp());
}

// STATIC: root of the app — sets up MaterialApp with theme and home screen
class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // STATIC: MaterialApp wraps everything and provides navigation + theme
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

// STATIC: home screen — a StatelessWidget because Phase 1 has no logic yet
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // STATIC: Scaffold provides the AppBar, body, and FloatingActionButton
    return Scaffold(
      // STATIC: AppBar displays the app title
      appBar: AppBar(
        title: const Text('My Study Planner'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // STATIC: body is a Column holding the heading and the goal cards
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATIC: heading above the list of goals
            Text(
              'My Study Goals',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            SizedBox(height: 12),

            // STATIC: hard-coded goal card 1
            GoalCard(subject: 'Mathematics',  hours: 3),

            // STATIC: hard-coded goal card 2
            GoalCard(subject: 'Physics',      hours: 5),

            // STATIC: hard-coded goal card 3
            GoalCard(subject: 'Programming',  hours: 4),

            // STATIC: hard-coded goal card 4 (bonus — shows variety)
            GoalCard(subject: 'English',      hours: 2),
          ],
        ),
      ),

      // STATIC: FloatingActionButton — does nothing yet in Phase 1
      floatingActionButton: FloatingActionButton(
        onPressed: null, // will be wired up in Phase 2
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// STATIC: reusable hard-coded goal card widget
// Shows the subject name and planned hours inside a Material Card.
class GoalCard extends StatelessWidget {
  // STATIC: subject name displayed on the card
  final String subject;

  // STATIC: planned study hours displayed on the card
  final int hours;

  const GoalCard({
    super.key,
    required this.subject,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    // STATIC: Card gives elevation and rounded corners
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        // STATIC: book icon on the left
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.book, color: Colors.white),
        ),

        // STATIC: subject name as the main text
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        // STATIC: hours as the subtitle
        subtitle: Text('$hours hours planned'),

        // STATIC: static label on the right showing "Pending"
        trailing: Chip(
          label: const Text('Pending'),
          backgroundColor: Colors.orange.shade100,
        ),
      ),
    );
  }
}
