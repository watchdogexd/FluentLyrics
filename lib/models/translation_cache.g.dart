// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTranslationCacheCollection on Isar {
  IsarCollection<TranslationCache> get translationCaches => this.collection();
}

const TranslationCacheSchema = CollectionSchema(
  name: r'TranslationCache',
  id: 6214070051513875310,
  properties: {
    r'cacheId': PropertySchema(
      id: 0,
      name: r'cacheId',
      type: IsarType.string,
    ),
    r'language': PropertySchema(
      id: 1,
      name: r'language',
      type: IsarType.string,
    ),
    r'lyrics': PropertySchema(
      id: 2,
      name: r'lyrics',
      type: IsarType.objectList,
      target: r'TranslationItem',
    ),
    r'rawTranslation': PropertySchema(
      id: 3,
      name: r'rawTranslation',
      type: IsarType.objectList,
      target: r'RawTranslationPair',
    ),
    r'source': PropertySchema(
      id: 4,
      name: r'source',
      type: IsarType.string,
    ),
    r'translationContributor': PropertySchema(
      id: 5,
      name: r'translationContributor',
      type: IsarType.string,
    ),
    r'translationProvider': PropertySchema(
      id: 6,
      name: r'translationProvider',
      type: IsarType.string,
    )
  },
  estimateSize: _translationCacheEstimateSize,
  serialize: _translationCacheSerialize,
  deserialize: _translationCacheDeserialize,
  deserializeProp: _translationCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'cacheId': IndexSchema(
      id: -7372113173438779531,
      name: r'cacheId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'cacheId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'TranslationItem': TranslationItemSchema,
    r'RawTranslationPair': RawTranslationPairSchema
  },
  getId: _translationCacheGetId,
  getLinks: _translationCacheGetLinks,
  attach: _translationCacheAttach,
  version: '3.1.0+1',
);

int _translationCacheEstimateSize(
  TranslationCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cacheId.length * 3;
  bytesCount += 3 + object.language.length * 3;
  bytesCount += 3 + object.lyrics.length * 3;
  {
    final offsets = allOffsets[TranslationItem]!;
    for (var i = 0; i < object.lyrics.length; i++) {
      final value = object.lyrics[i];
      bytesCount +=
          TranslationItemSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final list = object.rawTranslation;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[RawTranslationPair]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              RawTranslationPairSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.source.length * 3;
  {
    final value = object.translationContributor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.translationProvider.length * 3;
  return bytesCount;
}

void _translationCacheSerialize(
  TranslationCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cacheId);
  writer.writeString(offsets[1], object.language);
  writer.writeObjectList<TranslationItem>(
    offsets[2],
    allOffsets,
    TranslationItemSchema.serialize,
    object.lyrics,
  );
  writer.writeObjectList<RawTranslationPair>(
    offsets[3],
    allOffsets,
    RawTranslationPairSchema.serialize,
    object.rawTranslation,
  );
  writer.writeString(offsets[4], object.source);
  writer.writeString(offsets[5], object.translationContributor);
  writer.writeString(offsets[6], object.translationProvider);
}

TranslationCache _translationCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TranslationCache();
  object.cacheId = reader.readString(offsets[0]);
  object.id = id;
  object.language = reader.readString(offsets[1]);
  object.lyrics = reader.readObjectList<TranslationItem>(
        offsets[2],
        TranslationItemSchema.deserialize,
        allOffsets,
        TranslationItem(),
      ) ??
      [];
  object.rawTranslation = reader.readObjectList<RawTranslationPair>(
    offsets[3],
    RawTranslationPairSchema.deserialize,
    allOffsets,
    RawTranslationPair(),
  );
  object.source = reader.readString(offsets[4]);
  object.translationContributor = reader.readStringOrNull(offsets[5]);
  object.translationProvider = reader.readString(offsets[6]);
  return object;
}

P _translationCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readObjectList<TranslationItem>(
            offset,
            TranslationItemSchema.deserialize,
            allOffsets,
            TranslationItem(),
          ) ??
          []) as P;
    case 3:
      return (reader.readObjectList<RawTranslationPair>(
        offset,
        RawTranslationPairSchema.deserialize,
        allOffsets,
        RawTranslationPair(),
      )) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _translationCacheGetId(TranslationCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _translationCacheGetLinks(TranslationCache object) {
  return [];
}

void _translationCacheAttach(
    IsarCollection<dynamic> col, Id id, TranslationCache object) {
  object.id = id;
}

extension TranslationCacheByIndex on IsarCollection<TranslationCache> {
  Future<TranslationCache?> getByCacheId(String cacheId) {
    return getByIndex(r'cacheId', [cacheId]);
  }

  TranslationCache? getByCacheIdSync(String cacheId) {
    return getByIndexSync(r'cacheId', [cacheId]);
  }

  Future<bool> deleteByCacheId(String cacheId) {
    return deleteByIndex(r'cacheId', [cacheId]);
  }

  bool deleteByCacheIdSync(String cacheId) {
    return deleteByIndexSync(r'cacheId', [cacheId]);
  }

  Future<List<TranslationCache?>> getAllByCacheId(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'cacheId', values);
  }

  List<TranslationCache?> getAllByCacheIdSync(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'cacheId', values);
  }

  Future<int> deleteAllByCacheId(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'cacheId', values);
  }

  int deleteAllByCacheIdSync(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'cacheId', values);
  }

  Future<Id> putByCacheId(TranslationCache object) {
    return putByIndex(r'cacheId', object);
  }

  Id putByCacheIdSync(TranslationCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'cacheId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCacheId(List<TranslationCache> objects) {
    return putAllByIndex(r'cacheId', objects);
  }

  List<Id> putAllByCacheIdSync(List<TranslationCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'cacheId', objects, saveLinks: saveLinks);
  }
}

