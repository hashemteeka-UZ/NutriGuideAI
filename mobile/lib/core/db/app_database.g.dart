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

class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planDateMeta = const VerificationMeta(
    'planDate',
  );
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
    'plan_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _algorithmVersionMeta = const VerificationMeta(
    'algorithmVersion',
  );
  @override
  late final GeneratedColumn<String> algorithmVersion = GeneratedColumn<String>(
    'algorithm_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<int> kcal = GeneratedColumn<int>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<int> fiberG = GeneratedColumn<int>(
    'fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalsKcalMeta = const VerificationMeta(
    'totalsKcal',
  );
  @override
  late final GeneratedColumn<double> totalsKcal = GeneratedColumn<double>(
    'totals_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalsProteinGMeta = const VerificationMeta(
    'totalsProteinG',
  );
  @override
  late final GeneratedColumn<double> totalsProteinG = GeneratedColumn<double>(
    'totals_protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalsCarbGMeta = const VerificationMeta(
    'totalsCarbG',
  );
  @override
  late final GeneratedColumn<double> totalsCarbG = GeneratedColumn<double>(
    'totals_carb_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalsFatGMeta = const VerificationMeta(
    'totalsFatG',
  );
  @override
  late final GeneratedColumn<double> totalsFatG = GeneratedColumn<double>(
    'totals_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalsFiberGMeta = const VerificationMeta(
    'totalsFiberG',
  );
  @override
  late final GeneratedColumn<double> totalsFiberG = GeneratedColumn<double>(
    'totals_fiber_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalsSaturatedFatGMeta =
      const VerificationMeta('totalsSaturatedFatG');
  @override
  late final GeneratedColumn<double> totalsSaturatedFatG =
      GeneratedColumn<double>(
        'totals_saturated_fat_g',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalsSodiumMgMeta = const VerificationMeta(
    'totalsSodiumMg',
  );
  @override
  late final GeneratedColumn<double> totalsSodiumMg = GeneratedColumn<double>(
    'totals_sodium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalsSugarsGMeta = const VerificationMeta(
    'totalsSugarsG',
  );
  @override
  late final GeneratedColumn<double> totalsSugarsG = GeneratedColumn<double>(
    'totals_sugars_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalWithin10pctMeta = const VerificationMeta(
    'kcalWithin10pct',
  );
  @override
  late final GeneratedColumn<bool> kcalWithin10pct = GeneratedColumn<bool>(
    'kcal_within10pct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kcal_within10pct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _solverStatusMeta = const VerificationMeta(
    'solverStatus',
  );
  @override
  late final GeneratedColumn<String> solverStatus = GeneratedColumn<String>(
    'solver_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalRelaxedMeta = const VerificationMeta(
    'kcalRelaxed',
  );
  @override
  late final GeneratedColumn<bool> kcalRelaxed = GeneratedColumn<bool>(
    'kcal_relaxed',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kcal_relaxed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _solveSecondsMeta = const VerificationMeta(
    'solveSeconds',
  );
  @override
  late final GeneratedColumn<double> solveSeconds = GeneratedColumn<double>(
    'solve_seconds',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _candidateMealsMeta = const VerificationMeta(
    'candidateMeals',
  );
  @override
  late final GeneratedColumn<int> candidateMeals = GeneratedColumn<int>(
    'candidate_meals',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    planDate,
    planId,
    algorithmVersion,
    createdAt,
    kcal,
    proteinG,
    carbG,
    fatG,
    fiberG,
    totalsKcal,
    totalsProteinG,
    totalsCarbG,
    totalsFatG,
    totalsFiberG,
    totalsSaturatedFatG,
    totalsSodiumMg,
    totalsSugarsG,
    kcalWithin10pct,
    solverStatus,
    kcalRelaxed,
    solveSeconds,
    candidateMeals,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_date')) {
      context.handle(
        _planDateMeta,
        planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta),
      );
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('algorithm_version')) {
      context.handle(
        _algorithmVersionMeta,
        algorithmVersion.isAcceptableOrUnknown(
          data['algorithm_version']!,
          _algorithmVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_algorithmVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    } else if (isInserting) {
      context.missing(_fiberGMeta);
    }
    if (data.containsKey('totals_kcal')) {
      context.handle(
        _totalsKcalMeta,
        totalsKcal.isAcceptableOrUnknown(data['totals_kcal']!, _totalsKcalMeta),
      );
    }
    if (data.containsKey('totals_protein_g')) {
      context.handle(
        _totalsProteinGMeta,
        totalsProteinG.isAcceptableOrUnknown(
          data['totals_protein_g']!,
          _totalsProteinGMeta,
        ),
      );
    }
    if (data.containsKey('totals_carb_g')) {
      context.handle(
        _totalsCarbGMeta,
        totalsCarbG.isAcceptableOrUnknown(
          data['totals_carb_g']!,
          _totalsCarbGMeta,
        ),
      );
    }
    if (data.containsKey('totals_fat_g')) {
      context.handle(
        _totalsFatGMeta,
        totalsFatG.isAcceptableOrUnknown(
          data['totals_fat_g']!,
          _totalsFatGMeta,
        ),
      );
    }
    if (data.containsKey('totals_fiber_g')) {
      context.handle(
        _totalsFiberGMeta,
        totalsFiberG.isAcceptableOrUnknown(
          data['totals_fiber_g']!,
          _totalsFiberGMeta,
        ),
      );
    }
    if (data.containsKey('totals_saturated_fat_g')) {
      context.handle(
        _totalsSaturatedFatGMeta,
        totalsSaturatedFatG.isAcceptableOrUnknown(
          data['totals_saturated_fat_g']!,
          _totalsSaturatedFatGMeta,
        ),
      );
    }
    if (data.containsKey('totals_sodium_mg')) {
      context.handle(
        _totalsSodiumMgMeta,
        totalsSodiumMg.isAcceptableOrUnknown(
          data['totals_sodium_mg']!,
          _totalsSodiumMgMeta,
        ),
      );
    }
    if (data.containsKey('totals_sugars_g')) {
      context.handle(
        _totalsSugarsGMeta,
        totalsSugarsG.isAcceptableOrUnknown(
          data['totals_sugars_g']!,
          _totalsSugarsGMeta,
        ),
      );
    }
    if (data.containsKey('kcal_within10pct')) {
      context.handle(
        _kcalWithin10pctMeta,
        kcalWithin10pct.isAcceptableOrUnknown(
          data['kcal_within10pct']!,
          _kcalWithin10pctMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kcalWithin10pctMeta);
    }
    if (data.containsKey('solver_status')) {
      context.handle(
        _solverStatusMeta,
        solverStatus.isAcceptableOrUnknown(
          data['solver_status']!,
          _solverStatusMeta,
        ),
      );
    }
    if (data.containsKey('kcal_relaxed')) {
      context.handle(
        _kcalRelaxedMeta,
        kcalRelaxed.isAcceptableOrUnknown(
          data['kcal_relaxed']!,
          _kcalRelaxedMeta,
        ),
      );
    }
    if (data.containsKey('solve_seconds')) {
      context.handle(
        _solveSecondsMeta,
        solveSeconds.isAcceptableOrUnknown(
          data['solve_seconds']!,
          _solveSecondsMeta,
        ),
      );
    }
    if (data.containsKey('candidate_meals')) {
      context.handle(
        _candidateMealsMeta,
        candidateMeals.isAcceptableOrUnknown(
          data['candidate_meals']!,
          _candidateMealsMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {planDate};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      planDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_date'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      algorithmVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}algorithm_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
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
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fiber_g'],
      )!,
      totalsKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_kcal'],
      ),
      totalsProteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_protein_g'],
      ),
      totalsCarbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_carb_g'],
      ),
      totalsFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_fat_g'],
      ),
      totalsFiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_fiber_g'],
      ),
      totalsSaturatedFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_saturated_fat_g'],
      ),
      totalsSodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_sodium_mg'],
      ),
      totalsSugarsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}totals_sugars_g'],
      ),
      kcalWithin10pct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kcal_within10pct'],
      )!,
      solverStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solver_status'],
      ),
      kcalRelaxed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kcal_relaxed'],
      ),
      solveSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}solve_seconds'],
      ),
      candidateMeals: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}candidate_meals'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final String planDate;
  final int planId;
  final String algorithmVersion;
  final DateTime createdAt;
  final int kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final int fiberG;
  final double? totalsKcal;
  final double? totalsProteinG;
  final double? totalsCarbG;
  final double? totalsFatG;
  final double? totalsFiberG;
  final double? totalsSaturatedFatG;
  final double? totalsSodiumMg;
  final double? totalsSugarsG;
  final bool kcalWithin10pct;
  final String? solverStatus;
  final bool? kcalRelaxed;
  final double? solveSeconds;
  final int? candidateMeals;
  final DateTime fetchedAt;
  const Plan({
    required this.planDate,
    required this.planId,
    required this.algorithmVersion,
    required this.createdAt,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    this.totalsKcal,
    this.totalsProteinG,
    this.totalsCarbG,
    this.totalsFatG,
    this.totalsFiberG,
    this.totalsSaturatedFatG,
    this.totalsSodiumMg,
    this.totalsSugarsG,
    required this.kcalWithin10pct,
    this.solverStatus,
    this.kcalRelaxed,
    this.solveSeconds,
    this.candidateMeals,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_date'] = Variable<String>(planDate);
    map['plan_id'] = Variable<int>(planId);
    map['algorithm_version'] = Variable<String>(algorithmVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['kcal'] = Variable<int>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carb_g'] = Variable<double>(carbG);
    map['fat_g'] = Variable<double>(fatG);
    map['fiber_g'] = Variable<int>(fiberG);
    if (!nullToAbsent || totalsKcal != null) {
      map['totals_kcal'] = Variable<double>(totalsKcal);
    }
    if (!nullToAbsent || totalsProteinG != null) {
      map['totals_protein_g'] = Variable<double>(totalsProteinG);
    }
    if (!nullToAbsent || totalsCarbG != null) {
      map['totals_carb_g'] = Variable<double>(totalsCarbG);
    }
    if (!nullToAbsent || totalsFatG != null) {
      map['totals_fat_g'] = Variable<double>(totalsFatG);
    }
    if (!nullToAbsent || totalsFiberG != null) {
      map['totals_fiber_g'] = Variable<double>(totalsFiberG);
    }
    if (!nullToAbsent || totalsSaturatedFatG != null) {
      map['totals_saturated_fat_g'] = Variable<double>(totalsSaturatedFatG);
    }
    if (!nullToAbsent || totalsSodiumMg != null) {
      map['totals_sodium_mg'] = Variable<double>(totalsSodiumMg);
    }
    if (!nullToAbsent || totalsSugarsG != null) {
      map['totals_sugars_g'] = Variable<double>(totalsSugarsG);
    }
    map['kcal_within10pct'] = Variable<bool>(kcalWithin10pct);
    if (!nullToAbsent || solverStatus != null) {
      map['solver_status'] = Variable<String>(solverStatus);
    }
    if (!nullToAbsent || kcalRelaxed != null) {
      map['kcal_relaxed'] = Variable<bool>(kcalRelaxed);
    }
    if (!nullToAbsent || solveSeconds != null) {
      map['solve_seconds'] = Variable<double>(solveSeconds);
    }
    if (!nullToAbsent || candidateMeals != null) {
      map['candidate_meals'] = Variable<int>(candidateMeals);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      planDate: Value(planDate),
      planId: Value(planId),
      algorithmVersion: Value(algorithmVersion),
      createdAt: Value(createdAt),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbG: Value(carbG),
      fatG: Value(fatG),
      fiberG: Value(fiberG),
      totalsKcal: totalsKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsKcal),
      totalsProteinG: totalsProteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsProteinG),
      totalsCarbG: totalsCarbG == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsCarbG),
      totalsFatG: totalsFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsFatG),
      totalsFiberG: totalsFiberG == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsFiberG),
      totalsSaturatedFatG: totalsSaturatedFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsSaturatedFatG),
      totalsSodiumMg: totalsSodiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsSodiumMg),
      totalsSugarsG: totalsSugarsG == null && nullToAbsent
          ? const Value.absent()
          : Value(totalsSugarsG),
      kcalWithin10pct: Value(kcalWithin10pct),
      solverStatus: solverStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(solverStatus),
      kcalRelaxed: kcalRelaxed == null && nullToAbsent
          ? const Value.absent()
          : Value(kcalRelaxed),
      solveSeconds: solveSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(solveSeconds),
      candidateMeals: candidateMeals == null && nullToAbsent
          ? const Value.absent()
          : Value(candidateMeals),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory Plan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      planDate: serializer.fromJson<String>(json['planDate']),
      planId: serializer.fromJson<int>(json['planId']),
      algorithmVersion: serializer.fromJson<String>(json['algorithmVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      kcal: serializer.fromJson<int>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbG: serializer.fromJson<double>(json['carbG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      fiberG: serializer.fromJson<int>(json['fiberG']),
      totalsKcal: serializer.fromJson<double?>(json['totalsKcal']),
      totalsProteinG: serializer.fromJson<double?>(json['totalsProteinG']),
      totalsCarbG: serializer.fromJson<double?>(json['totalsCarbG']),
      totalsFatG: serializer.fromJson<double?>(json['totalsFatG']),
      totalsFiberG: serializer.fromJson<double?>(json['totalsFiberG']),
      totalsSaturatedFatG: serializer.fromJson<double?>(
        json['totalsSaturatedFatG'],
      ),
      totalsSodiumMg: serializer.fromJson<double?>(json['totalsSodiumMg']),
      totalsSugarsG: serializer.fromJson<double?>(json['totalsSugarsG']),
      kcalWithin10pct: serializer.fromJson<bool>(json['kcalWithin10pct']),
      solverStatus: serializer.fromJson<String?>(json['solverStatus']),
      kcalRelaxed: serializer.fromJson<bool?>(json['kcalRelaxed']),
      solveSeconds: serializer.fromJson<double?>(json['solveSeconds']),
      candidateMeals: serializer.fromJson<int?>(json['candidateMeals']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planDate': serializer.toJson<String>(planDate),
      'planId': serializer.toJson<int>(planId),
      'algorithmVersion': serializer.toJson<String>(algorithmVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'kcal': serializer.toJson<int>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbG': serializer.toJson<double>(carbG),
      'fatG': serializer.toJson<double>(fatG),
      'fiberG': serializer.toJson<int>(fiberG),
      'totalsKcal': serializer.toJson<double?>(totalsKcal),
      'totalsProteinG': serializer.toJson<double?>(totalsProteinG),
      'totalsCarbG': serializer.toJson<double?>(totalsCarbG),
      'totalsFatG': serializer.toJson<double?>(totalsFatG),
      'totalsFiberG': serializer.toJson<double?>(totalsFiberG),
      'totalsSaturatedFatG': serializer.toJson<double?>(totalsSaturatedFatG),
      'totalsSodiumMg': serializer.toJson<double?>(totalsSodiumMg),
      'totalsSugarsG': serializer.toJson<double?>(totalsSugarsG),
      'kcalWithin10pct': serializer.toJson<bool>(kcalWithin10pct),
      'solverStatus': serializer.toJson<String?>(solverStatus),
      'kcalRelaxed': serializer.toJson<bool?>(kcalRelaxed),
      'solveSeconds': serializer.toJson<double?>(solveSeconds),
      'candidateMeals': serializer.toJson<int?>(candidateMeals),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  Plan copyWith({
    String? planDate,
    int? planId,
    String? algorithmVersion,
    DateTime? createdAt,
    int? kcal,
    double? proteinG,
    double? carbG,
    double? fatG,
    int? fiberG,
    Value<double?> totalsKcal = const Value.absent(),
    Value<double?> totalsProteinG = const Value.absent(),
    Value<double?> totalsCarbG = const Value.absent(),
    Value<double?> totalsFatG = const Value.absent(),
    Value<double?> totalsFiberG = const Value.absent(),
    Value<double?> totalsSaturatedFatG = const Value.absent(),
    Value<double?> totalsSodiumMg = const Value.absent(),
    Value<double?> totalsSugarsG = const Value.absent(),
    bool? kcalWithin10pct,
    Value<String?> solverStatus = const Value.absent(),
    Value<bool?> kcalRelaxed = const Value.absent(),
    Value<double?> solveSeconds = const Value.absent(),
    Value<int?> candidateMeals = const Value.absent(),
    DateTime? fetchedAt,
  }) => Plan(
    planDate: planDate ?? this.planDate,
    planId: planId ?? this.planId,
    algorithmVersion: algorithmVersion ?? this.algorithmVersion,
    createdAt: createdAt ?? this.createdAt,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbG: carbG ?? this.carbG,
    fatG: fatG ?? this.fatG,
    fiberG: fiberG ?? this.fiberG,
    totalsKcal: totalsKcal.present ? totalsKcal.value : this.totalsKcal,
    totalsProteinG: totalsProteinG.present
        ? totalsProteinG.value
        : this.totalsProteinG,
    totalsCarbG: totalsCarbG.present ? totalsCarbG.value : this.totalsCarbG,
    totalsFatG: totalsFatG.present ? totalsFatG.value : this.totalsFatG,
    totalsFiberG: totalsFiberG.present ? totalsFiberG.value : this.totalsFiberG,
    totalsSaturatedFatG: totalsSaturatedFatG.present
        ? totalsSaturatedFatG.value
        : this.totalsSaturatedFatG,
    totalsSodiumMg: totalsSodiumMg.present
        ? totalsSodiumMg.value
        : this.totalsSodiumMg,
    totalsSugarsG: totalsSugarsG.present
        ? totalsSugarsG.value
        : this.totalsSugarsG,
    kcalWithin10pct: kcalWithin10pct ?? this.kcalWithin10pct,
    solverStatus: solverStatus.present ? solverStatus.value : this.solverStatus,
    kcalRelaxed: kcalRelaxed.present ? kcalRelaxed.value : this.kcalRelaxed,
    solveSeconds: solveSeconds.present ? solveSeconds.value : this.solveSeconds,
    candidateMeals: candidateMeals.present
        ? candidateMeals.value
        : this.candidateMeals,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      planId: data.planId.present ? data.planId.value : this.planId,
      algorithmVersion: data.algorithmVersion.present
          ? data.algorithmVersion.value
          : this.algorithmVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      totalsKcal: data.totalsKcal.present
          ? data.totalsKcal.value
          : this.totalsKcal,
      totalsProteinG: data.totalsProteinG.present
          ? data.totalsProteinG.value
          : this.totalsProteinG,
      totalsCarbG: data.totalsCarbG.present
          ? data.totalsCarbG.value
          : this.totalsCarbG,
      totalsFatG: data.totalsFatG.present
          ? data.totalsFatG.value
          : this.totalsFatG,
      totalsFiberG: data.totalsFiberG.present
          ? data.totalsFiberG.value
          : this.totalsFiberG,
      totalsSaturatedFatG: data.totalsSaturatedFatG.present
          ? data.totalsSaturatedFatG.value
          : this.totalsSaturatedFatG,
      totalsSodiumMg: data.totalsSodiumMg.present
          ? data.totalsSodiumMg.value
          : this.totalsSodiumMg,
      totalsSugarsG: data.totalsSugarsG.present
          ? data.totalsSugarsG.value
          : this.totalsSugarsG,
      kcalWithin10pct: data.kcalWithin10pct.present
          ? data.kcalWithin10pct.value
          : this.kcalWithin10pct,
      solverStatus: data.solverStatus.present
          ? data.solverStatus.value
          : this.solverStatus,
      kcalRelaxed: data.kcalRelaxed.present
          ? data.kcalRelaxed.value
          : this.kcalRelaxed,
      solveSeconds: data.solveSeconds.present
          ? data.solveSeconds.value
          : this.solveSeconds,
      candidateMeals: data.candidateMeals.present
          ? data.candidateMeals.value
          : this.candidateMeals,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('planDate: $planDate, ')
          ..write('planId: $planId, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('totalsKcal: $totalsKcal, ')
          ..write('totalsProteinG: $totalsProteinG, ')
          ..write('totalsCarbG: $totalsCarbG, ')
          ..write('totalsFatG: $totalsFatG, ')
          ..write('totalsFiberG: $totalsFiberG, ')
          ..write('totalsSaturatedFatG: $totalsSaturatedFatG, ')
          ..write('totalsSodiumMg: $totalsSodiumMg, ')
          ..write('totalsSugarsG: $totalsSugarsG, ')
          ..write('kcalWithin10pct: $kcalWithin10pct, ')
          ..write('solverStatus: $solverStatus, ')
          ..write('kcalRelaxed: $kcalRelaxed, ')
          ..write('solveSeconds: $solveSeconds, ')
          ..write('candidateMeals: $candidateMeals, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    planDate,
    planId,
    algorithmVersion,
    createdAt,
    kcal,
    proteinG,
    carbG,
    fatG,
    fiberG,
    totalsKcal,
    totalsProteinG,
    totalsCarbG,
    totalsFatG,
    totalsFiberG,
    totalsSaturatedFatG,
    totalsSodiumMg,
    totalsSugarsG,
    kcalWithin10pct,
    solverStatus,
    kcalRelaxed,
    solveSeconds,
    candidateMeals,
    fetchedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.planDate == this.planDate &&
          other.planId == this.planId &&
          other.algorithmVersion == this.algorithmVersion &&
          other.createdAt == this.createdAt &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.fiberG == this.fiberG &&
          other.totalsKcal == this.totalsKcal &&
          other.totalsProteinG == this.totalsProteinG &&
          other.totalsCarbG == this.totalsCarbG &&
          other.totalsFatG == this.totalsFatG &&
          other.totalsFiberG == this.totalsFiberG &&
          other.totalsSaturatedFatG == this.totalsSaturatedFatG &&
          other.totalsSodiumMg == this.totalsSodiumMg &&
          other.totalsSugarsG == this.totalsSugarsG &&
          other.kcalWithin10pct == this.kcalWithin10pct &&
          other.solverStatus == this.solverStatus &&
          other.kcalRelaxed == this.kcalRelaxed &&
          other.solveSeconds == this.solveSeconds &&
          other.candidateMeals == this.candidateMeals &&
          other.fetchedAt == this.fetchedAt);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> planDate;
  final Value<int> planId;
  final Value<String> algorithmVersion;
  final Value<DateTime> createdAt;
  final Value<int> kcal;
  final Value<double> proteinG;
  final Value<double> carbG;
  final Value<double> fatG;
  final Value<int> fiberG;
  final Value<double?> totalsKcal;
  final Value<double?> totalsProteinG;
  final Value<double?> totalsCarbG;
  final Value<double?> totalsFatG;
  final Value<double?> totalsFiberG;
  final Value<double?> totalsSaturatedFatG;
  final Value<double?> totalsSodiumMg;
  final Value<double?> totalsSugarsG;
  final Value<bool> kcalWithin10pct;
  final Value<String?> solverStatus;
  final Value<bool?> kcalRelaxed;
  final Value<double?> solveSeconds;
  final Value<int?> candidateMeals;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const PlansCompanion({
    this.planDate = const Value.absent(),
    this.planId = const Value.absent(),
    this.algorithmVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.totalsKcal = const Value.absent(),
    this.totalsProteinG = const Value.absent(),
    this.totalsCarbG = const Value.absent(),
    this.totalsFatG = const Value.absent(),
    this.totalsFiberG = const Value.absent(),
    this.totalsSaturatedFatG = const Value.absent(),
    this.totalsSodiumMg = const Value.absent(),
    this.totalsSugarsG = const Value.absent(),
    this.kcalWithin10pct = const Value.absent(),
    this.solverStatus = const Value.absent(),
    this.kcalRelaxed = const Value.absent(),
    this.solveSeconds = const Value.absent(),
    this.candidateMeals = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String planDate,
    required int planId,
    required String algorithmVersion,
    required DateTime createdAt,
    required int kcal,
    required double proteinG,
    required double carbG,
    required double fatG,
    required int fiberG,
    this.totalsKcal = const Value.absent(),
    this.totalsProteinG = const Value.absent(),
    this.totalsCarbG = const Value.absent(),
    this.totalsFatG = const Value.absent(),
    this.totalsFiberG = const Value.absent(),
    this.totalsSaturatedFatG = const Value.absent(),
    this.totalsSodiumMg = const Value.absent(),
    this.totalsSugarsG = const Value.absent(),
    required bool kcalWithin10pct,
    this.solverStatus = const Value.absent(),
    this.kcalRelaxed = const Value.absent(),
    this.solveSeconds = const Value.absent(),
    this.candidateMeals = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : planDate = Value(planDate),
       planId = Value(planId),
       algorithmVersion = Value(algorithmVersion),
       createdAt = Value(createdAt),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbG = Value(carbG),
       fatG = Value(fatG),
       fiberG = Value(fiberG),
       kcalWithin10pct = Value(kcalWithin10pct),
       fetchedAt = Value(fetchedAt);
  static Insertable<Plan> custom({
    Expression<String>? planDate,
    Expression<int>? planId,
    Expression<String>? algorithmVersion,
    Expression<DateTime>? createdAt,
    Expression<int>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<int>? fiberG,
    Expression<double>? totalsKcal,
    Expression<double>? totalsProteinG,
    Expression<double>? totalsCarbG,
    Expression<double>? totalsFatG,
    Expression<double>? totalsFiberG,
    Expression<double>? totalsSaturatedFatG,
    Expression<double>? totalsSodiumMg,
    Expression<double>? totalsSugarsG,
    Expression<bool>? kcalWithin10pct,
    Expression<String>? solverStatus,
    Expression<bool>? kcalRelaxed,
    Expression<double>? solveSeconds,
    Expression<int>? candidateMeals,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planDate != null) 'plan_date': planDate,
      if (planId != null) 'plan_id': planId,
      if (algorithmVersion != null) 'algorithm_version': algorithmVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (totalsKcal != null) 'totals_kcal': totalsKcal,
      if (totalsProteinG != null) 'totals_protein_g': totalsProteinG,
      if (totalsCarbG != null) 'totals_carb_g': totalsCarbG,
      if (totalsFatG != null) 'totals_fat_g': totalsFatG,
      if (totalsFiberG != null) 'totals_fiber_g': totalsFiberG,
      if (totalsSaturatedFatG != null)
        'totals_saturated_fat_g': totalsSaturatedFatG,
      if (totalsSodiumMg != null) 'totals_sodium_mg': totalsSodiumMg,
      if (totalsSugarsG != null) 'totals_sugars_g': totalsSugarsG,
      if (kcalWithin10pct != null) 'kcal_within10pct': kcalWithin10pct,
      if (solverStatus != null) 'solver_status': solverStatus,
      if (kcalRelaxed != null) 'kcal_relaxed': kcalRelaxed,
      if (solveSeconds != null) 'solve_seconds': solveSeconds,
      if (candidateMeals != null) 'candidate_meals': candidateMeals,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<String>? planDate,
    Value<int>? planId,
    Value<String>? algorithmVersion,
    Value<DateTime>? createdAt,
    Value<int>? kcal,
    Value<double>? proteinG,
    Value<double>? carbG,
    Value<double>? fatG,
    Value<int>? fiberG,
    Value<double?>? totalsKcal,
    Value<double?>? totalsProteinG,
    Value<double?>? totalsCarbG,
    Value<double?>? totalsFatG,
    Value<double?>? totalsFiberG,
    Value<double?>? totalsSaturatedFatG,
    Value<double?>? totalsSodiumMg,
    Value<double?>? totalsSugarsG,
    Value<bool>? kcalWithin10pct,
    Value<String?>? solverStatus,
    Value<bool?>? kcalRelaxed,
    Value<double?>? solveSeconds,
    Value<int?>? candidateMeals,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      planDate: planDate ?? this.planDate,
      planId: planId ?? this.planId,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      createdAt: createdAt ?? this.createdAt,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      totalsKcal: totalsKcal ?? this.totalsKcal,
      totalsProteinG: totalsProteinG ?? this.totalsProteinG,
      totalsCarbG: totalsCarbG ?? this.totalsCarbG,
      totalsFatG: totalsFatG ?? this.totalsFatG,
      totalsFiberG: totalsFiberG ?? this.totalsFiberG,
      totalsSaturatedFatG: totalsSaturatedFatG ?? this.totalsSaturatedFatG,
      totalsSodiumMg: totalsSodiumMg ?? this.totalsSodiumMg,
      totalsSugarsG: totalsSugarsG ?? this.totalsSugarsG,
      kcalWithin10pct: kcalWithin10pct ?? this.kcalWithin10pct,
      solverStatus: solverStatus ?? this.solverStatus,
      kcalRelaxed: kcalRelaxed ?? this.kcalRelaxed,
      solveSeconds: solveSeconds ?? this.solveSeconds,
      candidateMeals: candidateMeals ?? this.candidateMeals,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (algorithmVersion.present) {
      map['algorithm_version'] = Variable<String>(algorithmVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<int>(kcal.value);
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
    if (fiberG.present) {
      map['fiber_g'] = Variable<int>(fiberG.value);
    }
    if (totalsKcal.present) {
      map['totals_kcal'] = Variable<double>(totalsKcal.value);
    }
    if (totalsProteinG.present) {
      map['totals_protein_g'] = Variable<double>(totalsProteinG.value);
    }
    if (totalsCarbG.present) {
      map['totals_carb_g'] = Variable<double>(totalsCarbG.value);
    }
    if (totalsFatG.present) {
      map['totals_fat_g'] = Variable<double>(totalsFatG.value);
    }
    if (totalsFiberG.present) {
      map['totals_fiber_g'] = Variable<double>(totalsFiberG.value);
    }
    if (totalsSaturatedFatG.present) {
      map['totals_saturated_fat_g'] = Variable<double>(
        totalsSaturatedFatG.value,
      );
    }
    if (totalsSodiumMg.present) {
      map['totals_sodium_mg'] = Variable<double>(totalsSodiumMg.value);
    }
    if (totalsSugarsG.present) {
      map['totals_sugars_g'] = Variable<double>(totalsSugarsG.value);
    }
    if (kcalWithin10pct.present) {
      map['kcal_within10pct'] = Variable<bool>(kcalWithin10pct.value);
    }
    if (solverStatus.present) {
      map['solver_status'] = Variable<String>(solverStatus.value);
    }
    if (kcalRelaxed.present) {
      map['kcal_relaxed'] = Variable<bool>(kcalRelaxed.value);
    }
    if (solveSeconds.present) {
      map['solve_seconds'] = Variable<double>(solveSeconds.value);
    }
    if (candidateMeals.present) {
      map['candidate_meals'] = Variable<int>(candidateMeals.value);
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
    return (StringBuffer('PlansCompanion(')
          ..write('planDate: $planDate, ')
          ..write('planId: $planId, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('totalsKcal: $totalsKcal, ')
          ..write('totalsProteinG: $totalsProteinG, ')
          ..write('totalsCarbG: $totalsCarbG, ')
          ..write('totalsFatG: $totalsFatG, ')
          ..write('totalsFiberG: $totalsFiberG, ')
          ..write('totalsSaturatedFatG: $totalsSaturatedFatG, ')
          ..write('totalsSodiumMg: $totalsSodiumMg, ')
          ..write('totalsSugarsG: $totalsSugarsG, ')
          ..write('kcalWithin10pct: $kcalWithin10pct, ')
          ..write('solverStatus: $solverStatus, ')
          ..write('kcalRelaxed: $kcalRelaxed, ')
          ..write('solveSeconds: $solveSeconds, ')
          ..write('candidateMeals: $candidateMeals, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanItemsTable extends PlanItems
    with TableInfo<$PlanItemsTable, PlanItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planItemIdMeta = const VerificationMeta(
    'planItemId',
  );
  @override
  late final GeneratedColumn<int> planItemId = GeneratedColumn<int>(
    'plan_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planDateMeta = const VerificationMeta(
    'planDate',
  );
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
    'plan_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plans (plan_date) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
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
  static const VerificationMeta _mealNameMeta = const VerificationMeta(
    'mealName',
  );
  @override
  late final GeneratedColumn<String> mealName = GeneratedColumn<String>(
    'meal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingsMultiplierMeta =
      const VerificationMeta('servingsMultiplier');
  @override
  late final GeneratedColumn<double> servingsMultiplier =
      GeneratedColumn<double>(
        'servings_multiplier',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
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
  static const VerificationMeta _reasonCodesMeta = const VerificationMeta(
    'reasonCodes',
  );
  @override
  late final GeneratedColumn<String> reasonCodes = GeneratedColumn<String>(
    'reason_codes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasSwappedMeta = const VerificationMeta(
    'wasSwapped',
  );
  @override
  late final GeneratedColumn<bool> wasSwapped = GeneratedColumn<bool>(
    'was_swapped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_swapped" IN (0, 1))',
    ),
  );
  static const VerificationMeta _loggedMeta = const VerificationMeta('logged');
  @override
  late final GeneratedColumn<bool> logged = GeneratedColumn<bool>(
    'logged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("logged" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    planItemId,
    planDate,
    position,
    slot,
    mealId,
    mealName,
    servingsMultiplier,
    grams,
    kcal,
    proteinG,
    carbG,
    fatG,
    reasonCodes,
    wasSwapped,
    logged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_item_id')) {
      context.handle(
        _planItemIdMeta,
        planItemId.isAcceptableOrUnknown(
          data['plan_item_id']!,
          _planItemIdMeta,
        ),
      );
    }
    if (data.containsKey('plan_date')) {
      context.handle(
        _planDateMeta,
        planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta),
      );
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('meal_name')) {
      context.handle(
        _mealNameMeta,
        mealName.isAcceptableOrUnknown(data['meal_name']!, _mealNameMeta),
      );
    } else if (isInserting) {
      context.missing(_mealNameMeta);
    }
    if (data.containsKey('servings_multiplier')) {
      context.handle(
        _servingsMultiplierMeta,
        servingsMultiplier.isAcceptableOrUnknown(
          data['servings_multiplier']!,
          _servingsMultiplierMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servingsMultiplierMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
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
    if (data.containsKey('reason_codes')) {
      context.handle(
        _reasonCodesMeta,
        reasonCodes.isAcceptableOrUnknown(
          data['reason_codes']!,
          _reasonCodesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reasonCodesMeta);
    }
    if (data.containsKey('was_swapped')) {
      context.handle(
        _wasSwappedMeta,
        wasSwapped.isAcceptableOrUnknown(data['was_swapped']!, _wasSwappedMeta),
      );
    } else if (isInserting) {
      context.missing(_wasSwappedMeta);
    }
    if (data.containsKey('logged')) {
      context.handle(
        _loggedMeta,
        logged.isAcceptableOrUnknown(data['logged']!, _loggedMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planItemId};
  @override
  PlanItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanItem(
      planItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_item_id'],
      )!,
      planDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_date'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      )!,
      mealName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_name'],
      )!,
      servingsMultiplier: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}servings_multiplier'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
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
      reasonCodes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_codes'],
      )!,
      wasSwapped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_swapped'],
      )!,
      logged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}logged'],
      )!,
    );
  }

  @override
  $PlanItemsTable createAlias(String alias) {
    return $PlanItemsTable(attachedDatabase, alias);
  }
}

class PlanItem extends DataClass implements Insertable<PlanItem> {
  final int planItemId;
  final String planDate;
  final int position;
  final String slot;
  final int mealId;
  final String mealName;
  final double servingsMultiplier;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String reasonCodes;
  final bool wasSwapped;
  final bool logged;
  const PlanItem({
    required this.planItemId,
    required this.planDate,
    required this.position,
    required this.slot,
    required this.mealId,
    required this.mealName,
    required this.servingsMultiplier,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.reasonCodes,
    required this.wasSwapped,
    required this.logged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_item_id'] = Variable<int>(planItemId);
    map['plan_date'] = Variable<String>(planDate);
    map['position'] = Variable<int>(position);
    map['slot'] = Variable<String>(slot);
    map['meal_id'] = Variable<int>(mealId);
    map['meal_name'] = Variable<String>(mealName);
    map['servings_multiplier'] = Variable<double>(servingsMultiplier);
    map['grams'] = Variable<double>(grams);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carb_g'] = Variable<double>(carbG);
    map['fat_g'] = Variable<double>(fatG);
    map['reason_codes'] = Variable<String>(reasonCodes);
    map['was_swapped'] = Variable<bool>(wasSwapped);
    map['logged'] = Variable<bool>(logged);
    return map;
  }

  PlanItemsCompanion toCompanion(bool nullToAbsent) {
    return PlanItemsCompanion(
      planItemId: Value(planItemId),
      planDate: Value(planDate),
      position: Value(position),
      slot: Value(slot),
      mealId: Value(mealId),
      mealName: Value(mealName),
      servingsMultiplier: Value(servingsMultiplier),
      grams: Value(grams),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbG: Value(carbG),
      fatG: Value(fatG),
      reasonCodes: Value(reasonCodes),
      wasSwapped: Value(wasSwapped),
      logged: Value(logged),
    );
  }

  factory PlanItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanItem(
      planItemId: serializer.fromJson<int>(json['planItemId']),
      planDate: serializer.fromJson<String>(json['planDate']),
      position: serializer.fromJson<int>(json['position']),
      slot: serializer.fromJson<String>(json['slot']),
      mealId: serializer.fromJson<int>(json['mealId']),
      mealName: serializer.fromJson<String>(json['mealName']),
      servingsMultiplier: serializer.fromJson<double>(
        json['servingsMultiplier'],
      ),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbG: serializer.fromJson<double>(json['carbG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      reasonCodes: serializer.fromJson<String>(json['reasonCodes']),
      wasSwapped: serializer.fromJson<bool>(json['wasSwapped']),
      logged: serializer.fromJson<bool>(json['logged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planItemId': serializer.toJson<int>(planItemId),
      'planDate': serializer.toJson<String>(planDate),
      'position': serializer.toJson<int>(position),
      'slot': serializer.toJson<String>(slot),
      'mealId': serializer.toJson<int>(mealId),
      'mealName': serializer.toJson<String>(mealName),
      'servingsMultiplier': serializer.toJson<double>(servingsMultiplier),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbG': serializer.toJson<double>(carbG),
      'fatG': serializer.toJson<double>(fatG),
      'reasonCodes': serializer.toJson<String>(reasonCodes),
      'wasSwapped': serializer.toJson<bool>(wasSwapped),
      'logged': serializer.toJson<bool>(logged),
    };
  }

  PlanItem copyWith({
    int? planItemId,
    String? planDate,
    int? position,
    String? slot,
    int? mealId,
    String? mealName,
    double? servingsMultiplier,
    double? grams,
    double? kcal,
    double? proteinG,
    double? carbG,
    double? fatG,
    String? reasonCodes,
    bool? wasSwapped,
    bool? logged,
  }) => PlanItem(
    planItemId: planItemId ?? this.planItemId,
    planDate: planDate ?? this.planDate,
    position: position ?? this.position,
    slot: slot ?? this.slot,
    mealId: mealId ?? this.mealId,
    mealName: mealName ?? this.mealName,
    servingsMultiplier: servingsMultiplier ?? this.servingsMultiplier,
    grams: grams ?? this.grams,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbG: carbG ?? this.carbG,
    fatG: fatG ?? this.fatG,
    reasonCodes: reasonCodes ?? this.reasonCodes,
    wasSwapped: wasSwapped ?? this.wasSwapped,
    logged: logged ?? this.logged,
  );
  PlanItem copyWithCompanion(PlanItemsCompanion data) {
    return PlanItem(
      planItemId: data.planItemId.present
          ? data.planItemId.value
          : this.planItemId,
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      position: data.position.present ? data.position.value : this.position,
      slot: data.slot.present ? data.slot.value : this.slot,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      mealName: data.mealName.present ? data.mealName.value : this.mealName,
      servingsMultiplier: data.servingsMultiplier.present
          ? data.servingsMultiplier.value
          : this.servingsMultiplier,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      reasonCodes: data.reasonCodes.present
          ? data.reasonCodes.value
          : this.reasonCodes,
      wasSwapped: data.wasSwapped.present
          ? data.wasSwapped.value
          : this.wasSwapped,
      logged: data.logged.present ? data.logged.value : this.logged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanItem(')
          ..write('planItemId: $planItemId, ')
          ..write('planDate: $planDate, ')
          ..write('position: $position, ')
          ..write('slot: $slot, ')
          ..write('mealId: $mealId, ')
          ..write('mealName: $mealName, ')
          ..write('servingsMultiplier: $servingsMultiplier, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('reasonCodes: $reasonCodes, ')
          ..write('wasSwapped: $wasSwapped, ')
          ..write('logged: $logged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    planItemId,
    planDate,
    position,
    slot,
    mealId,
    mealName,
    servingsMultiplier,
    grams,
    kcal,
    proteinG,
    carbG,
    fatG,
    reasonCodes,
    wasSwapped,
    logged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanItem &&
          other.planItemId == this.planItemId &&
          other.planDate == this.planDate &&
          other.position == this.position &&
          other.slot == this.slot &&
          other.mealId == this.mealId &&
          other.mealName == this.mealName &&
          other.servingsMultiplier == this.servingsMultiplier &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.reasonCodes == this.reasonCodes &&
          other.wasSwapped == this.wasSwapped &&
          other.logged == this.logged);
}

class PlanItemsCompanion extends UpdateCompanion<PlanItem> {
  final Value<int> planItemId;
  final Value<String> planDate;
  final Value<int> position;
  final Value<String> slot;
  final Value<int> mealId;
  final Value<String> mealName;
  final Value<double> servingsMultiplier;
  final Value<double> grams;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbG;
  final Value<double> fatG;
  final Value<String> reasonCodes;
  final Value<bool> wasSwapped;
  final Value<bool> logged;
  const PlanItemsCompanion({
    this.planItemId = const Value.absent(),
    this.planDate = const Value.absent(),
    this.position = const Value.absent(),
    this.slot = const Value.absent(),
    this.mealId = const Value.absent(),
    this.mealName = const Value.absent(),
    this.servingsMultiplier = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.reasonCodes = const Value.absent(),
    this.wasSwapped = const Value.absent(),
    this.logged = const Value.absent(),
  });
  PlanItemsCompanion.insert({
    this.planItemId = const Value.absent(),
    required String planDate,
    required int position,
    required String slot,
    required int mealId,
    required String mealName,
    required double servingsMultiplier,
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbG,
    required double fatG,
    required String reasonCodes,
    required bool wasSwapped,
    required bool logged,
  }) : planDate = Value(planDate),
       position = Value(position),
       slot = Value(slot),
       mealId = Value(mealId),
       mealName = Value(mealName),
       servingsMultiplier = Value(servingsMultiplier),
       grams = Value(grams),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbG = Value(carbG),
       fatG = Value(fatG),
       reasonCodes = Value(reasonCodes),
       wasSwapped = Value(wasSwapped),
       logged = Value(logged);
  static Insertable<PlanItem> custom({
    Expression<int>? planItemId,
    Expression<String>? planDate,
    Expression<int>? position,
    Expression<String>? slot,
    Expression<int>? mealId,
    Expression<String>? mealName,
    Expression<double>? servingsMultiplier,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<String>? reasonCodes,
    Expression<bool>? wasSwapped,
    Expression<bool>? logged,
  }) {
    return RawValuesInsertable({
      if (planItemId != null) 'plan_item_id': planItemId,
      if (planDate != null) 'plan_date': planDate,
      if (position != null) 'position': position,
      if (slot != null) 'slot': slot,
      if (mealId != null) 'meal_id': mealId,
      if (mealName != null) 'meal_name': mealName,
      if (servingsMultiplier != null) 'servings_multiplier': servingsMultiplier,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (reasonCodes != null) 'reason_codes': reasonCodes,
      if (wasSwapped != null) 'was_swapped': wasSwapped,
      if (logged != null) 'logged': logged,
    });
  }

  PlanItemsCompanion copyWith({
    Value<int>? planItemId,
    Value<String>? planDate,
    Value<int>? position,
    Value<String>? slot,
    Value<int>? mealId,
    Value<String>? mealName,
    Value<double>? servingsMultiplier,
    Value<double>? grams,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbG,
    Value<double>? fatG,
    Value<String>? reasonCodes,
    Value<bool>? wasSwapped,
    Value<bool>? logged,
  }) {
    return PlanItemsCompanion(
      planItemId: planItemId ?? this.planItemId,
      planDate: planDate ?? this.planDate,
      position: position ?? this.position,
      slot: slot ?? this.slot,
      mealId: mealId ?? this.mealId,
      mealName: mealName ?? this.mealName,
      servingsMultiplier: servingsMultiplier ?? this.servingsMultiplier,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      reasonCodes: reasonCodes ?? this.reasonCodes,
      wasSwapped: wasSwapped ?? this.wasSwapped,
      logged: logged ?? this.logged,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planItemId.present) {
      map['plan_item_id'] = Variable<int>(planItemId.value);
    }
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (mealName.present) {
      map['meal_name'] = Variable<String>(mealName.value);
    }
    if (servingsMultiplier.present) {
      map['servings_multiplier'] = Variable<double>(servingsMultiplier.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
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
    if (reasonCodes.present) {
      map['reason_codes'] = Variable<String>(reasonCodes.value);
    }
    if (wasSwapped.present) {
      map['was_swapped'] = Variable<bool>(wasSwapped.value);
    }
    if (logged.present) {
      map['logged'] = Variable<bool>(logged.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanItemsCompanion(')
          ..write('planItemId: $planItemId, ')
          ..write('planDate: $planDate, ')
          ..write('position: $position, ')
          ..write('slot: $slot, ')
          ..write('mealId: $mealId, ')
          ..write('mealName: $mealName, ')
          ..write('servingsMultiplier: $servingsMultiplier, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('reasonCodes: $reasonCodes, ')
          ..write('wasSwapped: $wasSwapped, ')
          ..write('logged: $logged')
          ..write(')'))
        .toString();
  }
}

class $PlanUnmetMinimumsTable extends PlanUnmetMinimums
    with TableInfo<$PlanUnmetMinimumsTable, PlanUnmetMinimum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanUnmetMinimumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planDateMeta = const VerificationMeta(
    'planDate',
  );
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
    'plan_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plans (plan_date) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nutrientMeta = const VerificationMeta(
    'nutrient',
  );
  @override
  late final GeneratedColumn<String> nutrient = GeneratedColumn<String>(
    'nutrient',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minimumMeta = const VerificationMeta(
    'minimum',
  );
  @override
  late final GeneratedColumn<double> minimum = GeneratedColumn<double>(
    'minimum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [planDate, nutrient, minimum, total];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_unmet_minimums';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanUnmetMinimum> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_date')) {
      context.handle(
        _planDateMeta,
        planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta),
      );
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('nutrient')) {
      context.handle(
        _nutrientMeta,
        nutrient.isAcceptableOrUnknown(data['nutrient']!, _nutrientMeta),
      );
    } else if (isInserting) {
      context.missing(_nutrientMeta);
    }
    if (data.containsKey('minimum')) {
      context.handle(
        _minimumMeta,
        minimum.isAcceptableOrUnknown(data['minimum']!, _minimumMeta),
      );
    } else if (isInserting) {
      context.missing(_minimumMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planDate, nutrient};
  @override
  PlanUnmetMinimum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanUnmetMinimum(
      planDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_date'],
      )!,
      nutrient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutrient'],
      )!,
      minimum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      ),
    );
  }

  @override
  $PlanUnmetMinimumsTable createAlias(String alias) {
    return $PlanUnmetMinimumsTable(attachedDatabase, alias);
  }
}

class PlanUnmetMinimum extends DataClass
    implements Insertable<PlanUnmetMinimum> {
  final String planDate;
  final String nutrient;
  final double minimum;
  final double? total;
  const PlanUnmetMinimum({
    required this.planDate,
    required this.nutrient,
    required this.minimum,
    this.total,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_date'] = Variable<String>(planDate);
    map['nutrient'] = Variable<String>(nutrient);
    map['minimum'] = Variable<double>(minimum);
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<double>(total);
    }
    return map;
  }

  PlanUnmetMinimumsCompanion toCompanion(bool nullToAbsent) {
    return PlanUnmetMinimumsCompanion(
      planDate: Value(planDate),
      nutrient: Value(nutrient),
      minimum: Value(minimum),
      total: total == null && nullToAbsent
          ? const Value.absent()
          : Value(total),
    );
  }

  factory PlanUnmetMinimum.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanUnmetMinimum(
      planDate: serializer.fromJson<String>(json['planDate']),
      nutrient: serializer.fromJson<String>(json['nutrient']),
      minimum: serializer.fromJson<double>(json['minimum']),
      total: serializer.fromJson<double?>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planDate': serializer.toJson<String>(planDate),
      'nutrient': serializer.toJson<String>(nutrient),
      'minimum': serializer.toJson<double>(minimum),
      'total': serializer.toJson<double?>(total),
    };
  }

  PlanUnmetMinimum copyWith({
    String? planDate,
    String? nutrient,
    double? minimum,
    Value<double?> total = const Value.absent(),
  }) => PlanUnmetMinimum(
    planDate: planDate ?? this.planDate,
    nutrient: nutrient ?? this.nutrient,
    minimum: minimum ?? this.minimum,
    total: total.present ? total.value : this.total,
  );
  PlanUnmetMinimum copyWithCompanion(PlanUnmetMinimumsCompanion data) {
    return PlanUnmetMinimum(
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      nutrient: data.nutrient.present ? data.nutrient.value : this.nutrient,
      minimum: data.minimum.present ? data.minimum.value : this.minimum,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanUnmetMinimum(')
          ..write('planDate: $planDate, ')
          ..write('nutrient: $nutrient, ')
          ..write('minimum: $minimum, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(planDate, nutrient, minimum, total);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanUnmetMinimum &&
          other.planDate == this.planDate &&
          other.nutrient == this.nutrient &&
          other.minimum == this.minimum &&
          other.total == this.total);
}

class PlanUnmetMinimumsCompanion extends UpdateCompanion<PlanUnmetMinimum> {
  final Value<String> planDate;
  final Value<String> nutrient;
  final Value<double> minimum;
  final Value<double?> total;
  final Value<int> rowid;
  const PlanUnmetMinimumsCompanion({
    this.planDate = const Value.absent(),
    this.nutrient = const Value.absent(),
    this.minimum = const Value.absent(),
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanUnmetMinimumsCompanion.insert({
    required String planDate,
    required String nutrient,
    required double minimum,
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : planDate = Value(planDate),
       nutrient = Value(nutrient),
       minimum = Value(minimum);
  static Insertable<PlanUnmetMinimum> custom({
    Expression<String>? planDate,
    Expression<String>? nutrient,
    Expression<double>? minimum,
    Expression<double>? total,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planDate != null) 'plan_date': planDate,
      if (nutrient != null) 'nutrient': nutrient,
      if (minimum != null) 'minimum': minimum,
      if (total != null) 'total': total,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanUnmetMinimumsCompanion copyWith({
    Value<String>? planDate,
    Value<String>? nutrient,
    Value<double>? minimum,
    Value<double?>? total,
    Value<int>? rowid,
  }) {
    return PlanUnmetMinimumsCompanion(
      planDate: planDate ?? this.planDate,
      nutrient: nutrient ?? this.nutrient,
      minimum: minimum ?? this.minimum,
      total: total ?? this.total,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (nutrient.present) {
      map['nutrient'] = Variable<String>(nutrient.value);
    }
    if (minimum.present) {
      map['minimum'] = Variable<double>(minimum.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanUnmetMinimumsCompanion(')
          ..write('planDate: $planDate, ')
          ..write('nutrient: $nutrient, ')
          ..write('minimum: $minimum, ')
          ..write('total: $total, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealWindowsTable extends MealWindows
    with TableInfo<$MealWindowsTable, MealWindow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealWindowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _windowDateMeta = const VerificationMeta(
    'windowDate',
  );
  @override
  late final GeneratedColumn<String> windowDate = GeneratedColumn<String>(
    'window_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<String> start = GeneratedColumn<String>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<String> end = GeneratedColumn<String>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [windowDate, slot, start, end];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_windows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealWindow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('window_date')) {
      context.handle(
        _windowDateMeta,
        windowDate.isAcceptableOrUnknown(data['window_date']!, _windowDateMeta),
      );
    } else if (isInserting) {
      context.missing(_windowDateMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {windowDate, slot};
  @override
  MealWindow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealWindow(
      windowDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}window_date'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end'],
      )!,
    );
  }

  @override
  $MealWindowsTable createAlias(String alias) {
    return $MealWindowsTable(attachedDatabase, alias);
  }
}

class MealWindow extends DataClass implements Insertable<MealWindow> {
  final String windowDate;
  final String slot;
  final String start;
  final String end;
  const MealWindow({
    required this.windowDate,
    required this.slot,
    required this.start,
    required this.end,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['window_date'] = Variable<String>(windowDate);
    map['slot'] = Variable<String>(slot);
    map['start'] = Variable<String>(start);
    map['end'] = Variable<String>(end);
    return map;
  }

  MealWindowsCompanion toCompanion(bool nullToAbsent) {
    return MealWindowsCompanion(
      windowDate: Value(windowDate),
      slot: Value(slot),
      start: Value(start),
      end: Value(end),
    );
  }

  factory MealWindow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealWindow(
      windowDate: serializer.fromJson<String>(json['windowDate']),
      slot: serializer.fromJson<String>(json['slot']),
      start: serializer.fromJson<String>(json['start']),
      end: serializer.fromJson<String>(json['end']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'windowDate': serializer.toJson<String>(windowDate),
      'slot': serializer.toJson<String>(slot),
      'start': serializer.toJson<String>(start),
      'end': serializer.toJson<String>(end),
    };
  }

  MealWindow copyWith({
    String? windowDate,
    String? slot,
    String? start,
    String? end,
  }) => MealWindow(
    windowDate: windowDate ?? this.windowDate,
    slot: slot ?? this.slot,
    start: start ?? this.start,
    end: end ?? this.end,
  );
  MealWindow copyWithCompanion(MealWindowsCompanion data) {
    return MealWindow(
      windowDate: data.windowDate.present
          ? data.windowDate.value
          : this.windowDate,
      slot: data.slot.present ? data.slot.value : this.slot,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealWindow(')
          ..write('windowDate: $windowDate, ')
          ..write('slot: $slot, ')
          ..write('start: $start, ')
          ..write('end: $end')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(windowDate, slot, start, end);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealWindow &&
          other.windowDate == this.windowDate &&
          other.slot == this.slot &&
          other.start == this.start &&
          other.end == this.end);
}

class MealWindowsCompanion extends UpdateCompanion<MealWindow> {
  final Value<String> windowDate;
  final Value<String> slot;
  final Value<String> start;
  final Value<String> end;
  final Value<int> rowid;
  const MealWindowsCompanion({
    this.windowDate = const Value.absent(),
    this.slot = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealWindowsCompanion.insert({
    required String windowDate,
    required String slot,
    required String start,
    required String end,
    this.rowid = const Value.absent(),
  }) : windowDate = Value(windowDate),
       slot = Value(slot),
       start = Value(start),
       end = Value(end);
  static Insertable<MealWindow> custom({
    Expression<String>? windowDate,
    Expression<String>? slot,
    Expression<String>? start,
    Expression<String>? end,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (windowDate != null) 'window_date': windowDate,
      if (slot != null) 'slot': slot,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealWindowsCompanion copyWith({
    Value<String>? windowDate,
    Value<String>? slot,
    Value<String>? start,
    Value<String>? end,
    Value<int>? rowid,
  }) {
    return MealWindowsCompanion(
      windowDate: windowDate ?? this.windowDate,
      slot: slot ?? this.slot,
      start: start ?? this.start,
      end: end ?? this.end,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (windowDate.present) {
      map['window_date'] = Variable<String>(windowDate.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (start.present) {
      map['start'] = Variable<String>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<String>(end.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealWindowsCompanion(')
          ..write('windowDate: $windowDate, ')
          ..write('slot: $slot, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DaySummariesTable extends DaySummaries
    with TableInfo<$DaySummariesTable, DaySummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _summaryDateMeta = const VerificationMeta(
    'summaryDate',
  );
  @override
  late final GeneratedColumn<String> summaryDate = GeneratedColumn<String>(
    'summary_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetKcalMeta = const VerificationMeta(
    'targetKcal',
  );
  @override
  late final GeneratedColumn<double> targetKcal = GeneratedColumn<double>(
    'target_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
    'carb_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planItemsTotalMeta = const VerificationMeta(
    'planItemsTotal',
  );
  @override
  late final GeneratedColumn<int> planItemsTotal = GeneratedColumn<int>(
    'plan_items_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planItemsConsumedMeta = const VerificationMeta(
    'planItemsConsumed',
  );
  @override
  late final GeneratedColumn<int> planItemsConsumed = GeneratedColumn<int>(
    'plan_items_consumed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalMlMeta = const VerificationMeta(
    'totalMl',
  );
  @override
  late final GeneratedColumn<int> totalMl = GeneratedColumn<int>(
    'total_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMlMeta = const VerificationMeta('goalMl');
  @override
  late final GeneratedColumn<int> goalMl = GeneratedColumn<int>(
    'goal_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiresClinicianMeta = const VerificationMeta(
    'requiresClinician',
  );
  @override
  late final GeneratedColumn<bool> requiresClinician = GeneratedColumn<bool>(
    'requires_clinician',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_clinician" IN (0, 1))',
    ),
  );
  static const VerificationMeta _waterSourceMeta = const VerificationMeta(
    'waterSource',
  );
  @override
  late final GeneratedColumn<String> waterSource = GeneratedColumn<String>(
    'water_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    summaryDate,
    targetKcal,
    kcal,
    proteinG,
    carbG,
    fatG,
    planItemsTotal,
    planItemsConsumed,
    status,
    totalMl,
    goalMl,
    requiresClinician,
    waterSource,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DaySummary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('summary_date')) {
      context.handle(
        _summaryDateMeta,
        summaryDate.isAcceptableOrUnknown(
          data['summary_date']!,
          _summaryDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_summaryDateMeta);
    }
    if (data.containsKey('target_kcal')) {
      context.handle(
        _targetKcalMeta,
        targetKcal.isAcceptableOrUnknown(data['target_kcal']!, _targetKcalMeta),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('carb_g')) {
      context.handle(
        _carbGMeta,
        carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('plan_items_total')) {
      context.handle(
        _planItemsTotalMeta,
        planItemsTotal.isAcceptableOrUnknown(
          data['plan_items_total']!,
          _planItemsTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planItemsTotalMeta);
    }
    if (data.containsKey('plan_items_consumed')) {
      context.handle(
        _planItemsConsumedMeta,
        planItemsConsumed.isAcceptableOrUnknown(
          data['plan_items_consumed']!,
          _planItemsConsumedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planItemsConsumedMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_ml')) {
      context.handle(
        _totalMlMeta,
        totalMl.isAcceptableOrUnknown(data['total_ml']!, _totalMlMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMlMeta);
    }
    if (data.containsKey('goal_ml')) {
      context.handle(
        _goalMlMeta,
        goalMl.isAcceptableOrUnknown(data['goal_ml']!, _goalMlMeta),
      );
    }
    if (data.containsKey('requires_clinician')) {
      context.handle(
        _requiresClinicianMeta,
        requiresClinician.isAcceptableOrUnknown(
          data['requires_clinician']!,
          _requiresClinicianMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requiresClinicianMeta);
    }
    if (data.containsKey('water_source')) {
      context.handle(
        _waterSourceMeta,
        waterSource.isAcceptableOrUnknown(
          data['water_source']!,
          _waterSourceMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {summaryDate};
  @override
  DaySummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DaySummary(
      summaryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_date'],
      )!,
      targetKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_kcal'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      carbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      planItemsTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_items_total'],
      )!,
      planItemsConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_items_consumed'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      totalMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_ml'],
      )!,
      goalMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_ml'],
      ),
      requiresClinician: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_clinician'],
      )!,
      waterSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}water_source'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $DaySummariesTable createAlias(String alias) {
    return $DaySummariesTable(attachedDatabase, alias);
  }
}

class DaySummary extends DataClass implements Insertable<DaySummary> {
  final String summaryDate;
  final double? targetKcal;
  final double? kcal;
  final double? proteinG;
  final double? carbG;
  final double? fatG;
  final int planItemsTotal;
  final int planItemsConsumed;
  final String? status;
  final int totalMl;
  final int? goalMl;
  final bool requiresClinician;

  /// USER, DEFAULT or NONE: where the water goal comes from (version 5).
  final String? waterSource;
  final DateTime fetchedAt;
  const DaySummary({
    required this.summaryDate,
    this.targetKcal,
    this.kcal,
    this.proteinG,
    this.carbG,
    this.fatG,
    required this.planItemsTotal,
    required this.planItemsConsumed,
    this.status,
    required this.totalMl,
    this.goalMl,
    required this.requiresClinician,
    this.waterSource,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['summary_date'] = Variable<String>(summaryDate);
    if (!nullToAbsent || targetKcal != null) {
      map['target_kcal'] = Variable<double>(targetKcal);
    }
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<double>(kcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || carbG != null) {
      map['carb_g'] = Variable<double>(carbG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    map['plan_items_total'] = Variable<int>(planItemsTotal);
    map['plan_items_consumed'] = Variable<int>(planItemsConsumed);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['total_ml'] = Variable<int>(totalMl);
    if (!nullToAbsent || goalMl != null) {
      map['goal_ml'] = Variable<int>(goalMl);
    }
    map['requires_clinician'] = Variable<bool>(requiresClinician);
    if (!nullToAbsent || waterSource != null) {
      map['water_source'] = Variable<String>(waterSource);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  DaySummariesCompanion toCompanion(bool nullToAbsent) {
    return DaySummariesCompanion(
      summaryDate: Value(summaryDate),
      targetKcal: targetKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(targetKcal),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbG: carbG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      planItemsTotal: Value(planItemsTotal),
      planItemsConsumed: Value(planItemsConsumed),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      totalMl: Value(totalMl),
      goalMl: goalMl == null && nullToAbsent
          ? const Value.absent()
          : Value(goalMl),
      requiresClinician: Value(requiresClinician),
      waterSource: waterSource == null && nullToAbsent
          ? const Value.absent()
          : Value(waterSource),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory DaySummary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DaySummary(
      summaryDate: serializer.fromJson<String>(json['summaryDate']),
      targetKcal: serializer.fromJson<double?>(json['targetKcal']),
      kcal: serializer.fromJson<double?>(json['kcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      carbG: serializer.fromJson<double?>(json['carbG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      planItemsTotal: serializer.fromJson<int>(json['planItemsTotal']),
      planItemsConsumed: serializer.fromJson<int>(json['planItemsConsumed']),
      status: serializer.fromJson<String?>(json['status']),
      totalMl: serializer.fromJson<int>(json['totalMl']),
      goalMl: serializer.fromJson<int?>(json['goalMl']),
      requiresClinician: serializer.fromJson<bool>(json['requiresClinician']),
      waterSource: serializer.fromJson<String?>(json['waterSource']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'summaryDate': serializer.toJson<String>(summaryDate),
      'targetKcal': serializer.toJson<double?>(targetKcal),
      'kcal': serializer.toJson<double?>(kcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'carbG': serializer.toJson<double?>(carbG),
      'fatG': serializer.toJson<double?>(fatG),
      'planItemsTotal': serializer.toJson<int>(planItemsTotal),
      'planItemsConsumed': serializer.toJson<int>(planItemsConsumed),
      'status': serializer.toJson<String?>(status),
      'totalMl': serializer.toJson<int>(totalMl),
      'goalMl': serializer.toJson<int?>(goalMl),
      'requiresClinician': serializer.toJson<bool>(requiresClinician),
      'waterSource': serializer.toJson<String?>(waterSource),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  DaySummary copyWith({
    String? summaryDate,
    Value<double?> targetKcal = const Value.absent(),
    Value<double?> kcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> carbG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    int? planItemsTotal,
    int? planItemsConsumed,
    Value<String?> status = const Value.absent(),
    int? totalMl,
    Value<int?> goalMl = const Value.absent(),
    bool? requiresClinician,
    Value<String?> waterSource = const Value.absent(),
    DateTime? fetchedAt,
  }) => DaySummary(
    summaryDate: summaryDate ?? this.summaryDate,
    targetKcal: targetKcal.present ? targetKcal.value : this.targetKcal,
    kcal: kcal.present ? kcal.value : this.kcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    carbG: carbG.present ? carbG.value : this.carbG,
    fatG: fatG.present ? fatG.value : this.fatG,
    planItemsTotal: planItemsTotal ?? this.planItemsTotal,
    planItemsConsumed: planItemsConsumed ?? this.planItemsConsumed,
    status: status.present ? status.value : this.status,
    totalMl: totalMl ?? this.totalMl,
    goalMl: goalMl.present ? goalMl.value : this.goalMl,
    requiresClinician: requiresClinician ?? this.requiresClinician,
    waterSource: waterSource.present ? waterSource.value : this.waterSource,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  DaySummary copyWithCompanion(DaySummariesCompanion data) {
    return DaySummary(
      summaryDate: data.summaryDate.present
          ? data.summaryDate.value
          : this.summaryDate,
      targetKcal: data.targetKcal.present
          ? data.targetKcal.value
          : this.targetKcal,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      planItemsTotal: data.planItemsTotal.present
          ? data.planItemsTotal.value
          : this.planItemsTotal,
      planItemsConsumed: data.planItemsConsumed.present
          ? data.planItemsConsumed.value
          : this.planItemsConsumed,
      status: data.status.present ? data.status.value : this.status,
      totalMl: data.totalMl.present ? data.totalMl.value : this.totalMl,
      goalMl: data.goalMl.present ? data.goalMl.value : this.goalMl,
      requiresClinician: data.requiresClinician.present
          ? data.requiresClinician.value
          : this.requiresClinician,
      waterSource: data.waterSource.present
          ? data.waterSource.value
          : this.waterSource,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DaySummary(')
          ..write('summaryDate: $summaryDate, ')
          ..write('targetKcal: $targetKcal, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('planItemsTotal: $planItemsTotal, ')
          ..write('planItemsConsumed: $planItemsConsumed, ')
          ..write('status: $status, ')
          ..write('totalMl: $totalMl, ')
          ..write('goalMl: $goalMl, ')
          ..write('requiresClinician: $requiresClinician, ')
          ..write('waterSource: $waterSource, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    summaryDate,
    targetKcal,
    kcal,
    proteinG,
    carbG,
    fatG,
    planItemsTotal,
    planItemsConsumed,
    status,
    totalMl,
    goalMl,
    requiresClinician,
    waterSource,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DaySummary &&
          other.summaryDate == this.summaryDate &&
          other.targetKcal == this.targetKcal &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.planItemsTotal == this.planItemsTotal &&
          other.planItemsConsumed == this.planItemsConsumed &&
          other.status == this.status &&
          other.totalMl == this.totalMl &&
          other.goalMl == this.goalMl &&
          other.requiresClinician == this.requiresClinician &&
          other.waterSource == this.waterSource &&
          other.fetchedAt == this.fetchedAt);
}

class DaySummariesCompanion extends UpdateCompanion<DaySummary> {
  final Value<String> summaryDate;
  final Value<double?> targetKcal;
  final Value<double?> kcal;
  final Value<double?> proteinG;
  final Value<double?> carbG;
  final Value<double?> fatG;
  final Value<int> planItemsTotal;
  final Value<int> planItemsConsumed;
  final Value<String?> status;
  final Value<int> totalMl;
  final Value<int?> goalMl;
  final Value<bool> requiresClinician;
  final Value<String?> waterSource;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const DaySummariesCompanion({
    this.summaryDate = const Value.absent(),
    this.targetKcal = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.planItemsTotal = const Value.absent(),
    this.planItemsConsumed = const Value.absent(),
    this.status = const Value.absent(),
    this.totalMl = const Value.absent(),
    this.goalMl = const Value.absent(),
    this.requiresClinician = const Value.absent(),
    this.waterSource = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaySummariesCompanion.insert({
    required String summaryDate,
    this.targetKcal = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    required int planItemsTotal,
    required int planItemsConsumed,
    this.status = const Value.absent(),
    required int totalMl,
    this.goalMl = const Value.absent(),
    required bool requiresClinician,
    this.waterSource = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : summaryDate = Value(summaryDate),
       planItemsTotal = Value(planItemsTotal),
       planItemsConsumed = Value(planItemsConsumed),
       totalMl = Value(totalMl),
       requiresClinician = Value(requiresClinician),
       fetchedAt = Value(fetchedAt);
  static Insertable<DaySummary> custom({
    Expression<String>? summaryDate,
    Expression<double>? targetKcal,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<int>? planItemsTotal,
    Expression<int>? planItemsConsumed,
    Expression<String>? status,
    Expression<int>? totalMl,
    Expression<int>? goalMl,
    Expression<bool>? requiresClinician,
    Expression<String>? waterSource,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (summaryDate != null) 'summary_date': summaryDate,
      if (targetKcal != null) 'target_kcal': targetKcal,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (planItemsTotal != null) 'plan_items_total': planItemsTotal,
      if (planItemsConsumed != null) 'plan_items_consumed': planItemsConsumed,
      if (status != null) 'status': status,
      if (totalMl != null) 'total_ml': totalMl,
      if (goalMl != null) 'goal_ml': goalMl,
      if (requiresClinician != null) 'requires_clinician': requiresClinician,
      if (waterSource != null) 'water_source': waterSource,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaySummariesCompanion copyWith({
    Value<String>? summaryDate,
    Value<double?>? targetKcal,
    Value<double?>? kcal,
    Value<double?>? proteinG,
    Value<double?>? carbG,
    Value<double?>? fatG,
    Value<int>? planItemsTotal,
    Value<int>? planItemsConsumed,
    Value<String?>? status,
    Value<int>? totalMl,
    Value<int?>? goalMl,
    Value<bool>? requiresClinician,
    Value<String?>? waterSource,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return DaySummariesCompanion(
      summaryDate: summaryDate ?? this.summaryDate,
      targetKcal: targetKcal ?? this.targetKcal,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      planItemsTotal: planItemsTotal ?? this.planItemsTotal,
      planItemsConsumed: planItemsConsumed ?? this.planItemsConsumed,
      status: status ?? this.status,
      totalMl: totalMl ?? this.totalMl,
      goalMl: goalMl ?? this.goalMl,
      requiresClinician: requiresClinician ?? this.requiresClinician,
      waterSource: waterSource ?? this.waterSource,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (summaryDate.present) {
      map['summary_date'] = Variable<String>(summaryDate.value);
    }
    if (targetKcal.present) {
      map['target_kcal'] = Variable<double>(targetKcal.value);
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
    if (planItemsTotal.present) {
      map['plan_items_total'] = Variable<int>(planItemsTotal.value);
    }
    if (planItemsConsumed.present) {
      map['plan_items_consumed'] = Variable<int>(planItemsConsumed.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalMl.present) {
      map['total_ml'] = Variable<int>(totalMl.value);
    }
    if (goalMl.present) {
      map['goal_ml'] = Variable<int>(goalMl.value);
    }
    if (requiresClinician.present) {
      map['requires_clinician'] = Variable<bool>(requiresClinician.value);
    }
    if (waterSource.present) {
      map['water_source'] = Variable<String>(waterSource.value);
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
    return (StringBuffer('DaySummariesCompanion(')
          ..write('summaryDate: $summaryDate, ')
          ..write('targetKcal: $targetKcal, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('planItemsTotal: $planItemsTotal, ')
          ..write('planItemsConsumed: $planItemsConsumed, ')
          ..write('status: $status, ')
          ..write('totalMl: $totalMl, ')
          ..write('goalMl: $goalMl, ')
          ..write('requiresClinician: $requiresClinician, ')
          ..write('waterSource: $waterSource, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListsTable extends ShoppingLists
    with TableInfo<$ShoppingListsTable, ShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rangeKeyMeta = const VerificationMeta(
    'rangeKey',
  );
  @override
  late final GeneratedColumn<String> rangeKey = GeneratedColumn<String>(
    'range_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  List<GeneratedColumn> get $columns => [rangeKey, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('range_key')) {
      context.handle(
        _rangeKeyMeta,
        rangeKey.isAcceptableOrUnknown(data['range_key']!, _rangeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeKeyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {rangeKey};
  @override
  ShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingList(
      rangeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_key'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $ShoppingListsTable createAlias(String alias) {
    return $ShoppingListsTable(attachedDatabase, alias);
  }
}

class ShoppingList extends DataClass implements Insertable<ShoppingList> {
  final String rangeKey;
  final DateTime fetchedAt;
  const ShoppingList({required this.rangeKey, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['range_key'] = Variable<String>(rangeKey);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  ShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListsCompanion(
      rangeKey: Value(rangeKey),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingList(
      rangeKey: serializer.fromJson<String>(json['rangeKey']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rangeKey': serializer.toJson<String>(rangeKey),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  ShoppingList copyWith({String? rangeKey, DateTime? fetchedAt}) =>
      ShoppingList(
        rangeKey: rangeKey ?? this.rangeKey,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  ShoppingList copyWithCompanion(ShoppingListsCompanion data) {
    return ShoppingList(
      rangeKey: data.rangeKey.present ? data.rangeKey.value : this.rangeKey,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingList(')
          ..write('rangeKey: $rangeKey, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rangeKey, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingList &&
          other.rangeKey == this.rangeKey &&
          other.fetchedAt == this.fetchedAt);
}

class ShoppingListsCompanion extends UpdateCompanion<ShoppingList> {
  final Value<String> rangeKey;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const ShoppingListsCompanion({
    this.rangeKey = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListsCompanion.insert({
    required String rangeKey,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : rangeKey = Value(rangeKey),
       fetchedAt = Value(fetchedAt);
  static Insertable<ShoppingList> custom({
    Expression<String>? rangeKey,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rangeKey != null) 'range_key': rangeKey,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListsCompanion copyWith({
    Value<String>? rangeKey,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return ShoppingListsCompanion(
      rangeKey: rangeKey ?? this.rangeKey,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rangeKey.present) {
      map['range_key'] = Variable<String>(rangeKey.value);
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
    return (StringBuffer('ShoppingListsCompanion(')
          ..write('rangeKey: $rangeKey, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingItemsTable extends ShoppingItems
    with TableInfo<$ShoppingItemsTable, ShoppingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rangeKeyMeta = const VerificationMeta(
    'rangeKey',
  );
  @override
  late final GeneratedColumn<String> rangeKey = GeneratedColumn<String>(
    'range_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shopping_lists (range_key) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealsMeta = const VerificationMeta('meals');
  @override
  late final GeneratedColumn<int> meals = GeneratedColumn<int>(
    'meals',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rangeKey,
    ingredientId,
    name,
    grams,
    meals,
    checked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('range_key')) {
      context.handle(
        _rangeKeyMeta,
        rangeKey.isAcceptableOrUnknown(data['range_key']!, _rangeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeKeyMeta);
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
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('meals')) {
      context.handle(
        _mealsMeta,
        meals.isAcceptableOrUnknown(data['meals']!, _mealsMeta),
      );
    } else if (isInserting) {
      context.missing(_mealsMeta);
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    } else if (isInserting) {
      context.missing(_checkedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rangeKey, ingredientId};
  @override
  ShoppingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingItem(
      rangeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_key'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingredient_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      meals: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meals'],
      )!,
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
    );
  }

  @override
  $ShoppingItemsTable createAlias(String alias) {
    return $ShoppingItemsTable(attachedDatabase, alias);
  }
}

class ShoppingItem extends DataClass implements Insertable<ShoppingItem> {
  final String rangeKey;
  final int ingredientId;
  final String name;
  final double grams;
  final int meals;
  final bool checked;
  const ShoppingItem({
    required this.rangeKey,
    required this.ingredientId,
    required this.name,
    required this.grams,
    required this.meals,
    required this.checked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['range_key'] = Variable<String>(rangeKey);
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['name'] = Variable<String>(name);
    map['grams'] = Variable<double>(grams);
    map['meals'] = Variable<int>(meals);
    map['checked'] = Variable<bool>(checked);
    return map;
  }

  ShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingItemsCompanion(
      rangeKey: Value(rangeKey),
      ingredientId: Value(ingredientId),
      name: Value(name),
      grams: Value(grams),
      meals: Value(meals),
      checked: Value(checked),
    );
  }

  factory ShoppingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingItem(
      rangeKey: serializer.fromJson<String>(json['rangeKey']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      name: serializer.fromJson<String>(json['name']),
      grams: serializer.fromJson<double>(json['grams']),
      meals: serializer.fromJson<int>(json['meals']),
      checked: serializer.fromJson<bool>(json['checked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rangeKey': serializer.toJson<String>(rangeKey),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'name': serializer.toJson<String>(name),
      'grams': serializer.toJson<double>(grams),
      'meals': serializer.toJson<int>(meals),
      'checked': serializer.toJson<bool>(checked),
    };
  }

  ShoppingItem copyWith({
    String? rangeKey,
    int? ingredientId,
    String? name,
    double? grams,
    int? meals,
    bool? checked,
  }) => ShoppingItem(
    rangeKey: rangeKey ?? this.rangeKey,
    ingredientId: ingredientId ?? this.ingredientId,
    name: name ?? this.name,
    grams: grams ?? this.grams,
    meals: meals ?? this.meals,
    checked: checked ?? this.checked,
  );
  ShoppingItem copyWithCompanion(ShoppingItemsCompanion data) {
    return ShoppingItem(
      rangeKey: data.rangeKey.present ? data.rangeKey.value : this.rangeKey,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      name: data.name.present ? data.name.value : this.name,
      grams: data.grams.present ? data.grams.value : this.grams,
      meals: data.meals.present ? data.meals.value : this.meals,
      checked: data.checked.present ? data.checked.value : this.checked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItem(')
          ..write('rangeKey: $rangeKey, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('meals: $meals, ')
          ..write('checked: $checked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(rangeKey, ingredientId, name, grams, meals, checked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingItem &&
          other.rangeKey == this.rangeKey &&
          other.ingredientId == this.ingredientId &&
          other.name == this.name &&
          other.grams == this.grams &&
          other.meals == this.meals &&
          other.checked == this.checked);
}

class ShoppingItemsCompanion extends UpdateCompanion<ShoppingItem> {
  final Value<String> rangeKey;
  final Value<int> ingredientId;
  final Value<String> name;
  final Value<double> grams;
  final Value<int> meals;
  final Value<bool> checked;
  final Value<int> rowid;
  const ShoppingItemsCompanion({
    this.rangeKey = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.name = const Value.absent(),
    this.grams = const Value.absent(),
    this.meals = const Value.absent(),
    this.checked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingItemsCompanion.insert({
    required String rangeKey,
    required int ingredientId,
    required String name,
    required double grams,
    required int meals,
    required bool checked,
    this.rowid = const Value.absent(),
  }) : rangeKey = Value(rangeKey),
       ingredientId = Value(ingredientId),
       name = Value(name),
       grams = Value(grams),
       meals = Value(meals),
       checked = Value(checked);
  static Insertable<ShoppingItem> custom({
    Expression<String>? rangeKey,
    Expression<int>? ingredientId,
    Expression<String>? name,
    Expression<double>? grams,
    Expression<int>? meals,
    Expression<bool>? checked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rangeKey != null) 'range_key': rangeKey,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (name != null) 'name': name,
      if (grams != null) 'grams': grams,
      if (meals != null) 'meals': meals,
      if (checked != null) 'checked': checked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingItemsCompanion copyWith({
    Value<String>? rangeKey,
    Value<int>? ingredientId,
    Value<String>? name,
    Value<double>? grams,
    Value<int>? meals,
    Value<bool>? checked,
    Value<int>? rowid,
  }) {
    return ShoppingItemsCompanion(
      rangeKey: rangeKey ?? this.rangeKey,
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      meals: meals ?? this.meals,
      checked: checked ?? this.checked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rangeKey.present) {
      map['range_key'] = Variable<String>(rangeKey.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (meals.present) {
      map['meals'] = Variable<int>(meals.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemsCompanion(')
          ..write('rangeKey: $rangeKey, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('grams: $grams, ')
          ..write('meals: $meals, ')
          ..write('checked: $checked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityRefMeta = const VerificationMeta(
    'entityRef',
  );
  @override
  late final GeneratedColumn<String> entityRef = GeneratedColumn<String>(
    'entity_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    seq,
    opType,
    payloadJson,
    clientUuid,
    entityRef,
    createdAt,
    attempts,
    lastErrorCode,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    }
    if (data.containsKey('entity_ref')) {
      context.handle(
        _entityRefMeta,
        entityRef.isAcceptableOrUnknown(data['entity_ref']!, _entityRefMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      ),
      entityRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_ref'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final String opId;
  final int seq;
  final String opType;
  final String payloadJson;
  final String? clientUuid;
  final String? entityRef;
  final DateTime createdAt;
  final int attempts;
  final String? lastErrorCode;

  /// PENDING or REJECTED.
  final String state;
  const OutboxData({
    required this.opId,
    required this.seq,
    required this.opType,
    required this.payloadJson,
    this.clientUuid,
    this.entityRef,
    required this.createdAt,
    required this.attempts,
    this.lastErrorCode,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['seq'] = Variable<int>(seq);
    map['op_type'] = Variable<String>(opType);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || clientUuid != null) {
      map['client_uuid'] = Variable<String>(clientUuid);
    }
    if (!nullToAbsent || entityRef != null) {
      map['entity_ref'] = Variable<String>(entityRef);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    map['state'] = Variable<String>(state);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      opId: Value(opId),
      seq: Value(seq),
      opType: Value(opType),
      payloadJson: Value(payloadJson),
      clientUuid: clientUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(clientUuid),
      entityRef: entityRef == null && nullToAbsent
          ? const Value.absent()
          : Value(entityRef),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      state: Value(state),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      opId: serializer.fromJson<String>(json['opId']),
      seq: serializer.fromJson<int>(json['seq']),
      opType: serializer.fromJson<String>(json['opType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      clientUuid: serializer.fromJson<String?>(json['clientUuid']),
      entityRef: serializer.fromJson<String?>(json['entityRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'seq': serializer.toJson<int>(seq),
      'opType': serializer.toJson<String>(opType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'clientUuid': serializer.toJson<String?>(clientUuid),
      'entityRef': serializer.toJson<String?>(entityRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'state': serializer.toJson<String>(state),
    };
  }

  OutboxData copyWith({
    String? opId,
    int? seq,
    String? opType,
    String? payloadJson,
    Value<String?> clientUuid = const Value.absent(),
    Value<String?> entityRef = const Value.absent(),
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastErrorCode = const Value.absent(),
    String? state,
  }) => OutboxData(
    opId: opId ?? this.opId,
    seq: seq ?? this.seq,
    opType: opType ?? this.opType,
    payloadJson: payloadJson ?? this.payloadJson,
    clientUuid: clientUuid.present ? clientUuid.value : this.clientUuid,
    entityRef: entityRef.present ? entityRef.value : this.entityRef,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    state: state ?? this.state,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      opId: data.opId.present ? data.opId.value : this.opId,
      seq: data.seq.present ? data.seq.value : this.seq,
      opType: data.opType.present ? data.opType.value : this.opType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      entityRef: data.entityRef.present ? data.entityRef.value : this.entityRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('opId: $opId, ')
          ..write('seq: $seq, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('entityRef: $entityRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    seq,
    opType,
    payloadJson,
    clientUuid,
    entityRef,
    createdAt,
    attempts,
    lastErrorCode,
    state,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.opId == this.opId &&
          other.seq == this.seq &&
          other.opType == this.opType &&
          other.payloadJson == this.payloadJson &&
          other.clientUuid == this.clientUuid &&
          other.entityRef == this.entityRef &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastErrorCode == this.lastErrorCode &&
          other.state == this.state);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<String> opId;
  final Value<int> seq;
  final Value<String> opType;
  final Value<String> payloadJson;
  final Value<String?> clientUuid;
  final Value<String?> entityRef;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastErrorCode;
  final Value<String> state;
  final Value<int> rowid;
  const OutboxCompanion({
    this.opId = const Value.absent(),
    this.seq = const Value.absent(),
    this.opType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.entityRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String opId,
    required int seq,
    required String opType,
    required String payloadJson,
    this.clientUuid = const Value.absent(),
    this.entityRef = const Value.absent(),
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    required String state,
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       seq = Value(seq),
       opType = Value(opType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       state = Value(state);
  static Insertable<OutboxData> custom({
    Expression<String>? opId,
    Expression<int>? seq,
    Expression<String>? opType,
    Expression<String>? payloadJson,
    Expression<String>? clientUuid,
    Expression<String>? entityRef,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastErrorCode,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (seq != null) 'seq': seq,
      if (opType != null) 'op_type': opType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (entityRef != null) 'entity_ref': entityRef,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? opId,
    Value<int>? seq,
    Value<String>? opType,
    Value<String>? payloadJson,
    Value<String?>? clientUuid,
    Value<String?>? entityRef,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastErrorCode,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      opId: opId ?? this.opId,
      seq: seq ?? this.seq,
      opType: opType ?? this.opType,
      payloadJson: payloadJson ?? this.payloadJson,
      clientUuid: clientUuid ?? this.clientUuid,
      entityRef: entityRef ?? this.entityRef,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (entityRef.present) {
      map['entity_ref'] = Variable<String>(entityRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('opId: $opId, ')
          ..write('seq: $seq, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('entityRef: $entityRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsumptionLogsTable extends ConsumptionLogs
    with TableInfo<$ConsumptionLogsTable, ConsumptionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsumptionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverLogIdMeta = const VerificationMeta(
    'serverLogId',
  );
  @override
  late final GeneratedColumn<int> serverLogId = GeneratedColumn<int>(
    'server_log_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planItemIdMeta = const VerificationMeta(
    'planItemId',
  );
  @override
  late final GeneratedColumn<int> planItemId = GeneratedColumn<int>(
    'plan_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
    'meal_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logDateMeta = const VerificationMeta(
    'logDate',
  );
  @override
  late final GeneratedColumn<String> logDate = GeneratedColumn<String>(
    'log_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingsConsumedMeta = const VerificationMeta(
    'servingsConsumed',
  );
  @override
  late final GeneratedColumn<double> servingsConsumed = GeneratedColumn<double>(
    'servings_consumed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
    'carb_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientUuid,
    serverLogId,
    kind,
    planItemId,
    mealId,
    logDate,
    slot,
    servingsConsumed,
    consumedAt,
    name,
    kcal,
    proteinG,
    carbG,
    fatG,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consumption_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsumptionLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('server_log_id')) {
      context.handle(
        _serverLogIdMeta,
        serverLogId.isAcceptableOrUnknown(
          data['server_log_id']!,
          _serverLogIdMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('plan_item_id')) {
      context.handle(
        _planItemIdMeta,
        planItemId.isAcceptableOrUnknown(
          data['plan_item_id']!,
          _planItemIdMeta,
        ),
      );
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    }
    if (data.containsKey('log_date')) {
      context.handle(
        _logDateMeta,
        logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta),
      );
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    }
    if (data.containsKey('servings_consumed')) {
      context.handle(
        _servingsConsumedMeta,
        servingsConsumed.isAcceptableOrUnknown(
          data['servings_consumed']!,
          _servingsConsumedMeta,
        ),
      );
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('carb_g')) {
      context.handle(
        _carbGMeta,
        carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  ConsumptionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsumptionLog(
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      serverLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_log_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      planItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_item_id'],
      ),
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal_id'],
      ),
      logDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_date'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      ),
      servingsConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}servings_consumed'],
      ),
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      carbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $ConsumptionLogsTable createAlias(String alias) {
    return $ConsumptionLogsTable(attachedDatabase, alias);
  }
}

class ConsumptionLog extends DataClass implements Insertable<ConsumptionLog> {
  final String clientUuid;
  final int? serverLogId;
  final String kind;
  final int? planItemId;
  final int? mealId;
  final String logDate;
  final String? slot;
  final double? servingsConsumed;
  final DateTime consumedAt;
  final String? name;
  final double? kcal;
  final double? proteinG;
  final double? carbG;
  final double? fatG;

  /// PENDING, CONFIRMED, REJECTED or DELETING.
  final String state;
  const ConsumptionLog({
    required this.clientUuid,
    this.serverLogId,
    required this.kind,
    this.planItemId,
    this.mealId,
    required this.logDate,
    this.slot,
    this.servingsConsumed,
    required this.consumedAt,
    this.name,
    this.kcal,
    this.proteinG,
    this.carbG,
    this.fatG,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    if (!nullToAbsent || serverLogId != null) {
      map['server_log_id'] = Variable<int>(serverLogId);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || planItemId != null) {
      map['plan_item_id'] = Variable<int>(planItemId);
    }
    if (!nullToAbsent || mealId != null) {
      map['meal_id'] = Variable<int>(mealId);
    }
    map['log_date'] = Variable<String>(logDate);
    if (!nullToAbsent || slot != null) {
      map['slot'] = Variable<String>(slot);
    }
    if (!nullToAbsent || servingsConsumed != null) {
      map['servings_consumed'] = Variable<double>(servingsConsumed);
    }
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<double>(kcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || carbG != null) {
      map['carb_g'] = Variable<double>(carbG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    map['state'] = Variable<String>(state);
    return map;
  }

  ConsumptionLogsCompanion toCompanion(bool nullToAbsent) {
    return ConsumptionLogsCompanion(
      clientUuid: Value(clientUuid),
      serverLogId: serverLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverLogId),
      kind: Value(kind),
      planItemId: planItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(planItemId),
      mealId: mealId == null && nullToAbsent
          ? const Value.absent()
          : Value(mealId),
      logDate: Value(logDate),
      slot: slot == null && nullToAbsent ? const Value.absent() : Value(slot),
      servingsConsumed: servingsConsumed == null && nullToAbsent
          ? const Value.absent()
          : Value(servingsConsumed),
      consumedAt: Value(consumedAt),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbG: carbG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      state: Value(state),
    );
  }

  factory ConsumptionLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsumptionLog(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      serverLogId: serializer.fromJson<int?>(json['serverLogId']),
      kind: serializer.fromJson<String>(json['kind']),
      planItemId: serializer.fromJson<int?>(json['planItemId']),
      mealId: serializer.fromJson<int?>(json['mealId']),
      logDate: serializer.fromJson<String>(json['logDate']),
      slot: serializer.fromJson<String?>(json['slot']),
      servingsConsumed: serializer.fromJson<double?>(json['servingsConsumed']),
      consumedAt: serializer.fromJson<DateTime>(json['consumedAt']),
      name: serializer.fromJson<String?>(json['name']),
      kcal: serializer.fromJson<double?>(json['kcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      carbG: serializer.fromJson<double?>(json['carbG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'serverLogId': serializer.toJson<int?>(serverLogId),
      'kind': serializer.toJson<String>(kind),
      'planItemId': serializer.toJson<int?>(planItemId),
      'mealId': serializer.toJson<int?>(mealId),
      'logDate': serializer.toJson<String>(logDate),
      'slot': serializer.toJson<String?>(slot),
      'servingsConsumed': serializer.toJson<double?>(servingsConsumed),
      'consumedAt': serializer.toJson<DateTime>(consumedAt),
      'name': serializer.toJson<String?>(name),
      'kcal': serializer.toJson<double?>(kcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'carbG': serializer.toJson<double?>(carbG),
      'fatG': serializer.toJson<double?>(fatG),
      'state': serializer.toJson<String>(state),
    };
  }

  ConsumptionLog copyWith({
    String? clientUuid,
    Value<int?> serverLogId = const Value.absent(),
    String? kind,
    Value<int?> planItemId = const Value.absent(),
    Value<int?> mealId = const Value.absent(),
    String? logDate,
    Value<String?> slot = const Value.absent(),
    Value<double?> servingsConsumed = const Value.absent(),
    DateTime? consumedAt,
    Value<String?> name = const Value.absent(),
    Value<double?> kcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> carbG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    String? state,
  }) => ConsumptionLog(
    clientUuid: clientUuid ?? this.clientUuid,
    serverLogId: serverLogId.present ? serverLogId.value : this.serverLogId,
    kind: kind ?? this.kind,
    planItemId: planItemId.present ? planItemId.value : this.planItemId,
    mealId: mealId.present ? mealId.value : this.mealId,
    logDate: logDate ?? this.logDate,
    slot: slot.present ? slot.value : this.slot,
    servingsConsumed: servingsConsumed.present
        ? servingsConsumed.value
        : this.servingsConsumed,
    consumedAt: consumedAt ?? this.consumedAt,
    name: name.present ? name.value : this.name,
    kcal: kcal.present ? kcal.value : this.kcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    carbG: carbG.present ? carbG.value : this.carbG,
    fatG: fatG.present ? fatG.value : this.fatG,
    state: state ?? this.state,
  );
  ConsumptionLog copyWithCompanion(ConsumptionLogsCompanion data) {
    return ConsumptionLog(
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      serverLogId: data.serverLogId.present
          ? data.serverLogId.value
          : this.serverLogId,
      kind: data.kind.present ? data.kind.value : this.kind,
      planItemId: data.planItemId.present
          ? data.planItemId.value
          : this.planItemId,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      slot: data.slot.present ? data.slot.value : this.slot,
      servingsConsumed: data.servingsConsumed.present
          ? data.servingsConsumed.value
          : this.servingsConsumed,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
      name: data.name.present ? data.name.value : this.name,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsumptionLog(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('kind: $kind, ')
          ..write('planItemId: $planItemId, ')
          ..write('mealId: $mealId, ')
          ..write('logDate: $logDate, ')
          ..write('slot: $slot, ')
          ..write('servingsConsumed: $servingsConsumed, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('name: $name, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientUuid,
    serverLogId,
    kind,
    planItemId,
    mealId,
    logDate,
    slot,
    servingsConsumed,
    consumedAt,
    name,
    kcal,
    proteinG,
    carbG,
    fatG,
    state,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsumptionLog &&
          other.clientUuid == this.clientUuid &&
          other.serverLogId == this.serverLogId &&
          other.kind == this.kind &&
          other.planItemId == this.planItemId &&
          other.mealId == this.mealId &&
          other.logDate == this.logDate &&
          other.slot == this.slot &&
          other.servingsConsumed == this.servingsConsumed &&
          other.consumedAt == this.consumedAt &&
          other.name == this.name &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.state == this.state);
}

class ConsumptionLogsCompanion extends UpdateCompanion<ConsumptionLog> {
  final Value<String> clientUuid;
  final Value<int?> serverLogId;
  final Value<String> kind;
  final Value<int?> planItemId;
  final Value<int?> mealId;
  final Value<String> logDate;
  final Value<String?> slot;
  final Value<double?> servingsConsumed;
  final Value<DateTime> consumedAt;
  final Value<String?> name;
  final Value<double?> kcal;
  final Value<double?> proteinG;
  final Value<double?> carbG;
  final Value<double?> fatG;
  final Value<String> state;
  final Value<int> rowid;
  const ConsumptionLogsCompanion({
    this.clientUuid = const Value.absent(),
    this.serverLogId = const Value.absent(),
    this.kind = const Value.absent(),
    this.planItemId = const Value.absent(),
    this.mealId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.slot = const Value.absent(),
    this.servingsConsumed = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsumptionLogsCompanion.insert({
    required String clientUuid,
    this.serverLogId = const Value.absent(),
    required String kind,
    this.planItemId = const Value.absent(),
    this.mealId = const Value.absent(),
    required String logDate,
    this.slot = const Value.absent(),
    this.servingsConsumed = const Value.absent(),
    required DateTime consumedAt,
    this.name = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    required String state,
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       kind = Value(kind),
       logDate = Value(logDate),
       consumedAt = Value(consumedAt),
       state = Value(state);
  static Insertable<ConsumptionLog> custom({
    Expression<String>? clientUuid,
    Expression<int>? serverLogId,
    Expression<String>? kind,
    Expression<int>? planItemId,
    Expression<int>? mealId,
    Expression<String>? logDate,
    Expression<String>? slot,
    Expression<double>? servingsConsumed,
    Expression<DateTime>? consumedAt,
    Expression<String>? name,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (serverLogId != null) 'server_log_id': serverLogId,
      if (kind != null) 'kind': kind,
      if (planItemId != null) 'plan_item_id': planItemId,
      if (mealId != null) 'meal_id': mealId,
      if (logDate != null) 'log_date': logDate,
      if (slot != null) 'slot': slot,
      if (servingsConsumed != null) 'servings_consumed': servingsConsumed,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (name != null) 'name': name,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsumptionLogsCompanion copyWith({
    Value<String>? clientUuid,
    Value<int?>? serverLogId,
    Value<String>? kind,
    Value<int?>? planItemId,
    Value<int?>? mealId,
    Value<String>? logDate,
    Value<String?>? slot,
    Value<double?>? servingsConsumed,
    Value<DateTime>? consumedAt,
    Value<String?>? name,
    Value<double?>? kcal,
    Value<double?>? proteinG,
    Value<double?>? carbG,
    Value<double?>? fatG,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return ConsumptionLogsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      serverLogId: serverLogId ?? this.serverLogId,
      kind: kind ?? this.kind,
      planItemId: planItemId ?? this.planItemId,
      mealId: mealId ?? this.mealId,
      logDate: logDate ?? this.logDate,
      slot: slot ?? this.slot,
      servingsConsumed: servingsConsumed ?? this.servingsConsumed,
      consumedAt: consumedAt ?? this.consumedAt,
      name: name ?? this.name,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (serverLogId.present) {
      map['server_log_id'] = Variable<int>(serverLogId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (planItemId.present) {
      map['plan_item_id'] = Variable<int>(planItemId.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<String>(logDate.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (servingsConsumed.present) {
      map['servings_consumed'] = Variable<double>(servingsConsumed.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsumptionLogsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('kind: $kind, ')
          ..write('planItemId: $planItemId, ')
          ..write('mealId: $mealId, ')
          ..write('logDate: $logDate, ')
          ..write('slot: $slot, ')
          ..write('servingsConsumed: $servingsConsumed, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('name: $name, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaterLogsTable extends WaterLogs
    with TableInfo<$WaterLogsTable, WaterLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverLogIdMeta = const VerificationMeta(
    'serverLogId',
  );
  @override
  late final GeneratedColumn<int> serverLogId = GeneratedColumn<int>(
    'server_log_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logDateMeta = const VerificationMeta(
    'logDate',
  );
  @override
  late final GeneratedColumn<String> logDate = GeneratedColumn<String>(
    'log_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientUuid,
    serverLogId,
    amountMl,
    consumedAt,
    logDate,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('server_log_id')) {
      context.handle(
        _serverLogIdMeta,
        serverLogId.isAcceptableOrUnknown(
          data['server_log_id']!,
          _serverLogIdMeta,
        ),
      );
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    if (data.containsKey('log_date')) {
      context.handle(
        _logDateMeta,
        logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta),
      );
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  WaterLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterLog(
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      serverLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_log_id'],
      ),
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      )!,
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      )!,
      logDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_date'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $WaterLogsTable createAlias(String alias) {
    return $WaterLogsTable(attachedDatabase, alias);
  }
}

class WaterLog extends DataClass implements Insertable<WaterLog> {
  final String clientUuid;
  final int? serverLogId;
  final int amountMl;
  final DateTime consumedAt;
  final String logDate;

  /// PENDING, CONFIRMED, REJECTED or DELETING.
  final String state;
  const WaterLog({
    required this.clientUuid,
    this.serverLogId,
    required this.amountMl,
    required this.consumedAt,
    required this.logDate,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    if (!nullToAbsent || serverLogId != null) {
      map['server_log_id'] = Variable<int>(serverLogId);
    }
    map['amount_ml'] = Variable<int>(amountMl);
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    map['log_date'] = Variable<String>(logDate);
    map['state'] = Variable<String>(state);
    return map;
  }

  WaterLogsCompanion toCompanion(bool nullToAbsent) {
    return WaterLogsCompanion(
      clientUuid: Value(clientUuid),
      serverLogId: serverLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverLogId),
      amountMl: Value(amountMl),
      consumedAt: Value(consumedAt),
      logDate: Value(logDate),
      state: Value(state),
    );
  }

  factory WaterLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterLog(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      serverLogId: serializer.fromJson<int?>(json['serverLogId']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      consumedAt: serializer.fromJson<DateTime>(json['consumedAt']),
      logDate: serializer.fromJson<String>(json['logDate']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'serverLogId': serializer.toJson<int?>(serverLogId),
      'amountMl': serializer.toJson<int>(amountMl),
      'consumedAt': serializer.toJson<DateTime>(consumedAt),
      'logDate': serializer.toJson<String>(logDate),
      'state': serializer.toJson<String>(state),
    };
  }

  WaterLog copyWith({
    String? clientUuid,
    Value<int?> serverLogId = const Value.absent(),
    int? amountMl,
    DateTime? consumedAt,
    String? logDate,
    String? state,
  }) => WaterLog(
    clientUuid: clientUuid ?? this.clientUuid,
    serverLogId: serverLogId.present ? serverLogId.value : this.serverLogId,
    amountMl: amountMl ?? this.amountMl,
    consumedAt: consumedAt ?? this.consumedAt,
    logDate: logDate ?? this.logDate,
    state: state ?? this.state,
  );
  WaterLog copyWithCompanion(WaterLogsCompanion data) {
    return WaterLog(
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      serverLogId: data.serverLogId.present
          ? data.serverLogId.value
          : this.serverLogId,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterLog(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('amountMl: $amountMl, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('logDate: $logDate, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientUuid,
    serverLogId,
    amountMl,
    consumedAt,
    logDate,
    state,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterLog &&
          other.clientUuid == this.clientUuid &&
          other.serverLogId == this.serverLogId &&
          other.amountMl == this.amountMl &&
          other.consumedAt == this.consumedAt &&
          other.logDate == this.logDate &&
          other.state == this.state);
}

class WaterLogsCompanion extends UpdateCompanion<WaterLog> {
  final Value<String> clientUuid;
  final Value<int?> serverLogId;
  final Value<int> amountMl;
  final Value<DateTime> consumedAt;
  final Value<String> logDate;
  final Value<String> state;
  final Value<int> rowid;
  const WaterLogsCompanion({
    this.clientUuid = const Value.absent(),
    this.serverLogId = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.logDate = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaterLogsCompanion.insert({
    required String clientUuid,
    this.serverLogId = const Value.absent(),
    required int amountMl,
    required DateTime consumedAt,
    required String logDate,
    required String state,
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       amountMl = Value(amountMl),
       consumedAt = Value(consumedAt),
       logDate = Value(logDate),
       state = Value(state);
  static Insertable<WaterLog> custom({
    Expression<String>? clientUuid,
    Expression<int>? serverLogId,
    Expression<int>? amountMl,
    Expression<DateTime>? consumedAt,
    Expression<String>? logDate,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (serverLogId != null) 'server_log_id': serverLogId,
      if (amountMl != null) 'amount_ml': amountMl,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (logDate != null) 'log_date': logDate,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaterLogsCompanion copyWith({
    Value<String>? clientUuid,
    Value<int?>? serverLogId,
    Value<int>? amountMl,
    Value<DateTime>? consumedAt,
    Value<String>? logDate,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return WaterLogsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      serverLogId: serverLogId ?? this.serverLogId,
      amountMl: amountMl ?? this.amountMl,
      consumedAt: consumedAt ?? this.consumedAt,
      logDate: logDate ?? this.logDate,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (serverLogId.present) {
      map['server_log_id'] = Variable<int>(serverLogId.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<String>(logDate.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverLogId: $serverLogId, ')
          ..write('amountMl: $amountMl, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('logDate: $logDate, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightsTable extends Weights with TableInfo<$WeightsTable, Weight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _measuredOnMeta = const VerificationMeta(
    'measuredOn',
  );
  @override
  late final GeneratedColumn<String> measuredOn = GeneratedColumn<String>(
    'measured_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    measuredOn,
    weightKg,
    updatedAt,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weights';
  @override
  VerificationContext validateIntegrity(
    Insertable<Weight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('measured_on')) {
      context.handle(
        _measuredOnMeta,
        measuredOn.isAcceptableOrUnknown(data['measured_on']!, _measuredOnMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredOnMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {measuredOn};
  @override
  Weight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Weight(
      measuredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measured_on'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $WeightsTable createAlias(String alias) {
    return $WeightsTable(attachedDatabase, alias);
  }
}

class Weight extends DataClass implements Insertable<Weight> {
  final String measuredOn;
  final double weightKg;
  final DateTime updatedAt;

  /// PENDING or CONFIRMED.
  final String state;
  const Weight({
    required this.measuredOn,
    required this.weightKg,
    required this.updatedAt,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['measured_on'] = Variable<String>(measuredOn);
    map['weight_kg'] = Variable<double>(weightKg);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['state'] = Variable<String>(state);
    return map;
  }

  WeightsCompanion toCompanion(bool nullToAbsent) {
    return WeightsCompanion(
      measuredOn: Value(measuredOn),
      weightKg: Value(weightKg),
      updatedAt: Value(updatedAt),
      state: Value(state),
    );
  }

  factory Weight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Weight(
      measuredOn: serializer.fromJson<String>(json['measuredOn']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'measuredOn': serializer.toJson<String>(measuredOn),
      'weightKg': serializer.toJson<double>(weightKg),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'state': serializer.toJson<String>(state),
    };
  }

  Weight copyWith({
    String? measuredOn,
    double? weightKg,
    DateTime? updatedAt,
    String? state,
  }) => Weight(
    measuredOn: measuredOn ?? this.measuredOn,
    weightKg: weightKg ?? this.weightKg,
    updatedAt: updatedAt ?? this.updatedAt,
    state: state ?? this.state,
  );
  Weight copyWithCompanion(WeightsCompanion data) {
    return Weight(
      measuredOn: data.measuredOn.present
          ? data.measuredOn.value
          : this.measuredOn,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Weight(')
          ..write('measuredOn: $measuredOn, ')
          ..write('weightKg: $weightKg, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(measuredOn, weightKg, updatedAt, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Weight &&
          other.measuredOn == this.measuredOn &&
          other.weightKg == this.weightKg &&
          other.updatedAt == this.updatedAt &&
          other.state == this.state);
}

class WeightsCompanion extends UpdateCompanion<Weight> {
  final Value<String> measuredOn;
  final Value<double> weightKg;
  final Value<DateTime> updatedAt;
  final Value<String> state;
  final Value<int> rowid;
  const WeightsCompanion({
    this.measuredOn = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightsCompanion.insert({
    required String measuredOn,
    required double weightKg,
    required DateTime updatedAt,
    required String state,
    this.rowid = const Value.absent(),
  }) : measuredOn = Value(measuredOn),
       weightKg = Value(weightKg),
       updatedAt = Value(updatedAt),
       state = Value(state);
  static Insertable<Weight> custom({
    Expression<String>? measuredOn,
    Expression<double>? weightKg,
    Expression<DateTime>? updatedAt,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (measuredOn != null) 'measured_on': measuredOn,
      if (weightKg != null) 'weight_kg': weightKg,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightsCompanion copyWith({
    Value<String>? measuredOn,
    Value<double>? weightKg,
    Value<DateTime>? updatedAt,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return WeightsCompanion(
      measuredOn: measuredOn ?? this.measuredOn,
      weightKg: weightKg ?? this.weightKg,
      updatedAt: updatedAt ?? this.updatedAt,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (measuredOn.present) {
      map['measured_on'] = Variable<String>(measuredOn.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightsCompanion(')
          ..write('measuredOn: $measuredOn, ')
          ..write('weightKg: $weightKg, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('state: $state, ')
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
  late final $PlansTable plans = $PlansTable(this);
  late final $PlanItemsTable planItems = $PlanItemsTable(this);
  late final $PlanUnmetMinimumsTable planUnmetMinimums =
      $PlanUnmetMinimumsTable(this);
  late final $MealWindowsTable mealWindows = $MealWindowsTable(this);
  late final $DaySummariesTable daySummaries = $DaySummariesTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  late final $ShoppingItemsTable shoppingItems = $ShoppingItemsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $ConsumptionLogsTable consumptionLogs = $ConsumptionLogsTable(
    this,
  );
  late final $WaterLogsTable waterLogs = $WaterLogsTable(this);
  late final $WeightsTable weights = $WeightsTable(this);
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
    plans,
    planItems,
    planUnmetMinimums,
    mealWindows,
    daySummaries,
    shoppingLists,
    shoppingItems,
    outbox,
    consumptionLogs,
    waterLogs,
    weights,
    mealsLangSearchKey,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_unmet_minimums', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shopping_lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shopping_items', kind: UpdateKind.delete)],
    ),
  ]);
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
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String planDate,
  required int planId,
  required String algorithmVersion,
  required DateTime createdAt,
  required int kcal,
  required double proteinG,
  required double carbG,
  required double fatG,
  required int fiberG,
  Value<double?> totalsKcal,
  Value<double?> totalsProteinG,
  Value<double?> totalsCarbG,
  Value<double?> totalsFatG,
  Value<double?> totalsFiberG,
  Value<double?> totalsSaturatedFatG,
  Value<double?> totalsSodiumMg,
  Value<double?> totalsSugarsG,
  required bool kcalWithin10pct,
  Value<String?> solverStatus,
  Value<bool?> kcalRelaxed,
  Value<double?> solveSeconds,
  Value<int?> candidateMeals,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> planDate,
  Value<int> planId,
  Value<String> algorithmVersion,
  Value<DateTime> createdAt,
  Value<int> kcal,
  Value<double> proteinG,
  Value<double> carbG,
  Value<double> fatG,
  Value<int> fiberG,
  Value<double?> totalsKcal,
  Value<double?> totalsProteinG,
  Value<double?> totalsCarbG,
  Value<double?> totalsFatG,
  Value<double?> totalsFiberG,
  Value<double?> totalsSaturatedFatG,
  Value<double?> totalsSodiumMg,
  Value<double?> totalsSugarsG,
  Value<bool> kcalWithin10pct,
  Value<String?> solverStatus,
  Value<bool?> kcalRelaxed,
  Value<double?> solveSeconds,
  Value<int?> candidateMeals,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

final class $$PlansTableReferences
    extends BaseReferences<_$AppDatabase, $PlansTable, Plan> {
  $$PlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanItemsTable, List<PlanItem>>
  _planItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planItems,
    aliasName: 'plans__plan_date__plan_items__plan_date',
  );

  $$PlanItemsTableProcessedTableManager get planItemsRefs {
    final manager = $$PlanItemsTableTableManager($_db, $_db.planItems).filter(
      (f) => f.planDate.planDate.sqlEquals($_itemColumn<String>('plan_date')!),
    );

    final cache = $_typedResult.readTableOrNull(_planItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlanUnmetMinimumsTable, List<PlanUnmetMinimum>>
  _planUnmetMinimumsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.planUnmetMinimums,
        aliasName: 'plans__plan_date__plan_unmet_minimums__plan_date',
      );

  $$PlanUnmetMinimumsTableProcessedTableManager get planUnmetMinimumsRefs {
    final manager =
        $$PlanUnmetMinimumsTableTableManager(
          $_db,
          $_db.planUnmetMinimums,
        ).filter(
          (f) =>
              f.planDate.planDate.sqlEquals($_itemColumn<String>('plan_date')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _planUnmetMinimumsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get planDate => $composableBuilder(
    column: $table.planDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kcal => $composableBuilder(
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

  ColumnFilters<int> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsKcal => $composableBuilder(
    column: $table.totalsKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsProteinG => $composableBuilder(
    column: $table.totalsProteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsCarbG => $composableBuilder(
    column: $table.totalsCarbG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsFatG => $composableBuilder(
    column: $table.totalsFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsFiberG => $composableBuilder(
    column: $table.totalsFiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsSaturatedFatG => $composableBuilder(
    column: $table.totalsSaturatedFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsSodiumMg => $composableBuilder(
    column: $table.totalsSodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalsSugarsG => $composableBuilder(
    column: $table.totalsSugarsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kcalWithin10pct => $composableBuilder(
    column: $table.kcalWithin10pct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solverStatus => $composableBuilder(
    column: $table.solverStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kcalRelaxed => $composableBuilder(
    column: $table.kcalRelaxed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get solveSeconds => $composableBuilder(
    column: $table.solveSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get candidateMeals => $composableBuilder(
    column: $table.candidateMeals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> planItemsRefs(
    Expression<bool> Function($$PlanItemsTableFilterComposer f) f,
  ) {
    final $$PlanItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableFilterComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> planUnmetMinimumsRefs(
    Expression<bool> Function($$PlanUnmetMinimumsTableFilterComposer f) f,
  ) {
    final $$PlanUnmetMinimumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.planUnmetMinimums,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanUnmetMinimumsTableFilterComposer(
            $db: $db,
            $table: $db.planUnmetMinimums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get planDate => $composableBuilder(
    column: $table.planDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcal => $composableBuilder(
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

  ColumnOrderings<int> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsKcal => $composableBuilder(
    column: $table.totalsKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsProteinG => $composableBuilder(
    column: $table.totalsProteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsCarbG => $composableBuilder(
    column: $table.totalsCarbG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsFatG => $composableBuilder(
    column: $table.totalsFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsFiberG => $composableBuilder(
    column: $table.totalsFiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsSaturatedFatG => $composableBuilder(
    column: $table.totalsSaturatedFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsSodiumMg => $composableBuilder(
    column: $table.totalsSodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalsSugarsG => $composableBuilder(
    column: $table.totalsSugarsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kcalWithin10pct => $composableBuilder(
    column: $table.kcalWithin10pct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solverStatus => $composableBuilder(
    column: $table.solverStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kcalRelaxed => $composableBuilder(
    column: $table.kcalRelaxed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get solveSeconds => $composableBuilder(
    column: $table.solveSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get candidateMeals => $composableBuilder(
    column: $table.candidateMeals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get planDate =>
      $composableBuilder(column: $table.planDate, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<int> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get totalsKcal => $composableBuilder(
    column: $table.totalsKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalsProteinG => $composableBuilder(
    column: $table.totalsProteinG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalsCarbG => $composableBuilder(
    column: $table.totalsCarbG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalsFatG => $composableBuilder(
    column: $table.totalsFatG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalsFiberG => $composableBuilder(
    column: $table.totalsFiberG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalsSaturatedFatG => $composableBuilder(
    column: $table.totalsSaturatedFatG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalsSodiumMg => $composableBuilder(
    column: $table.totalsSodiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalsSugarsG => $composableBuilder(
    column: $table.totalsSugarsG,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get kcalWithin10pct => $composableBuilder(
    column: $table.kcalWithin10pct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get solverStatus => $composableBuilder(
    column: $table.solverStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get kcalRelaxed => $composableBuilder(
    column: $table.kcalRelaxed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get solveSeconds => $composableBuilder(
    column: $table.solveSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get candidateMeals => $composableBuilder(
    column: $table.candidateMeals,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  Expression<T> planItemsRefs<T extends Object>(
    Expression<T> Function($$PlanItemsTableAnnotationComposer a) f,
  ) {
    final $$PlanItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> planUnmetMinimumsRefs<T extends Object>(
    Expression<T> Function($$PlanUnmetMinimumsTableAnnotationComposer a) f,
  ) {
    final $$PlanUnmetMinimumsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.planDate,
          referencedTable: $db.planUnmetMinimums,
          getReferencedColumn: (t) => t.planDate,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlanUnmetMinimumsTableAnnotationComposer(
                $db: $db,
                $table: $db.planUnmetMinimums,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          Plan,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (Plan, $$PlansTableReferences),
          Plan,
          PrefetchHooks Function({
            bool planItemsRefs,
            bool planUnmetMinimumsRefs,
          })
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> planDate = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<String> algorithmVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<int> fiberG = const Value.absent(),
                Value<double?> totalsKcal = const Value.absent(),
                Value<double?> totalsProteinG = const Value.absent(),
                Value<double?> totalsCarbG = const Value.absent(),
                Value<double?> totalsFatG = const Value.absent(),
                Value<double?> totalsFiberG = const Value.absent(),
                Value<double?> totalsSaturatedFatG = const Value.absent(),
                Value<double?> totalsSodiumMg = const Value.absent(),
                Value<double?> totalsSugarsG = const Value.absent(),
                Value<bool> kcalWithin10pct = const Value.absent(),
                Value<String?> solverStatus = const Value.absent(),
                Value<bool?> kcalRelaxed = const Value.absent(),
                Value<double?> solveSeconds = const Value.absent(),
                Value<int?> candidateMeals = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                planDate: planDate,
                planId: planId,
                algorithmVersion: algorithmVersion,
                createdAt: createdAt,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                fiberG: fiberG,
                totalsKcal: totalsKcal,
                totalsProteinG: totalsProteinG,
                totalsCarbG: totalsCarbG,
                totalsFatG: totalsFatG,
                totalsFiberG: totalsFiberG,
                totalsSaturatedFatG: totalsSaturatedFatG,
                totalsSodiumMg: totalsSodiumMg,
                totalsSugarsG: totalsSugarsG,
                kcalWithin10pct: kcalWithin10pct,
                solverStatus: solverStatus,
                kcalRelaxed: kcalRelaxed,
                solveSeconds: solveSeconds,
                candidateMeals: candidateMeals,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String planDate,
                required int planId,
                required String algorithmVersion,
                required DateTime createdAt,
                required int kcal,
                required double proteinG,
                required double carbG,
                required double fatG,
                required int fiberG,
                Value<double?> totalsKcal = const Value.absent(),
                Value<double?> totalsProteinG = const Value.absent(),
                Value<double?> totalsCarbG = const Value.absent(),
                Value<double?> totalsFatG = const Value.absent(),
                Value<double?> totalsFiberG = const Value.absent(),
                Value<double?> totalsSaturatedFatG = const Value.absent(),
                Value<double?> totalsSodiumMg = const Value.absent(),
                Value<double?> totalsSugarsG = const Value.absent(),
                required bool kcalWithin10pct,
                Value<String?> solverStatus = const Value.absent(),
                Value<bool?> kcalRelaxed = const Value.absent(),
                Value<double?> solveSeconds = const Value.absent(),
                Value<int?> candidateMeals = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                planDate: planDate,
                planId: planId,
                algorithmVersion: algorithmVersion,
                createdAt: createdAt,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                fiberG: fiberG,
                totalsKcal: totalsKcal,
                totalsProteinG: totalsProteinG,
                totalsCarbG: totalsCarbG,
                totalsFatG: totalsFatG,
                totalsFiberG: totalsFiberG,
                totalsSaturatedFatG: totalsSaturatedFatG,
                totalsSodiumMg: totalsSodiumMg,
                totalsSugarsG: totalsSugarsG,
                kcalWithin10pct: kcalWithin10pct,
                solverStatus: solverStatus,
                kcalRelaxed: kcalRelaxed,
                solveSeconds: solveSeconds,
                candidateMeals: candidateMeals,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, Plan>(table),
                  $$PlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({planItemsRefs = false, planUnmetMinimumsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (planItemsRefs) db.planItems,
                    if (planUnmetMinimumsRefs) db.planUnmetMinimums,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (planItemsRefs)
                        await $_getPrefetchedData<Plan, $PlansTable, PlanItem>(
                          currentTable: table,
                          referencedTable: $$PlansTableReferences
                              ._planItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlansTableReferences(
                                db,
                                table,
                                p0,
                              ).planItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planDate == item.planDate,
                              ),
                          typedResults: items,
                        ),
                      if (planUnmetMinimumsRefs)
                        await $_getPrefetchedData<
                          Plan,
                          $PlansTable,
                          PlanUnmetMinimum
                        >(
                          currentTable: table,
                          referencedTable: $$PlansTableReferences
                              ._planUnmetMinimumsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlansTableReferences(
                                db,
                                table,
                                p0,
                              ).planUnmetMinimumsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planDate == item.planDate,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      Plan,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (Plan, $$PlansTableReferences),
      Plan,
      PrefetchHooks Function({bool planItemsRefs, bool planUnmetMinimumsRefs})
    >;
typedef $$PlanItemsTableCreateCompanionBuilder = PlanItemsCompanion Function({
  Value<int> planItemId,
  required String planDate,
  required int position,
  required String slot,
  required int mealId,
  required String mealName,
  required double servingsMultiplier,
  required double grams,
  required double kcal,
  required double proteinG,
  required double carbG,
  required double fatG,
  required String reasonCodes,
  required bool wasSwapped,
  required bool logged,
});
typedef $$PlanItemsTableUpdateCompanionBuilder = PlanItemsCompanion Function({
  Value<int> planItemId,
  Value<String> planDate,
  Value<int> position,
  Value<String> slot,
  Value<int> mealId,
  Value<String> mealName,
  Value<double> servingsMultiplier,
  Value<double> grams,
  Value<double> kcal,
  Value<double> proteinG,
  Value<double> carbG,
  Value<double> fatG,
  Value<String> reasonCodes,
  Value<bool> wasSwapped,
  Value<bool> logged,
});

final class $$PlanItemsTableReferences
    extends BaseReferences<_$AppDatabase, $PlanItemsTable, PlanItem> {
  $$PlanItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlansTable _planDateTable(_$AppDatabase db) =>
      db.plans.createAlias('plan_items__plan_date__plans__plan_date');

  $$PlansTableProcessedTableManager get planDate {
    final $_column = $_itemColumn<String>('plan_date')!;

    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.planDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlanItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanItemsTable> {
  $$PlanItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get planItemId => $composableBuilder(
    column: $table.planItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingsMultiplier => $composableBuilder(
    column: $table.servingsMultiplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
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

  ColumnFilters<String> get reasonCodes => $composableBuilder(
    column: $table.reasonCodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasSwapped => $composableBuilder(
    column: $table.wasSwapped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get logged => $composableBuilder(
    column: $table.logged,
    builder: (column) => ColumnFilters(column),
  );

  $$PlansTableFilterComposer get planDate {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanItemsTable> {
  $$PlanItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get planItemId => $composableBuilder(
    column: $table.planItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingsMultiplier => $composableBuilder(
    column: $table.servingsMultiplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
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

  ColumnOrderings<String> get reasonCodes => $composableBuilder(
    column: $table.reasonCodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasSwapped => $composableBuilder(
    column: $table.wasSwapped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get logged => $composableBuilder(
    column: $table.logged,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlansTableOrderingComposer get planDate {
    final $$PlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableOrderingComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanItemsTable> {
  $$PlanItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get planItemId => $composableBuilder(
    column: $table.planItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get mealName =>
      $composableBuilder(column: $table.mealName, builder: (column) => column);

  GeneratedColumn<double> get servingsMultiplier => $composableBuilder(
    column: $table.servingsMultiplier,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get reasonCodes => $composableBuilder(
    column: $table.reasonCodes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasSwapped => $composableBuilder(
    column: $table.wasSwapped,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get logged =>
      $composableBuilder(column: $table.logged, builder: (column) => column);

  $$PlansTableAnnotationComposer get planDate {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanItemsTable,
          PlanItem,
          $$PlanItemsTableFilterComposer,
          $$PlanItemsTableOrderingComposer,
          $$PlanItemsTableAnnotationComposer,
          $$PlanItemsTableCreateCompanionBuilder,
          $$PlanItemsTableUpdateCompanionBuilder,
          (PlanItem, $$PlanItemsTableReferences),
          PlanItem,
          PrefetchHooks Function({bool planDate})
        > {
  $$PlanItemsTableTableManager(_$AppDatabase db, $PlanItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> planItemId = const Value.absent(),
                Value<String> planDate = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<int> mealId = const Value.absent(),
                Value<String> mealName = const Value.absent(),
                Value<double> servingsMultiplier = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<String> reasonCodes = const Value.absent(),
                Value<bool> wasSwapped = const Value.absent(),
                Value<bool> logged = const Value.absent(),
              }) => PlanItemsCompanion(
                planItemId: planItemId,
                planDate: planDate,
                position: position,
                slot: slot,
                mealId: mealId,
                mealName: mealName,
                servingsMultiplier: servingsMultiplier,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                reasonCodes: reasonCodes,
                wasSwapped: wasSwapped,
                logged: logged,
              ),
          createCompanionCallback:
              ({
                Value<int> planItemId = const Value.absent(),
                required String planDate,
                required int position,
                required String slot,
                required int mealId,
                required String mealName,
                required double servingsMultiplier,
                required double grams,
                required double kcal,
                required double proteinG,
                required double carbG,
                required double fatG,
                required String reasonCodes,
                required bool wasSwapped,
                required bool logged,
              }) => PlanItemsCompanion.insert(
                planItemId: planItemId,
                planDate: planDate,
                position: position,
                slot: slot,
                mealId: mealId,
                mealName: mealName,
                servingsMultiplier: servingsMultiplier,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                reasonCodes: reasonCodes,
                wasSwapped: wasSwapped,
                logged: logged,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanItemsTable, PlanItem>(table),
                  $$PlanItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planDate = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planDate) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planDate,
                        referencedTable: $$PlanItemsTableReferences
                            ._planDateTable(db),
                        referencedColumn: $$PlanItemsTableReferences
                            ._planDateTable(db)
                            .planDate,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlanItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanItemsTable,
      PlanItem,
      $$PlanItemsTableFilterComposer,
      $$PlanItemsTableOrderingComposer,
      $$PlanItemsTableAnnotationComposer,
      $$PlanItemsTableCreateCompanionBuilder,
      $$PlanItemsTableUpdateCompanionBuilder,
      (PlanItem, $$PlanItemsTableReferences),
      PlanItem,
      PrefetchHooks Function({bool planDate})
    >;
typedef $$PlanUnmetMinimumsTableCreateCompanionBuilder =
    PlanUnmetMinimumsCompanion Function({
      required String planDate,
      required String nutrient,
      required double minimum,
      Value<double?> total,
      Value<int> rowid,
    });
typedef $$PlanUnmetMinimumsTableUpdateCompanionBuilder =
    PlanUnmetMinimumsCompanion Function({
      Value<String> planDate,
      Value<String> nutrient,
      Value<double> minimum,
      Value<double?> total,
      Value<int> rowid,
    });

final class $$PlanUnmetMinimumsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlanUnmetMinimumsTable,
          PlanUnmetMinimum
        > {
  $$PlanUnmetMinimumsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlansTable _planDateTable(_$AppDatabase db) =>
      db.plans.createAlias('plan_unmet_minimums__plan_date__plans__plan_date');

  $$PlansTableProcessedTableManager get planDate {
    final $_column = $_itemColumn<String>('plan_date')!;

    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.planDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlanUnmetMinimumsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanUnmetMinimumsTable> {
  $$PlanUnmetMinimumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nutrient => $composableBuilder(
    column: $table.nutrient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimum => $composableBuilder(
    column: $table.minimum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  $$PlansTableFilterComposer get planDate {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanUnmetMinimumsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanUnmetMinimumsTable> {
  $$PlanUnmetMinimumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nutrient => $composableBuilder(
    column: $table.nutrient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimum => $composableBuilder(
    column: $table.minimum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlansTableOrderingComposer get planDate {
    final $$PlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableOrderingComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanUnmetMinimumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanUnmetMinimumsTable> {
  $$PlanUnmetMinimumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nutrient =>
      $composableBuilder(column: $table.nutrient, builder: (column) => column);

  GeneratedColumn<double> get minimum =>
      $composableBuilder(column: $table.minimum, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  $$PlansTableAnnotationComposer get planDate {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDate,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.planDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanUnmetMinimumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanUnmetMinimumsTable,
          PlanUnmetMinimum,
          $$PlanUnmetMinimumsTableFilterComposer,
          $$PlanUnmetMinimumsTableOrderingComposer,
          $$PlanUnmetMinimumsTableAnnotationComposer,
          $$PlanUnmetMinimumsTableCreateCompanionBuilder,
          $$PlanUnmetMinimumsTableUpdateCompanionBuilder,
          (PlanUnmetMinimum, $$PlanUnmetMinimumsTableReferences),
          PlanUnmetMinimum,
          PrefetchHooks Function({bool planDate})
        > {
  $$PlanUnmetMinimumsTableTableManager(
    _$AppDatabase db,
    $PlanUnmetMinimumsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanUnmetMinimumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanUnmetMinimumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanUnmetMinimumsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> planDate = const Value.absent(),
                Value<String> nutrient = const Value.absent(),
                Value<double> minimum = const Value.absent(),
                Value<double?> total = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanUnmetMinimumsCompanion(
                planDate: planDate,
                nutrient: nutrient,
                minimum: minimum,
                total: total,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String planDate,
                required String nutrient,
                required double minimum,
                Value<double?> total = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanUnmetMinimumsCompanion.insert(
                planDate: planDate,
                nutrient: nutrient,
                minimum: minimum,
                total: total,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanUnmetMinimumsTable, PlanUnmetMinimum>(table),
                  $$PlanUnmetMinimumsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planDate = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planDate) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planDate,
                        referencedTable: $$PlanUnmetMinimumsTableReferences
                            ._planDateTable(db),
                        referencedColumn: $$PlanUnmetMinimumsTableReferences
                            ._planDateTable(db)
                            .planDate,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlanUnmetMinimumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanUnmetMinimumsTable,
      PlanUnmetMinimum,
      $$PlanUnmetMinimumsTableFilterComposer,
      $$PlanUnmetMinimumsTableOrderingComposer,
      $$PlanUnmetMinimumsTableAnnotationComposer,
      $$PlanUnmetMinimumsTableCreateCompanionBuilder,
      $$PlanUnmetMinimumsTableUpdateCompanionBuilder,
      (PlanUnmetMinimum, $$PlanUnmetMinimumsTableReferences),
      PlanUnmetMinimum,
      PrefetchHooks Function({bool planDate})
    >;
typedef $$MealWindowsTableCreateCompanionBuilder =
    MealWindowsCompanion Function({
      required String windowDate,
      required String slot,
      required String start,
      required String end,
      Value<int> rowid,
    });
typedef $$MealWindowsTableUpdateCompanionBuilder =
    MealWindowsCompanion Function({
      Value<String> windowDate,
      Value<String> slot,
      Value<String> start,
      Value<String> end,
      Value<int> rowid,
    });

class $$MealWindowsTableFilterComposer
    extends Composer<_$AppDatabase, $MealWindowsTable> {
  $$MealWindowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get windowDate => $composableBuilder(
    column: $table.windowDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealWindowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealWindowsTable> {
  $$MealWindowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get windowDate => $composableBuilder(
    column: $table.windowDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealWindowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealWindowsTable> {
  $$MealWindowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get windowDate => $composableBuilder(
    column: $table.windowDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<String> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);
}

class $$MealWindowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealWindowsTable,
          MealWindow,
          $$MealWindowsTableFilterComposer,
          $$MealWindowsTableOrderingComposer,
          $$MealWindowsTableAnnotationComposer,
          $$MealWindowsTableCreateCompanionBuilder,
          $$MealWindowsTableUpdateCompanionBuilder,
          (
            MealWindow,
            BaseReferences<_$AppDatabase, $MealWindowsTable, MealWindow>,
          ),
          MealWindow,
          PrefetchHooks Function()
        > {
  $$MealWindowsTableTableManager(_$AppDatabase db, $MealWindowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealWindowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealWindowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealWindowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> windowDate = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<String> start = const Value.absent(),
                Value<String> end = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealWindowsCompanion(
                windowDate: windowDate,
                slot: slot,
                start: start,
                end: end,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String windowDate,
                required String slot,
                required String start,
                required String end,
                Value<int> rowid = const Value.absent(),
              }) => MealWindowsCompanion.insert(
                windowDate: windowDate,
                slot: slot,
                start: start,
                end: end,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealWindowsTable, MealWindow>(table),
                  BaseReferences<_$AppDatabase, $MealWindowsTable, MealWindow>(
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

typedef $$MealWindowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealWindowsTable,
      MealWindow,
      $$MealWindowsTableFilterComposer,
      $$MealWindowsTableOrderingComposer,
      $$MealWindowsTableAnnotationComposer,
      $$MealWindowsTableCreateCompanionBuilder,
      $$MealWindowsTableUpdateCompanionBuilder,
      (
        MealWindow,
        BaseReferences<_$AppDatabase, $MealWindowsTable, MealWindow>,
      ),
      MealWindow,
      PrefetchHooks Function()
    >;
typedef $$DaySummariesTableCreateCompanionBuilder =
    DaySummariesCompanion Function({
      required String summaryDate,
      Value<double?> targetKcal,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> carbG,
      Value<double?> fatG,
      required int planItemsTotal,
      required int planItemsConsumed,
      Value<String?> status,
      required int totalMl,
      Value<int?> goalMl,
      required bool requiresClinician,
      Value<String?> waterSource,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$DaySummariesTableUpdateCompanionBuilder =
    DaySummariesCompanion Function({
      Value<String> summaryDate,
      Value<double?> targetKcal,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> carbG,
      Value<double?> fatG,
      Value<int> planItemsTotal,
      Value<int> planItemsConsumed,
      Value<String?> status,
      Value<int> totalMl,
      Value<int?> goalMl,
      Value<bool> requiresClinician,
      Value<String?> waterSource,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$DaySummariesTableFilterComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetKcal => $composableBuilder(
    column: $table.targetKcal,
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

  ColumnFilters<int> get planItemsTotal => $composableBuilder(
    column: $table.planItemsTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planItemsConsumed => $composableBuilder(
    column: $table.planItemsConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMl => $composableBuilder(
    column: $table.totalMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalMl => $composableBuilder(
    column: $table.goalMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresClinician => $composableBuilder(
    column: $table.requiresClinician,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DaySummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetKcal => $composableBuilder(
    column: $table.targetKcal,
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

  ColumnOrderings<int> get planItemsTotal => $composableBuilder(
    column: $table.planItemsTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planItemsConsumed => $composableBuilder(
    column: $table.planItemsConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMl => $composableBuilder(
    column: $table.totalMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalMl => $composableBuilder(
    column: $table.goalMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresClinician => $composableBuilder(
    column: $table.requiresClinician,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DaySummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetKcal => $composableBuilder(
    column: $table.targetKcal,
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

  GeneratedColumn<int> get planItemsTotal => $composableBuilder(
    column: $table.planItemsTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get planItemsConsumed => $composableBuilder(
    column: $table.planItemsConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalMl =>
      $composableBuilder(column: $table.totalMl, builder: (column) => column);

  GeneratedColumn<int> get goalMl =>
      $composableBuilder(column: $table.goalMl, builder: (column) => column);

  GeneratedColumn<bool> get requiresClinician => $composableBuilder(
    column: $table.requiresClinician,
    builder: (column) => column,
  );

  GeneratedColumn<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$DaySummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DaySummariesTable,
          DaySummary,
          $$DaySummariesTableFilterComposer,
          $$DaySummariesTableOrderingComposer,
          $$DaySummariesTableAnnotationComposer,
          $$DaySummariesTableCreateCompanionBuilder,
          $$DaySummariesTableUpdateCompanionBuilder,
          (
            DaySummary,
            BaseReferences<_$AppDatabase, $DaySummariesTable, DaySummary>,
          ),
          DaySummary,
          PrefetchHooks Function()
        > {
  $$DaySummariesTableTableManager(_$AppDatabase db, $DaySummariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaySummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaySummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> summaryDate = const Value.absent(),
                Value<double?> targetKcal = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<int> planItemsTotal = const Value.absent(),
                Value<int> planItemsConsumed = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> totalMl = const Value.absent(),
                Value<int?> goalMl = const Value.absent(),
                Value<bool> requiresClinician = const Value.absent(),
                Value<String?> waterSource = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DaySummariesCompanion(
                summaryDate: summaryDate,
                targetKcal: targetKcal,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                planItemsTotal: planItemsTotal,
                planItemsConsumed: planItemsConsumed,
                status: status,
                totalMl: totalMl,
                goalMl: goalMl,
                requiresClinician: requiresClinician,
                waterSource: waterSource,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String summaryDate,
                Value<double?> targetKcal = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                required int planItemsTotal,
                required int planItemsConsumed,
                Value<String?> status = const Value.absent(),
                required int totalMl,
                Value<int?> goalMl = const Value.absent(),
                required bool requiresClinician,
                Value<String?> waterSource = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => DaySummariesCompanion.insert(
                summaryDate: summaryDate,
                targetKcal: targetKcal,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                planItemsTotal: planItemsTotal,
                planItemsConsumed: planItemsConsumed,
                status: status,
                totalMl: totalMl,
                goalMl: goalMl,
                requiresClinician: requiresClinician,
                waterSource: waterSource,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DaySummariesTable, DaySummary>(table),
                  BaseReferences<_$AppDatabase, $DaySummariesTable, DaySummary>(
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

typedef $$DaySummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DaySummariesTable,
      DaySummary,
      $$DaySummariesTableFilterComposer,
      $$DaySummariesTableOrderingComposer,
      $$DaySummariesTableAnnotationComposer,
      $$DaySummariesTableCreateCompanionBuilder,
      $$DaySummariesTableUpdateCompanionBuilder,
      (
        DaySummary,
        BaseReferences<_$AppDatabase, $DaySummariesTable, DaySummary>,
      ),
      DaySummary,
      PrefetchHooks Function()
    >;
typedef $$ShoppingListsTableCreateCompanionBuilder =
    ShoppingListsCompanion Function({
      required String rangeKey,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$ShoppingListsTableUpdateCompanionBuilder =
    ShoppingListsCompanion Function({
      Value<String> rangeKey,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

final class $$ShoppingListsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingList> {
  $$ShoppingListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ShoppingItemsTable, List<ShoppingItem>>
  _shoppingItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingItems,
    aliasName: 'shopping_lists__range_key__shopping_items__range_key',
  );

  $$ShoppingItemsTableProcessedTableManager get shoppingItemsRefs {
    final manager = $$ShoppingItemsTableTableManager($_db, $_db.shoppingItems)
        .filter(
          (f) =>
              f.rangeKey.rangeKey.sqlEquals($_itemColumn<String>('range_key')!),
        );

    final cache = $_typedResult.readTableOrNull(_shoppingItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get rangeKey => $composableBuilder(
    column: $table.rangeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shoppingItemsRefs(
    Expression<bool> Function($$ShoppingItemsTableFilterComposer f) f,
  ) {
    final $$ShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeKey,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.rangeKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get rangeKey => $composableBuilder(
    column: $table.rangeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get rangeKey =>
      $composableBuilder(column: $table.rangeKey, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  Expression<T> shoppingItemsRefs<T extends Object>(
    Expression<T> Function($$ShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeKey,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.rangeKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListsTable,
          ShoppingList,
          $$ShoppingListsTableFilterComposer,
          $$ShoppingListsTableOrderingComposer,
          $$ShoppingListsTableAnnotationComposer,
          $$ShoppingListsTableCreateCompanionBuilder,
          $$ShoppingListsTableUpdateCompanionBuilder,
          (ShoppingList, $$ShoppingListsTableReferences),
          ShoppingList,
          PrefetchHooks Function({bool shoppingItemsRefs})
        > {
  $$ShoppingListsTableTableManager(_$AppDatabase db, $ShoppingListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rangeKey = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion(
                rangeKey: rangeKey,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rangeKey,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion.insert(
                rangeKey: rangeKey,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoppingListsTable, ShoppingList>(table),
                  $$ShoppingListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shoppingItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (shoppingItemsRefs) db.shoppingItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shoppingItemsRefs)
                    await $_getPrefetchedData<
                      ShoppingList,
                      $ShoppingListsTable,
                      ShoppingItem
                    >(
                      currentTable: table,
                      referencedTable: $$ShoppingListsTableReferences
                          ._shoppingItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ShoppingListsTableReferences(
                            db,
                            table,
                            p0,
                          ).shoppingItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.rangeKey == item.rangeKey,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListsTable,
      ShoppingList,
      $$ShoppingListsTableFilterComposer,
      $$ShoppingListsTableOrderingComposer,
      $$ShoppingListsTableAnnotationComposer,
      $$ShoppingListsTableCreateCompanionBuilder,
      $$ShoppingListsTableUpdateCompanionBuilder,
      (ShoppingList, $$ShoppingListsTableReferences),
      ShoppingList,
      PrefetchHooks Function({bool shoppingItemsRefs})
    >;
typedef $$ShoppingItemsTableCreateCompanionBuilder =
    ShoppingItemsCompanion Function({
      required String rangeKey,
      required int ingredientId,
      required String name,
      required double grams,
      required int meals,
      required bool checked,
      Value<int> rowid,
    });
typedef $$ShoppingItemsTableUpdateCompanionBuilder =
    ShoppingItemsCompanion Function({
      Value<String> rangeKey,
      Value<int> ingredientId,
      Value<String> name,
      Value<double> grams,
      Value<int> meals,
      Value<bool> checked,
      Value<int> rowid,
    });

final class $$ShoppingItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingItemsTable, ShoppingItem> {
  $$ShoppingItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShoppingListsTable _rangeKeyTable(_$AppDatabase db) => db
      .shoppingLists
      .createAlias('shopping_items__range_key__shopping_lists__range_key');

  $$ShoppingListsTableProcessedTableManager get rangeKey {
    final $_column = $_itemColumn<String>('range_key')!;

    final manager = $$ShoppingListsTableTableManager(
      $_db,
      $_db.shoppingLists,
    ).filter((f) => f.rangeKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rangeKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShoppingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meals => $composableBuilder(
    column: $table.meals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );

  $$ShoppingListsTableFilterComposer get rangeKey {
    final $$ShoppingListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeKey,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.rangeKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meals => $composableBuilder(
    column: $table.meals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShoppingListsTableOrderingComposer get rangeKey {
    final $$ShoppingListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeKey,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.rangeKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableOrderingComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<int> get meals =>
      $composableBuilder(column: $table.meals, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  $$ShoppingListsTableAnnotationComposer get rangeKey {
    final $$ShoppingListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rangeKey,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.rangeKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingItemsTable,
          ShoppingItem,
          $$ShoppingItemsTableFilterComposer,
          $$ShoppingItemsTableOrderingComposer,
          $$ShoppingItemsTableAnnotationComposer,
          $$ShoppingItemsTableCreateCompanionBuilder,
          $$ShoppingItemsTableUpdateCompanionBuilder,
          (ShoppingItem, $$ShoppingItemsTableReferences),
          ShoppingItem,
          PrefetchHooks Function({bool rangeKey})
        > {
  $$ShoppingItemsTableTableManager(_$AppDatabase db, $ShoppingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rangeKey = const Value.absent(),
                Value<int> ingredientId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<int> meals = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion(
                rangeKey: rangeKey,
                ingredientId: ingredientId,
                name: name,
                grams: grams,
                meals: meals,
                checked: checked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rangeKey,
                required int ingredientId,
                required String name,
                required double grams,
                required int meals,
                required bool checked,
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion.insert(
                rangeKey: rangeKey,
                ingredientId: ingredientId,
                name: name,
                grams: grams,
                meals: meals,
                checked: checked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoppingItemsTable, ShoppingItem>(table),
                  $$ShoppingItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({rangeKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (rangeKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.rangeKey,
                        referencedTable: $$ShoppingItemsTableReferences
                            ._rangeKeyTable(db),
                        referencedColumn: $$ShoppingItemsTableReferences
                            ._rangeKeyTable(db)
                            .rangeKey,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingItemsTable,
      ShoppingItem,
      $$ShoppingItemsTableFilterComposer,
      $$ShoppingItemsTableOrderingComposer,
      $$ShoppingItemsTableAnnotationComposer,
      $$ShoppingItemsTableCreateCompanionBuilder,
      $$ShoppingItemsTableUpdateCompanionBuilder,
      (ShoppingItem, $$ShoppingItemsTableReferences),
      ShoppingItem,
      PrefetchHooks Function({bool rangeKey})
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String opId,
  required int seq,
  required String opType,
  required String payloadJson,
  Value<String?> clientUuid,
  Value<String?> entityRef,
  required DateTime createdAt,
  Value<int> attempts,
  Value<String?> lastErrorCode,
  required String state,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> opId,
  Value<int> seq,
  Value<String> opType,
  Value<String> payloadJson,
  Value<String?> clientUuid,
  Value<String?> entityRef,
  Value<DateTime> createdAt,
  Value<int> attempts,
  Value<String?> lastErrorCode,
  Value<String> state,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityRef => $composableBuilder(
    column: $table.entityRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityRef => $composableBuilder(
    column: $table.entityRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityRef =>
      $composableBuilder(column: $table.entityRef, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> clientUuid = const Value.absent(),
                Value<String?> entityRef = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                opId: opId,
                seq: seq,
                opType: opType,
                payloadJson: payloadJson,
                clientUuid: clientUuid,
                entityRef: entityRef,
                createdAt: createdAt,
                attempts: attempts,
                lastErrorCode: lastErrorCode,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required int seq,
                required String opType,
                required String payloadJson,
                Value<String?> clientUuid = const Value.absent(),
                Value<String?> entityRef = const Value.absent(),
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                opId: opId,
                seq: seq,
                opType: opType,
                payloadJson: payloadJson,
                clientUuid: clientUuid,
                entityRef: entityRef,
                createdAt: createdAt,
                attempts: attempts,
                lastErrorCode: lastErrorCode,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>(
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

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$ConsumptionLogsTableCreateCompanionBuilder =
    ConsumptionLogsCompanion Function({
      required String clientUuid,
      Value<int?> serverLogId,
      required String kind,
      Value<int?> planItemId,
      Value<int?> mealId,
      required String logDate,
      Value<String?> slot,
      Value<double?> servingsConsumed,
      required DateTime consumedAt,
      Value<String?> name,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> carbG,
      Value<double?> fatG,
      required String state,
      Value<int> rowid,
    });
typedef $$ConsumptionLogsTableUpdateCompanionBuilder =
    ConsumptionLogsCompanion Function({
      Value<String> clientUuid,
      Value<int?> serverLogId,
      Value<String> kind,
      Value<int?> planItemId,
      Value<int?> mealId,
      Value<String> logDate,
      Value<String?> slot,
      Value<double?> servingsConsumed,
      Value<DateTime> consumedAt,
      Value<String?> name,
      Value<double?> kcal,
      Value<double?> proteinG,
      Value<double?> carbG,
      Value<double?> fatG,
      Value<String> state,
      Value<int> rowid,
    });

class $$ConsumptionLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ConsumptionLogsTable> {
  $$ConsumptionLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverLogId => $composableBuilder(
    column: $table.serverLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planItemId => $composableBuilder(
    column: $table.planItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingsConsumed => $composableBuilder(
    column: $table.servingsConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConsumptionLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsumptionLogsTable> {
  $$ConsumptionLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverLogId => $composableBuilder(
    column: $table.serverLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planItemId => $composableBuilder(
    column: $table.planItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingsConsumed => $composableBuilder(
    column: $table.servingsConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConsumptionLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsumptionLogsTable> {
  $$ConsumptionLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverLogId => $composableBuilder(
    column: $table.serverLogId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get planItemId => $composableBuilder(
    column: $table.planItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<double> get servingsConsumed => $composableBuilder(
    column: $table.servingsConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$ConsumptionLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsumptionLogsTable,
          ConsumptionLog,
          $$ConsumptionLogsTableFilterComposer,
          $$ConsumptionLogsTableOrderingComposer,
          $$ConsumptionLogsTableAnnotationComposer,
          $$ConsumptionLogsTableCreateCompanionBuilder,
          $$ConsumptionLogsTableUpdateCompanionBuilder,
          (
            ConsumptionLog,
            BaseReferences<
              _$AppDatabase,
              $ConsumptionLogsTable,
              ConsumptionLog
            >,
          ),
          ConsumptionLog,
          PrefetchHooks Function()
        > {
  $$ConsumptionLogsTableTableManager(
    _$AppDatabase db,
    $ConsumptionLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsumptionLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsumptionLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsumptionLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientUuid = const Value.absent(),
                Value<int?> serverLogId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> planItemId = const Value.absent(),
                Value<int?> mealId = const Value.absent(),
                Value<String> logDate = const Value.absent(),
                Value<String?> slot = const Value.absent(),
                Value<double?> servingsConsumed = const Value.absent(),
                Value<DateTime> consumedAt = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsumptionLogsCompanion(
                clientUuid: clientUuid,
                serverLogId: serverLogId,
                kind: kind,
                planItemId: planItemId,
                mealId: mealId,
                logDate: logDate,
                slot: slot,
                servingsConsumed: servingsConsumed,
                consumedAt: consumedAt,
                name: name,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientUuid,
                Value<int?> serverLogId = const Value.absent(),
                required String kind,
                Value<int?> planItemId = const Value.absent(),
                Value<int?> mealId = const Value.absent(),
                required String logDate,
                Value<String?> slot = const Value.absent(),
                Value<double?> servingsConsumed = const Value.absent(),
                required DateTime consumedAt,
                Value<String?> name = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => ConsumptionLogsCompanion.insert(
                clientUuid: clientUuid,
                serverLogId: serverLogId,
                kind: kind,
                planItemId: planItemId,
                mealId: mealId,
                logDate: logDate,
                slot: slot,
                servingsConsumed: servingsConsumed,
                consumedAt: consumedAt,
                name: name,
                kcal: kcal,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConsumptionLogsTable, ConsumptionLog>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConsumptionLogsTable,
                    ConsumptionLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConsumptionLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsumptionLogsTable,
      ConsumptionLog,
      $$ConsumptionLogsTableFilterComposer,
      $$ConsumptionLogsTableOrderingComposer,
      $$ConsumptionLogsTableAnnotationComposer,
      $$ConsumptionLogsTableCreateCompanionBuilder,
      $$ConsumptionLogsTableUpdateCompanionBuilder,
      (
        ConsumptionLog,
        BaseReferences<_$AppDatabase, $ConsumptionLogsTable, ConsumptionLog>,
      ),
      ConsumptionLog,
      PrefetchHooks Function()
    >;
typedef $$WaterLogsTableCreateCompanionBuilder = WaterLogsCompanion Function({
  required String clientUuid,
  Value<int?> serverLogId,
  required int amountMl,
  required DateTime consumedAt,
  required String logDate,
  required String state,
  Value<int> rowid,
});
typedef $$WaterLogsTableUpdateCompanionBuilder = WaterLogsCompanion Function({
  Value<String> clientUuid,
  Value<int?> serverLogId,
  Value<int> amountMl,
  Value<DateTime> consumedAt,
  Value<String> logDate,
  Value<String> state,
  Value<int> rowid,
});

class $$WaterLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverLogId => $composableBuilder(
    column: $table.serverLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverLogId => $composableBuilder(
    column: $table.serverLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverLogId => $composableBuilder(
    column: $table.serverLogId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$WaterLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterLogsTable,
          WaterLog,
          $$WaterLogsTableFilterComposer,
          $$WaterLogsTableOrderingComposer,
          $$WaterLogsTableAnnotationComposer,
          $$WaterLogsTableCreateCompanionBuilder,
          $$WaterLogsTableUpdateCompanionBuilder,
          (WaterLog, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>),
          WaterLog,
          PrefetchHooks Function()
        > {
  $$WaterLogsTableTableManager(_$AppDatabase db, $WaterLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientUuid = const Value.absent(),
                Value<int?> serverLogId = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<DateTime> consumedAt = const Value.absent(),
                Value<String> logDate = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterLogsCompanion(
                clientUuid: clientUuid,
                serverLogId: serverLogId,
                amountMl: amountMl,
                consumedAt: consumedAt,
                logDate: logDate,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientUuid,
                Value<int?> serverLogId = const Value.absent(),
                required int amountMl,
                required DateTime consumedAt,
                required String logDate,
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => WaterLogsCompanion.insert(
                clientUuid: clientUuid,
                serverLogId: serverLogId,
                amountMl: amountMl,
                consumedAt: consumedAt,
                logDate: logDate,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WaterLogsTable, WaterLog>(table),
                  BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>(
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

typedef $$WaterLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterLogsTable,
      WaterLog,
      $$WaterLogsTableFilterComposer,
      $$WaterLogsTableOrderingComposer,
      $$WaterLogsTableAnnotationComposer,
      $$WaterLogsTableCreateCompanionBuilder,
      $$WaterLogsTableUpdateCompanionBuilder,
      (WaterLog, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>),
      WaterLog,
      PrefetchHooks Function()
    >;
typedef $$WeightsTableCreateCompanionBuilder = WeightsCompanion Function({
  required String measuredOn,
  required double weightKg,
  required DateTime updatedAt,
  required String state,
  Value<int> rowid,
});
typedef $$WeightsTableUpdateCompanionBuilder = WeightsCompanion Function({
  Value<String> measuredOn,
  Value<double> weightKg,
  Value<DateTime> updatedAt,
  Value<String> state,
  Value<int> rowid,
});

class $$WeightsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get measuredOn => $composableBuilder(
    column: $table.measuredOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get measuredOn => $composableBuilder(
    column: $table.measuredOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightsTable> {
  $$WeightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get measuredOn => $composableBuilder(
    column: $table.measuredOn,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$WeightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightsTable,
          Weight,
          $$WeightsTableFilterComposer,
          $$WeightsTableOrderingComposer,
          $$WeightsTableAnnotationComposer,
          $$WeightsTableCreateCompanionBuilder,
          $$WeightsTableUpdateCompanionBuilder,
          (Weight, BaseReferences<_$AppDatabase, $WeightsTable, Weight>),
          Weight,
          PrefetchHooks Function()
        > {
  $$WeightsTableTableManager(_$AppDatabase db, $WeightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> measuredOn = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightsCompanion(
                measuredOn: measuredOn,
                weightKg: weightKg,
                updatedAt: updatedAt,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String measuredOn,
                required double weightKg,
                required DateTime updatedAt,
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => WeightsCompanion.insert(
                measuredOn: measuredOn,
                weightKg: weightKg,
                updatedAt: updatedAt,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeightsTable, Weight>(table),
                  BaseReferences<_$AppDatabase, $WeightsTable, Weight>(
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

typedef $$WeightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightsTable,
      Weight,
      $$WeightsTableFilterComposer,
      $$WeightsTableOrderingComposer,
      $$WeightsTableAnnotationComposer,
      $$WeightsTableCreateCompanionBuilder,
      $$WeightsTableUpdateCompanionBuilder,
      (Weight, BaseReferences<_$AppDatabase, $WeightsTable, Weight>),
      Weight,
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
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$PlanItemsTableTableManager get planItems =>
      $$PlanItemsTableTableManager(_db, _db.planItems);
  $$PlanUnmetMinimumsTableTableManager get planUnmetMinimums =>
      $$PlanUnmetMinimumsTableTableManager(_db, _db.planUnmetMinimums);
  $$MealWindowsTableTableManager get mealWindows =>
      $$MealWindowsTableTableManager(_db, _db.mealWindows);
  $$DaySummariesTableTableManager get daySummaries =>
      $$DaySummariesTableTableManager(_db, _db.daySummaries);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db, _db.shoppingLists);
  $$ShoppingItemsTableTableManager get shoppingItems =>
      $$ShoppingItemsTableTableManager(_db, _db.shoppingItems);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$ConsumptionLogsTableTableManager get consumptionLogs =>
      $$ConsumptionLogsTableTableManager(_db, _db.consumptionLogs);
  $$WaterLogsTableTableManager get waterLogs =>
      $$WaterLogsTableTableManager(_db, _db.waterLogs);
  $$WeightsTableTableManager get weights =>
      $$WeightsTableTableManager(_db, _db.weights);
}
