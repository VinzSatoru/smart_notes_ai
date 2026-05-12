import 'package:pocketbase/pocketbase.dart';
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
  });

  factory CategoryModel.fromRecord(RecordModel record) {
    return CategoryModel(
      id: record.id,
      name: record.getStringValue('name'),
    );
  }
}
