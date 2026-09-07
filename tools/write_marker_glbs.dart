// Writes one small GLB per grading marker. Baseball-simple placeholders
// so AR-06 can anchor a distinct model before authored art arrives.
// Each file is a single colored box, well under 4 MB and 50k triangles.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() {
  final out = Directory('assets/models');
  writeBox(
    out,
    id: 'marcador_estadio_leones',
    halfX: 0.06,
    halfZ: 0.05,
    height: 0.03,
    rgba: [0.11, 0.48, 0.23, 1],
  );
  writeBox(
    out,
    id: 'marcador_jugador_olmecas',
    halfX: 0.02,
    halfZ: 0.02,
    height: 0.12,
    rgba: [0.12, 0.16, 0.36, 1],
  );
  writeBox(
    out,
    id: 'marcador_trofeo_piratas',
    halfX: 0.025,
    halfZ: 0.025,
    height: 0.09,
    rgba: [0.83, 0.66, 0.22, 1],
  );
}

void writeBox(
  Directory root, {
  required String id,
  required double halfX,
  required double halfZ,
  required double height,
  required List<double> rgba,
}) {
  final dir = Directory('${root.path}/$id')..createSync(recursive: true);
  final file = File('${dir.path}/modelo.glb');
  file.writeAsBytesSync(_boxGlb(halfX, halfZ, height, rgba));
  stdout.writeln('${file.path} ${file.lengthSync()} bytes');
}

Uint8List _boxGlb(
  double halfX,
  double halfZ,
  double height,
  List<double> rgba,
) {
  final positions = Float32List.fromList([
    -halfX, 0, -halfZ, halfX, 0, -halfZ, halfX, 0, halfZ, -halfX, 0, halfZ,
    -halfX, height, -halfZ, halfX, height, -halfZ, halfX, height, halfZ,
    -halfX, height, halfZ,
  ]);
  final indices = Uint16List.fromList([
    0, 2, 1, 0, 3, 2,
    4, 5, 6, 4, 6, 7,
    0, 1, 5, 0, 5, 4,
    1, 2, 6, 1, 6, 5,
    2, 3, 7, 2, 7, 6,
    3, 0, 4, 3, 4, 7,
  ]);

  final bin = BytesBuilder();
  bin.add(positions.buffer.asUint8List());
  final indexPad = (4 - (bin.length % 4)) % 4;
  bin.add(List.filled(indexPad, 0));
  final indexOffset = bin.length;
  bin.add(indices.buffer.asUint8List());
  final binBytes = bin.toBytes();
  final binPad = (4 - (binBytes.length % 4)) % 4;
  final paddedBin = Uint8List(binBytes.length + binPad)
    ..setRange(0, binBytes.length, binBytes);

  final json = jsonEncode({
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {
        'mesh': 0,
      },
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0},
            'indices': 1,
            'material': 0,
          },
        ],
      },
    ],
    'materials': [
      {
        'pbrMetallicRoughness': {
          'baseColorFactor': rgba,
          'metallicFactor': 0.1,
          'roughnessFactor': 0.6,
        },
      },
    ],
    'accessors': [
      {
        'bufferView': 0,
        'componentType': 5126,
        'count': 8,
        'type': 'VEC3',
        'min': [-halfX, 0, -halfZ],
        'max': [halfX, height, halfZ],
      },
      {
        'bufferView': 1,
        'componentType': 5123,
        'count': indices.length,
        'type': 'SCALAR',
      },
    ],
    'bufferViews': [
      {
        'buffer': 0,
        'byteOffset': 0,
        'byteLength': positions.lengthInBytes,
        'target': 34962,
      },
      {
        'buffer': 0,
        'byteOffset': indexOffset,
        'byteLength': indices.lengthInBytes,
        'target': 34963,
      },
    ],
    'buffers': [
      {'byteLength': paddedBin.length},
    ],
  });
  final jsonBytes = utf8.encode(json);
  final jsonPadCount = (4 - (jsonBytes.length % 4)) % 4;
  final paddedJson = Uint8List(jsonBytes.length + jsonPadCount)
    ..setRange(0, jsonBytes.length, jsonBytes);
  for (var i = jsonBytes.length; i < paddedJson.length; i++) {
    paddedJson[i] = 0x20;
  }

  final total = 12 + 8 + paddedJson.length + 8 + paddedBin.length;
  final out = BytesBuilder();
  void u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    out.add(data.buffer.asUint8List());
  }

  u32(0x46546C67);
  u32(2);
  u32(total);
  u32(paddedJson.length);
  u32(0x4E4F534A);
  out.add(paddedJson);
  u32(paddedBin.length);
  u32(0x004E4942);
  out.add(paddedBin);
  return out.toBytes();
}
