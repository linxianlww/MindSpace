import 'package:flutter_test/flutter_test.dart';
import 'package:mindspace/core/utils/uuid_utils.dart';

void main() {
  group('UuidUtils', () {
    test('newId 生成标准 v4（含 4 个连字符，版本位为 4）', () {
      final id = UuidUtils.newId();
      expect(id.split('-').length, 5);
      expect(id.split('-')[2].startsWith('4'), isTrue);
    });

    test('newFileId 去掉连字符，长度为 32', () {
      final f = UuidUtils.newFileId();
      expect(f.contains('-'), isFalse);
      expect(f.length, 32);
    });

    test('连续生成不重复', () {
      final set = List.generate(1000, (_) => UuidUtils.newId()).toSet();
      expect(set.length, 1000);
    });
  });
}
