<?php namespace Acorn\CreateSystem\Semantic;

use Acorn\CreateSystem\Database\Column;

/**
 * ISPattern — Information Systems Pattern Catalogue
 *
 * Maps DDL structural situations to named IS patterns and their associated
 * WinterCMS rendering decisions (groups of fields.yaml / columns.yaml properties).
 *
 * Pipeline:
 *   DDL structural situation
 *     → IS Pattern (named, semantic)
 *     → WinterCMS property group (fields.yaml + columns.yaml + filter properties)
 *     → Generated plugin files
 *
 * Usage:
 *   $field->isPattern = ISPattern::BELONGS_TO_SORTABLE;
 *   $desc = ISPattern::get(ISPattern::BELONGS_TO_SORTABLE)->description;
 *   $all  = ISPattern::catalogue();
 */
class ISPattern
{
    // -------------------------------------------------------------------------
    // Named IS pattern constants
    // Use these as $field->isPattern values throughout the codebase.
    // -------------------------------------------------------------------------

    // --- Direct column patterns (no FK, no relation)
    const DIRECT_TEXT        = 'direct_text';
    const DIRECT_NUMBER      = 'direct_number';
    const DIRECT_DATE        = 'direct_date';
    const DIRECT_BOOLEAN     = 'direct_boolean';
    const DIRECT_RICH_TEXT   = 'direct_rich_text';
    const DIRECT_FILE_UPLOAD = 'direct_file_upload';
    const DIRECT_JSON        = 'direct_json';

    // --- FK / forward relation patterns (this table has the *_id column)
    // Xto1: FK column referencing an external table
    const BELONGS_TO          = 'belongs_to';          // target lacks a sortable "name" column
    const BELONGS_TO_SORTABLE = 'belongs_to_sortable'; // target has "name" → relation + sqlSelect (sortable)
    // 1to1: FK with UNIQUE constraint on this table
    const BELONGS_TO_1TO1     = 'belongs_to_1to1';     // specialises / extends the target record
    // leaf: FK that is also the PK of this table (class-table inheritance)
    const LEAF_EXTENSION      = 'leaf_extension';

    // --- Embedded presentation patterns (resolved in Model::fields, not at create time)
    const EMBEDDED_1TO1          = 'embedded_1to1';         // 1to1 fields embedded via bracket[key] notation
    const HAS_MANY_DEEP_SORTABLE = 'has_many_deep_sortable'; // 1to1 chain surfaced via HasManyDeep for sortability

    // --- Reverse relation patterns (PseudoFromForeignIdField / relation manager tabs)
    const HAS_MANY_RM          = 'has_many_relation_manager';
    const HAS_ONE_RM           = 'has_one_relation_manager';
    const BELONGS_TO_MANY_RM   = 'belongs_to_many_relation_manager';
    const BELONGS_TO_MANY_SEMI = 'belongs_to_many_semi_pivot';

    // --- Special / computed patterns
    const TRANSLATABLE          = 'translatable';
    const HINT                  = 'hint';
    const QR_CODE               = 'qr_code';
    const SELF_REFERENCING_TREE = 'self_referencing_tree';

    // -------------------------------------------------------------------------
    // Catalogue entry properties
    // -------------------------------------------------------------------------

    public string $name;
    public string $description;
    public string $ddlTrigger;    // DDL structural situation that activates this pattern

    /**
     * WinterCMS property groups for this pattern.
     *
     * Keys: 'field' (fields.yaml), 'column' (columns.yaml), 'filter' (config_filter.yaml)
     * Values: associative arrays of property-name => brief description/example
     */
    public array $fieldProps  = [];
    public array $columnProps = [];
    public array $filterProps = [];

    /** WinterCMS / Laravel constraints that shape this pattern */
    public array $constraints = [];

    // -------------------------------------------------------------------------
    // Construction (private — use catalogue() or get())
    // -------------------------------------------------------------------------

