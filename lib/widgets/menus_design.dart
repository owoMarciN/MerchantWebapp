import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/models/menus.dart';
import 'package:user_app/screens/items_screen.dart';

class MenusDesignWidget extends StatelessWidget {
  final Menus? model;
  final BuildContext? context;
  const MenusDesignWidget({super.key, this.model, this.context});

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasImage = model?.bannerUrl != null && model!.bannerUrl!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemsScreen(model: model)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image
            SizedBox(
              height: 160,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      model!.bannerUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: brandColors.navy?.withValues(alpha: 0.05),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: brandColors.navy,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _placeholder(brandColors),
                    )
                  : _placeholder(brandColors),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model?.title ?? 'Untitled Menu',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model?.description ?? '',
                    style: TextStyle(fontSize: 12, color: brandColors.muted, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.lightBlueAccent),
                      const SizedBox(width: 4),
                      Text(
                        'View Items',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.lightBlueAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BrandColors brandColors) {
    return Container(
      color: brandColors.navy?.withValues(alpha: 0.05),
      child: Center(
        child: Icon(Icons.restaurant_menu_rounded, size: 40, color: brandColors.muted),
      ),
    );
  }
}