extension TranslationCacheQueryWhereSort
    on QueryBuilder<TranslationCache, TranslationCache, QWhere> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TranslationCacheQueryWhere
    on QueryBuilder<TranslationCache, TranslationCache, QWhereClause> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
      cacheIdEqualTo(String cacheId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cacheId',
        value: [cacheId],
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
      cacheIdNotEqualTo(String cacheId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [],
              upper: [cacheId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [cacheId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [cacheId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [],
              upper: [cacheId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TranslationCacheQueryFilter
    on QueryBuilder<TranslationCache, TranslationCache, QFilterCondition> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cacheId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cacheId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheId',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      cacheIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cacheId',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'language',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'language',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      languageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      lyricsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      lyricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      lyricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      lyricsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      lyricsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      lyricsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rawTranslation',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rawTranslation',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rawTranslation',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rawTranslation',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rawTranslation',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rawTranslation',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rawTranslation',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rawTranslation',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'translationContributor',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'translationContributor',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translationContributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'translationContributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'translationContributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'translationContributor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'translationContributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'translationContributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'translationContributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'translationContributor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translationContributor',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationContributorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'translationContributor',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translationProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'translationProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'translationProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'translationProvider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'translationProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'translationProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'translationProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'translationProvider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translationProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      translationProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'translationProvider',
        value: '',
      ));
    });
  }
}

extension TranslationCacheQueryObject
    on QueryBuilder<TranslationCache, TranslationCache, QFilterCondition> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      lyricsElement(FilterQuery<TranslationItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'lyrics');
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
      rawTranslationElement(FilterQuery<RawTranslationPair> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'rawTranslation');
    });
  }
}

extension TranslationCacheQueryLinks
    on QueryBuilder<TranslationCache, TranslationCache, QFilterCondition> {}

extension TranslationCacheQuerySortBy
    on QueryBuilder<TranslationCache, TranslationCache, QSortBy> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByCacheId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByCacheIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByTranslationContributor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByTranslationContributorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByTranslationProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      sortByTranslationProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.desc);
    });
  }
}

extension TranslationCacheQuerySortThenBy
    on QueryBuilder<TranslationCache, TranslationCache, QSortThenBy> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByCacheId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByCacheIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByTranslationContributor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByTranslationContributorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByTranslationProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
      thenByTranslationProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.desc);
    });
  }
}

extension TranslationCacheQueryWhereDistinct
    on QueryBuilder<TranslationCache, TranslationCache, QDistinct> {
  QueryBuilder<TranslationCache, TranslationCache, QDistinct> distinctByCacheId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
      distinctByLanguage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'language', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
      distinctByTranslationContributor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'translationContributor',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
      distinctByTranslationProvider({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'translationProvider',
          caseSensitive: caseSensitive);
    });
  }
}

