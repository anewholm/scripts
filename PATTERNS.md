# IS Pattern Catalogue — acorn-create-system

This document catalogues every **Information System (IS) pattern** that the `acorn-create-system`
tool recognises, generates, and optimises for. It is the design foundation for the refactoring
that will introduce a proper semantic layer between DDL introspection and framework-specific
code generation.

**Reading this document**: each pattern section follows the template:
- **Triggered by** — DDL structural fact(s) that auto-detect this pattern
- **YAML augmentation** — comment keys in table/column/FK comments that control the pattern
- **IS semantics** — what the pattern means in framework-independent terms
- **WinterCMS rendering** — what files/sections are generated
- **WinterCMS constraints** — framework limitations that drive rendering choices
- **Current code location** — where the logic lives today

---

## Section 1 — Table-Level DDL Structural Situations

### 1.1 Naming Convention: Content Table vs Pivot Table

The primary structural bifurcation is determined entirely by grammatical number of the table name:

| DDL situation | Table type |
|---|---|
| Table name is **plural** (`entities`, `users`) | `ContentTable` |
| Table name is **singular** (`entity_user`, `defendant_category`) AND no `id` UUID column | `PivotTable` (pure, no ID) |
| Table name is **singular** AND has `id` UUID column AND has extra content columns | `SemiPivotTable` |
| `table-type: central` in YAML comment | `CentralTable` (a ContentTable subtype — the shared base of leaf tables) |
| `table-type: report` in YAML comment | `ReportTable` (read-only view-like) |

**Code**: `Table::isContentTable()`, `Table::isPivotTable()`, `Table::isSemiPivotTable()`,
`Table::isCentralTable()`, `Table::isReportTable()` — `Table.php:1281`

**YAML override**: `table-type: content|pivot|semi-pivot|central|report`

---

## Section 2 — Foreign Key Structural Situations & Relation Types

Every FK has a **type** that is either inferred from structural facts or explicitly set.
The type determines which Relation class is instantiated and how the generated ORM, fields,
and columns are produced.

### 2.1 Pattern: BelongsTo (Xto1) — Many-to-One

**Triggered by**:
- Column `<table>_id` (ends with `_id`, more than one word-part)
- `tableFrom` is a ContentTable or ReportTable
- `tableTo` is a ContentTable (not CentralTable)
- No UNIQUE constraint on the FK column
- `columnClass` is not overridden

**YAML augmentation** (on the FK column comment or the FK DB constraint comment):
- `type: Xto1` (explicit)
- `read-only: true` — renders as text, not dropdown
- `field-exclude: true` — suppress from fields.yaml
- `column-exclude: true` — suppress from columns.yaml
- `hidden: true` / `invisible: true`
- `tab: <key>` — place in a specific tab
- `tab-location: 1|2|3` — primary/secondary/tertiary
- `can-filter: true|false`
- `depends-on: [field, ...]`
- `labels: {en: ..., ku: ..., ar: ...}`
- `global-scope: from|to` — scoped relation (see GlobalScope pattern)
- `no-relation-manager: true`
- `filter-search-name-select: <sql>` — custom SQL for filter term search
- `filter-conditions: <sql>` — raw SQL conditions for filter widget

**IS semantics**: "This record belongs to exactly one record of another entity type. The FK
column is the owning side of the relationship."

**WinterCMS rendering**:
- `fields.yaml`: `type: dropdown` with `options:` pointing to the target model's
  `dropdownOptions()` method
- `columns.yaml`: embedded column(s) using `relation:` + `sqlSelect:` (see §3.2)
- `$belongsTo` array entry in the PHP Model class
- `config_filter.yaml`: filter scope entry if `canFilter`

**WinterCMS constraints**:
- The FK column itself is hidden (`hidden: true`) in fields — the dropdown replaces it
- SQL select clause on the joined column is required for sortability (see §3.2)

**Code**: `Model::relationsXto1()` — `Model.php:1167`, `ForeignKey::isXto1()` — `ForeignKey.php:270`

---

### 2.2 Pattern: BelongsTo1to1 — One-to-One (owning side)

**Triggered by**:
- Same as Xto1 PLUS: the FK column has a **UNIQUE constraint** (single-column unique index)
- OR `type: 1to1` explicit in YAML
- OR the target table `isCentralTable()` (makes it a `leaf` — see §2.3)

**YAML augmentation**: same as Xto1 plus:
- `type: 1to1` (explicit)
- `fields-settings: {fieldName: {key: value, ...}}` — override sub-fields
- `has-many-deep-settings: {relationName: {...}}` — control HasManyDeep chain

**IS semantics**: "This record has exactly one associated record of another entity type, and
this table owns the FK. The target table's fields should be embedded directly into this
record's form."

