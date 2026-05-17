import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late String type; // 'εσοδο' or 'εξοδο'

  @HiveField(4)
  late String category;

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  String? accountId;

  @HiveField(7)
  String? photoPath;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.accountId,
    this.photoPath,
  });
}