import 'package:flutter/material.dart';

import '../../domain/entities/link.dart';

class LinkTile extends StatelessWidget {
  const LinkTile({
    super.key,
    required this.link,
    required this.onTap,
    required this.onDelete,
  });

  final Link link;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(link.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Icon(
          link.openedViaTor ? Icons.security : Icons.public,
          color: link.openedViaTor ? Colors.purple : null,
        ),
        title: Text(
          (link.title?.isNotEmpty ?? false) ? link.title! : link.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(link.url, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}