**WinterCMS rendering**:
- Fields: **nested field names** `parent[child][field]` in fields.yaml
- Columns: **HasManyDeep relation** + `sqlSelect:` per column (see §3.2, §3.3)
- `$belongsTo` (not `$hasOne`) in PHP model — because the FK is on this table
- No relation manager (relation manager would be wrong — it's 1to1)

**WinterCMS constraints**:
- `valueFrom:` cannot be used for sortable columns — `sqlSelect:` is required instead
- Unqualified column names (e.g. `name`) cause SQL ambiguity — fully-qualified select required
- Nested bracket fields (`parent[child][field]`) are **not sortable** in columns.yaml
- Therefore two parallel representations are generated:
  - *For fields.yaml*: nested bracket form (editable)
  - *For columns.yaml*: flat name with `relation:` + `sqlSelect:` (sortable)

**Code**: `ForeignKey::is1to1()` — `ForeignKey.php:256`, embedded in `Model::fields()` — `Model.php:1586`

---

### 2.3 Pattern: LeafRelation — Specialisation (Central/Leaf inheritance)

**Triggered by**:
- FK target `isCentralTable()` — a table marked `table-type: central`
- FK source is a ContentTable that adds specialised attributes to the central base
- OR `type: leaf` explicit in YAML

**IS semantics**: "Two tables implement a class-table inheritance: the *central* table holds
shared properties (e.g. `people`) and the *leaf* table adds specialised properties
(e.g. `teachers`, `students`). The leaf table's controller *replaces* the central table's
controller — there is no standalone central controller."

**WinterCMS rendering**:
- Leaf model's form embeds the central table's fields (nested, same as 1to1)
- **No controller is generated for the central table** — access goes through leaf controllers
- Navigation menus point to leaf controllers only
- `$belongsTo` for the leaf's FK to the central table

**WinterCMS constraints**: same as BelongsTo1to1 for field embedding

**Code**: `ForeignKey::isLeaf()` — `ForeignKey.php:298`, `Table::isCentralTable()` — `Table.php:1294`

---

### 2.4 Pattern: HasMany (1fromX) — One-to-Many (reverse side)

**Triggered by**:
- FK on a *foreign* plural (ContentTable) pointing **to** this table's `id`
- `tableFrom.isContentTable()` AND `tableTo == thisTable`
- Not pivot, not 1to1

**YAML augmentation** (on the FK DB constraint comment, from the foreign table side):
- `type: 1fromX` (explicit)
- `tab: <key>` — which tab to appear in
- `tab-location: 1|2|3`
- `rl-buttons: [create, delete, link, unlink]` — relation manager toolbar
- `records-per-page: N`
- `can-filter: true|false`
- `show-filter: true|false`
- `show-search: true|false`
- `name-object: true` — show target as a named object link
- `no-relation-manager: true` — render as checkbox list instead
- `delete: true` — cascade delete in ORM
- `deferrable: true` — allow deferred binding (nullable FK)
- `filter-search-name-select: <sql>`

**IS semantics**: "This record has many associated records of another entity type. That other
entity owns the FK back to here."

**WinterCMS rendering**:
- `fields.yaml`: `type: relationmanager` field with CSS `single-tab-1fromX` class
- `config_relation.yaml`: `hasMany` entry
- `$hasMany` array entry in PHP model
- If FK is NOT nullable (not deferrable): a `hint_deferred_binding` hint field is injected
  in create context with `stop-circle` level to warn that the sub-record cannot be created
  until the parent exists
- Columns.yaml: `type: partial` / `partial: multi` for inline list column view

**WinterCMS constraints**:
- WinterCMS does NOT support relation manager creation in `create` context unless the FK is
  nullable (deferrable binding). Non-nullable FK gets a blocking hint in create mode.
- Self-referencing HasMany (tree children) gets tab key
  `acorn::lang.models.general.children`

**Code**: `Model::relations1fromX()` — `Model.php:1097`, `Model::fields()` — `Model.php:1993`

---

### 2.5 Pattern: HasOne (1from1) — One-to-One (reverse side)

**Triggered by**:
- FK on a foreign table with UNIQUE constraint pointing to this table's `id`
- Usually the reverse of a BelongsTo1to1 on the other table

**IS semantics**: "This record has exactly one associated record of another type, and the
other table owns the FK."

**WinterCMS rendering**: Typically produces no standalone interface (the leaf side handles it).
Appears in `$hasOne` in PHP model.

**Code**: `Model::relations1from1()` — `Model.php:814`

---

### 2.6 Pattern: BelongsToMany / XtoX — Pure Many-to-Many (via pivot table)

**Triggered by**:
- FK is on a **PivotTable** (singular name, no `id` UUID column)
- Both FKs from the pivot point to ContentTables

**YAML augmentation**:
- `rl-buttons: [create, delete, link, unlink]` — default for XtoX
- `tab: <key>`, `tab-location: 1|2|3`
- `records-per-page: N`
- `can-filter: true|false`
- `conditions: <sql>` — config_relation.yaml conditions

**IS semantics**: "Many records of type A can be associated with many records of type B,
with no extra data on the association itself."

**WinterCMS rendering**:
- `fields.yaml`: `type: relationmanager` with CSS `single-tab-XtoX`
- `config_relation.yaml`: `belongsToMany` entry with `table:` pivot
- `$belongsToMany` in PHP model

**Code**: `ForeignKey::isXtoX()` — `ForeignKey.php:313`, `Model::relationsXfromX()` — `Model.php:1301`

---

### 2.7 Pattern: BelongsToManyWithPivot / XtoXSemi — Many-to-Many with pivot data

**Triggered by**:
- FK is on a **SemiPivotTable** (singular name WITH `id` UUID column, has extra content columns)

**IS semantics**: "Many-to-many association that carries its own attributes (e.g. a
`defendant_user` pivot with a `role` column). The pivot model needs its own form."

**WinterCMS rendering**:
- `fields.yaml`: `type: relationmanager` with CSS `single-tab-XtoXSemi`
- `config_relation.yaml`: `belongsToMany` with `pivotModel:` pointing to the semi-pivot model
- Relation manager has `link`/`unlink` buttons in addition to `create`/`delete`
- The pivot model itself gets its own form interface

**Code**: `ForeignKey::isXtoXSemi()` — `ForeignKey.php:329`, `Model::relationsXfromXSemi()` — `Model.php:1238`

---

### 2.8 Pattern: SelfReference — Hierarchical Tree (parent_id)

**Triggered by**:
- FK column name contains `parent_` (e.g. `parent_entity_id`)
- FK points to the same table's `id` column (`tableFrom == tableTo`)