    private function __construct(
        string $name,
        string $description,
        string $ddlTrigger,
        array  $fieldProps  = [],
        array  $columnProps = [],
        array  $filterProps = [],
        array  $constraints = []
    ) {
        $this->name        = $name;
        $this->description = $description;
        $this->ddlTrigger  = $ddlTrigger;
        $this->fieldProps  = $fieldProps;
        $this->columnProps = $columnProps;
        $this->filterProps = $filterProps;
        $this->constraints = $constraints;
    }

    // -------------------------------------------------------------------------
    // Catalogue access
    // -------------------------------------------------------------------------

    private static ?array $catalogue = null;

    /** Retrieve a single catalogue entry by pattern constant. */
    public static function get(string $pattern): self
    {
        return self::catalogue()[$pattern] ?? self::catalogue()[self::DIRECT_TEXT];
    }

    /** Return the full catalogue keyed by pattern constant. */
    public static function catalogue(): array
    {
        if (self::$catalogue === null) {
            self::$catalogue = self::buildCatalogue();
        }
        return self::$catalogue;
    }

    // -------------------------------------------------------------------------
    // Auto-tagging helper
    // -------------------------------------------------------------------------

    /**
     * Infer the IS pattern for a freshly-constructed Field object.
     *
     * Called from Field::create() after the Field subclass is instantiated so
     * that subclass-level property assignments (sqlSelect, relation, etc.) are
     * already visible.
     *
     * Note: EMBEDDED_1TO1 and HAS_MANY_DEEP_SORTABLE are assigned later in
     * Model::fields() because they depend on the embedding context, not the
     * field itself.
     */
    public static function inferFromField(Field $field, ?Column $column, array $relations): string
    {
        // Reverse relation pseudo-fields — pattern set at construction time in the
        // subclass constructors, so we leave them alone here.
        if ($field instanceof PseudoFromForeignIdField || $field instanceof Hint) {
            return $field->isPattern ?? self::HINT;
        }

        // FK field: determine which forward-relation pattern applies
        if ($field instanceof ForeignIdField) {
            // Leaf extension: FK is also the PK (class-table inheritance)
            foreach ($relations as $relation) {
                if ($relation instanceof RelationLeaf) {
                    return self::LEAF_EXTENSION;
                }
            }
            // 1to1: FK with UNIQUE constraint
            foreach ($relations as $relation) {
                if ($relation instanceof Relation1to1) {
                    return self::BELONGS_TO_1TO1;
                }
            }
            // Xto1: sortable (target table has "name" column) vs unsortable
            return ($field->sqlSelect ? self::BELONGS_TO_SORTABLE : self::BELONGS_TO);
        }

        // Direct column: classify by data type
        if ($column) {
            return match($column->data_type) {
                'integer', 'bigint', 'int',
                'double precision', 'double', 'money' => self::DIRECT_NUMBER,

                'timestamp with time zone',
                'timestamp without time zone',
                'timestamp(0) with time zone',
                'timestamp(0) without time zone',
                'date', 'datetime'               => self::DIRECT_DATE,

                'boolean', 'bool'                => self::DIRECT_BOOLEAN,
                'text'                           => self::DIRECT_RICH_TEXT,
                'path'                           => self::DIRECT_FILE_UPLOAD,
                'json'                           => self::DIRECT_JSON,
                default                          => self::DIRECT_TEXT,
            };
        }

        return self::DIRECT_TEXT;
    }

    // -------------------------------------------------------------------------
    // Catalogue definition
    // -------------------------------------------------------------------------

