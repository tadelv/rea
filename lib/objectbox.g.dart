// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again:
// With a Flutter package, run `flutter pub run build_runner build`.
// With a Dart package, run `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart';
import 'package:objectbox_flutter_libs/objectbox_flutter_libs.dart';

import 'model/coffee.dart';
import 'model/shot.dart';
import 'model/shotstate.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <ModelEntity>[
  ModelEntity(
      id: const IdUid(3, 5050282589413394899),
      name: 'Shot',
      lastPropertyId: const IdUid(6, 3371539309151542209),
      flags: 0,
      properties: <ModelProperty>[
        ModelProperty(
            id: const IdUid(1, 3409921168948181785),
            name: 'id',
            type: 6,
            flags: 1),
        ModelProperty(
            id: const IdUid(2, 2023678536313964966),
            name: 'date',
            type: 10,
            flags: 0),
        ModelProperty(
            id: const IdUid(3, 8622027867479492178),
            name: 'coffeeId',
            type: 11,
            flags: 520,
            indexId: const IdUid(3, 6812967169057673456),
            relationTarget: 'Coffee'),
        ModelProperty(
            id: const IdUid(4, 8755594923067759447),
            name: 'profileId',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(5, 5926041023112911997),
            name: 'pourTime',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(6, 3371539309151542209),
            name: 'pourWeight',
            type: 8,
            flags: 0)
      ],
      relations: <ModelRelation>[
        ModelRelation(
            id: const IdUid(1, 2516218059471133212),
            name: 'shotstates',
            targetId: const IdUid(7, 7915358336460233027))
      ],
      backlinks: <ModelBacklink>[]),
  ModelEntity(
      id: const IdUid(5, 6166132089796684361),
      name: 'Coffee',
      lastPropertyId: const IdUid(13, 8572628874963105062),
      flags: 0,
      properties: <ModelProperty>[
        ModelProperty(
            id: const IdUid(1, 5615950171516587099),
            name: 'id',
            type: 6,
            flags: 1),
        ModelProperty(
            id: const IdUid(2, 8472885439572250925),
            name: 'name',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(3, 5110044840806149074),
            name: 'roasterId',
            type: 11,
            flags: 520,
            indexId: const IdUid(2, 3069173701919379915),
            relationTarget: 'Roaster'),
        ModelProperty(
            id: const IdUid(4, 5457947097987531063),
            name: 'imageURL',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(5, 4303540774085095790),
            name: 'grinderSettings',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(6, 225021759355650432),
            name: 'acidRating',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(7, 6130861246586256372),
            name: 'intensityRating',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(8, 1334308936684528664),
            name: 'roastLevel',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(9, 6520200225208100644),
            name: 'arabica',
            type: 6,
            flags: 0),
        ModelProperty(
            id: const IdUid(10, 6062984101281118472),
            name: 'robusta',
            type: 6,
            flags: 0),
        ModelProperty(
            id: const IdUid(11, 5546651948055766963),
            name: 'description',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(12, 1497565644929136769),
            name: 'origin',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(13, 8572628874963105062),
            name: 'price',
            type: 9,
            flags: 0)
      ],
      relations: <ModelRelation>[],
      backlinks: <ModelBacklink>[]),
  ModelEntity(
      id: const IdUid(6, 8881644376576832429),
      name: 'Roaster',
      lastPropertyId: const IdUid(6, 970876983252056704),
      flags: 0,
      properties: <ModelProperty>[
        ModelProperty(
            id: const IdUid(1, 5991058579053841031),
            name: 'id',
            type: 6,
            flags: 1),
        ModelProperty(
            id: const IdUid(2, 2492045522554162963),
            name: 'name',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(3, 109766545405737050),
            name: 'imageURL',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(4, 9028335971533423619),
            name: 'description',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(5, 5316187485168323519),
            name: 'address',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(6, 970876983252056704),
            name: 'homepage',
            type: 9,
            flags: 0)
      ],
      relations: <ModelRelation>[],
      backlinks: <ModelBacklink>[
        ModelBacklink(name: 'coffees', srcEntity: 'Coffee', srcField: 'roaster')
      ]),
  ModelEntity(
      id: const IdUid(7, 7915358336460233027),
      name: 'ShotState',
      lastPropertyId: const IdUid(17, 6151090906092388458),
      flags: 0,
      properties: <ModelProperty>[
        ModelProperty(
            id: const IdUid(1, 5911801733392743346),
            name: 'id',
            type: 6,
            flags: 1),
        ModelProperty(
            id: const IdUid(2, 873810899844548098),
            name: 'subState',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(3, 5430882212744780164),
            name: 'weight',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(4, 7057243266656013589),
            name: 'sampleTime',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(5, 7139045219632015353),
            name: 'sampleTimeCorrected',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(6, 8336035996648567372),
            name: 'pourTime',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(7, 3728387464400538728),
            name: 'groupPressure',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(8, 7163267269115276469),
            name: 'groupFlow',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(9, 3024067366106544243),
            name: 'mixTemp',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(10, 6481804704343187952),
            name: 'headTemp',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(11, 4452444150576753969),
            name: 'setMixTemp',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(12, 5828096454211460982),
            name: 'setHeadTemp',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(13, 6404583577823963796),
            name: 'setGroupPressure',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(14, 953787600600014188),
            name: 'setGroupFlow',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(15, 4614454596637650047),
            name: 'flowWeight',
            type: 8,
            flags: 0),
        ModelProperty(
            id: const IdUid(16, 8625810897882043509),
            name: 'frameNumber',
            type: 6,
            flags: 0),
        ModelProperty(
            id: const IdUid(17, 6151090906092388458),
            name: 'steamTemp',
            type: 6,
            flags: 0)
      ],
      relations: <ModelRelation>[],
      backlinks: <ModelBacklink>[])
];

