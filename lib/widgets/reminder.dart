import 'package:flutter/material.dart';
import 'package:quotes_app/views/themes/colors.dart';

class ReminderWidget extends StatefulWidget {
  const ReminderWidget({super.key});

  @override
  _ReminderWidgetState createState() => _ReminderWidgetState();
}

// function that takes a number and return a string on a time format.
// Input: 850
// Output: 08:30
String timeToString(int time) {
  String timeString = time.toString();
  if (timeString.length == 3) {
    timeString = "0" + timeString;
  }
  String prefix = timeString.substring(0, 2);
  String suffix = timeString.substring(2, 4);
  return prefix + ":" + (suffix == "00" ? "00" : "30");
}

class _ReminderWidgetState extends State<ReminderWidget> {
  String typeOfQuote = 'General';
  int howMany = 10;
  int startTime = 800;
  int endTime = 2200;
  int minTime = 100;
  int maxTime = 2350;
  final values = [false, true, true, true, true, true, false];
  final String days = "SMTWTFS";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: MyColors.primary,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                textColor: Colors.white,
                title: const Text('Repeat'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.indeterminate_check_box_rounded),
                      onPressed: () {
                        setState(() {
                          howMany = howMany - 1;
                        });
                      },
                    ),
                    Text("${howMany}X"),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.add_box_rounded),
                      onPressed: () {
                        setState(() {
                          howMany = howMany + 1;
                          if (howMany > 20) {
                            howMany = 20;
                          }
                          if (howMany <= 0) {
                            howMany = 1;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                  textColor: Colors.white,
                  title: const Text('Start at'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.indeterminate_check_box_rounded),
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            startTime = startTime - 50;
                            if (startTime < minTime) {
                              startTime = minTime;
                            }
                          });
                        },
                      ),
                      Text(timeToString(startTime)),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.add_box_rounded),
                        onPressed: () {
                          setState(() {
                            startTime = startTime + 50;
                            if (startTime > maxTime) {
                              startTime = maxTime;
                            }
                          });
                        },
                      ),
                    ],
                  )),
              ListTile(
                  textColor: Colors.white,
                  title: const Text('End at'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.indeterminate_check_box_rounded),
                        onPressed: () {
                          setState(() {
                            endTime = endTime - 50;
                            if (endTime < minTime) {
                              endTime = minTime;
                            }
                          });
                        },
                      ),
                      Text(timeToString(endTime)),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.add_box_rounded),
                        onPressed: () {
                          setState(() {
                            endTime = endTime + 50;
                            if (endTime > maxTime) {
                              endTime = maxTime;
                            }
                          });
                        },
                      ),
                    ],
                  )),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Text("Days",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: values
                    .asMap()
                    .entries
                    .map((entry) => _buildDayCircle(days[entry.key],
                            selected: entry.value, onPress: () {
                          setState(() {
                            values[entry.key] = !values[entry.key];
                          });
                        }))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCircle(String day,
      {bool selected = false, onPress: Function}) {
    return GestureDetector(
        onTap: onPress,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: MyColors.primaryDark, // Set border color
              width: 1.0, // Set border width
            ),
          ),
          child: CircleAvatar(
            foregroundColor: selected ? MyColors.primaryDark : Colors.white,
            backgroundColor: selected ? MyColors.primary : MyColors.primaryDark,
            child: Text(day),
          ),
        ));
  }
}
