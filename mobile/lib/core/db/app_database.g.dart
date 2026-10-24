// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CatalogMetaTable extends CatalogMeta
    with TableInfo<$CatalogMetaTable, CatalogMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datasetVersionMeta = const VerificationMeta(
    'datasetVersion',
  );
  @override
  late final GeneratedColumn<String> datasetVersion = GeneratedColumn<String>(
    'dataset_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealCountMeta = const VerificationMeta(
    'mealCount',
  );
  @override
  late final GeneratedColumn<int> mealCount = GeneratedColumn<int>(
    'meal_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lang,
    etag,
    datasetVersion,
    mealCount,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    } else if (isInserting) {
      context.missing(_etagMeta);
    }
    if (data.containsKey('dataset_version')) {
      context.handle(
        _datasetVersionMeta,
        datasetVersion.isAcceptableOrUnknown(
          data['dataset_version']!,
          _datasetVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_datasetVersionMeta);
    }
    if (data.containsKey('meal_count')) {
      context.handle(
        _mealCountMeta,
        mealCount.isAcceptableOrUnknown(data['meal_count']!, _mealCountMeta),
      );
    } else if (isInserting) {
      context.missing(_mealCountMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang};
  @override
  CatalogMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogMetaData(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      )!,
      datasetVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_version'],
      )!,
      mealCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_count'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CatalogMetaTable createAlias(String alias) {
    return $CatalogMetaTable(attachedDatabase, alias);
  }
}

