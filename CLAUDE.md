# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A collection of `acorn-*` shell/PHP scripts for setting up and maintaining Acorn WinterCMS installations. The most complex script is `acorn-create-system` — a database-first code generator that introspects a PostgreSQL schema and generates complete WinterCMS plugin code.

Clone into `/var/www/` so scripts run as `scripts/acorn-*`.

## Running acorn-create-system

The script must be run **from inside a WinterCMS installation directory** — it reads `.env` from `$cwd` for database credentials and detects the framework by checking for `modules/acorn/Model.php`.

```bash
cd /var/www/<project>
../scripts/acorn-create-system              # interactive: prompts to select plugin
../scripts/acorn-create-system university   # generate a single named plugin
../scripts/acorn-create-system all          # generate all plugins
../scripts/acorn-create-system olap         # regenerate OLAP cubes only
```

Optional extra arguments: `<git-policy (push|ask|leave)>` and `<write-README (y|n)>`.

## Testing / verifying changes

There is no automated test suite. The workflow is:

1. Save a baseline of the generated output before making changes:
   ```bash
   cp -r /var/www/<project>/plugins/acorn/<plugin>/ /var/www/<project>_baseline/
   ```
2. Make changes to the scripts.
3. Re-run the generator:
   ```bash
   cd /var/www/<project> && ../scripts/acorn-create-system <plugin>
   ```
4. Diff the output against the baseline:
   ```bash
   diff -r /var/www/<project>_baseline/ /var/www/<project>/plugins/acorn/<plugin>/
   ```

A working baseline for the `university` project lives at `/var/www/university_baseline/`.

Note: `/var/www/university/.env` currently contains placeholder credentials (`<D8AUTH>`) — real credentials are required to run the generator against the university database.

## Architecture of acorn-create-system

### Pipeline

```
PostgreSQL schema (tables, columns, FKs, YAML comments in DDL)
  → DB / Schema / Table / Column / ForeignKey  (introspection layer)
  → IS Pattern detection  (ISPattern.php)
  → Plugin / Model / Controller               (semantic model)
  → WinterCMS adapter                         (WinterCMS.php)
  → Buffered file writes                      (Framework.php cache)
  → Flushed to disk on script exit
```

### Key design principles

**Framework independence**: `Framework.php` is the abstract base; `WinterCMS.php` is the only concrete implementation today. Drupal/Django adapters were the original intent. Subclasses self-register via `Framework::registerDetector(WinterCMS::class)` at the bottom of `WinterCMS.php`.

**DDL as the source of truth**: Table/column names, FK constraints, and UNIQUE constraints drive code generation. Semantic metadata is layered on top via YAML-formatted PostgreSQL object comments (e.g. `COMMENT ON COLUMN people.name IS 'label: Full Name\nhidden: true'`).

**IS Pattern catalogue**: `ISPattern.php` names the 18 patterns that map DDL structural situations to WinterCMS rendering decisions (property groups for fields.yaml, columns.yaml, config_filter.yaml). See `PATTERNS.md` for the full catalogue with constraint reasoning. Each `Field` object carries an `$isPattern` property set during `Field::create()` and overridden in `Model::fields()` for embedding contexts.

**Buffered writes**: Generated content is never written to disk immediately. It accumulates in three caches on the `Framework` instance (`FILES[]`, `ARRAY_FILES[]`, `YAML_FILES[]`) and is flushed by the destructor. `fileLoad()` / `replaceInFile()` operate on the cache so a file can be built up across many method calls before touching disk.

### File responsibilities

| File | Role |
|------|------|
| `Framework.php` | Abstract base: DB connection, file cache, detector registry, `PhpCodeWriterTrait` |
| `WinterCMS.php` | Concrete adapter: all WinterCMS-specific generation (~2800 lines) |
| `DB.php` | PDO wrapper; loads schemas, tables, views, materialized views |
| `Table.php` | Table/view with columns, FKs, YAML comment metadata, type classification |
| `Column.php` | Column DDL + YAML annotation parsing; `standardFieldDefinitions()` |
| `ForeignKey.php` | FK classification: `isXto1()`, `is1to1()`, `isLeaf()`, `isXtoX()`, etc. |
| `Relation.php` | Relation value objects: `RelationXto1`, `Relation1to1`, `RelationLeaf`, `RelationHasManyDeep`, etc. |
| `Model.php` | Model-level generation: `fields()`, `columns()`, `relations()` — core logic (~3500 lines) |
| `Field.php` | Field value object for one fields.yaml / columns.yaml entry; `createFromColumn()` |
| `ISPattern.php` | Named IS pattern catalogue with WinterCMS property groups and constraint notes |
| `PhpCodeWriterTrait.php` | PHP source manipulation: `addMethod()`, `setPropertyInClassFile()`, `varExport()`, etc. |
| `Plugin.php` / `Module.php` | Plugin/module containers; collect models from tables |
| `OLAP.php` | SQL view + Mondrian OLAP cube generation |

### Table type classification (from naming convention)

| Type | Detection | Code generation |
|------|-----------|-----------------|
| `ContentTable` | Plural name | Full Model + Controller + CRUD |
| `PivotTable` | Singular name, no UUID id, exactly 2 FKs | BelongsToMany relation only |
| `SemiPivotTable` | Singular name + UUID id + extra columns | BelongsToManyWithPivot |
| `CentralTable` | Central base referenced by leaf tables | Embedded fields only |
| `ReportTable` | View or materialised view | Read-only model |

### Critical WinterCMS constraints (shape many generation decisions)

- `valueFrom:` is **not sortable** — sortable list columns must use `sqlSelect:` with a fully-qualified column name
- Unqualified column names (e.g. bare `name`) cause **SQL ambiguity** in joined queries — always table-qualify
- Nested bracket field keys (`parent[child][field]`) are **not sortable** — HasManyDeep relations are used as the sortable alternative
- Non-nullable FK relations cannot be created in create context (deferred binding required)

### YAML comment vocabulary

PostgreSQL object comments accept YAML to augment generation. Keys are documented in `PATTERNS.md` (§6 YAML Key Reference, ~100 keys). All existing keys must continue to work — backward compatibility is a hard requirement.

## Memory files

Session memory is stored in `/home/sz/.claude/projects/-var-www-scripts/memory/`.