/// Open an ObjectBox store with the model declared in this file.
Future<Store> openStore(
        {String? directory,
        int? maxDBSizeInKB,
        int? fileMode,
        int? maxReaders,
        bool queriesCaseSensitiveDefault = true,
        String? macosApplicationGroup}) async =>
    Store(getObjectBoxModel(),
        directory: directory ?? (await defaultStoreDirectory()).path,
        maxDBSizeInKB: maxDBSizeInKB,
        fileMode: fileMode,
        maxReaders: maxReaders,
        queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
        macosApplicationGroup: macosApplicationGroup);

/// ObjectBox model definition, pass it to [Store] - Store(getObjectBoxModel())
ModelDefinition getObjectBoxModel() {
  final model = ModelInfo(
      entities: _entities,
      lastEntityId: const IdUid(7, 7915358336460233027),
      lastIndexId: const IdUid(3, 6812967169057673456),
      lastRelationId: const IdUid(1, 2516218059471133212),
      lastSequenceId: const IdUid(0, 0),
      retiredEntityUids: const [
        2372411160892302204,
        5004946134676291479,
        6316057013526616538
      ],
      retiredIndexUids: const [],
      retiredPropertyUids: const [
        5255554628564942194,
        4168856612577632112,
        3658428756522006494,
        2013349328392287066,
        9166906492209766753,
        5231134079281534832,
        1727902073541153245,
        1222105438427089261,
        3645189919220185120,
        1883480049140865748,
        4649133190255639234,
        2790985158327310841,
        8906507704897213981,
        4326142425280702554,
        2470357611331815358,
        4175497157621930327,
        5263902387495551329,
        262288466734433874,
        6341762800821505123,
        6441265075855571922,
        7453959482162594558,
        4587334211713455012
      ],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, EntityDefinition>{
    Shot: EntityDefinition<Shot>(
        model: _entities[0],
        toOneRelations: (Shot object) => [object.coffee],
        toManyRelations: (Shot object) =>
            {RelInfo<Shot>.toMany(1, object.id): object.shotstates},
        getId: (Shot object) => object.id,
        setId: (Shot object, int id) {
          object.id = id;
        },
        objectToFB: (Shot object, fb.Builder fbb) {
          final profileIdOffset = fbb.writeString(object.profileId);
          fbb.startTable(7);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.date.millisecondsSinceEpoch);
          fbb.addInt64(2, object.coffee.targetId);
          fbb.addOffset(3, profileIdOffset);
          fbb.addFloat64(4, object.pourTime);
          fbb.addFloat64(5, object.pourWeight);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = Shot()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..date = DateTime.fromMillisecondsSinceEpoch(
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0))
            ..profileId = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..pourTime =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 12, 0)
            ..pourWeight =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 14, 0);
          object.coffee.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          object.coffee.attach(store);
          InternalToManyAccess.setRelInfo(object.shotstates, store,
              RelInfo<Shot>.toMany(1, object.id), store.box<Shot>());
          return object;
        }),
    Coffee: EntityDefinition<Coffee>(
        model: _entities[1],
        toOneRelations: (Coffee object) => [object.roaster],
        toManyRelations: (Coffee object) => {},
        getId: (Coffee object) => object.id,
        setId: (Coffee object, int id) {
          object.id = id;
        },
        objectToFB: (Coffee object, fb.Builder fbb) {
          final nameOffset = fbb.writeString(object.name);
          final imageURLOffset = fbb.writeString(object.imageURL);
          final descriptionOffset = fbb.writeString(object.description);
          final originOffset = fbb.writeString(object.origin);
          final priceOffset = fbb.writeString(object.price);
          fbb.startTable(14);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, nameOffset);
          fbb.addInt64(2, object.roaster.targetId);
          fbb.addOffset(3, imageURLOffset);
          fbb.addFloat64(4, object.grinderSettings);
          fbb.addFloat64(5, object.acidRating);
          fbb.addFloat64(6, object.intensityRating);
          fbb.addFloat64(7, object.roastLevel);
          fbb.addInt64(8, object.arabica);
          fbb.addInt64(9, object.robusta);
          fbb.addOffset(10, descriptionOffset);
          fbb.addOffset(11, originOffset);
          fbb.addOffset(12, priceOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = Coffee()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..name = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 6, '')
            ..imageURL = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..grinderSettings =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 12, 0)
            ..acidRating =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 14, 0)
            ..intensityRating =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 16, 0)
            ..roastLevel =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 18, 0)
            ..arabica =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 20, 0)
            ..robusta =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 22, 0)
            ..description = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 24, '')
            ..origin = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 26, '')
            ..price = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 28, '');
          object.roaster.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          object.roaster.attach(store);
          return object;
        }),
    Roaster: EntityDefinition<Roaster>(
        model: _entities[2],
        toOneRelations: (Roaster object) => [],
        toManyRelations: (Roaster object) => {
              RelInfo<Coffee>.toOneBacklink(
                      3, object.id, (Coffee srcObject) => srcObject.roaster):
                  object.coffees
            },
        getId: (Roaster object) => object.id,
        setId: (Roaster object, int id) {
          object.id = id;
        },
        objectToFB: (Roaster object, fb.Builder fbb) {
          final nameOffset = fbb.writeString(object.name);
          final imageURLOffset = fbb.writeString(object.imageURL);
          final descriptionOffset = fbb.writeString(object.description);
          final addressOffset = fbb.writeString(object.address);
          final homepageOffset = fbb.writeString(object.homepage);
          fbb.startTable(7);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, nameOffset);
          fbb.addOffset(2, imageURLOffset);
          fbb.addOffset(3, descriptionOffset);
          fbb.addOffset(4, addressOffset);
          fbb.addOffset(5, homepageOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = Roaster()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..name = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 6, '')
            ..imageURL = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 8, '')
            ..description = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..address = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 12, '')
            ..homepage = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 14, '');
          InternalToManyAccess.setRelInfo(
              object.coffees,
              store,
              RelInfo<Coffee>.toOneBacklink(
                  3, object.id, (Coffee srcObject) => srcObject.roaster),
              store.box<Roaster>());
          return object;
        }),
    ShotState: EntityDefinition<ShotState>(
        model: _entities[3],
        toOneRelations: (ShotState object) => [],
        toManyRelations: (ShotState object) => {},
        getId: (ShotState object) => object.id,
        setId: (ShotState object, int id) {
          object.id = id;
        },
        objectToFB: (ShotState object, fb.Builder fbb) {
          final subStateOffset = fbb.writeString(object.subState);
          fbb.startTable(18);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, subStateOffset);
          fbb.addFloat64(2, object.weight);
          fbb.addFloat64(3, object.sampleTime);
          fbb.addFloat64(4, object.sampleTimeCorrected);
          fbb.addFloat64(5, object.pourTime);
          fbb.addFloat64(6, object.groupPressure);
          fbb.addFloat64(7, object.groupFlow);
          fbb.addFloat64(8, object.mixTemp);
          fbb.addFloat64(9, object.headTemp);
          fbb.addFloat64(10, object.setMixTemp);
          fbb.addFloat64(11, object.setHeadTemp);
          fbb.addFloat64(12, object.setGroupPressure);
          fbb.addFloat64(13, object.setGroupFlow);
          fbb.addFloat64(14, object.flowWeight);
          fbb.addInt64(15, object.frameNumber);
          fbb.addInt64(16, object.steamTemp);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = ShotState(
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 10, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 12, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 16, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 18, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 20, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 22, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 24, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 26, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 28, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 30, 0),
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 34, 0),
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 36, 0),
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 8, 0),
              const fb.StringReader(asciiOptimization: true)
                  .vTableGet(buffer, rootOffset, 6, ''))
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..pourTime =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 14, 0)
            ..flowWeight =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 32, 0);

          return object;
        })
  };

  return ModelDefinition(model, bindings);
}

