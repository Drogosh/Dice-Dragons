import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../models/item.dart';

class InventoryScreen extends StatefulWidget {
  final Inventory inventory;

  const InventoryScreen({
    super.key,
    required this.inventory,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Inventory inventory;

  @override
  void initState() {
    super.initState();
    inventory = widget.inventory;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Инвентарь',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (inventory.items.isEmpty)
              Center(
                child: Text(
                  'Инвентарь пуст',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inventory.items.length,
                itemBuilder: (context, index) {
                  final item = inventory.items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(item.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            inventory.removeItemAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