class CatalogMetaData extends DataClass implements Insertable<CatalogMetaData> {
  final String lang;
  final String etag;
  final String datasetVersion;
  final int mealCount;
  final DateTime fetchedAt;
  const CatalogMetaData({
    required this.lang,
    required this.etag,
    required this.datasetVersion,
    required this.mealCount,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['etag'] = Variable<String>(etag);
    map['dataset_version'] = Variable<String>(datasetVersion);
    map['meal_count'] = Variable<int>(mealCount);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CatalogMetaCompanion toCompanion(bool nullToAbsent) {
    return CatalogMetaCompanion(
      lang: Value(lang),
      etag: Value(etag),
      datasetVersion: Value(datasetVersion),
      mealCount: Value(mealCount),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CatalogMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogMetaData(
      lang: serializer.fromJson<String>(json['lang']),
      etag: serializer.fromJson<String>(json['etag']),
      datasetVersion: serializer.fromJson<String>(json['datasetVersion']),
      mealCount: serializer.fromJson<int>(json['mealCount']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'etag': serializer.toJson<String>(etag),
      'datasetVersion': serializer.toJson<String>(datasetVersion),
      'mealCount': serializer.toJson<int>(mealCount),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CatalogMetaData copyWith({
    String? lang,
    String? etag,
    String? datasetVersion,
    int? mealCount,
    DateTime? fetchedAt,
  }) => CatalogMetaData(
    lang: lang ?? this.lang,
    etag: etag ?? this.etag,
    datasetVersion: datasetVersion ?? this.datasetVersion,
    mealCount: mealCount ?? this.mealCount,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CatalogMetaData copyWithCompanion(CatalogMetaCompanion data) {
    return CatalogMetaData(
      lang: data.lang.present ? data.lang.value : this.lang,
      etag: data.etag.present ? data.etag.value : this.etag,
      datasetVersion: data.datasetVersion.present
          ? data.datasetVersion.value
          : this.datasetVersion,
      mealCount: data.mealCount.present ? data.mealCount.value : this.mealCount,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogMetaData(')
          ..write('lang: $lang, ')
          ..write('etag: $etag, ')
          ..write('datasetVersion: $datasetVersion, ')
          ..write('mealCount: $mealCount, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(lang, etag, datasetVersion, mealCount, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogMetaData &&
          other.lang == this.lang &&
          other.etag == this.etag &&
          other.datasetVersion == this.datasetVersion &&
          other.mealCount == this.mealCount &&
          other.fetchedAt == this.fetchedAt);
}

class CatalogMetaCompanion extends UpdateCompanion<CatalogMetaData> {
  final Value<String> lang;
  final Value<String> etag;
  final Value<String> datasetVersion;
  final Value<int> mealCount;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CatalogMetaCompanion({
    this.lang = const Value.absent(),
    this.etag = const Value.absent(),
    this.datasetVersion = const Value.absent(),
    this.mealCount = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogMetaCompanion.insert({
    required String lang,
    required String etag,
    required String datasetVersion,
    required int mealCount,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       etag = Value(etag),
       datasetVersion = Value(datasetVersion),
       mealCount = Value(mealCount),
       fetchedAt = Value(fetchedAt);
  static Insertable<CatalogMetaData> custom({
    Expression<String>? lang,
    Expression<String>? etag,
    Expression<String>? datasetVersion,
    Expression<int>? mealCount,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (etag != null) 'etag': etag,
      if (datasetVersion != null) 'dataset_version': datasetVersion,
      if (mealCount != null) 'meal_count': mealCount,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogMetaCompanion copyWith({
    Value<String>? lang,
    Value<String>? etag,
    Value<String>? datasetVersion,
    Value<int>? mealCount,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CatalogMetaCompanion(
      lang: lang ?? this.lang,
      etag: etag ?? this.etag,
      datasetVersion: datasetVersion ?? this.datasetVersion,
      mealCount: mealCount ?? this.mealCount,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (datasetVersion.present) {
      map['dataset_version'] = Variable<String>(datasetVersion.value);
    }
    if (mealCount.present) {
      map['meal_count'] = Variable<int>(mealCount.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogMetaCompanion(')
          ..write('lang: $lang, ')
          ..write('etag: $etag, ')
          ..write('datasetVersion: $datasetVersion, ')
          ..write('mealCount: $mealCount, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchKeyMeta = const VerificationMeta(
    'searchKey',
  );
  @override
  late final GeneratedColumn<String> searchKey = GeneratedColumn<String>(
    'search_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuisineMeta = const VerificationMeta(
    'cuisine',
  );
  @override
  late final GeneratedColumn<String> cuisine = GeneratedColumn<String>(
    'cuisine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dishFormMeta = const VerificationMeta(
    'dishForm',
  );
  @override
  late final GeneratedColumn<String> dishForm = GeneratedColumn<String>(
    'dish_form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingGramsMeta = const VerificationMeta(
    'servingGrams',
  );
  @override
  late final GeneratedColumn<double> servingGrams = GeneratedColumn<double>(
    'serving_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalGramsMeta = const VerificationMeta(
    'totalGrams',
  );
  @override
  late final GeneratedColumn<double> totalGrams = GeneratedColumn<double>(
    'total_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
    'carb_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datasetVersionMeta = const VerificationMeta(
    'datasetVersion',
  );
  @override
  late final GeneratedColumn<String> datasetVersion = GeneratedColumn<String>(
    'dataset_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lang,
    mealId,
    name,
    searchKey,
    cuisine,
    dishForm,
    servingGrams,
    servings,
    totalGrams,
    kcal,
    proteinG,
    carbG,
    fatG,
    source,
    datasetVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Meal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('search_key')) {
      context.handle(
        _searchKeyMeta,
        searchKey.isAcceptableOrUnknown(data['search_key']!, _searchKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_searchKeyMeta);
    }
    if (data.containsKey('cuisine')) {
      context.handle(
        _cuisineMeta,
        cuisine.isAcceptableOrUnknown(data['cuisine']!, _cuisineMeta),
      );
    }
    if (data.containsKey('dish_form')) {
      context.handle(
        _dishFormMeta,
        dishForm.isAcceptableOrUnknown(data['dish_form']!, _dishFormMeta),
      );
    }
    if (data.containsKey('serving_grams')) {
      context.handle(
        _servingGramsMeta,
        servingGrams.isAcceptableOrUnknown(
          data['serving_grams']!,
          _servingGramsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servingGramsMeta);
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    } else if (isInserting) {
      context.missing(_servingsMeta);
    }
    if (data.containsKey('total_grams')) {
      context.handle(
        _totalGramsMeta,
        totalGrams.isAcceptableOrUnknown(data['total_grams']!, _totalGramsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalGramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carb_g')) {
      context.handle(
        _carbGMeta,
        carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('dataset_version')) {
      context.handle(
        _datasetVersionMeta,
        datasetVersion.isAcceptableOrUnknown(
          data['dataset_version']!,
          _datasetVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_datasetVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang, mealId};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      searchKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_key'],
      )!,
      cuisine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuisine'],
      ),
      dishForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dish_form'],
      ),
      servingGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_grams'],
      )!,
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      )!,
      totalGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_grams'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      datasetVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_version'],
      )!,
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final String lang;
  final int mealId;
  final String name;
  final String searchKey;
  final String? cuisine;
  final String? dishForm;
  final double servingGrams;
  final int servings;
  final double totalGrams;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String source;
  final String datasetVersion;
  const Meal({
    required this.lang,
    required this.mealId,
    required this.name,
    required this.searchKey,
    this.cuisine,
    this.dishForm,
    required this.servingGrams,
    required this.servings,
    required this.totalGrams,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.source,
    required this.datasetVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['meal_id'] = Variable<int>(mealId);
    map['name'] = Variable<String>(name);
    map['search_key'] = Variable<String>(searchKey);
    if (!nullToAbsent || cuisine != null) {
      map['cuisine'] = Variable<String>(cuisine);
    }
    if (!nullToAbsent || dishForm != null) {
      map['dish_form'] = Variable<String>(dishForm);
    }
    map['serving_grams'] = Variable<double>(servingGrams);
    map['servings'] = Variable<int>(servings);
    map['total_grams'] = Variable<double>(totalGrams);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carb_g'] = Variable<double>(carbG);
    map['fat_g'] = Variable<double>(fatG);
    map['source'] = Variable<String>(source);
    map['dataset_version'] = Variable<String>(datasetVersion);
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      lang: Value(lang),
      mealId: Value(mealId),
      name: Value(name),
      searchKey: Value(searchKey),
      cuisine: cuisine == null && nullToAbsent
          ? const Value.absent()
          : Value(cuisine),
      dishForm: dishForm == null && nullToAbsent
          ? const Value.absent()
          : Value(dishForm),
      servingGrams: Value(servingGrams),
      servings: Value(servings),
      totalGrams: Value(totalGrams),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbG: Value(carbG),
      fatG: Value(fatG),
      source: Value(source),
      datasetVersion: Value(datasetVersion),
    );
  }

  factory Meal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      lang: serializer.fromJson<String>(json['lang']),
      mealId: serializer.fromJson<int>(json['mealId']),
      name: serializer.fromJson<String>(json['name']),
      searchKey: serializer.fromJson<String>(json['searchKey']),
      cuisine: serializer.fromJson<String?>(json['cuisine']),
      dishForm: serializer.fromJson<String?>(json['dishForm']),
      servingGrams: serializer.fromJson<double>(json['servingGrams']),
      servings: serializer.fromJson<int>(json['servings']),
      totalGrams: serializer.fromJson<double>(json['totalGrams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbG: serializer.fromJson<double>(json['carbG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      source: serializer.fromJson<String>(json['source']),
      datasetVersion: serializer.fromJson<String>(json['datasetVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'mealId': serializer.toJson<int>(mealId),
      'name': serializer.toJson<String>(name),
      'searchKey': serializer.toJson<String>(searchKey),
      'cuisine': serializer.toJson<String?>(cuisine),
      'dishForm': serializer.toJson<String?>(dishForm),
      'servingGrams': serializer.toJson<double>(servingGrams),
      'servings': serializer.toJson<int>(servings),
      'totalGrams': serializer.toJson<double>(totalGrams),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbG': serializer.toJson<double>(carbG),
      'fatG': serializer.toJson<double>(fatG),
      'source': serializer.toJson<String>(source),
      'datasetVersion': serializer.toJson<String>(datasetVersion),
    };
  }

  Meal copyWith({
    String? lang,
    int? mealId,
    String? name,
    String? searchKey,
    Value<String?> cuisine = const Value.absent(),
    Value<String?> dishForm = const Value.absent(),
    double? servingGrams,
    int? servings,
    double? totalGrams,
    double? kcal,
    double? proteinG,
    double? carbG,
    double? fatG,
    String? source,
    String? datasetVersion,
  }) => Meal(
    lang: lang ?? this.lang,
    mealId: mealId ?? this.mealId,
    name: name ?? this.name,
    searchKey: searchKey ?? this.searchKey,
    cuisine: cuisine.present ? cuisine.value : this.cuisine,
    dishForm: dishForm.present ? dishForm.value : this.dishForm,
    servingGrams: servingGrams ?? this.servingGrams,
    servings: servings ?? this.servings,
    totalGrams: totalGrams ?? this.totalGrams,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbG: carbG ?? this.carbG,
    fatG: fatG ?? this.fatG,
    source: source ?? this.source,
    datasetVersion: datasetVersion ?? this.datasetVersion,
  );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      lang: data.lang.present ? data.lang.value : this.lang,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      name: data.name.present ? data.name.value : this.name,
      searchKey: data.searchKey.present ? data.searchKey.value : this.searchKey,
      cuisine: data.cuisine.present ? data.cuisine.value : this.cuisine,
      dishForm: data.dishForm.present ? data.dishForm.value : this.dishForm,
      servingGrams: data.servingGrams.present
          ? data.servingGrams.value
          : this.servingGrams,
      servings: data.servings.present ? data.servings.value : this.servings,
      totalGrams: data.totalGrams.present
          ? data.totalGrams.value
          : this.totalGrams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      source: data.source.present ? data.source.value : this.source,
      datasetVersion: data.datasetVersion.present
          ? data.datasetVersion.value
          : this.datasetVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('name: $name, ')
          ..write('searchKey: $searchKey, ')
          ..write('cuisine: $cuisine, ')
          ..write('dishForm: $dishForm, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('servings: $servings, ')
          ..write('totalGrams: $totalGrams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('source: $source, ')
          ..write('datasetVersion: $datasetVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lang,
    mealId,
    name,
    searchKey,
    cuisine,
    dishForm,
    servingGrams,
    servings,
    totalGrams,
    kcal,
    proteinG,
    carbG,
    fatG,
    source,
    datasetVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.lang == this.lang &&
          other.mealId == this.mealId &&
          other.name == this.name &&
          other.searchKey == this.searchKey &&
          other.cuisine == this.cuisine &&
          other.dishForm == this.dishForm &&
          other.servingGrams == this.servingGrams &&
          other.servings == this.servings &&
          other.totalGrams == this.totalGrams &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.source == this.source &&
          other.datasetVersion == this.datasetVersion);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<String> lang;
  final Value<int> mealId;
  final Value<String> name;
  final Value<String> searchKey;
  final Value<String?> cuisine;
  final Value<String?> dishForm;
  final Value<double> servingGrams;
  final Value<int> servings;
  final Value<double> totalGrams;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbG;
  final Value<double> fatG;
  final Value<String> source;
  final Value<String> datasetVersion;
  final Value<int> rowid;
  const MealsCompanion({
    this.lang = const Value.absent(),
    this.mealId = const Value.absent(),
    this.name = const Value.absent(),
    this.searchKey = const Value.absent(),
    this.cuisine = const Value.absent(),
    this.dishForm = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.servings = const Value.absent(),
    this.totalGrams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.source = const Value.absent(),
    this.datasetVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealsCompanion.insert({
    required String lang,
    required int mealId,
    required String name,
    required String searchKey,
    this.cuisine = const Value.absent(),
    this.dishForm = const Value.absent(),
    required double servingGrams,
    required int servings,
    required double totalGrams,
    required double kcal,
    required double proteinG,
    required double carbG,
    required double fatG,
    required String source,
    required String datasetVersion,
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       mealId = Value(mealId),
       name = Value(name),
       searchKey = Value(searchKey),
       servingGrams = Value(servingGrams),
       servings = Value(servings),
       totalGrams = Value(totalGrams),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbG = Value(carbG),
       fatG = Value(fatG),
       source = Value(source),
       datasetVersion = Value(datasetVersion);
  static Insertable<Meal> custom({
    Expression<String>? lang,
    Expression<int>? mealId,
    Expression<String>? name,
    Expression<String>? searchKey,
    Expression<String>? cuisine,
    Expression<String>? dishForm,
    Expression<double>? servingGrams,
    Expression<int>? servings,
    Expression<double>? totalGrams,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<String>? source,
    Expression<String>? datasetVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (mealId != null) 'meal_id': mealId,
      if (name != null) 'name': name,
      if (searchKey != null) 'search_key': searchKey,
      if (cuisine != null) 'cuisine': cuisine,
      if (dishForm != null) 'dish_form': dishForm,
      if (servingGrams != null) 'serving_grams': servingGrams,
      if (servings != null) 'servings': servings,
      if (totalGrams != null) 'total_grams': totalGrams,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (source != null) 'source': source,
      if (datasetVersion != null) 'dataset_version': datasetVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealsCompanion copyWith({
    Value<String>? lang,
    Value<int>? mealId,
    Value<String>? name,
    Value<String>? searchKey,
    Value<String?>? cuisine,
    Value<String?>? dishForm,
    Value<double>? servingGrams,
    Value<int>? servings,
    Value<double>? totalGrams,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbG,
    Value<double>? fatG,
    Value<String>? source,
    Value<String>? datasetVersion,
    Value<int>? rowid,
  }) {
    return MealsCompanion(
      lang: lang ?? this.lang,
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      searchKey: searchKey ?? this.searchKey,
      cuisine: cuisine ?? this.cuisine,
      dishForm: dishForm ?? this.dishForm,
      servingGrams: servingGrams ?? this.servingGrams,
      servings: servings ?? this.servings,
      totalGrams: totalGrams ?? this.totalGrams,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      source: source ?? this.source,
      datasetVersion: datasetVersion ?? this.datasetVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (searchKey.present) {
      map['search_key'] = Variable<String>(searchKey.value);
    }
    if (cuisine.present) {
      map['cuisine'] = Variable<String>(cuisine.value);
    }
    if (dishForm.present) {
      map['dish_form'] = Variable<String>(dishForm.value);
    }
    if (servingGrams.present) {
      map['serving_grams'] = Variable<double>(servingGrams.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (totalGrams.present) {
      map['total_grams'] = Variable<double>(totalGrams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (datasetVersion.present) {
      map['dataset_version'] = Variable<String>(datasetVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('name: $name, ')
          ..write('searchKey: $searchKey, ')
          ..write('cuisine: $cuisine, ')
          ..write('dishForm: $dishForm, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('servings: $servings, ')
          ..write('totalGrams: $totalGrams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('source: $source, ')
          ..write('datasetVersion: $datasetVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealTagsTable extends MealTags with TableInfo<$MealTagsTable, MealTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lang, mealId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang, mealId, tag};
  @override
  MealTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTag(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $MealTagsTable createAlias(String alias) {
    return $MealTagsTable(attachedDatabase, alias);
  }
}

class MealTag extends DataClass implements Insertable<MealTag> {
  final String lang;
  final int mealId;
  final String tag;
  const MealTag({required this.lang, required this.mealId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['meal_id'] = Variable<int>(mealId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  MealTagsCompanion toCompanion(bool nullToAbsent) {
    return MealTagsCompanion(
      lang: Value(lang),
      mealId: Value(mealId),
      tag: Value(tag),
    );
  }

  factory MealTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTag(
      lang: serializer.fromJson<String>(json['lang']),
      mealId: serializer.fromJson<int>(json['mealId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'mealId': serializer.toJson<int>(mealId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  MealTag copyWith({String? lang, int? mealId, String? tag}) => MealTag(
    lang: lang ?? this.lang,
    mealId: mealId ?? this.mealId,
    tag: tag ?? this.tag,
  );
  MealTag copyWithCompanion(MealTagsCompanion data) {
    return MealTag(
      lang: data.lang.present ? data.lang.value : this.lang,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTag(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lang, mealId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTag &&
          other.lang == this.lang &&
          other.mealId == this.mealId &&
          other.tag == this.tag);
}

class MealTagsCompanion extends UpdateCompanion<MealTag> {
  final Value<String> lang;
  final Value<int> mealId;
  final Value<String> tag;
  final Value<int> rowid;
  const MealTagsCompanion({
    this.lang = const Value.absent(),
    this.mealId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealTagsCompanion.insert({
    required String lang,
    required int mealId,
    required String tag,
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       mealId = Value(mealId),
       tag = Value(tag);
  static Insertable<MealTag> custom({
    Expression<String>? lang,
    Expression<int>? mealId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (mealId != null) 'meal_id': mealId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealTagsCompanion copyWith({
    Value<String>? lang,
    Value<int>? mealId,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return MealTagsCompanion(
      lang: lang ?? this.lang,
      mealId: mealId ?? this.mealId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealTagsCompanion(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealAllergensTable extends MealAllergens
    with TableInfo<$MealAllergensTable, MealAllergen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealAllergensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lang, mealId, code];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_allergens';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealAllergen> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang, mealId, code};
  @override
  MealAllergen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealAllergen(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
    );
  }

  @override
  $MealAllergensTable createAlias(String alias) {
    return $MealAllergensTable(attachedDatabase, alias);
  }
}

class MealAllergen extends DataClass implements Insertable<MealAllergen> {
  final String lang;
  final int mealId;
  final String code;
  const MealAllergen({
    required this.lang,
    required this.mealId,
    required this.code,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['meal_id'] = Variable<int>(mealId);
    map['code'] = Variable<String>(code);
    return map;
  }

  MealAllergensCompanion toCompanion(bool nullToAbsent) {
    return MealAllergensCompanion(
      lang: Value(lang),
      mealId: Value(mealId),
      code: Value(code),
    );
  }

  factory MealAllergen.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealAllergen(
      lang: serializer.fromJson<String>(json['lang']),
      mealId: serializer.fromJson<int>(json['mealId']),
      code: serializer.fromJson<String>(json['code']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'mealId': serializer.toJson<int>(mealId),
      'code': serializer.toJson<String>(code),
    };
  }

  MealAllergen copyWith({String? lang, int? mealId, String? code}) =>
      MealAllergen(
        lang: lang ?? this.lang,
        mealId: mealId ?? this.mealId,
        code: code ?? this.code,
      );
  MealAllergen copyWithCompanion(MealAllergensCompanion data) {
    return MealAllergen(
      lang: data.lang.present ? data.lang.value : this.lang,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      code: data.code.present ? data.code.value : this.code,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealAllergen(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('code: $code')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lang, mealId, code);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealAllergen &&
          other.lang == this.lang &&
          other.mealId == this.mealId &&
          other.code == this.code);
}

class MealAllergensCompanion extends UpdateCompanion<MealAllergen> {
  final Value<String> lang;
  final Value<int> mealId;
  final Value<String> code;
  final Value<int> rowid;
  const MealAllergensCompanion({
    this.lang = const Value.absent(),
    this.mealId = const Value.absent(),
    this.code = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealAllergensCompanion.insert({
    required String lang,
    required int mealId,
    required String code,
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       mealId = Value(mealId),
       code = Value(code);
  static Insertable<MealAllergen> custom({
    Expression<String>? lang,
    Expression<int>? mealId,
    Expression<String>? code,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (mealId != null) 'meal_id': mealId,
      if (code != null) 'code': code,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealAllergensCompanion copyWith({
    Value<String>? lang,
    Value<int>? mealId,
    Value<String>? code,
    Value<int>? rowid,
  }) {
    return MealAllergensCompanion(
      lang: lang ?? this.lang,
      mealId: mealId ?? this.mealId,
      code: code ?? this.code,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealAllergensCompanion(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('code: $code, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealIngredientsTable extends MealIngredients
    with TableInfo<$MealIngredientsTable, MealIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsPerServingMeta = const VerificationMeta(
    'gramsPerServing',
  );
  @override
  late final GeneratedColumn<double> gramsPerServing = GeneratedColumn<double>(
    'grams_per_serving',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOptionalMeta = const VerificationMeta(
    'isOptional',
  );
  @override
  late final GeneratedColumn<bool> isOptional = GeneratedColumn<bool>(
    'is_optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_optional" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    lang,
    mealId,
    position,
    ingredientId,
    name,
    gramsPerServing,
    isOptional,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grams_per_serving')) {
      context.handle(
        _gramsPerServingMeta,
        gramsPerServing.isAcceptableOrUnknown(
          data['grams_per_serving']!,
          _gramsPerServingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gramsPerServingMeta);
    }
    if (data.containsKey('is_optional')) {
      context.handle(
        _isOptionalMeta,
        isOptional.isAcceptableOrUnknown(data['is_optional']!, _isOptionalMeta),
      );
    } else if (isInserting) {
      context.missing(_isOptionalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang, mealId, position};
  @override
  MealIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealIngredient(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingredient_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gramsPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams_per_serving'],
      )!,
      isOptional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_optional'],
      )!,
    );
  }

  @override
  $MealIngredientsTable createAlias(String alias) {
    return $MealIngredientsTable(attachedDatabase, alias);
  }
}

class MealIngredient extends DataClass implements Insertable<MealIngredient> {
  final String lang;
  final int mealId;
  final int position;
  final int ingredientId;
  final String name;
  final double gramsPerServing;
  final bool isOptional;
  const MealIngredient({
    required this.lang,
    required this.mealId,
    required this.position,
    required this.ingredientId,
    required this.name,
    required this.gramsPerServing,
    required this.isOptional,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['meal_id'] = Variable<int>(mealId);
    map['position'] = Variable<int>(position);
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['name'] = Variable<String>(name);
    map['grams_per_serving'] = Variable<double>(gramsPerServing);
    map['is_optional'] = Variable<bool>(isOptional);
    return map;
  }

  MealIngredientsCompanion toCompanion(bool nullToAbsent) {
    return MealIngredientsCompanion(
      lang: Value(lang),
      mealId: Value(mealId),
      position: Value(position),
      ingredientId: Value(ingredientId),
      name: Value(name),
      gramsPerServing: Value(gramsPerServing),
      isOptional: Value(isOptional),
    );
  }

  factory MealIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealIngredient(
      lang: serializer.fromJson<String>(json['lang']),
      mealId: serializer.fromJson<int>(json['mealId']),
      position: serializer.fromJson<int>(json['position']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      name: serializer.fromJson<String>(json['name']),
      gramsPerServing: serializer.fromJson<double>(json['gramsPerServing']),
      isOptional: serializer.fromJson<bool>(json['isOptional']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'mealId': serializer.toJson<int>(mealId),
      'position': serializer.toJson<int>(position),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'name': serializer.toJson<String>(name),
      'gramsPerServing': serializer.toJson<double>(gramsPerServing),
      'isOptional': serializer.toJson<bool>(isOptional),
    };
  }

  MealIngredient copyWith({
    String? lang,
    int? mealId,
    int? position,
    int? ingredientId,
    String? name,
    double? gramsPerServing,
    bool? isOptional,
  }) => MealIngredient(
    lang: lang ?? this.lang,
    mealId: mealId ?? this.mealId,
    position: position ?? this.position,
    ingredientId: ingredientId ?? this.ingredientId,
    name: name ?? this.name,
    gramsPerServing: gramsPerServing ?? this.gramsPerServing,
    isOptional: isOptional ?? this.isOptional,
  );
  MealIngredient copyWithCompanion(MealIngredientsCompanion data) {
    return MealIngredient(
      lang: data.lang.present ? data.lang.value : this.lang,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      position: data.position.present ? data.position.value : this.position,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      name: data.name.present ? data.name.value : this.name,
      gramsPerServing: data.gramsPerServing.present
          ? data.gramsPerServing.value
          : this.gramsPerServing,
      isOptional: data.isOptional.present
          ? data.isOptional.value
          : this.isOptional,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealIngredient(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('gramsPerServing: $gramsPerServing, ')
          ..write('isOptional: $isOptional')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lang,
    mealId,
    position,
    ingredientId,
    name,
    gramsPerServing,
    isOptional,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealIngredient &&
          other.lang == this.lang &&
          other.mealId == this.mealId &&
          other.position == this.position &&
          other.ingredientId == this.ingredientId &&
          other.name == this.name &&
          other.gramsPerServing == this.gramsPerServing &&
          other.isOptional == this.isOptional);
}

class MealIngredientsCompanion extends UpdateCompanion<MealIngredient> {
  final Value<String> lang;
  final Value<int> mealId;
  final Value<int> position;
  final Value<int> ingredientId;
  final Value<String> name;
  final Value<double> gramsPerServing;
  final Value<bool> isOptional;
  final Value<int> rowid;
  const MealIngredientsCompanion({
    this.lang = const Value.absent(),
    this.mealId = const Value.absent(),
    this.position = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.name = const Value.absent(),
    this.gramsPerServing = const Value.absent(),
    this.isOptional = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealIngredientsCompanion.insert({
    required String lang,
    required int mealId,
    required int position,
    required int ingredientId,
    required String name,
    required double gramsPerServing,
    required bool isOptional,
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       mealId = Value(mealId),
       position = Value(position),
       ingredientId = Value(ingredientId),
       name = Value(name),
       gramsPerServing = Value(gramsPerServing),
       isOptional = Value(isOptional);
  static Insertable<MealIngredient> custom({
    Expression<String>? lang,
    Expression<int>? mealId,
    Expression<int>? position,
    Expression<int>? ingredientId,
    Expression<String>? name,
    Expression<double>? gramsPerServing,
    Expression<bool>? isOptional,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (mealId != null) 'meal_id': mealId,
      if (position != null) 'position': position,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (name != null) 'name': name,
      if (gramsPerServing != null) 'grams_per_serving': gramsPerServing,
      if (isOptional != null) 'is_optional': isOptional,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealIngredientsCompanion copyWith({
    Value<String>? lang,
    Value<int>? mealId,
    Value<int>? position,
    Value<int>? ingredientId,
    Value<String>? name,
    Value<double>? gramsPerServing,
    Value<bool>? isOptional,
    Value<int>? rowid,
  }) {
    return MealIngredientsCompanion(
      lang: lang ?? this.lang,
      mealId: mealId ?? this.mealId,
      position: position ?? this.position,
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      gramsPerServing: gramsPerServing ?? this.gramsPerServing,
      isOptional: isOptional ?? this.isOptional,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gramsPerServing.present) {
      map['grams_per_serving'] = Variable<double>(gramsPerServing.value);
    }
    if (isOptional.present) {
      map['is_optional'] = Variable<bool>(isOptional.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealIngredientsCompanion(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('gramsPerServing: $gramsPerServing, ')
          ..write('isOptional: $isOptional, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealNutrientsTable extends MealNutrients
    with TableInfo<$MealNutrientsTable, MealNutrient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealNutrientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100gMeta = const VerificationMeta(
    'per100g',
  );
  @override
  late final GeneratedColumn<double> per100g = GeneratedColumn<double>(
    'per_100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _perServingMeta = const VerificationMeta(
    'perServing',
  );
  @override
  late final GeneratedColumn<double> perServing = GeneratedColumn<double>(
    'per_serving',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lang,
    mealId,
    code,
    unit,
    per100g,
    perServing,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_nutrients';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealNutrient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('per_100g')) {
      context.handle(
        _per100gMeta,
        per100g.isAcceptableOrUnknown(data['per_100g']!, _per100gMeta),
      );
    }
    if (data.containsKey('per_serving')) {
      context.handle(
        _perServingMeta,
        perServing.isAcceptableOrUnknown(data['per_serving']!, _perServingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang, mealId, code};
  @override
  MealNutrient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealNutrient(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      per100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per_100g'],
      ),
      perServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per_serving'],
      ),
    );
  }

  @override
  $MealNutrientsTable createAlias(String alias) {
    return $MealNutrientsTable(attachedDatabase, alias);
  }
}

class MealNutrient extends DataClass implements Insertable<MealNutrient> {
  final String lang;
  final int mealId;
  final String code;
  final String unit;
  final double? per100g;
  final double? perServing;
  const MealNutrient({
    required this.lang,
    required this.mealId,
    required this.code,
    required this.unit,
    this.per100g,
    this.perServing,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['meal_id'] = Variable<int>(mealId);
    map['code'] = Variable<String>(code);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || per100g != null) {
      map['per_100g'] = Variable<double>(per100g);
    }
    if (!nullToAbsent || perServing != null) {
      map['per_serving'] = Variable<double>(perServing);
    }
    return map;
  }

  MealNutrientsCompanion toCompanion(bool nullToAbsent) {
    return MealNutrientsCompanion(
      lang: Value(lang),
      mealId: Value(mealId),
      code: Value(code),
      unit: Value(unit),
      per100g: per100g == null && nullToAbsent
          ? const Value.absent()
          : Value(per100g),
      perServing: perServing == null && nullToAbsent
          ? const Value.absent()
          : Value(perServing),
    );
  }

  factory MealNutrient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealNutrient(
      lang: serializer.fromJson<String>(json['lang']),
      mealId: serializer.fromJson<int>(json['mealId']),
      code: serializer.fromJson<String>(json['code']),
      unit: serializer.fromJson<String>(json['unit']),
      per100g: serializer.fromJson<double?>(json['per100g']),
      perServing: serializer.fromJson<double?>(json['perServing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'mealId': serializer.toJson<int>(mealId),
      'code': serializer.toJson<String>(code),
      'unit': serializer.toJson<String>(unit),
      'per100g': serializer.toJson<double?>(per100g),
      'perServing': serializer.toJson<double?>(perServing),
    };
  }

  MealNutrient copyWith({
    String? lang,
    int? mealId,
    String? code,
    String? unit,
    Value<double?> per100g = const Value.absent(),
    Value<double?> perServing = const Value.absent(),
  }) => MealNutrient(
    lang: lang ?? this.lang,
    mealId: mealId ?? this.mealId,
    code: code ?? this.code,
    unit: unit ?? this.unit,
    per100g: per100g.present ? per100g.value : this.per100g,
    perServing: perServing.present ? perServing.value : this.perServing,
  );
  MealNutrient copyWithCompanion(MealNutrientsCompanion data) {
    return MealNutrient(
      lang: data.lang.present ? data.lang.value : this.lang,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      code: data.code.present ? data.code.value : this.code,
      unit: data.unit.present ? data.unit.value : this.unit,
      per100g: data.per100g.present ? data.per100g.value : this.per100g,
      perServing: data.perServing.present
          ? data.perServing.value
          : this.perServing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealNutrient(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('code: $code, ')
          ..write('unit: $unit, ')
          ..write('per100g: $per100g, ')
          ..write('perServing: $perServing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(lang, mealId, code, unit, per100g, perServing);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealNutrient &&
          other.lang == this.lang &&
          other.mealId == this.mealId &&
          other.code == this.code &&
          other.unit == this.unit &&
          other.per100g == this.per100g &&
          other.perServing == this.perServing);
}

class MealNutrientsCompanion extends UpdateCompanion<MealNutrient> {
  final Value<String> lang;
  final Value<int> mealId;
  final Value<String> code;
  final Value<String> unit;
  final Value<double?> per100g;
  final Value<double?> perServing;
  final Value<int> rowid;
  const MealNutrientsCompanion({
    this.lang = const Value.absent(),
    this.mealId = const Value.absent(),
    this.code = const Value.absent(),
    this.unit = const Value.absent(),
    this.per100g = const Value.absent(),
    this.perServing = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealNutrientsCompanion.insert({
    required String lang,
    required int mealId,
    required String code,
    required String unit,
    this.per100g = const Value.absent(),
    this.perServing = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       mealId = Value(mealId),
       code = Value(code),
       unit = Value(unit);
  static Insertable<MealNutrient> custom({
    Expression<String>? lang,
    Expression<int>? mealId,
    Expression<String>? code,
    Expression<String>? unit,
    Expression<double>? per100g,
    Expression<double>? perServing,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (mealId != null) 'meal_id': mealId,
      if (code != null) 'code': code,
      if (unit != null) 'unit': unit,
      if (per100g != null) 'per_100g': per100g,
      if (perServing != null) 'per_serving': perServing,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealNutrientsCompanion copyWith({
    Value<String>? lang,
    Value<int>? mealId,
    Value<String>? code,
    Value<String>? unit,
    Value<double?>? per100g,
    Value<double?>? perServing,
    Value<int>? rowid,
  }) {
    return MealNutrientsCompanion(
      lang: lang ?? this.lang,
      mealId: mealId ?? this.mealId,
      code: code ?? this.code,
      unit: unit ?? this.unit,
      per100g: per100g ?? this.per100g,
      perServing: perServing ?? this.perServing,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (per100g.present) {
      map['per_100g'] = Variable<double>(per100g.value);
    }
    if (perServing.present) {
      map['per_serving'] = Variable<double>(perServing.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealNutrientsCompanion(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('code: $code, ')
          ..write('unit: $unit, ')
          ..write('per100g: $per100g, ')
          ..write('perServing: $perServing, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealStepsTable extends MealSteps
    with TableInfo<$MealStepsTable, MealStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepTextMeta = const VerificationMeta(
    'stepText',
  );
  @override
  late final GeneratedColumn<String> stepText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lang, mealId, position, stepText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _stepTextMeta,
        stepText.isAcceptableOrUnknown(data['text']!, _stepTextMeta),
      );
    } else if (isInserting) {
      context.missing(_stepTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang, mealId, position};
  @override
  MealStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealStep(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      stepText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $MealStepsTable createAlias(String alias) {
    return $MealStepsTable(attachedDatabase, alias);
  }
}

class MealStep extends DataClass implements Insertable<MealStep> {
  final String lang;
  final int mealId;
  final int position;
  final String stepText;
  const MealStep({
    required this.lang,
    required this.mealId,
    required this.position,
    required this.stepText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['meal_id'] = Variable<int>(mealId);
    map['position'] = Variable<int>(position);
    map['text'] = Variable<String>(stepText);
    return map;
  }

  MealStepsCompanion toCompanion(bool nullToAbsent) {
    return MealStepsCompanion(
      lang: Value(lang),
      mealId: Value(mealId),
      position: Value(position),
      stepText: Value(stepText),
    );
  }

  factory MealStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealStep(
      lang: serializer.fromJson<String>(json['lang']),
      mealId: serializer.fromJson<int>(json['mealId']),
      position: serializer.fromJson<int>(json['position']),
      stepText: serializer.fromJson<String>(json['stepText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'mealId': serializer.toJson<int>(mealId),
      'position': serializer.toJson<int>(position),
      'stepText': serializer.toJson<String>(stepText),
    };
  }

  MealStep copyWith({
    String? lang,
    int? mealId,
    int? position,
    String? stepText,
  }) => MealStep(
    lang: lang ?? this.lang,
    mealId: mealId ?? this.mealId,
    position: position ?? this.position,
    stepText: stepText ?? this.stepText,
  );
  MealStep copyWithCompanion(MealStepsCompanion data) {
    return MealStep(
      lang: data.lang.present ? data.lang.value : this.lang,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      position: data.position.present ? data.position.value : this.position,
      stepText: data.stepText.present ? data.stepText.value : this.stepText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealStep(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('stepText: $stepText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lang, mealId, position, stepText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealStep &&
          other.lang == this.lang &&
          other.mealId == this.mealId &&
          other.position == this.position &&
          other.stepText == this.stepText);
}

class MealStepsCompanion extends UpdateCompanion<MealStep> {
  final Value<String> lang;
  final Value<int> mealId;
  final Value<int> position;
  final Value<String> stepText;
  final Value<int> rowid;
  const MealStepsCompanion({
    this.lang = const Value.absent(),
    this.mealId = const Value.absent(),
    this.position = const Value.absent(),
    this.stepText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealStepsCompanion.insert({
    required String lang,
    required int mealId,
    required int position,
    required String stepText,
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       mealId = Value(mealId),
       position = Value(position),
       stepText = Value(stepText);
  static Insertable<MealStep> custom({
    Expression<String>? lang,
    Expression<int>? mealId,
    Expression<int>? position,
    Expression<String>? stepText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (mealId != null) 'meal_id': mealId,
      if (position != null) 'position': position,
      if (stepText != null) 'text': stepText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealStepsCompanion copyWith({
    Value<String>? lang,
    Value<int>? mealId,
    Value<int>? position,
    Value<String>? stepText,
    Value<int>? rowid,
  }) {
    return MealStepsCompanion(
      lang: lang ?? this.lang,
      mealId: mealId ?? this.mealId,
      position: position ?? this.position,
      stepText: stepText ?? this.stepText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (stepText.present) {
      map['text'] = Variable<String>(stepText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealStepsCompanion(')
          ..write('lang: $lang, ')
          ..write('mealId: $mealId, ')
          ..write('position: $position, ')
          ..write('stepText: $stepText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CuisinesTable extends Cuisines with TableInfo<$CuisinesTable, Cuisine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CuisinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lang, code, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cuisines';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cuisine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lang, code};
  @override
  Cuisine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cuisine(
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CuisinesTable createAlias(String alias) {
    return $CuisinesTable(attachedDatabase, alias);
  }
}

class Cuisine extends DataClass implements Insertable<Cuisine> {
  final String lang;
  final String code;
  final String name;
  const Cuisine({required this.lang, required this.code, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang'] = Variable<String>(lang);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    return map;
  }

  CuisinesCompanion toCompanion(bool nullToAbsent) {
    return CuisinesCompanion(
      lang: Value(lang),
      code: Value(code),
      name: Value(name),
    );
  }

  factory Cuisine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cuisine(
      lang: serializer.fromJson<String>(json['lang']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lang': serializer.toJson<String>(lang),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
    };
  }

  Cuisine copyWith({String? lang, String? code, String? name}) => Cuisine(
    lang: lang ?? this.lang,
    code: code ?? this.code,
    name: name ?? this.name,
  );
  Cuisine copyWithCompanion(CuisinesCompanion data) {
    return Cuisine(
      lang: data.lang.present ? data.lang.value : this.lang,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cuisine(')
          ..write('lang: $lang, ')
          ..write('code: $code, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lang, code, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cuisine &&
          other.lang == this.lang &&
          other.code == this.code &&
          other.name == this.name);
}

class CuisinesCompanion extends UpdateCompanion<Cuisine> {
  final Value<String> lang;
  final Value<String> code;
  final Value<String> name;
  final Value<int> rowid;
  const CuisinesCompanion({
    this.lang = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CuisinesCompanion.insert({
    required String lang,
    required String code,
    required String name,
    this.rowid = const Value.absent(),
  }) : lang = Value(lang),
       code = Value(code),
       name = Value(name);
  static Insertable<Cuisine> custom({
    Expression<String>? lang,
    Expression<String>? code,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lang != null) 'lang': lang,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CuisinesCompanion copyWith({
    Value<String>? lang,
    Value<String>? code,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return CuisinesCompanion(
      lang: lang ?? this.lang,
      code: code ?? this.code,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CuisinesCompanion(')
          ..write('lang: $lang, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMealPrefsTable extends LocalMealPrefs
    with TableInfo<$LocalMealPrefsTable, LocalMealPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMealPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stanceMeta = const VerificationMeta('stance');
  @override
  late final GeneratedColumn<String> stance = GeneratedColumn<String>(
    'stance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [mealId, stance, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMealPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    }
    if (data.containsKey('stance')) {
      context.handle(
        _stanceMeta,
        stance.isAcceptableOrUnknown(data['stance']!, _stanceMeta),
      );
    } else if (isInserting) {
      context.missing(_stanceMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mealId};
  @override
  LocalMealPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMealPref(
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      stance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stance'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMealPrefsTable createAlias(String alias) {
    return $LocalMealPrefsTable(attachedDatabase, alias);
  }
}

class LocalMealPref extends DataClass implements Insertable<LocalMealPref> {
  final int mealId;
  final String stance;
  final DateTime updatedAt;
  const LocalMealPref({
    required this.mealId,
    required this.stance,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['meal_id'] = Variable<int>(mealId);
    map['stance'] = Variable<String>(stance);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMealPrefsCompanion toCompanion(bool nullToAbsent) {
    return LocalMealPrefsCompanion(
      mealId: Value(mealId),
      stance: Value(stance),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMealPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMealPref(
      mealId: serializer.fromJson<int>(json['mealId']),
      stance: serializer.fromJson<String>(json['stance']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mealId': serializer.toJson<int>(mealId),
      'stance': serializer.toJson<String>(stance),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMealPref copyWith({int? mealId, String? stance, DateTime? updatedAt}) =>
      LocalMealPref(
        mealId: mealId ?? this.mealId,
        stance: stance ?? this.stance,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalMealPref copyWithCompanion(LocalMealPrefsCompanion data) {
    return LocalMealPref(
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      stance: data.stance.present ? data.stance.value : this.stance,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealPref(')
          ..write('mealId: $mealId, ')
          ..write('stance: $stance, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mealId, stance, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMealPref &&
          other.mealId == this.mealId &&
          other.stance == this.stance &&
          other.updatedAt == this.updatedAt);
}

class LocalMealPrefsCompanion extends UpdateCompanion<LocalMealPref> {
  final Value<int> mealId;
  final Value<String> stance;
  final Value<DateTime> updatedAt;
  const LocalMealPrefsCompanion({
    this.mealId = const Value.absent(),
    this.stance = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalMealPrefsCompanion.insert({
    this.mealId = const Value.absent(),
    required String stance,
    required DateTime updatedAt,
  }) : stance = Value(stance),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMealPref> custom({
    Expression<int>? mealId,
    Expression<String>? stance,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (mealId != null) 'meal_id': mealId,
      if (stance != null) 'stance': stance,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalMealPrefsCompanion copyWith({
    Value<int>? mealId,
    Value<String>? stance,
    Value<DateTime>? updatedAt,
  }) {
    return LocalMealPrefsCompanion(
      mealId: mealId ?? this.mealId,
      stance: stance ?? this.stance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (stance.present) {
      map['stance'] = Variable<String>(stance.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealPrefsCompanion(')
          ..write('mealId: $mealId, ')
          ..write('stance: $stance, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserAllergensTable extends UserAllergens
    with TableInfo<$UserAllergensTable, UserAllergen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserAllergensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [code, severity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_allergens';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserAllergen> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  UserAllergen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAllergen(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
    );
  }

  @override
  $UserAllergensTable createAlias(String alias) {
    return $UserAllergensTable(attachedDatabase, alias);
  }
}

class UserAllergen extends DataClass implements Insertable<UserAllergen> {
  final String code;
  final String severity;
  const UserAllergen({required this.code, required this.severity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['severity'] = Variable<String>(severity);
    return map;
  }

  UserAllergensCompanion toCompanion(bool nullToAbsent) {
    return UserAllergensCompanion(code: Value(code), severity: Value(severity));
  }

  factory UserAllergen.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAllergen(
      code: serializer.fromJson<String>(json['code']),
      severity: serializer.fromJson<String>(json['severity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'severity': serializer.toJson<String>(severity),
    };
  }

  UserAllergen copyWith({String? code, String? severity}) => UserAllergen(
    code: code ?? this.code,
    severity: severity ?? this.severity,
  );
  UserAllergen copyWithCompanion(UserAllergensCompanion data) {
    return UserAllergen(
      code: data.code.present ? data.code.value : this.code,
      severity: data.severity.present ? data.severity.value : this.severity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserAllergen(')
          ..write('code: $code, ')
          ..write('severity: $severity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, severity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAllergen &&
          other.code == this.code &&
          other.severity == this.severity);
}

class UserAllergensCompanion extends UpdateCompanion<UserAllergen> {
  final Value<String> code;
  final Value<String> severity;
  final Value<int> rowid;
  const UserAllergensCompanion({
    this.code = const Value.absent(),
    this.severity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserAllergensCompanion.insert({
    required String code,
    required String severity,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       severity = Value(severity);
  static Insertable<UserAllergen> custom({
    Expression<String>? code,
    Expression<String>? severity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (severity != null) 'severity': severity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserAllergensCompanion copyWith({
    Value<String>? code,
    Value<String>? severity,
    Value<int>? rowid,
  }) {
    return UserAllergensCompanion(
      code: code ?? this.code,
      severity: severity ?? this.severity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserAllergensCompanion(')
          ..write('code: $code, ')
          ..write('severity: $severity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CatalogMetaTable catalogMeta = $CatalogMetaTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $MealTagsTable mealTags = $MealTagsTable(this);
  late final $MealAllergensTable mealAllergens = $MealAllergensTable(this);
  late final $MealIngredientsTable mealIngredients = $MealIngredientsTable(
    this,
  );
  late final $MealNutrientsTable mealNutrients = $MealNutrientsTable(this);
  late final $MealStepsTable mealSteps = $MealStepsTable(this);
  late final $CuisinesTable cuisines = $CuisinesTable(this);
  late final $LocalMealPrefsTable localMealPrefs = $LocalMealPrefsTable(this);
  late final $UserAllergensTable userAllergens = $UserAllergensTable(this);
  late final Index mealsLangSearchKey = Index(
    'meals_lang_search_key',
    'CREATE INDEX meals_lang_search_key ON meals (lang, search_key)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    catalogMeta,
    meals,
    mealTags,
    mealAllergens,
    mealIngredients,
    mealNutrients,
    mealSteps,
    cuisines,
    localMealPrefs,
    userAllergens,
    mealsLangSearchKey,
  ];
}

typedef $$CatalogMetaTableCreateCompanionBuilder =
    CatalogMetaCompanion Function({
      required String lang,
      required String etag,
      required String datasetVersion,
      required int mealCount,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CatalogMetaTableUpdateCompanionBuilder =
    CatalogMetaCompanion Function({
      Value<String> lang,
      Value<String> etag,
      Value<String> datasetVersion,
      Value<int> mealCount,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CatalogMetaTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogMetaTable> {
  $$CatalogMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealCount => $composableBuilder(
    column: $table.mealCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogMetaTable> {
  $$CatalogMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealCount => $composableBuilder(
    column: $table.mealCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogMetaTable> {
  $$CatalogMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mealCount =>
      $composableBuilder(column: $table.mealCount, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CatalogMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogMetaTable,
          CatalogMetaData,
          $$CatalogMetaTableFilterComposer,
          $$CatalogMetaTableOrderingComposer,
          $$CatalogMetaTableAnnotationComposer,
          $$CatalogMetaTableCreateCompanionBuilder,
          $$CatalogMetaTableUpdateCompanionBuilder,
          (
            CatalogMetaData,
            BaseReferences<_$AppDatabase, $CatalogMetaTable, CatalogMetaData>,
          ),
          CatalogMetaData,
          PrefetchHooks Function()
        > {
  $$CatalogMetaTableTableManager(_$AppDatabase db, $CatalogMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<String> etag = const Value.absent(),
                Value<String> datasetVersion = const Value.absent(),
                Value<int> mealCount = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogMetaCompanion(
                lang: lang,
                etag: etag,
                datasetVersion: datasetVersion,
                mealCount: mealCount,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required String etag,
                required String datasetVersion,
                required int mealCount,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CatalogMetaCompanion.insert(
                lang: lang,
                etag: etag,
                datasetVersion: datasetVersion,
                mealCount: mealCount,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogMetaTable, CatalogMetaData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CatalogMetaTable,
                    CatalogMetaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogMetaTable,
      CatalogMetaData,
      $$CatalogMetaTableFilterComposer,
      $$CatalogMetaTableOrderingComposer,
      $$CatalogMetaTableAnnotationComposer,
      $$CatalogMetaTableCreateCompanionBuilder,
      $$CatalogMetaTableUpdateCompanionBuilder,
      (
        CatalogMetaData,
        BaseReferences<_$AppDatabase, $CatalogMetaTable, CatalogMetaData>,
      ),
      CatalogMetaData,
      PrefetchHooks Function()
    >;
typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  required String lang,
  required int mealId,
  required String name,
  required String searchKey,
  Value<String?> cuisine,
  Value<String?> dishForm,
  required double servingGrams,
  required int servings,
  required double totalGrams,
  required double kcal,
  required double proteinG,
  required double carbG,
  required double fatG,
  required String source,
  required String datasetVersion,
  Value<int> rowid,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<String> lang,
  Value<int> mealId,
  Value<String> name,
  Value<String> searchKey,
  Value<String?> cuisine,
  Value<String?> dishForm,
  Value<double> servingGrams,
  Value<int> servings,
  Value<double> totalGrams,
  Value<double> kcal,
  Value<double> proteinG,
  Value<double> carbG,
  Value<double> fatG,
  Value<String> source,
  Value<String> datasetVersion,
  Value<int> rowid,
});

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchKey => $composableBuilder(
    column: $table.searchKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dishForm => $composableBuilder(
    column: $table.dishForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalGrams => $composableBuilder(
    column: $table.totalGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchKey => $composableBuilder(
    column: $table.searchKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dishForm => $composableBuilder(
    column: $table.dishForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalGrams => $composableBuilder(
    column: $table.totalGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get searchKey =>
      $composableBuilder(column: $table.searchKey, builder: (column) => column);

  GeneratedColumn<String> get cuisine =>
      $composableBuilder(column: $table.cuisine, builder: (column) => column);

  GeneratedColumn<String> get dishForm =>
      $composableBuilder(column: $table.dishForm, builder: (column) => column);

  GeneratedColumn<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => column,
  );

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<double> get totalGrams => $composableBuilder(
    column: $table.totalGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get datasetVersion => $composableBuilder(
    column: $table.datasetVersion,
    builder: (column) => column,
  );
}

class $$MealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealsTable,
          Meal,
          $$MealsTableFilterComposer,
          $$MealsTableOrderingComposer,
          $$MealsTableAnnotationComposer,
          $$MealsTableCreateCompanionBuilder,
          $$MealsTableUpdateCompanionBuilder,
          (Meal, BaseReferences<_$AppDatabase, $MealsTable, Meal>),
          Meal,
          PrefetchHooks Function()
        > {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> searchKey = const Value.absent(),
                Value<String?> cuisine = const Value.absent(),
                Value<String?> dishForm = const Value.absent(),
                Value<double> servingGrams = const Value.absent(),
                Value<int> servings = const Value.absent(),
                Value<double> totalGrams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> datasetVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion(
                lang: lang,
                mealId: mealId,
                name: name,
                searchKey: searchKey,
                cuisine: cuisine,
                dishForm: dishForm,
                servingGrams: servingGrams,
                servings: servings,
                totalGrams: totalGrams,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                source: source,
                datasetVersion: datasetVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required int mealId,
                required String name,
                required String searchKey,
                Value<String?> cuisine = const Value.absent(),
                Value<String?> dishForm = const Value.absent(),
                required double servingGrams,
                required int servings,
                required double totalGrams,
                required double kcal,
                required double proteinG,
                required double carbG,
                required double fatG,
                required String source,
                required String datasetVersion,
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion.insert(
                lang: lang,
                mealId: mealId,
                name: name,
                searchKey: searchKey,
                cuisine: cuisine,
                dishForm: dishForm,
                servingGrams: servingGrams,
                servings: servings,
                totalGrams: totalGrams,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                source: source,
                datasetVersion: datasetVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealsTable, Meal>(table),
                  BaseReferences<_$AppDatabase, $MealsTable, Meal>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealsTable,
      Meal,
      $$MealsTableFilterComposer,
      $$MealsTableOrderingComposer,
      $$MealsTableAnnotationComposer,
      $$MealsTableCreateCompanionBuilder,
      $$MealsTableUpdateCompanionBuilder,
      (Meal, BaseReferences<_$AppDatabase, $MealsTable, Meal>),
      Meal,
      PrefetchHooks Function()
    >;
typedef $$MealTagsTableCreateCompanionBuilder = MealTagsCompanion Function({
  required String lang,
  required int mealId,
  required String tag,
  Value<int> rowid,
});
typedef $$MealTagsTableUpdateCompanionBuilder = MealTagsCompanion Function({
  Value<String> lang,
  Value<int> mealId,
  Value<String> tag,
  Value<int> rowid,
});

class $$MealTagsTableFilterComposer
    extends Composer<_$AppDatabase, $MealTagsTable> {
  $$MealTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealTagsTable> {
  $$MealTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealTagsTable> {
  $$MealTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$MealTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealTagsTable,
          MealTag,
          $$MealTagsTableFilterComposer,
          $$MealTagsTableOrderingComposer,
          $$MealTagsTableAnnotationComposer,
          $$MealTagsTableCreateCompanionBuilder,
          $$MealTagsTableUpdateCompanionBuilder,
          (MealTag, BaseReferences<_$AppDatabase, $MealTagsTable, MealTag>),
          MealTag,
          PrefetchHooks Function()
        > {
  $$MealTagsTableTableManager(_$AppDatabase db, $MealTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealTagsCompanion(
                lang: lang,
                mealId: mealId,
                tag: tag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required int mealId,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => MealTagsCompanion.insert(
                lang: lang,
                mealId: mealId,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealTagsTable, MealTag>(table),
                  BaseReferences<_$AppDatabase, $MealTagsTable, MealTag>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealTagsTable,
      MealTag,
      $$MealTagsTableFilterComposer,
      $$MealTagsTableOrderingComposer,
      $$MealTagsTableAnnotationComposer,
      $$MealTagsTableCreateCompanionBuilder,
      $$MealTagsTableUpdateCompanionBuilder,
      (MealTag, BaseReferences<_$AppDatabase, $MealTagsTable, MealTag>),
      MealTag,
      PrefetchHooks Function()
    >;
typedef $$MealAllergensTableCreateCompanionBuilder =
    MealAllergensCompanion Function({
      required String lang,
      required int mealId,
      required String code,
      Value<int> rowid,
    });
typedef $$MealAllergensTableUpdateCompanionBuilder =
    MealAllergensCompanion Function({
      Value<String> lang,
      Value<int> mealId,
      Value<String> code,
      Value<int> rowid,
    });

class $$MealAllergensTableFilterComposer
    extends Composer<_$AppDatabase, $MealAllergensTable> {
  $$MealAllergensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealAllergensTableOrderingComposer
    extends Composer<_$AppDatabase, $MealAllergensTable> {
  $$MealAllergensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealAllergensTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealAllergensTable> {
  $$MealAllergensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);
}

class $$MealAllergensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealAllergensTable,
          MealAllergen,
          $$MealAllergensTableFilterComposer,
          $$MealAllergensTableOrderingComposer,
          $$MealAllergensTableAnnotationComposer,
          $$MealAllergensTableCreateCompanionBuilder,
          $$MealAllergensTableUpdateCompanionBuilder,
          (
            MealAllergen,
            BaseReferences<_$AppDatabase, $MealAllergensTable, MealAllergen>,
          ),
          MealAllergen,
          PrefetchHooks Function()
        > {
  $$MealAllergensTableTableManager(_$AppDatabase db, $MealAllergensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealAllergensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealAllergensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealAllergensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealAllergensCompanion(
                lang: lang,
                mealId: mealId,
                code: code,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required int mealId,
                required String code,
                Value<int> rowid = const Value.absent(),
              }) => MealAllergensCompanion.insert(
                lang: lang,
                mealId: mealId,
                code: code,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealAllergensTable, MealAllergen>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MealAllergensTable,
                    MealAllergen
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealAllergensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealAllergensTable,
      MealAllergen,
      $$MealAllergensTableFilterComposer,
      $$MealAllergensTableOrderingComposer,
      $$MealAllergensTableAnnotationComposer,
      $$MealAllergensTableCreateCompanionBuilder,
      $$MealAllergensTableUpdateCompanionBuilder,
      (
        MealAllergen,
        BaseReferences<_$AppDatabase, $MealAllergensTable, MealAllergen>,
      ),
      MealAllergen,
      PrefetchHooks Function()
    >;
typedef $$MealIngredientsTableCreateCompanionBuilder =
    MealIngredientsCompanion Function({
      required String lang,
      required int mealId,
      required int position,
      required int ingredientId,
      required String name,
      required double gramsPerServing,
      required bool isOptional,
      Value<int> rowid,
    });
typedef $$MealIngredientsTableUpdateCompanionBuilder =
    MealIngredientsCompanion Function({
      Value<String> lang,
      Value<int> mealId,
      Value<int> position,
      Value<int> ingredientId,
      Value<String> name,
      Value<double> gramsPerServing,
      Value<bool> isOptional,
      Value<int> rowid,
    });

class $$MealIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $MealIngredientsTable> {
  $$MealIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gramsPerServing => $composableBuilder(
    column: $table.gramsPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealIngredientsTable> {
  $$MealIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramsPerServing => $composableBuilder(
    column: $table.gramsPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealIngredientsTable> {
  $$MealIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get gramsPerServing => $composableBuilder(
    column: $table.gramsPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => column,
  );
}

class $$MealIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealIngredientsTable,
          MealIngredient,
          $$MealIngredientsTableFilterComposer,
          $$MealIngredientsTableOrderingComposer,
          $$MealIngredientsTableAnnotationComposer,
          $$MealIngredientsTableCreateCompanionBuilder,
          $$MealIngredientsTableUpdateCompanionBuilder,
          (
            MealIngredient,
            BaseReferences<
              _$AppDatabase,
              $MealIngredientsTable,
              MealIngredient
            >,
          ),
          MealIngredient,
          PrefetchHooks Function()
        > {
  $$MealIngredientsTableTableManager(
    _$AppDatabase db,
    $MealIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealIngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> ingredientId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> gramsPerServing = const Value.absent(),
                Value<bool> isOptional = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealIngredientsCompanion(
                lang: lang,
                mealId: mealId,
                position: position,
                ingredientId: ingredientId,
                name: name,
                gramsPerServing: gramsPerServing,
                isOptional: isOptional,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required int mealId,
                required int position,
                required int ingredientId,
                required String name,
                required double gramsPerServing,
                required bool isOptional,
                Value<int> rowid = const Value.absent(),
              }) => MealIngredientsCompanion.insert(
                lang: lang,
                mealId: mealId,
                position: position,
                ingredientId: ingredientId,
                name: name,
                gramsPerServing: gramsPerServing,
                isOptional: isOptional,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealIngredientsTable, MealIngredient>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MealIngredientsTable,
                    MealIngredient
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealIngredientsTable,
      MealIngredient,
      $$MealIngredientsTableFilterComposer,
      $$MealIngredientsTableOrderingComposer,
      $$MealIngredientsTableAnnotationComposer,
      $$MealIngredientsTableCreateCompanionBuilder,
      $$MealIngredientsTableUpdateCompanionBuilder,
      (
        MealIngredient,
        BaseReferences<_$AppDatabase, $MealIngredientsTable, MealIngredient>,
      ),
      MealIngredient,
      PrefetchHooks Function()
    >;
typedef $$MealNutrientsTableCreateCompanionBuilder =
    MealNutrientsCompanion Function({
      required String lang,
      required int mealId,
      required String code,
      required String unit,
      Value<double?> per100g,
      Value<double?> perServing,
      Value<int> rowid,
    });
typedef $$MealNutrientsTableUpdateCompanionBuilder =
    MealNutrientsCompanion Function({
      Value<String> lang,
      Value<int> mealId,
      Value<String> code,
      Value<String> unit,
      Value<double?> per100g,
      Value<double?> perServing,
      Value<int> rowid,
    });

class $$MealNutrientsTableFilterComposer
    extends Composer<_$AppDatabase, $MealNutrientsTable> {
  $$MealNutrientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get per100g => $composableBuilder(
    column: $table.per100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get perServing => $composableBuilder(
    column: $table.perServing,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealNutrientsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealNutrientsTable> {
  $$MealNutrientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get per100g => $composableBuilder(
    column: $table.per100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get perServing => $composableBuilder(
    column: $table.perServing,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealNutrientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealNutrientsTable> {
  $$MealNutrientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get per100g =>
      $composableBuilder(column: $table.per100g, builder: (column) => column);

  GeneratedColumn<double> get perServing => $composableBuilder(
    column: $table.perServing,
    builder: (column) => column,
  );
}

class $$MealNutrientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealNutrientsTable,
          MealNutrient,
          $$MealNutrientsTableFilterComposer,
          $$MealNutrientsTableOrderingComposer,
          $$MealNutrientsTableAnnotationComposer,
          $$MealNutrientsTableCreateCompanionBuilder,
          $$MealNutrientsTableUpdateCompanionBuilder,
          (
            MealNutrient,
            BaseReferences<_$AppDatabase, $MealNutrientsTable, MealNutrient>,
          ),
          MealNutrient,
          PrefetchHooks Function()
        > {
  $$MealNutrientsTableTableManager(_$AppDatabase db, $MealNutrientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealNutrientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealNutrientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealNutrientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> per100g = const Value.absent(),
                Value<double?> perServing = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealNutrientsCompanion(
                lang: lang,
                mealId: mealId,
                code: code,
                unit: unit,
                per100g: per100g,
                perServing: perServing,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required int mealId,
                required String code,
                required String unit,
                Value<double?> per100g = const Value.absent(),
                Value<double?> perServing = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealNutrientsCompanion.insert(
                lang: lang,
                mealId: mealId,
                code: code,
                unit: unit,
                per100g: per100g,
                perServing: perServing,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealNutrientsTable, MealNutrient>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MealNutrientsTable,
                    MealNutrient
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealNutrientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealNutrientsTable,
      MealNutrient,
      $$MealNutrientsTableFilterComposer,
      $$MealNutrientsTableOrderingComposer,
      $$MealNutrientsTableAnnotationComposer,
      $$MealNutrientsTableCreateCompanionBuilder,
      $$MealNutrientsTableUpdateCompanionBuilder,
      (
        MealNutrient,
        BaseReferences<_$AppDatabase, $MealNutrientsTable, MealNutrient>,
      ),
      MealNutrient,
      PrefetchHooks Function()
    >;
typedef $$MealStepsTableCreateCompanionBuilder = MealStepsCompanion Function({
  required String lang,
  required int mealId,
  required int position,
  required String stepText,
  Value<int> rowid,
});
typedef $$MealStepsTableUpdateCompanionBuilder = MealStepsCompanion Function({
  Value<String> lang,
  Value<int> mealId,
  Value<int> position,
  Value<String> stepText,
  Value<int> rowid,
});

class $$MealStepsTableFilterComposer
    extends Composer<_$AppDatabase, $MealStepsTable> {
  $$MealStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepText => $composableBuilder(
    column: $table.stepText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealStepsTable> {
  $$MealStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepText => $composableBuilder(
    column: $table.stepText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealStepsTable> {
  $$MealStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get stepText =>
      $composableBuilder(column: $table.stepText, builder: (column) => column);
}

class $$MealStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealStepsTable,
          MealStep,
          $$MealStepsTableFilterComposer,
          $$MealStepsTableOrderingComposer,
          $$MealStepsTableAnnotationComposer,
          $$MealStepsTableCreateCompanionBuilder,
          $$MealStepsTableUpdateCompanionBuilder,
          (MealStep, BaseReferences<_$AppDatabase, $MealStepsTable, MealStep>),
          MealStep,
          PrefetchHooks Function()
        > {
  $$MealStepsTableTableManager(_$AppDatabase db, $MealStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> stepText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealStepsCompanion(
                lang: lang,
                mealId: mealId,
                position: position,
                stepText: stepText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required int mealId,
                required int position,
                required String stepText,
                Value<int> rowid = const Value.absent(),
              }) => MealStepsCompanion.insert(
                lang: lang,
                mealId: mealId,
                position: position,
                stepText: stepText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealStepsTable, MealStep>(table),
                  BaseReferences<_$AppDatabase, $MealStepsTable, MealStep>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealStepsTable,
      MealStep,
      $$MealStepsTableFilterComposer,
      $$MealStepsTableOrderingComposer,
      $$MealStepsTableAnnotationComposer,
      $$MealStepsTableCreateCompanionBuilder,
      $$MealStepsTableUpdateCompanionBuilder,
      (MealStep, BaseReferences<_$AppDatabase, $MealStepsTable, MealStep>),
      MealStep,
      PrefetchHooks Function()
    >;
typedef $$CuisinesTableCreateCompanionBuilder = CuisinesCompanion Function({
  required String lang,
  required String code,
  required String name,
  Value<int> rowid,
});
typedef $$CuisinesTableUpdateCompanionBuilder = CuisinesCompanion Function({
  Value<String> lang,
  Value<String> code,
  Value<String> name,
  Value<int> rowid,
});

class $$CuisinesTableFilterComposer
    extends Composer<_$AppDatabase, $CuisinesTable> {
  $$CuisinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CuisinesTableOrderingComposer
    extends Composer<_$AppDatabase, $CuisinesTable> {
  $$CuisinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CuisinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CuisinesTable> {
  $$CuisinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$CuisinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CuisinesTable,
          Cuisine,
          $$CuisinesTableFilterComposer,
          $$CuisinesTableOrderingComposer,
          $$CuisinesTableAnnotationComposer,
          $$CuisinesTableCreateCompanionBuilder,
          $$CuisinesTableUpdateCompanionBuilder,
          (Cuisine, BaseReferences<_$AppDatabase, $CuisinesTable, Cuisine>),
          Cuisine,
          PrefetchHooks Function()
        > {
  $$CuisinesTableTableManager(_$AppDatabase db, $CuisinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CuisinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CuisinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CuisinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lang = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CuisinesCompanion(
                lang: lang,
                code: code,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lang,
                required String code,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => CuisinesCompanion.insert(
                lang: lang,
                code: code,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CuisinesTable, Cuisine>(table),
                  BaseReferences<_$AppDatabase, $CuisinesTable, Cuisine>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CuisinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CuisinesTable,
      Cuisine,
      $$CuisinesTableFilterComposer,
      $$CuisinesTableOrderingComposer,
      $$CuisinesTableAnnotationComposer,
      $$CuisinesTableCreateCompanionBuilder,
      $$CuisinesTableUpdateCompanionBuilder,
      (Cuisine, BaseReferences<_$AppDatabase, $CuisinesTable, Cuisine>),
      Cuisine,
      PrefetchHooks Function()
    >;
typedef $$LocalMealPrefsTableCreateCompanionBuilder =
    LocalMealPrefsCompanion Function({
      Value<int> mealId,
      required String stance,
      required DateTime updatedAt,
    });
typedef $$LocalMealPrefsTableUpdateCompanionBuilder =
    LocalMealPrefsCompanion Function({
      Value<int> mealId,
      Value<String> stance,
      Value<DateTime> updatedAt,
    });

class $$LocalMealPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMealPrefsTable> {
  $$LocalMealPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stance => $composableBuilder(
    column: $table.stance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMealPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMealPrefsTable> {
  $$LocalMealPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stance => $composableBuilder(
    column: $table.stance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMealPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMealPrefsTable> {
  $$LocalMealPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get stance =>
      $composableBuilder(column: $table.stance, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMealPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMealPrefsTable,
          LocalMealPref,
          $$LocalMealPrefsTableFilterComposer,
          $$LocalMealPrefsTableOrderingComposer,
          $$LocalMealPrefsTableAnnotationComposer,
          $$LocalMealPrefsTableCreateCompanionBuilder,
          $$LocalMealPrefsTableUpdateCompanionBuilder,
          (
            LocalMealPref,
            BaseReferences<_$AppDatabase, $LocalMealPrefsTable, LocalMealPref>,
          ),
          LocalMealPref,
          PrefetchHooks Function()
        > {
  $$LocalMealPrefsTableTableManager(
    _$AppDatabase db,
    $LocalMealPrefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMealPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMealPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMealPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> mealId = const Value.absent(),
                Value<String> stance = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalMealPrefsCompanion(
                mealId: mealId,
                stance: stance,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> mealId = const Value.absent(),
                required String stance,
                required DateTime updatedAt,
              }) => LocalMealPrefsCompanion.insert(
                mealId: mealId,
                stance: stance,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMealPrefsTable, LocalMealPref>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalMealPrefsTable,
                    LocalMealPref
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMealPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMealPrefsTable,
      LocalMealPref,
      $$LocalMealPrefsTableFilterComposer,
      $$LocalMealPrefsTableOrderingComposer,
      $$LocalMealPrefsTableAnnotationComposer,
      $$LocalMealPrefsTableCreateCompanionBuilder,
      $$LocalMealPrefsTableUpdateCompanionBuilder,
      (
        LocalMealPref,
        BaseReferences<_$AppDatabase, $LocalMealPrefsTable, LocalMealPref>,
      ),
      LocalMealPref,
      PrefetchHooks Function()
    >;
typedef $$UserAllergensTableCreateCompanionBuilder =
    UserAllergensCompanion Function({
      required String code,
      required String severity,
      Value<int> rowid,
    });
typedef $$UserAllergensTableUpdateCompanionBuilder =
    UserAllergensCompanion Function({
      Value<String> code,
      Value<String> severity,
      Value<int> rowid,
    });

class $$UserAllergensTableFilterComposer
    extends Composer<_$AppDatabase, $UserAllergensTable> {
  $$UserAllergensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserAllergensTableOrderingComposer
    extends Composer<_$AppDatabase, $UserAllergensTable> {
  $$UserAllergensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserAllergensTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserAllergensTable> {
  $$UserAllergensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);
}

class $$UserAllergensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserAllergensTable,
          UserAllergen,
          $$UserAllergensTableFilterComposer,
          $$UserAllergensTableOrderingComposer,
          $$UserAllergensTableAnnotationComposer,
          $$UserAllergensTableCreateCompanionBuilder,
          $$UserAllergensTableUpdateCompanionBuilder,
          (
            UserAllergen,
            BaseReferences<_$AppDatabase, $UserAllergensTable, UserAllergen>,
          ),
          UserAllergen,
          PrefetchHooks Function()
        > {
  $$UserAllergensTableTableManager(_$AppDatabase db, $UserAllergensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserAllergensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserAllergensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserAllergensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserAllergensCompanion(
                code: code,
                severity: severity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String severity,
                Value<int> rowid = const Value.absent(),
              }) => UserAllergensCompanion.insert(
                code: code,
                severity: severity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserAllergensTable, UserAllergen>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserAllergensTable,
                    UserAllergen
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserAllergensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserAllergensTable,
      UserAllergen,
      $$UserAllergensTableFilterComposer,
      $$UserAllergensTableOrderingComposer,
      $$UserAllergensTableAnnotationComposer,
      $$UserAllergensTableCreateCompanionBuilder,
      $$UserAllergensTableUpdateCompanionBuilder,
      (
        UserAllergen,
        BaseReferences<_$AppDatabase, $UserAllergensTable, UserAllergen>,
      ),
      UserAllergen,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CatalogMetaTableTableManager get catalogMeta =>
      $$CatalogMetaTableTableManager(_db, _db.catalogMeta);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$MealTagsTableTableManager get mealTags =>
      $$MealTagsTableTableManager(_db, _db.mealTags);
  $$MealAllergensTableTableManager get mealAllergens =>
      $$MealAllergensTableTableManager(_db, _db.mealAllergens);
  $$MealIngredientsTableTableManager get mealIngredients =>
      $$MealIngredientsTableTableManager(_db, _db.mealIngredients);
  $$MealNutrientsTableTableManager get mealNutrients =>
      $$MealNutrientsTableTableManager(_db, _db.mealNutrients);
  $$MealStepsTableTableManager get mealSteps =>
      $$MealStepsTableTableManager(_db, _db.mealSteps);
  $$CuisinesTableTableManager get cuisines =>
      $$CuisinesTableTableManager(_db, _db.cuisines);
  $$LocalMealPrefsTableTableManager get localMealPrefs =>
      $$LocalMealPrefsTableTableManager(_db, _db.localMealPrefs);
  $$UserAllergensTableTableManager get userAllergens =>
      $$UserAllergensTableTableManager(_db, _db.userAllergens);
}
