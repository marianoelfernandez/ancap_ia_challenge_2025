import "package:flutter/material.dart";
import "package:anc_app/src/features/sidebar/widgets/sidebar.dart";

class AuditScreen extends StatelessWidget {
  const AuditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Audit"),
              ),
              body: const Center(
                child: Text(
                  "Audit Screen",
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