**YAML augmentation**:
- `flags: {hierarchy: true}` — activates WinterCMS NestedTree sort UI
- `global-scope: ...` — hierarchy-aware global scope

**IS semantics**: "Records of this type form a tree/hierarchy — each record may have a
parent record of the same type."

**WinterCMS rendering**:
- `$belongsTo` for the parent FK
- `$hasMany` for `children` (auto-named when `isSelfReferencing()`)
- Tab label `acorn::lang.models.general.children`
- `nest_left`, `nest_right`, `nest_depth` system columns suppressed from display

**Code**: `ForeignKey::isSelfReferencing()` — `ForeignKey.php:286`

---

### 2.9 Pattern: HasManyDeep — Deep Chained Relation

**Triggered by**:
- A chain of 1to1/leaf relations connecting this model to a distant model
- Enables **sortable** display of otherwise-unsortable nested columns

**YAML augmentation** (on the first FK in the chain):
- `has-many-deep-settings: {deepRelationName: {field-exclude: bool, column-exclude: bool, ...}}`
- `has-many-deep-include: true` — include a non-1to1 step in a deep chain

**IS semantics**: "A column value from a distantly-related model should be displayed inline
and sortably in this model's list view, traversing multiple 1-to-1 joins."

**WinterCMS rendering**:
- `$hasManyDeep` via `\Staudenmeir\EloquentHasManyDeep` in PHP model
- columns.yaml: flat column name, `relation: <hasManyDeepName>`, `sqlSelect: <fqn>`
- fields.yaml: nested bracket form for editing
- When chain contains non-1to1 steps (`containsNon1to1s`): field/column excluded unless
  `hasManyDeepSettings` explicitly enables it

**WinterCMS constraints**:
- `valueFrom:` is NOT sortable — `sqlSelect:` with a fully-qualified column name required
- Unqualified `name` causes SQL `ambiguous column` — must use `table.name` in sqlSelect
- Repeating models in the chain (same model appears twice) cause duplicate FROM clause —
  automatically excluded (`repeatingModels = TRUE` → `fieldExclude = TRUE`)

**Code**: `Model::relationsHasManyDeep()` — `Model.php:977`,
`Model::recursive1to1Relations()` — `Model.php:983`,
`Model::fields()` line 1610 HasManyDeep columns block

---

## Section 3 — Column-Level Structural Situations

### 3.1 Pattern: StandardDataColumn — Hidden infrastructure columns

**Triggered by**: Column name is in the STANDARD_DATA_COLUMNS list:
`id`, `created_at`, `updated_at`, `created_at_event_id`, `updated_at_event_id`,
`created_by`, `updated_by`, `created_by_user_id`, `updated_by_user_id`,
`_actions`, `_qrcode`, `_qrcode_scan`, `state_indicator`, `server_id`, `response`

**YAML override**: `system: true` — completely suppresses; `hidden: false` — override auto-hidden

**IS semantics**: "Infrastructure/audit columns — not for direct user editing."

**WinterCMS rendering**: `hidden: true` in fields.yaml, `invisible: true` in columns.yaml.
`state_indicator` gets `column-type: partial`.

**Code**: `Column::isStandard()`, `Column::standardFieldDefinitions()` — `Column.php:302`

---

### 3.2 Pattern: ForeignIdColumn — FK display with sortable column

**Triggered by**: Column name ends in `_id`, more than one underscore-part,
`columnClass` is `null` or `foreign-id`

