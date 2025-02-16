<?php namespace Acorn\CreateSystem;

require_once('ForeignKey.php');

class Column {
    protected const STANDARD_DATA_COLUMNS = array(
        'id',
        // Normal created & updated timestamps
        'created_at',
        'updated_at',
        // Calendar created & updated => event_id
        'created_at_event_id',
        'updated_at_event_id',
        // DB auth created & updated => CURRENT_USER varchar
        'created_by',
        'updated_by',
        // created & updated => user_id
        'created_by_user_id',
        'updated_by_user_id',
        // Misc
        'server_id',
        'response'
    );
    protected const STANDARD_CONTENT_COLUMNS = array(
        'name',
        'description'
    );
    public    const DATA_COLUMN_ONLY = TRUE;
    public    const INCLUDE_CONTENT_COLUMNS = FALSE;
    public    const INCLUDE_SCHEMA   = TRUE;
    public    const PLURAL   = TRUE;
    public    const SINGULAR = FALSE;
    public const NULLABLE = TRUE;
    public const NOT_NULL = FALSE;

    // Objects
    public $table;
    public $foreignKeysFrom = array();
    public $foreignKeysTo   = array();
    public $autoFKType; // For auto-setting a single associated FK

    // --------------------- Database column settings
    // information_schema.columns.* SQL standard
    public $oid;
    public $column_name;
    public $table_name;
    public $ordinal_position;
    public $column_default;
    public $is_nullable;
    public $data_type;
    public $character_maximum_length;
    public $character_octet_length;
    public $numeric_precision;
    public $numeric_precision_radix;
    public $numeric_scale;
    public $datetime_precision;
    public $interval_type;
    public $interval_precision;
    public $character_set_catalog;
    public $character_set_schema;
    public $character_set_name;
    public $collation_catalog;
    public $collation_schema;
    public $collation_name;
    public $domain_catalog;
    public $domain_schema;
    public $domain_name;
    public $udt_catalog;
    public $udt_schema;
    public $udt_name;
    public $scope_catalog;
    public $scope_schema;
    public $scope_name;
    public $maximum_cardinality;
    public $dtd_identifier;
    public $is_self_referencing;
    public $is_identity;
    public $identity_generation;
    public $identity_start;
    public $identity_increment;
    public $identity_maximum;
    public $identity_minimum;
    public $identity_cycle;
    public $is_generated;
    public $generation_expression;
    public $is_updatable;

    // Aliases
    public $name; // = column_name

    // --------------------- Column comment accepted values
    // These flow through to Field
    public $comment; // YAML comment
    public $fieldComment; // HTML field comment
    public $system;  // Internal column, do not process
    public $todo;    // TODO: This column structure has not been analysed / enabled yet
    public $setting; // Only show the column if a Setting is TRUE
    public $env;     // Only show the column if an env VAR is TRUE
    // For fields
    public $fieldType;
    public $rules = array();
    public $span;
    public $hidden;
    // Arrays for css class
    public $cssClasses;   // css-classes: - hug-left
    public $newRow;
    public $noLabel;      // css-classes: nolabel
    public $bootstraps;   // bootstrap: xs: 12 sm: 4
    public $popupClasses; // popup-classes: h
    public $containerAttributes;
    // For columns
    public $columnType;
    public $sqlSelect;
    public $valueFrom; // We should never use this because it cannot be sorted
    public $invisible;
    public $tab;
    public $icon;
    public $tabLocation; // primary|secondary|tertiary
    // Translation arrays
    public $labels;
    public $labelsPlural;

    public static function fromRow(Table &$table, array $row)
    {
        return new self($table, ...$row);
    }

    static protected function blockingAlert(string $message, string $level = 'WARNING'): void
    {
        global $YELLOW, $NC;

        print("$YELLOW$level$NC: $message. Continue (y)? ");
        $yn = readline();
        if (strtolower($yn) == 'n') exit(0);
    }

