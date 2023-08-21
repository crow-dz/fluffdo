import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fluffdo/constants.dart';
import 'package:uuid/uuid.dart';

// setting up class with update function
@immutable
class Task {
  final String id;
  final String description;
  final bool isDone;
  const Task(
      {required this.id, required this.description, required this.isDone});
  Task copy({required bool isDone}) {
    return Task(id: id, description: description, isDone: isDone);
  }

  @override
  String toString() => 'Tasks( id: $id, '
      ' description: $description,'
      ' isDone: $isDone )';
  @override
  bool operator ==(covariant Task other) =>
      id == other.id && isDone == other.isDone;
  @override
  int get hashCode => Object.hashAll([id, isDone]);
}

//setting state notifier
class AllTask extends StateNotifier<List<Task>> {
  AllTask() : super(allTasks);
  void update(Task task, bool isDone) {
    state = [
      for (var oldTask in state)
        if (oldTask.id == task.id) task.copy(isDone: isDone) else oldTask
    ];
  }

  void add(Task newTask) {
    state = [...state, newTask];
    log(state.toString());
  }
}

// Enum List for Done and Undone task
enum TasksStatus {
  all,
  done,
  notDone,
}
// Providers in our case we have 4 providers
// first one for tasks state
// second one for getting all tasks from StateNotifier class
// other two regular providers getting data from  StateNotifier provider

// State Provider
final tasksStatusProvider =
    StateProvider<TasksStatus>((ref) => TasksStatus.all);
// StateNotifierProvider
final allTasksProvider =
    StateNotifierProvider<AllTask, List<Task>>((_) => AllTask());
// regular provider
final tasksAreDone =
    Provider((ref) => ref.watch(allTasksProvider).where((task) => task.isDone));
// regular provider
final tasksAreNotDone = Provider(
    (ref) => ref.watch(allTasksProvider).where((task) => !task.isDone));

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe6e6e6),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: Image.asset("assets/images/cat_face.png"),
        title: Text("Fluffdo", style: GoogleFonts.pacifico(fontSize: 24)),
        backgroundColor: const Color(0xffe6e6e6),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const FilterWidget(),
              Consumer(builder: (context, ref, child) {
                final filter = ref.watch(tasksStatusProvider);
                switch (filter) {
                  case TasksStatus.all:
                    return TasksListWidget(
                      provider: allTasksProvider,
                    );
                  case TasksStatus.done:
                    return TasksListWidget(
                      provider: tasksAreDone,
                    );
                  case TasksStatus.notDone:
                    return TasksListWidget(
                      provider: tasksAreNotDone,
                    );
                }
              }),
            ],
          ),
          Positioned(
              bottom: -10,
              right: 10,
              child: Consumer(builder: (context, ref, child) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: InkWell(
                    child: Image.asset("assets/images/cat_paw.png"),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return buttomSheetWidget(context);
                        },
                      );
                    },
                  ),
                ).animate(autoPlay: true).moveY(begin: 0, end: 10);
              }))
        ],
      ),
    );
  }

  Widget buttomSheetWidget(BuildContext context) {
    final textCtr = TextEditingController();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: textCtr,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Enter task description',
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Consumer(builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      const snackBar = SnackBar(
                        behavior:
                            SnackBarBehavior.floating, // Change the behavior

                        content: Text('Please write down your task'),
                      );
                      // Add logic for the add button
                      if (textCtr.text != "") {
                        final uuid = Uuid();
                        ref.read(allTasksProvider.notifier).add(Task(
                            id: uuid.v4().toString(),
                            description: textCtr.text,
                            isDone: false));
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}

class TasksListWidget extends ConsumerWidget {
  const TasksListWidget({super.key, required this.provider});
  final AlwaysAliveProviderBase<Iterable<Task>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(provider);
    return Expanded(
        child: tasks.isNotEmpty
            ? ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks.elementAt(index);
                  return Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/images/one_cat.png"),
                            fit: BoxFit.fill),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 85.0, left: 80),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.pacifico(
                                    decoration: task.isDone
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 25, left: 10.0),
                            child: Transform.scale(
                              scale: 1.4,
                              child: Checkbox(
                                  fillColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) =>
                                              const Color(0xff61484b)),
                                  shape: const CircleBorder(),
                                  value: task.isDone,
                                  onChanged: (value) {
                                    ref
                                        .read(allTasksProvider.notifier)
                                        .update(task, value!);
                                  }),
                            ),
                          )
                        ],
                      ));
                })
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/no_task.png"),
                  Text(
                    "There is no Tasks !",
                    style: GoogleFonts.pacifico(fontSize: 18),
                  ),
                ],
              ));
  }
}

class FilterWidget extends StatelessWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      return DropdownButton(
          value: ref.watch(tasksStatusProvider),
          items: TasksStatus.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ))
              .toList(),
          onChanged: (TasksStatus? value) {
            ref.read(tasksStatusProvider.state).state = value!;
          });
    });
  }
}