**IS semantics**: "This column is a foreign key reference — display as a dropdown for
editing and as a derived value (the target's `name`) for listing."

**WinterCMS rendering**:
- fields.yaml: `type: dropdown` (hidden FK column itself)
- columns.yaml: derived column via `relation: <relationName>` + `sqlSelect: table.name`

**WinterCMS constraints**:
- The FK column value (a UUID) is meaningless to users — the target's `name` is shown
- `valueFrom: name` is NOT sortable — must use `sqlSelect: (select name from ...)`
  with a fully-qualified subquery or joined column reference
- Unqualified `name` in a join context causes SQL ambiguity — always FQN in sqlSelect

**YAML override**: `column-class: normal` — treat as a regular (non-FK) column

**Code**: `Column::isForeignID()` — `Column.php:545`

---

### 3.3 Pattern: SortableEmbeddedColumn — 1to1 column with sortable display

This is the key WinterCMS rendering optimisation.

**Problem**: When a 1to1 relation's fields are embedded via nested brackets
(`parent[child][field]`), WinterCMS cannot sort on them in list view. The nested column name
is not a real database column.

**Solution**: Use `HasManyDeep` + `sqlSelect` to produce a **flat, sortable column** alongside
the nested form field.

**Two parallel representations for each 1to1 embedded field**:

| Representation | Name format | Purpose | Sortable? |
|---|---|---|---|
| Nested field | `parent[child][field]` | fields.yaml edit form | N/A |
| Flat column | `field` | columns.yaml list view | **Yes** |

The flat column uses:
```yaml
fieldName:
  relation: hasManyDeepRelationName
  select: "schema.table.column_name"
```

**WinterCMS constraints** (the rules from Model.php:1675):
1. `valueFrom:` cannot be sorted → use `sqlSelect:` instead
2. Unqualified `name` causes SQL ambiguity → always use FQN `schema.table.name`
3. Relation embeds need a `select:` for the value → auto-generate if not set
4. Exception: Yaml-only fields without a DB column skip the sqlSelect

**Inclusion criteria** (a sub-field is included as a sortable column only if):
- Not `id` or pseudo-field
- `canDisplayAsColumn()` is true
- Not a duplicate of an existing field
- Not already a sub-relation (`hasSubRelation`)
- `sortable !== FALSE` OR has an explicit `sqlSelect`

**Code**: `Model::fields()` — `Model.php:1610–1706`

---

### 3.4 Pattern: NestedFormField — 1to1 embedded form field

For the editing side of embedded 1to1 relations:

**Generated as**: `parent[child][field]` bracket notation in fields.yaml

**Rules**:
- `relationmanager` type fields within the embedded model use `RELATION_MODE` (not nested
  bracket name) because they refer to `config_relation.yaml` entries
- `type: relation` fields are converted to `type: dropdown` in nested context
- `fileupload` fields: fixed embed (no create context issue)
- Nested sub-relation fields cannot be filters (`canFilter = FALSE`)
- `WinterModel` (non-create-system, loaded from existing fields.yaml) sub-fields included
  if `sortable: false` and no `sqlSelect` (included as a nested column)

**Code**: `Model::fields()` — `Model.php:1709–1830`

---

### 3.5 Pattern: TranslatableColumn — Multi-language content

**Triggered by**: Column name is `name` or `description` (TRANSLATABLE_COLUMNS)

**IS semantics**: "This column value should be translatable into multiple languages."

**WinterCMS rendering**:
- `$translatable` array in PHP model
- If `name` is directly on this model (not nested) AND no `translations` field already exists:
  auto-injects a `translations` pseudo-field (`type: partial`, `partial: translations`)
  in tertiary tab (`tabLocation: 3`), update context only

**Code**: `Column::isTranslatable()` — `Column.php:535`, `Model::fields()` — `Model.php:2298`

---

### 3.6 Pattern: SystemColumn — NestedTree infrastructure

**Triggered by**: Column name is `nest_left`, `nest_right`, or `nest_depth`

**IS semantics**: "WinterCMS NestedTree/sorted tree infrastructure column — never shown."

**WinterCMS rendering**: `system: true` — column suppressed entirely from all processing

**Code**: `Column::isSystem()` — `Column.php:530`

---

### 3.7 Pattern: QRCode — Scannable record identifier

**Triggered by**: Column name `_qrcode` or `_qrcode_scan` in STANDARD_DATA_COLUMNS,
OR `qrcode-object: true` in column YAML comment

**IS semantics**: "This record can be identified by a QR code for physical scanning workflows."

**WinterCMS rendering**:
- Auto-injects `_qrcode` PseudoField: `type: partial`, `partial: qrcode`, tertiary tab,
  update+preview context only, permission-gated by `acorn.view_qrcode`
- Columns.yaml: `type: partial`, `partial: qrcode`, invisible by default

**Code**: `Model::fields()` — `Model.php:2326`

---

### 3.8 Pattern: StateIndicator — Computed status display

**Triggered by**: Column name `state_indicator`

**IS semantics**: "A computed/derived status display column, rendered as a coloured indicator."

**WinterCMS rendering**: `column-type: partial` (auto-set in `Column::standardFieldDefinitions()`)

---

### 3.9 Pattern: EventFKTarget — Calendar event reference

**Triggered by**: The FK target model `isAcornEvent()` (points to
`acorn_calendar_events`)

**IS semantics**: "This FK references a Calendar event — expose the event's start (and
optionally end) datetime for display and filtering."

**WinterCMS rendering** (auto-injected by `standardTargetModelFieldDefinitions()`):
- `[start]` field: `type: datepicker`, `column-type: partial`, `column-partial: datetime`
- `[end]` field (if `with-end: true`): same
- `sqlSelect`: correlated subquery selecting `aacep.start` from event_parts
- `can-filter: true`, `filter-type: daterange`, custom `filter-conditions` SQL
- `actions: {goto-event: true}` — link to the event record

**YAML augmentation** (on the FK column):
- `with-end: true` — also generate the `[end]` field

**Code**: `Model::standardTargetModelFieldDefinitions()` — `Model.php:506`

---

### 3.10 Pattern: UserFKTarget — User reference display

**Triggered by**: The FK target model `isAcornUser()` (points to
`acorn_user_users`)

**IS semantics**: "This FK references a User — show the user's name as text."

**WinterCMS rendering**:
- `type: text`, `column-type: text`
- `sqlSelect`: correlated subquery `(select aauu.name from acorn_user_users aauu where aauu.id = <fkColumn>)`
- `can-filter: true`

**Code**: `Model::standardTargetModelFieldDefinitions()` — `Model.php:570`

---

## Section 4 — Table-Level IS Patterns (Model-wide)

### 4.1 Pattern: NavigationMenuItem — Backend menu registration

**Triggered by**: `menu: true` in table YAML comment

**YAML augmentation** (table comment):
- `menu: true` — register as a top-level or nested menu item
- `menu-splitter: true` — insert a visual separator before this item
- `menu-indent: N` — indent level (0 = top)
- `menu-task-items: {key: label, ...}` — task-based sub-menu items
- `plugin-icon: <icon>` — override icon for this plugin's nav registration
- `plugin-url: <url>` — override URL

**IS semantics**: "This entity type should appear as a navigable item in the admin backend
navigation."

**WinterCMS rendering**:
- `registerNavigation()` entry in Plugin.php
- `registerPermissions()` entry for `view_menu` permission
- Task items generate additional menu entries + permissions

**Code**: `WinterCMS::createMenus()` — `WinterCMS.php:616`

---

### 4.2 Pattern: GlobalScope — Cross-model filtering anchor

**Triggered by**: `global-scope: true|{css-theme: ...}` in table YAML comment

**YAML augmentation**:
- `global-scope: true`
- `global-scope-css-theme: <css-class>` — body class applied when scope is active
- `flags: {hierarchy: true}` on relations — hierarchy-aware scope

