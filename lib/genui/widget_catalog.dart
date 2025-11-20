import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../widgets/custom/feature_card.dart';
import '../widgets/custom/section_header.dart';

/// Widget catalog with core GenUI widgets and custom widgets
class WidgetCatalog {
  static Catalog createCatalog() {
    // Create custom catalog items
    final featureCard = CatalogItem(
      name: 'FeatureCard',
      dataSchema: S.object(
        properties: {
          'title': S.string(),
          'description': S.string(),
        },
        required: ['title', 'description'],
      ),
      widgetBuilder: FeatureCard.builder,
    );

    final sectionHeader = CatalogItem(
      name: 'SectionHeader',
      dataSchema: S.object(
        properties: {
          'text': S.string(),
        },
        required: ['text'],
      ),
      widgetBuilder: SectionHeader.builder,
    );

    // Combine core catalog with custom widgets
    return CoreCatalogItems.asCatalog().copyWith([
      featureCard,
      sectionHeader,
    ]);
  }
}