    protected function __construct(Table &$table, ...$properties)
    {
        $this->table = &$table;
        foreach ($properties as $name => $value) {
            if (property_exists($this, $name)) $this->$name = $value;
        }
        $this->name = $this->column_name;

        // Columns data types will be quoted if they are reserved words
        $this->data_type = str_replace('"', '', $this->data_type);

        // TODO: This needs to be moved to the standardTargetModelFieldDefinitions()
        foreach ($this->standardFieldDefinitions($this->name) as $name => $value) {
            if (property_exists($this, $name)) $this->$name = $value;
        }

        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) self::blockingAlert("Property [$nameCamel] does not exist on [$this->table.$this->name]");
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }

        // Checks
        if ($this->labels       && !is_array($this->labels))       throw new \Exception("labels: should be an array");
        if ($this->labelsPlural && !is_array($this->labelsPlural)) throw new \Exception("labels-plural: should be an array");
    }

    public function standardFieldDefinitions(string $name): array
    {
        // TODO: This needs to be moved to the standardTargetModelFieldDefinitions()
        $definition = array();
        if ($this->isStandard(self::DATA_COLUMN_ONLY)) {
            $definition = array(
                'hidden'     => TRUE,   // fields
                'invisible'  => TRUE,   // columns
            );
            if (!$this->isTheIdColumn()) $definition['autoFKType'] = 'Xto1'; // relations
        }
        return $definition;
    }

    public function shouldProcess(): bool
    {
        return ($this->table->shouldProcess() && !$this->system && !$this->todo);
    }

    public function loadForeignKeys()
    {
        $tableName = $this->table->name;
        // The from on these foreign keys is always the column the FK is attached to
        // So foreignKeysTo will point (to) to this table id, and from a foreign table
        $this->foreignKeysFrom = $this->db()->foreignKeysFrom($this); // from => to
        $this->foreignKeysTo   = $this->db()->foreignKeysTo($this);   // to <= from
    }

    protected function db()
    {
        return $this->table->db();
    }

    public function dbLangPath()
    {
        $tableLangPath = $this->table->dbLangPath();
        return "$tableLangPath.columns.$this->column_name";
    }

    protected function firstName(): string
    {
        $nameParts = explode('_', $this->name);
        return $nameParts[0];
    }

    protected function lastName(): string
    {
        // Often id
        $nameParts = explode('_', $this->name);
        return end($nameParts);
    }

    public function nameWithoutId(): string
    {
        // id != isForeignID
        $nameParts = explode('_', $this->name);
        if (count($nameParts) > 1 && end($nameParts) == 'id') array_pop($nameParts);
        return implode('_', $nameParts);
    }

    protected function lastNameWithoutId(): string
    {
        // Often id
        $nameParts = explode('_', $this->name);
        if (count($nameParts) > 1 && end($nameParts) == 'id') array_pop($nameParts);
        return end($nameParts);
    }

    // ----------------------------------------- Display
    public function __toString(): string
    {
        $toString = "$this->name($this->data_type)";

        if ($this->isGenerated()) $toString = "#!$toString";

        if (is_array($this->labels) && isset($this->labels['en'])) {
            $labelEn   = $this->labels['en'];
            $toString .= " labelled($labelEn)";
        }

        return $toString;
    }

    public function show(int $indent = 0)
    {
        global $GREEN, $YELLOW;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$this\n");
        foreach ($this->foreignKeysFrom as &$fk) $fk->show($indent+1);
        foreach ($this->foreignKeysTo   as &$fk) $fk->show($indent+1);
    }

    // ----------------------------------------- Semantic information
    public function isTheIdColumn(): bool
    {
        return ($this->name == 'id');
    }

    public function isStandard(bool $dataColumnOnly = self::INCLUDE_CONTENT_COLUMNS): bool
    {
        return (array_search($this->name, self::STANDARD_DATA_COLUMNS) !== FALSE
            ||  (!$dataColumnOnly && array_search($this->name, self::STANDARD_CONTENT_COLUMNS) !== FALSE)
        );
    }

    public function isCustom(): bool
    {
        return !$this->isStandard();
    }

    public function isForeignID(): bool
    {
        // id != isForeignID
        $nameParts = explode('_', $this->name);
        return (count($nameParts) > 1 && end($nameParts) == 'id');
    }

    public function isGenerated(): bool
    {
        return ($this->is_generated != 'NEVER');
    }

    public function relationName(bool $plural = self::SINGULAR): string
    {
        // TODO: This should be static Relation::nameFromColumn(Column $column)
        if ($this->isTheIdColumn()) throw new \Exception("Relation name not possible for ID columns");
        $fieldName = $this->nameWithoutId();
        return ($plural ? Str::plural($fieldName) : $fieldName);
    }

    public function fromRelationName(bool $plural = self::SINGULAR): string
    {
        // TODO: This should be static Relation::fromNameFromColumn(Column $column)
        // When a relation is from this column to an id
        // e.g. 1fromX justice.id <= civil.legalcase_id
        // where we cannot use the Field that the from relation is attached to, ID
        // so we use civil_legalcases_legalcase
        if ($this->isTheIdColumn()) throw new \Exception("From relation name not possible for ID columns");
        $tableRelationName = $this->table->relationName(); // civil_legalcases
        $relationName      = $this->relationName($plural); // legalcase[s]
        return "${tableRelationName}_$relationName";
    }

    public function fullyQualifiedName(bool $includeSchema = self::INCLUDE_SCHEMA): string
    {
        $table = &$this->table;
        $fqn   = "$table->name.$this->name";
        if ($includeSchema) $fqn = "$table->schema.$fqn";
        return $fqn;
    }
}