**IS semantics**: "This entity acts as a filter anchor — when a user selects a record of
this type, all other models that relate to it are filtered to show only related records.
Typical use: select a 'project' and all sub-entities filter accordingly."

**WinterCMS rendering**:
- A `GlobalScope` PHP class is generated and injected into the model
- `registerPermissions()` entries for `globalscope.view` and `globalscope.change`
- Related models get `global-scope: from|to` on their FKs to participate in the scope

**Code**: `WinterCMS::createModel()` — `WinterCMS.php:973`, permissions — `Model.php:736`

---

### 4.3 Pattern: ReadOnly — Non-editable entity

**Triggered by**: `read-only: true` in table YAML comment, or target model `isAcornUser()`

**IS semantics**: "This entity is managed elsewhere (external system, seeded data) and should
not be editable through this admin interface."

**WinterCMS rendering**:
- All fields rendered `read-only: true`
- No create/delete buttons in relation managers
- Controller may suppress create/update actions

---

### 4.4 Pattern: PivotDisplay — Rotated column display

**Triggered by**: `pivot: {by: <columnName>}` in table YAML comment

**IS semantics**: "The list view should pivot/rotate: instead of one row per record, show
one column per distinct value of `by` column, with rows representing the other dimension."

**WinterCMS rendering**: `_multi.php` configuration with pivot settings

---

### 4.5 Pattern: StageFunction — DB-triggered actions (Before/After/Action)

**Triggered by**: `before-functions: {name: config}`, `after-functions: {name: config}`,
`action-functions: {name: config}` in table YAML comment

**IS semantics**: "Database-level or application-level functions that execute before/after
record save, or on explicit user action. These become UI action buttons."

**WinterCMS rendering**:
- Action buttons injected into the form
- Permission entries for `use_function_<name>`
- `ales-functions` for Action/Link/Event/Step patterns

**Code**: `Model::allActionThings()` — `Model.php:2490`, permissions — `Model.php:698`

---

### 4.6 Pattern: ImportExport — Bulk data operations

**Triggered by**: `import: true|{config}` and/or `export: true|{config}` in table YAML comment

**IS semantics**: "This entity type supports bulk import from CSV/Excel and/or export."

**WinterCMS rendering**:
- Import/Export behaviours added to Controller
- `config_import.yaml` / `config_export.yaml` generated
- Toolbar buttons added

**Code**: `WinterCMS::createController()` — `WinterCMS.php:2146`

---

### 4.7 Pattern: BatchPrint — Multi-record printing

**Triggered by**: `batch-print: true|{config}` in table YAML comment

**IS semantics**: "Multiple records of this type can be selected and batch-printed."

**WinterCMS rendering**: Batch print behaviour + toolbar button + permission `print`

---

### 4.8 Pattern: Printable — Single-record print

**Triggered by**: `printable: true|{permissions: [...]}` in table YAML comment

**IS semantics**: "A single record can be printed."

**WinterCMS rendering**: Print permission entry added to `registerPermissions()`

---

### 4.9 Pattern: FlowChart — Process/workflow visualisation

**Triggered by**: `flow-chart: {config}` in table YAML comment

**IS semantics**: "Records of this type represent steps in a process flow that can be
visualised as a flowchart."

**WinterCMS rendering**: Flowchart-specific configuration / partial

---

### 4.10 Pattern: PermissionSettings — Field-level access control

**Triggered by**: `permission-settings: {permissionName: {field: ..., readOnly: ..., disabled: ...}}`
in table or column YAML comment

**IS semantics**: "Certain fields on this entity are gated behind named permissions —
users without the permission see a read-only or hidden version."

**WinterCMS rendering**:
- Named permissions registered in `registerPermissions()`
- Field definitions include conditional `readOnly`/`disabled` settings referencing the permission
- Supports `NOT=permissionName@context` negation syntax

**Code**: `Model::allPermissionNames()` — `Model.php:589`

---

## Section 5 — Field/Column-Level IS Patterns

### 5.1 Pattern: DeferrableRelation — Nullable FK with deferred binding

**Triggered by**: `Relation1fromX` (HasMany) where FK column on the foreign table IS nullable

**IS semantics**: "The parent record can be created before the child records exist. Child
records can be linked later (deferred binding — WinterCMS stores them in a session until the
parent is saved)."

**WinterCMS rendering**:
- `deferrable: true` on the relation field
- `deferred_binding_hint` pseudo-field NOT injected (because deferrable means no warning needed)
- If NOT deferrable: `hint_deferred_binding` hint with `stop-circle` icon injected in create
  context, warning the user that the sub-record cannot be created here until parent saved

**Code**: `Relation::deferrable()` — `Relation.php:222`, `Model::fields()` — `Model.php:2071`

---

### 5.2 Pattern: CanFilter — Column/relation filter scope

**Triggered by**: `can-filter: true` in column/FK YAML comment, or
automatically enabled for `RelationXto1` and `RelationXfromX*` types by default

**IS semantics**: "This column/relation can be used as a filter in the list view's filter bar."

**WinterCMS rendering**:
- `config_filter.yaml` scope entry for this field
- For dates: `filter-type: daterange`, `year-range: N`
- For relations: `filter-type: group` referencing the relation model
- Custom SQL: `filter-conditions: <sql>` for complex filter logic

**Code**: `Relation::canFilterDefault()` — `Relation.php:128`, `WinterCMS::createController()` — `WinterCMS.php:2183`

---

### 5.3 Pattern: HintField — Contextual UI hints

**Triggered by**: `hints: {hintName: {content: ..., level: ...}}` in table/FK YAML comment

**IS semantics**: "Display informational, warning, or error callout boxes near specific
fields to guide the user."