    private static function buildCatalogue(): array
    {
        return [

            // ----- Direct column patterns ------------------------------------

            self::DIRECT_TEXT => new self(
                'Direct Text Column',
                'Plain varchar / character-varying column rendered as a text input.',
                'Column with data_type varchar|character varying (not a FK)',
                ['type' => 'text', 'placeholder' => 'optional'],
                ['type' => 'text (default)', 'searchable' => 'true', 'sortable' => 'true (needs sqlSelect)'],
            ),

            self::DIRECT_NUMBER => new self(
                'Direct Numeric Column',
                'Integer, bigint, double precision or money column rendered as a number input.',
                'Column with data_type integer|bigint|double precision|money',
                ['type' => 'number'],
                ['type' => 'number', 'sortable' => 'true', 'sqlSelect' => '<table>.<column> (for money: ::numeric cast)'],
            ),

            self::DIRECT_DATE => new self(
                'Direct Date/Timestamp Column',
                'Timestamp or date column rendered as a datepicker with a daterange filter.',
                'Column with data_type timestamp*|date|datetime',
                ['type' => 'datepicker', 'mode' => 'datetime|date'],
                ['type' => 'partial', 'partial' => 'datetime', 'sortable' => 'true', 'sqlSelect' => '<table>.<column>'],
                ['type' => 'daterange', 'conditions' => "<col> >= ':after' AND <col> <= ':before'"],
            ),

            self::DIRECT_BOOLEAN => new self(
                'Direct Boolean Column',
                'Boolean / bool column rendered as a switch toggle with a tick-partial in lists.',
                'Column with data_type boolean|bool',
                ['type' => 'switch'],
                ['type' => 'partial', 'partial' => 'tick', 'sortable' => 'true', 'sqlSelect' => '<table>.<column>'],
            ),

            self::DIRECT_RICH_TEXT => new self(
                'Direct Rich Text Column',
                'Text (long-form) column rendered as a rich-text editor.',
                'Column with data_type text',
                ['type' => 'richeditor'],
                ['type' => 'text', 'sortable' => 'true', 'sqlSelect' => '<table>.<column>'],
            ),

            self::DIRECT_FILE_UPLOAD => new self(
                'Direct File / Image Upload Column',
                'path-typed column rendered as a fileupload widget. The column itself must be nullable (no value stored).',
                'Column with custom data_type path',
                ['type' => 'fileupload', 'mode' => 'image', 'imageHeight' => '260', 'imageWidth' => '260'],
                ['type' => 'image'],
                [],
                ['Column must be nullable — the attachment is stored in the attachments table, not the column itself'],
            ),

            self::DIRECT_JSON => new self(
                'Direct JSON Column',
                'json column exposed via a WinterCMS datatable or codeeditor widget.',
                'Column with data_type json',
                ['type' => 'datatable|codeeditor', 'jsonable' => 'true (on model)'],
                ['type' => 'text'],
            ),

            // ----- FK / forward relation patterns ----------------------------

            self::BELONGS_TO_SORTABLE => new self(
                'BelongsTo Sortable Relation',
                'FK column (*_id) where the target table has a "name" column. Uses relation: + sqlSelect: so the '
                . 'list column is sortable and searchable. The dropdown uses dropdownOptions().',
                'FK column with Xto1 relation where target table has column "name"',
                ['type' => 'dropdown', 'options' => 'dropdownOptions()', 'dependsOn' => 'optional cascade'],
                [
                    'relation'   => '<relation_name>',
                    'sqlSelect'  => '<target_table>.name',
                    'sortable'   => 'true',
                    'searchable' => 'true',
                ],
                ['type' => 'group'],
                [
                    'sqlSelect required for sortability — valueFrom is NOT sortable in WinterCMS lists',
                    'Column name must be table-qualified to prevent SQL ambiguity in joins',
                ],
            ),

            self::BELONGS_TO => new self(
                'BelongsTo Unsortable Relation',
                'FK column (*_id) where the target table lacks a simple "name" column. Falls back to valueFrom: '
                . '(nested path). Not sortable in list view.',
                'FK column with Xto1/1to1 relation where target table has no "name" column',
                ['type' => 'dropdown', 'options' => 'dropdownOptions()', 'nameFrom' => 'optional name-object path'],
                ['valueFrom' => '<nested.path>', 'sortable' => 'false', 'searchable' => 'false'],
                [],
                [
                    'valueFrom is NOT sortable — list column will be unsortable',
                    'Consider adding a "name" virtual/generated column to enable the BELONGS_TO_SORTABLE pattern',
                ],
            ),

            self::BELONGS_TO_1TO1 => new self(
                'BelongsTo OneToOne Specialisation',
                'FK with a UNIQUE constraint on this table: this record specialises (extends) the target record. '
                . 'Form fields are embedded inline via bracket[key] notation; '
                . 'list columns use HasManyDeep for sortability.',
                'FK column (*_id) with a UNIQUE constraint (1-to-1 relationship to target table)',
                [
                    'fieldKey' => 'entity[relation_name][column] (nested bracket notation)',
                    'type'     => 'inherited from the related table column type',
                ],
                [
                    'relation'  => '<relation_name>',
                    'valueFrom' => '<relation_name>.<column> OR sqlSelect (if sortable via HasManyDeep)',
                    'sortable'  => 'true only when HasManyDeep relation exists',
                ],
                [],
                ['Nested bracket fields are NOT sortable — HasManyDeep used as sortable column alternative'],
            ),

            self::LEAF_EXTENSION => new self(
                'Leaf Table Extension (Class-Table Inheritance)',
                'This table is a specialisation of a base/central table via a "leaf" FK. '
                . 'The FK is also the PK of this table. Base table fields are embedded inline '
                . 'using bracket[key] notation.',
                'FK column named <base_table>_id where the FK is simultaneously the PK of this table',
                [
                    'fieldKey' => 'base[leaf_relation][column] (nested bracket notation for base columns)',
                    'type'     => 'inherited from the base table column type',
                ],
                [
                    'relation'  => '<leaf_relation_name>',
                    'sortable'  => 'true only via HasManyDeep',
                ],
                [],
                [],
            ),

            // ----- Embedded presentation patterns (set in Model::fields) -----

            self::EMBEDDED_1TO1 => new self(
                'Embedded OneToOne Fields',
                'Fields from a 1to1 related model embedded directly into this form via nested bracket[key] notation. '
                . 'Triggered when Model::fields() processes a ForeignIdField with 1to1 relations.',
                'ForeignIdField with 1to1/leaf relations, processed during Model::fields() embedding pass',
                [
                    'fieldKey' => 'entity[relation_name][column] (nested bracket key)',
                    'type'     => 'inherited from source field',
                ],
                [],
                [],
                ['Nested bracket keys are NOT sortable in WinterCMS list columns'],
            ),

            self::HAS_MANY_DEEP_SORTABLE => new self(
                'HasManyDeep Sortable Embedded Column',
                'A 1to1-chained relation column surfaced via the Staudenmeir HasManyDeep library '
                . 'so the column is sortable and searchable in list view. '
                . 'The field is column-only (fieldType set to FALSE — not shown in the form). '
                . 'sqlSelect must be fully qualified to avoid SQL ambiguity.',
                '1to1 relation chain where the leaf column must be sortable in a list',
                [
                    'fieldType' => 'FALSE (column-only, not rendered in forms)',
                    'fieldKey'  => 'FALSE',
                ],
                [
                    'relation'             => '<has_many_deep_relation_name>',
                    'sqlSelect'            => '<table>.<column> (fully qualified)',
                    'sortable'             => 'true',
                    'searchable'           => 'true',
                    'useRelationCondition' => 'true (custom AA relation-based filter)',
                ],
                [],
                [
                    'valueFrom is NOT sortable — must use sqlSelect instead',
                    'Unqualified column names cause SQL ambiguity in multi-table joins',
                    'Nested bracket fields [a][b][c] are NOT sortable',
                    'YAML-only fields without a DB column omit sqlSelect',
                ],
            ),

            // ----- Reverse relation patterns (relation manager tabs) ----------

            self::HAS_MANY_RM => new self(
                'HasMany Relation Manager',
                'This table is referenced by a FK on another table (1fromX). '
                . 'Rendered as a WinterCMS RelationManager tab showing child records.',
                'Another table has an FK column pointing to this table (reverse FK, 1fromX)',
                ['tab' => '<plural child name>', 'type' => 'pseudo field → relation manager tab'],
                [],
                [],
                [
                    'Create context: deferred binding required when the child FK is non-nullable '
                    . '(child cannot be created before the parent record is saved)',
                ],
            ),

            self::HAS_ONE_RM => new self(
                'HasOne Relation Manager',
                'This table is referenced by a unique FK on exactly one other record (1from1). '
                . 'May be shown as a tab or embedded inline.',
                'Another table has a UNIQUE FK column pointing to this table (reverse 1-to-1 FK)',
                ['tab' => '<singular child name>', 'type' => 'pseudo field → relation manager tab'],
            ),

            self::BELONGS_TO_MANY_RM => new self(
                'BelongsToMany Relation Manager',
                'Many-to-many relationship via a pure pivot table. '
                . 'Rendered as a WinterCMS RelationManager tab.',
                'A pivot table (singular name, no UUID id, exactly 2 FK columns) links two content tables',
                ['tab' => '<plural related name>', 'type' => 'pseudo field → relation manager tab'],
            ),

            self::BELONGS_TO_MANY_SEMI => new self(
                'BelongsToManyWithPivot Relation Manager',
                'Many-to-many with extra pivot data. Pivot columns are shown inside the relation manager.',
                'A semi-pivot table (singular name + UUID id + extra non-FK columns)',
                ['tab' => '<plural related name>', 'pivotData' => 'extra pivot columns shown inline in the relation manager'],
            ),

            // ----- Special / computed patterns --------------------------------

            self::TRANSLATABLE => new self(
                'Translatable Column',
                'Column that stores multilingual content via RainLab.Translate. '
                . 'Activated by the YAML annotation "translatable: true" or a known translatable column name.',
                'Column with YAML comment translatable: true or matching a known translatable name pattern',
                ['type' => 'text|richeditor', 'translatable' => 'true (on the field entry)'],
                [],
                [],
            ),

            self::HINT => new self(
                'Hint / Callout Field',
                'Non-data display field showing an informational callout in the form. '
                . 'Driven by the YAML annotation "hint:" on a column or as a standalone directive.',
                'YAML comment hint: {type, content, span, cssClass, ...} on a column or standalone',
                [
                    'type'     => 'hint',
                    'path'     => 'partial path to rendered hint content',
                    'span'     => 'storm (side-by-side layout)',
                    'cssClass' => 'col-xs-6 col-md-4 callout-<level>',
                ],
            ),

            self::QR_CODE => new self(
                'QR Code Display Field',
                'Displays a scannable QR code generated from field value(s). '
                . 'Driven by the YAML annotation "qr-code:" on a column.',
                'Column with YAML comment qr-code: or column named qr_code',
                ['type' => 'partial', 'path' => 'field_qr_code', 'span' => 'auto'],
            ),

            self::SELF_REFERENCING_TREE => new self(
                'Self-Referencing Tree / Hierarchy',
                'Table with an FK column pointing to itself, forming a parent-child hierarchy. '
                . 'Uses a nested/sortable tree widget in forms.',
                'FK column *_id where the referenced table is this same table (self-referencing FK)',
                ['type' => 'nesteditem|treeview', 'hierarchical' => 'true'],
                ['type' => 'text', 'valueFrom' => 'path or name'],
            ),

        ];
    }

    // -------------------------------------------------------------------------
    // Utility
    // -------------------------------------------------------------------------

    public function __toString(): string
    {
        return $this->name;
    }
}