/// [Shot] entity fields to define ObjectBox queries.
class Shot_ {
  /// see [Shot.id]
  static final id = QueryIntegerProperty<Shot>(_entities[0].properties[0]);

  /// see [Shot.date]
  static final date = QueryIntegerProperty<Shot>(_entities[0].properties[1]);

  /// see [Shot.coffee]
  static final coffee =
      QueryRelationToOne<Shot, Coffee>(_entities[0].properties[2]);

  /// see [Shot.profileId]
  static final profileId =
      QueryStringProperty<Shot>(_entities[0].properties[3]);

  /// see [Shot.pourTime]
  static final pourTime = QueryDoubleProperty<Shot>(_entities[0].properties[4]);

  /// see [Shot.pourWeight]
  static final pourWeight =
      QueryDoubleProperty<Shot>(_entities[0].properties[5]);

  /// see [Shot.shotstates]
  static final shotstates =
      QueryRelationToMany<Shot, ShotState>(_entities[0].relations[0]);
}

/// [Coffee] entity fields to define ObjectBox queries.
class Coffee_ {
  /// see [Coffee.id]
  static final id = QueryIntegerProperty<Coffee>(_entities[1].properties[0]);

  /// see [Coffee.name]
  static final name = QueryStringProperty<Coffee>(_entities[1].properties[1]);