**WinterCMS rendering**:
- `type: hint` field entries in fields.yaml
- Levels: `info`, `warning`, `danger`, `stop-circle`
- CSS classes like `callout-stop-circle` applied
- Can be context-specific (`contexts: create`)

---

### 5.4 Pattern: ActionField — In-form action buttons

**Triggered by**: `actions: {actionName: config}` in column YAML comment

**IS semantics**: "A clickable action button appears next to this field (e.g. 'Go to event',
'Scan QR')."

**WinterCMS rendering**: Action partial injected next to the field in fields.yaml

---

### 5.5 Pattern: ListEditable — Inline list editing

**Triggered by**: `list-editable: true` in column YAML comment, and
`type-editable: <type>` for the partial type

**IS semantics**: "This column value can be edited directly in the list view without
opening the full form."

**WinterCMS rendering**: `$listRecordEditable` config + partial for editable row

---

### 5.6 Pattern: AdvancedField — Hidden-until-toggled field

**Triggered by**: `advanced: true` in column/FK YAML comment

**IS semantics**: "This field is rarely used and should be hidden behind an 'Advanced' toggle
to reduce visual clutter."

**WinterCMS rendering**: `advanced: true` on the field, rendered collapsed by default

---

### 5.7 Pattern: ConditionalField — Trigger-dependent visibility

**Triggered by**: `trigger: {action: show|hide|enable|disable, field: <name>, condition: <value>}`
in column YAML comment

**IS semantics**: "This field's visibility/enabled state depends on the value of another field."

**WinterCMS rendering**: `trigger:` config on the field in fields.yaml

---

### 5.8 Pattern: ContextSpecificField — Create/Update/Preview variants

**Triggered by**: `context-update: {key: value}`, `context-create: {key: value}`,
`context-preview: {key: value}` in column YAML comment

**IS semantics**: "This field has different display properties in create vs update vs
preview contexts."

**WinterCMS rendering**: Multiple field entries with `context:` qualifier, or merged
properties on the base field

---

### 5.9 Pattern: ExtraForeignKey — View-defined virtual FK

