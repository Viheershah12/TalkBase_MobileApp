import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class TenantSelector extends StatefulWidget {
  final Function(String) onTenantSelected;
  final String? initialTenant;

  const TenantSelector({
    Key? key,
    required this.onTenantSelected,
    this.initialTenant,
  }) : super(key: key);

  @override
  State<TenantSelector> createState() => _TenantSelectorState();
}

class _TenantSelectorState extends State<TenantSelector> {
  String? selectedTenant;

  @override
  void initState() {
    super.initState();
    selectedTenant = widget.initialTenant;
  }

  Future<void> _showTenantDialog() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool checking = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "Enter Tenant Name",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.apartment),
                    labelText: "Tenant Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: error,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                if (checking)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Check Tenant"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  FocusScope.of(context).unfocus(); // dismiss keyboard
                  setState(() {
                    checking = true;
                    error = null;
                  });

                  final exists = await _checkTenant(controller.text.trim());

                  setState(() => checking = false);

                  if (exists) {
                    widget.onTenantSelected(controller.text.trim());
                    Navigator.pop(context);
                  } else {
                    setState(() => error = "Tenant not found");
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _checkTenant(String name) async {
    // Replace with actual API call
    var provider = Provider.of<AuthProvider>(context, listen: false);
    var res = await provider.checkTenant(name);
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _showTenantDialog,
      icon: const Icon(Icons.apartment, size: 20),
      label: Text(
        selectedTenant == null ? "Select Tenant" : "Tenant: $selectedTenant",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: Colors.deepPurple, // Primary color
        foregroundColor: Colors.white, // Text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
      ),
    );
  }
}