  /// see [Coffee.roaster]
  static final roaster =
      QueryRelationToOne<Coffee, Roaster>(_entities[1].properties[2]);

  /// see [Coffee.imageURL]
  static final imageURL =
      QueryStringProperty<Coffee>(_entities[1].properties[3]);

  /// see [Coffee.grinderSettings]
  static final grinderSettings =
      QueryDoubleProperty<Coffee>(_entities[1].properties[4]);

  /// see [Coffee.acidRating]
  static final acidRating =
      QueryDoubleProperty<Coffee>(_entities[1].properties[5]);

  /// see [Coffee.intensityRating]
  static final intensityRating =
      QueryDoubleProperty<Coffee>(_entities[1].properties[6]);

  /// see [Coffee.roastLevel]
  static final roastLevel =
      QueryDoubleProperty<Coffee>(_entities[1].properties[7]);

  /// see [Coffee.arabica]
  static final arabica =
      QueryIntegerProperty<Coffee>(_entities[1].properties[8]);

  /// see [Coffee.robusta]
  static final robusta =
      QueryIntegerProperty<Coffee>(_entities[1].properties[9]);

  /// see [Coffee.description]
  static final description =
      QueryStringProperty<Coffee>(_entities[1].properties[10]);

  /// see [Coffee.origin]
  static final origin =
      QueryStringProperty<Coffee>(_entities[1].properties[11]);