**Triggered by**: `extra-foreign-key: {table: ..., column: ..., comment: ..., add-reverse: bool}`
in column YAML comment (for database Views that don't have real FK constraints)

**IS semantics**: "This view column semantically references another table's records, but
the DB cannot enforce it with a constraint. Declare it explicitly."

**WinterCMS rendering**: Synthetic FK object created and added to the column's FK list,
with optional reverse FK on the target table

**Code**: `Column::loadForeignKeys()` — `Column.php:334`

---

## Section 6 — YAML Comment Key Reference

### Table-level keys (in DB table comment)

| YAML key | camelCase property | Type | Meaning |
|---|---|---|---|
| `table-type` | `tableType` | string | `content\|central\|pivot\|semi-pivot\|report` |
| `system` | `system` | bool | Suppress entirely |
| `todo` | `todo` | bool | Not yet processed |
| `menu` | `menu` | bool | Register backend nav item |
| `menu-splitter` | `menuSplitter` | bool | Visual separator before nav item |
| `menu-indent` | `menuIndent` | int | Nav indent level |
| `menu-task-items` | `menuTaskItems` | array | Task-based sub-nav items |
| `global-scope` | `globalScope` | bool/array | Cross-model filter anchor |
| `global-scope-css-theme` | `globalScopeCssTheme` | string | Body CSS class when scope active |
| `read-only` | `readOnly` | bool | All fields read-only |
| `pivot` | `pivot` | array | Pivot/rotate list display `{by: column}` |
| `icon` | `icon` | string | Icon identifier |
| `plugin-icon` | `pluginIcon` | string | Plugin nav icon override |
| `plugin-url` | `pluginUrl` | string | Plugin nav URL override |
| `package-type` | `packageType` | string | `plugin\|module` |
| `form-comment` | `formComment` | string | Section text at top of form |
| `form-comment-contexts` | `formCommentContexts` | array | Contexts for form-comment |
| `add-missing-columns` | `addMissingColumns` | bool | Auto-add missing columns |
| `default-sort` | `defaultSort` | string/array | Default list sort column + direction |
| `show-sorting` | `showSorting` | bool | Show sort controls |
| `hints` | `hints` | array | Table-level UI hints |
| `flow-chart` | `flowChart` | array | Flowchart configuration |
| `seeding` | `seeding` | array | Seed data |
| `seeding-other` | `seedingOther` | array | Seed data for other tables |
| `before-functions` | `beforeFunctions` | array | Pre-save DB/app functions → action buttons |
| `after-functions` | `afterFunctions` | array | Post-save DB/app functions → action buttons |
| `action-functions` | `actionFunctions` | array | Explicit action buttons |
| `action-links` | `actionLinks` | array | URL-based action links |
| `ales-functions` | `alesFunctions` | array | Action/Link/Event/Step functions |
| `printable` | `printable` | bool/array | Single-record print |
| `import` | `import` | bool/array | Import behaviour |
| `export` | `export` | bool/array | Export behaviour |
| `batch-print` | `batchPrint` | bool/array | Multi-record batch print |
| `qr-code-scan` | `qrCodeScan` | bool/array | QR scan integration |
| `all-controllers` | `allControllers` | bool | Generate controllers for all relations |
| `body-classes` | `bodyClasses` | array | CSS classes on controller body |
| `filters` | `filters` | array | Additional filter scopes |
| `list-record-url` | `listRecordUrl` | string | Custom list record URL |
| `visible-column-actions` | `visibleColumnActions` | array | Always-visible column actions |
| `no-relation-manager-default` | `noRelationManagerDefault` | bool | Default no-RM for all relations |
| `can-filter-default` | `canFilterDefault` | bool | Default canFilter for all relations |
| `labels` | `labels` | array | `{en: ..., ku: ..., ar: ...}` |
| `labels-plural` | `labelsPlural` | array | Plural labels |
| `permission-settings` | `permissionSettings` | array | Field-level permission gating |
| `attribute-functions` | `attributeFunctions` | array | PHP accessor methods |
| `methods` | `methods` | array | PHP methods to inject |
| `olap` | `isOlap` | bool | Mark as OLAP (analytics) table |
| `labels-from` | `labelsFrom` | array | Inherit labels from another table |
| `action-aliases` | `actionAliases` | array | Controller action aliases |
| `extra-translations` | `extraTranslations` | array | Additional lang.php entries |

### Column-level keys (in DB column comment)

| YAML key | camelCase property | Type | Meaning |
|---|---|---|---|
| `system` | `system` | bool | Suppress entirely |
| `todo` | `todo` | bool | Not yet processed |
| `field-exclude` | `fieldExclude` | bool | Exclude from fields.yaml |
| `column-exclude` | `columnExclude` | bool | Exclude from columns.yaml |
| `hidden` | `hidden` | bool | Hidden in fields.yaml |
| `invisible` | `invisible` | bool | Invisible in columns.yaml |
| `column-class` | `columnClass` | string | `normal\|foreign-id` override |
| `format` | `format` | string | Display format: `text\|date\|number` etc. |
| `bar` | `bar` | bool/array | Progress bar display |
| `field-options` | `fieldOptions` | array | Dropdown options |
| `options-with` | `optionsWith` | string | Custom options relation |
| `options-where` | `optionsWhere` | string | Custom options filter |
| `searchable` | `searchable` | bool | Searchable in list |
| `actions` | `actions` | array | Field action buttons |
| `css-classes-column` | `cssClassesColumn` | array | CSS classes for column |
| `sortable` | `sortable` | bool | Sortable in list |
| `relation` | `relation` | string | Explicit relation name override |
| `deferrable` | `deferrable` | bool | Deferred binding |
| `order` | `order` | int | Display order |
| `invisible` | `invisible` | bool | Hidden in list |
| `setting` | `setting` | string | Show if Setting is TRUE |
| `setting-not` | `settingNot` | string | Show if Setting is FALSE |
| `env` | `env` | string | Show if env var is TRUE |
| `list-editable` | `listEditable` | bool | Editable in list |
| `on` / `off` | `on` / `off` | string | Toggle values |
| `column-type` | `columnType` | string | WinterCMS column type |
| `column-partial` | `columnPartial` | string | Column partial name |
| `sql-select` | `sqlSelect` | string | SQL SELECT expression for column |
| `value-from` | `valueFrom` | string | (Avoid — not sortable) |
| `jsonable` | `jsonable` | bool | JSON storage |
| `qrcode-object` | `qrcodeObject` | bool | Generate QR code for this column |
| `context-update` | `contextUpdate` | array | Override field settings in update context |
| `context-create` | `contextCreate` | array | Override field settings in create context |
| `context-preview` | `contextPreview` | array | Override field settings in preview context |
| `field-type` | `fieldType` | string | WinterCMS field type override |
| `field-key-qualifier` | `fieldKeyQualifier` | string | Append to field key (e.g. `[start]`) |
| `name-from` | `nameFrom` | string | Name source for relation display |
| `hints` | `hints` | array | Field-level hints |
| `field-comment` | `fieldComment` | array | HTML comment below field |
| `type-editable` | `typeEditable` | string | Partial type for list-editable |
| `rules` | `rules` | array/bool | Validation rules |
| `with-end` | `withEnd` | bool | Include `[end]` field for event FKs |
| `partial` | `partial` | string | Custom partial |
| `contexts` | `contexts` | string/array | Visible in contexts |
| `default` | `default` | mixed | Default value |
| `required` | `required` | bool | Required (also inferred from NOT NULL + no default) |
| `trigger` | `trigger` | array | Conditional visibility trigger |
| `show-search` | `showSearch` | bool | Show search in relation manager |
| `span` | `span` | string | `storm\|left\|right\|full\|auto` |
| `hidden` | `hidden` | bool | Hidden |
| `css-classes` | `cssClasses` | array | CSS classes |
| `new-row` | `newRow` | bool | Force new row before field |
| `read-only` | `readOnly` | bool | Read-only |
| `no-label` | `noLabel` | bool | Suppress label |
| `bootstraps` | `bootstraps` | array | Bootstrap grid classes |
| `popup-classes` | `popupClasses` | array | Popup CSS classes |
| `record-on-click` | `recordOnClick` | string | JS on row click |
| `record-url` | `recordUrl` | string | URL for record link |
| `attributes` | `attributes` | array | HTML attributes |
| `depends-on` | `dependsOn` | array | Field dependency |
| `container-attributes` | `containerAttributes` | array | Container HTML attributes |
| `permission-settings` | `permissionSettings` | array | Field-level permission gating |
| `tab` | `tab` | string | Tab key |
| `icon` | `icon` | string | Icon |
| `tab-location` | `tabLocation` | int | `1=primary, 2=secondary, 3=tertiary` |
| `advanced` | `advanced` | bool | Advanced toggle |
| `disabled` | `disabled` | bool | Disabled |
| `adding` | `adding` | bool | DataTable: allow adding rows |
| `searching` | `searching` | bool | DataTable: enable search |
| `deleting` | `deleting` | bool | DataTable: allow deleting |
| `columns` | `columns` | array | DataTable: column definitions |
| `height` | `height` | int | DataTable: height |
| `key-from` | `keyFrom` | string | DataTable: key column |
| `can-filter` | `canFilter` | bool | Enable as filter scope |
| `filter-search-name-select` | `filterSearchNameSelect` | string | Custom SQL for filter search |
| `filter-conditions` | `filterConditions` | string | Raw SQL filter conditions |
| `labels` | `labels` | array | `{en: ..., ku: ..., ar: ...}` |
| `labels-plural` | `labelsPlural` | array | Plural labels |
| `extra-translations` | `extraTranslations` | array | Additional lang.php entries |
| `translatable` | `translatable` | bool | Override translatable flag |
| `olap` | `olap` | string/array | OLAP: `measure` etc. |
| `multi` | `multi` | array | `_multi.php` config |
| `revisionable` | `revisionable` | bool | Track revision history |

### FK/Relation-level keys (in FK DB constraint comment)

These apply to the FK constraint's `COMMENT` in PostgreSQL, and flow through to the
`Relation` object:

| YAML key | Meaning |
|---|---|
| `type: 1to1\|Xto1\|XtoX\|XtoXSemi\|leaf` | Explicit FK type override |
| `hidden` / `invisible` | Hide from form / list |
| `field-exclude` / `column-exclude` | Exclude from fields / columns |
| `has-many-deep-settings: {name: {...}}` | HasManyDeep chain control |
| `fields-settings: {fieldName: {...}}` | Override sub-field properties |
| `fields-settings-to: {fieldName: {...}}` | Override sub-column properties |
| `order` | Appearance order in tab pools |
| `type` | Explicit relation type |
| `multi` | `_multi.php` config |
| `delete` | Cascade delete in ORM |
| `contexts` | Visible contexts |
| `record-url` / `record-on-click` | Row click behaviour |
| `records-per-page` | Relation manager page size |
| `extra-translations` | Additional lang.php entries |
| `trigger` | Conditional visibility |
| `status: ok\|exclude\|broken` | Processing status |
| `include` | Force include |
| `advanced` | Advanced toggle |
| `prefix` / `suffix` | Display prefix/suffix |
| `name-object` | Show as named object link |
| `read-only` | Read-only |
| `css-classes` | CSS classes |
| `new-row` | Force new row |
| `bootstraps` | Bootstrap grid |
| `tab` | Tab key |
| `tab-location` | `1=primary, 2=secondary, 3=tertiary` |
| `span` | Column span |
| `conditions` | SQL conditions in config_relation.yaml |
| `labels` / `labels-plural` | Translation arrays |
| `default-sort` | Default sort |
| `value-from` | (Avoid — not sortable) |
| `hints` | Relation-level hints |
| `global-scope` | Scoped relation participation |
| `no-relation-manager` | Render as checkbox list instead of RM |
| `filter-conditions` | Raw SQL filter conditions |
| `has-many-deep-include` | Include in HMD chain even if non-1to1 |
| `show-filter` | Show filter in relation manager (default true) |
| `show-search` | Show search in relation manager (default true) |
| `can-filter` | Enable as filter scope |
| `depends-on` | Field dependency array |
| `flags` | Special flags (e.g. `{hierarchy: true}`) |
| `filter-search-name-select` | Custom SQL for filter term search |
| `rl-buttons` | Relation manager toolbar buttons |
| `rl-title` | Relation manager title |

---

## Section 7 — Key WinterCMS Constraint Rules

These are the framework-specific constraints that drive rendering decisions. They must be
documented so that any future framework adapter knows what to reproduce or avoid:

1. **valueFrom is not sortable**: `valueFrom: name` produces a non-sortable column.
   Always use `sqlSelect: (select t.name from table t where t.id = this.fk_id)` for sortable display.

2. **Unqualified column names cause SQL ambiguity in joins**: When a `relation:` + column name
   pattern is used in columns.yaml and the relation involves a JOIN, unqualified column names
   like `name` cause PostgreSQL `ambiguous column reference` errors. Always use `schema.table.name`.

3. **Nested bracket fields are not sortable**: `parent[child][field]` in columns.yaml is not
   a real DB column path and cannot be sorted. The HasManyDeep + sqlSelect pattern is the
   workaround.

4. **Relation embeds need a `select:` clause**: Even when embedding via `relation:`, WinterCMS
   needs an explicit `select:` to retrieve the value correctly (as of tested WinterCMS version).
   Exception: Yaml-only fields without a backing DB column.

5. **Non-nullable FK relations cannot be created in create context**: The sub-record requires
   the parent's ID, which doesn't exist yet. WinterCMS deferred binding solves this only for
   nullable FKs. Non-nullable gets a `hint_deferred_binding` warning.

6. **Relation managers are always full-width / nolabel**: CSS classes `single-tab nolabel col-xs-12`
   are auto-applied because the relation manager toolbar demonstrates its identity.

7. **1to1 relations should not be relation managers**: `Relation1to1::__construct()` sets
   `rlButtons: FALSE` because 1to1s are embedded via nested fields, not managed lists.

8. **Repeating models in HasManyDeep chains**: If the same model appears twice in a chain,
   the SQL JOIN produces duplicated FROM aliases. WinterCMS cannot alias them, so
   `repeatingModels = TRUE` → `fieldExclude = TRUE` / `columnExclude = TRUE`.

9. **User model columns excluded from column views**: `isAcornUser()` relations
   auto-set `columnExclude = TRUE` due to slow-down on large user sets.

10. **tabLocation values**: `1 = primary tabs` (main form), `2 = secondary tabs` (sidebar),
    `3 = tertiary tabs` (bottom, for system fields like QR code, translations).

---

*This catalogue was generated by discovery pass on 2026-03-12.*
*Current code locations reference the pre-refactoring state.*
