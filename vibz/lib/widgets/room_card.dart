// lib/widgets/room_card.dart
import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final String roomId;
  final String name;
  final String createdBy;
  final bool isPublic;
  final void Function() onJoin; // use VoidCallback here

  const RoomCard({
    Key? key,
    required this.roomId,
    required this.name,
    required this.createdBy,
    required this.isPublic,
    required this.onJoin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subtitle = createdBy.contains('@') ? 'by ${createdBy.split('@').first}' : 'by $createdBy';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'R')),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(onPressed: onJoin, child: const Text('Join')),
        onTap: onJoin,
      ),
    );
  }
}