  /// see [Coffee.price]
  static final price = QueryStringProperty<Coffee>(_entities[1].properties[12]);
}

/// [Roaster] entity fields to define ObjectBox queries.
class Roaster_ {
  /// see [Roaster.id]
  static final id = QueryIntegerProperty<Roaster>(_entities[2].properties[0]);

  /// see [Roaster.name]
  static final name = QueryStringProperty<Roaster>(_entities[2].properties[1]);

  /// see [Roaster.imageURL]
  static final imageURL =
      QueryStringProperty<Roaster>(_entities[2].properties[2]);

  /// see [Roaster.description]
  static final description =
      QueryStringProperty<Roaster>(_entities[2].properties[3]);

  /// see [Roaster.address]
  static final address =
      QueryStringProperty<Roaster>(_entities[2].properties[4]);

  /// see [Roaster.homepage]
  static final homepage =
      QueryStringProperty<Roaster>(_entities[2].properties[5]);
}

/// [ShotState] entity fields to define ObjectBox queries.
class ShotState_ {
  /// see [ShotState.id]
  static final id = QueryIntegerProperty<ShotState>(_entities[3].properties[0]);

  /// see [ShotState.subState]
  static final subState =
      QueryStringProperty<ShotState>(_entities[3].properties[1]);

  /// see [ShotState.weight]
  static final weight =
      QueryDoubleProperty<ShotState>(_entities[3].properties[2]);

  /// see [ShotState.sampleTime]
  static final sampleTime =
      QueryDoubleProperty<ShotState>(_entities[3].properties[3]);

  /// see [ShotState.sampleTimeCorrected]
  static final sampleTimeCorrected =
      QueryDoubleProperty<ShotState>(_entities[3].properties[4]);

  /// see [ShotState.pourTime]
  static final pourTime =
      QueryDoubleProperty<ShotState>(_entities[3].properties[5]);

  /// see [ShotState.groupPressure]
  static final groupPressure =
      QueryDoubleProperty<ShotState>(_entities[3].properties[6]);

  /// see [ShotState.groupFlow]
  static final groupFlow =
      QueryDoubleProperty<ShotState>(_entities[3].properties[7]);

  /// see [ShotState.mixTemp]
  static final mixTemp =
      QueryDoubleProperty<ShotState>(_entities[3].properties[8]);

  /// see [ShotState.headTemp]
  static final headTemp =
      QueryDoubleProperty<ShotState>(_entities[3].properties[9]);

  /// see [ShotState.setMixTemp]
  static final setMixTemp =
      QueryDoubleProperty<ShotState>(_entities[3].properties[10]);

  /// see [ShotState.setHeadTemp]
  static final setHeadTemp =
      QueryDoubleProperty<ShotState>(_entities[3].properties[11]);

  /// see [ShotState.setGroupPressure]
  static final setGroupPressure =
      QueryDoubleProperty<ShotState>(_entities[3].properties[12]);

  /// see [ShotState.setGroupFlow]
  static final setGroupFlow =
      QueryDoubleProperty<ShotState>(_entities[3].properties[13]);

  /// see [ShotState.flowWeight]
  static final flowWeight =
      QueryDoubleProperty<ShotState>(_entities[3].properties[14]);

  /// see [ShotState.frameNumber]
  static final frameNumber =
      QueryIntegerProperty<ShotState>(_entities[3].properties[15]);

  /// see [ShotState.steamTemp]
  static final steamTemp =
      QueryIntegerProperty<ShotState>(_entities[3].properties[16]);
}