extension TranslationCacheQueryProperty
    on QueryBuilder<TranslationCache, TranslationCache, QQueryProperty> {
  QueryBuilder<TranslationCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations> cacheIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheId');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations> languageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'language');
    });
  }

  QueryBuilder<TranslationCache, List<TranslationItem>, QQueryOperations>
      lyricsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lyrics');
    });
  }

  QueryBuilder<TranslationCache, List<RawTranslationPair>?, QQueryOperations>
      rawTranslationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawTranslation');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<TranslationCache, String?, QQueryOperations>
      translationContributorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translationContributor');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations>
      translationProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translationProvider');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const RawTranslationPairSchema = Schema(
  name: r'RawTranslationPair',
  id: -2519904812350907104,
  properties: {
    r'original': PropertySchema(
      id: 0,
      name: r'original',
      type: IsarType.string,
    ),
    r'translated': PropertySchema(
      id: 1,
      name: r'translated',
      type: IsarType.string,
    )
  },
  estimateSize: _rawTranslationPairEstimateSize,
  serialize: _rawTranslationPairSerialize,
  deserialize: _rawTranslationPairDeserialize,
  deserializeProp: _rawTranslationPairDeserializeProp,
);

int _rawTranslationPairEstimateSize(
  RawTranslationPair object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.original;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.translated;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _rawTranslationPairSerialize(
  RawTranslationPair object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.original);
  writer.writeString(offsets[1], object.translated);
}

RawTranslationPair _rawTranslationPairDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RawTranslationPair();
  object.original = reader.readStringOrNull(offsets[0]);
  object.translated = reader.readStringOrNull(offsets[1]);
  return object;
}

P _rawTranslationPairDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension RawTranslationPairQueryFilter
    on QueryBuilder<RawTranslationPair, RawTranslationPair, QFilterCondition> {
  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'original',
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'original',
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'original',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'original',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'original',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'original',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'original',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'original',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'original',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'original',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'original',
        value: '',
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      originalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'original',
        value: '',
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'translated',
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'translated',
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'translated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'translated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'translated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'translated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'translated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'translated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'translated',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translated',
        value: '',
      ));
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
      translatedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'translated',
        value: '',
      ));
    });
  }
}

extension RawTranslationPairQueryObject
    on QueryBuilder<RawTranslationPair, RawTranslationPair, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TranslationItemSchema = Schema(
  name: r'TranslationItem',
  id: -7238149442883127455,
  properties: {
    r'endTimeMs': PropertySchema(
      id: 0,
      name: r'endTimeMs',
      type: IsarType.long,
    ),
    r'startTimeMs': PropertySchema(
      id: 1,
      name: r'startTimeMs',
      type: IsarType.long,
    ),
    r'text': PropertySchema(
      id: 2,
      name: r'text',
      type: IsarType.string,
    )
  },
  estimateSize: _translationItemEstimateSize,
  serialize: _translationItemSerialize,
  deserialize: _translationItemDeserialize,
  deserializeProp: _translationItemDeserializeProp,
);

int _translationItemEstimateSize(
  TranslationItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _translationItemSerialize(
  TranslationItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endTimeMs);
  writer.writeLong(offsets[1], object.startTimeMs);
  writer.writeString(offsets[2], object.text);
}

TranslationItem _translationItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TranslationItem();
  object.endTimeMs = reader.readLongOrNull(offsets[0]);
  object.startTimeMs = reader.readLong(offsets[1]);
  object.text = reader.readString(offsets[2]);
  return object;
}

P _translationItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TranslationItemQueryFilter
    on QueryBuilder<TranslationItem, TranslationItem, QFilterCondition> {
  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      endTimeMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTimeMs',
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      endTimeMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTimeMs',
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      endTimeMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      endTimeMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      endTimeMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      endTimeMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTimeMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      startTimeMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      startTimeMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      startTimeMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      startTimeMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTimeMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
      textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }
}

extension TranslationItemQueryObject
    on QueryBuilder<TranslationItem, TranslationItem, QFilterCondition> {}
