<?php namespace Acorn\CreateSystem;

require_once('ForeignKey.php');

class Column {
    public const SEED_IGNORE_COLUMNS = array(
        // Calendar created & updated => event_id
        'created_at_event_id',
        'updated_at_event_id',
        // created & updated => user_id
        'created_by_user_id',
        'updated_by_user_id',
        // Misc
        'server_id',
    );

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
        // Pseudo
        '_actions',
        '_qrcode',
        '_qrcode_scan',
        'state_indicator',
        // Misc
        'server_id',
        'response'
    );
    protected const STANDARD_CONTENT_COLUMNS = array(
        'name',
        'description'
    );
    protected const STANDARD_SYSTEM_COLUMNS = array(
        // NestedTree
        'nest_left',
        'nest_right',
        'nest_depth'
    );
    protected const TRANSLATABLE_COLUMNS = array(
        'name',
        'description'
    );
    public    const DATA_COLUMN_ONLY = TRUE;
    public    const INCLUDE_CONTENT_COLUMNS = FALSE;
    public    const INCLUDE_SCHEMA   = TRUE;
    public    const NO_SCHEMA   = FALSE;
    public    const PLURAL   = TRUE;
    public    const SINGULAR = FALSE;
    public const NULLABLE = TRUE;
    public const NOT_NULL = FALSE;
    public const ALWAYS_ARRAY = TRUE;

    // Objects
    public $table;
    public $foreignKeysFrom = array();
    public $foreignKeysTo   = array();
    public $autoFKType; // For auto-setting a single associated FK
    public $extraForeignKey; // Explicit fake FK. VIEWS only
    public $fieldExclude;
    public $columnExclude;
    public $filters;

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
    public $prefix; // Supported by _some_ partials
    public $suffix; // Supported by _some_ partials
    public $multi;

    // --------------------- Column comment accepted values
    // These flow through to Field
    public $comment; // YAML comment
    public $columnClass; // Useful when *_id fields are not FK fields
    public $format; // text, date, number, etc. Includes suffix & prefix
    public $bar;
    public $parsedComment; // array
    public $fieldOptions;  // array
    public $searchable;
    public $cssClassesColumn;
    public $sortable;
    public $relation; // Explicit relation: setting
    public $order;
    public $invisible;
    public $system;  // Internal column, do not process
    public $todo;    // TODO: This column structure has not been analysed / enabled yet
    public $setting; // Only show the column if a Setting is TRUE
    public $env;     // Only show the column if an env VAR is TRUE
    public $listEditable;
    public $columnType;
    public $columnPartial;
    public $sqlSelect;
    public $valueFrom; // We should never use this because it cannot be sorted
    public $jsonable;
    public $qrcodeObject;

    // --------------------- Field comment accepted values
    public $fieldType;
    public $fieldComment; // HTML field comment
    public $typeEditable; // For list-editable row partial
    public $rules = array();
    public $partial;
    public $default;
    public $required;
    public $trigger;
    public $showSearch;
    public $span;
    public $hidden;
    // Arrays for css class
    public $cssClasses;   // css-classes: - hug-left
    public $newRow;
    public $readOnly;
    public $commentHtml;
    public $noLabel;      // css-classes: nolabel
    public $bootstraps;   // bootstrap: xs: 12 sm: 4
    public $popupClasses; // popup-classes: h
    public $attributes;
    public $containerAttributes;
    // Assemble all field permission-settings directives names
    // for Plugin registerPermissions()
    // Permission names (keys) are fully-qualified
    //   permission-settings:
    //      NOT=legalcases__owner_user_group_id__update@update:
    //         field:
    //         readOnly: true
    //         disabled: true
    //         labels: 
    //           en: Update owning Group
    public $permissionSettings;
    // For columns
    public $tab;
    public $icon;
    public $tabLocation; // primary|secondary|tertiary
    public $advanced; // Toggle advanced to show

    // DataTable field type
    public $adding;
    public $searching;
    public $deleting;
    public $columns;
    public $height;
    public $keyFrom;

    // Translation arrays
    public $labels;
    public $labelsPlural;
    public $extraTranslations; // array
    public $translatable;

    public static function fromRow(Table &$table, array $row): Column
    {
        return new self($table, ...$row);
    }

    public static function dummy(Table &$table, string $column_name): Column
    {
        return self::fromRow($table, array(
            'column_name' => $column_name,
        ));
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
            if (property_exists($this, $name)
                && !isset($this->$name)
            ) {
                $this->$name = $value;
            }
        }

        $this->parsedComment = \Spyc::YAMLLoadString($this->comment);
        foreach ($this->parsedComment as $name => $value) {
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
            if ($this->column_name == 'state_indicator') 
                $definition['columnType'] = 'partial'; 
        }
        else if ($this->isSystem()) {
            $definition = array(
                'system'     => TRUE,   // Do not process at all
            );
        }
        
        if ($this->isTranslatable()) {
            $definition['translatable'] = TRUE;
        }

        return $definition;
    }

    public function shouldProcess(): bool
    {
        return ($this->table->shouldProcess() && !$this->system && !$this->todo);
    }

    public function loadForeignKeys(): void
    {
        global $YELLOW, $NC;

        // The from on these foreign keys is always the column the FK is attached to
        // So foreignKeysTo will point (to) to this table id, and from a foreign table
        $this->foreignKeysFrom = $this->db()->foreignKeysFrom($this); // from => to(id), $to=FALSE
        $this->foreignKeysTo   = $this->db()->foreignKeysTo($this);   // to(id) <= from, $to=TRUE

        if ($this->extraForeignKey) {
            // Used by views to create links with other tables
            // We assume this is a FK from the view foreign key field
            // to an id on another table
            $table    = $this->table;
            $toSchema = $this->extraForeignKey['schema']  ?? 'public';
            $toTable  = $this->extraForeignKey['table'];
            $toColumn = $this->extraForeignKey['column']  ?? 'id';
            $comment  = $this->extraForeignKey['comment'] ?? array();
            $addReverse  = $this->extraForeignKey['add-reverse'] ?? TRUE;
            $commentTo   = $this->extraForeignKey['comment-to'] ?? array();
            $commentFrom = $this->extraForeignKey['comment-from'] ?? array();
            
            if (!$commentTo)   $commentTo   = $comment;
            if (!$commentFrom) $commentFrom = $comment;
            if (!isset($commentTo['read-only']))   $commentTo['read-only']   = TRUE;
            if (!isset($commentFrom['read-only'])) $commentFrom['read-only'] = TRUE;
            
            $to     = FALSE;
            $row    = array(
                // Copied from DB::foreignKeys()
                'oid'     => '',
                'name'    => "$toTable.$this->name",
                'comment' => \Spyc::YAMLDump($commentTo, FALSE, FALSE, TRUE), // e.g. tab-location: 3
                'table_from_schema' => $table->schema,
                'table_from_name'   => $table->name,
                'table_from_column' => $this->name,
                'table_to_schema'   => $toSchema,
                'table_to_name'     => $toTable,
                'table_to_column'   => $toColumn,
            );
            $fk   = ForeignKey::fromRow($this, $to, $row);
            $name = $fk->fullyQualifiedName();
            if (isset($this->foreignKeysFrom[$name]))
                throw new \Exception("Foreign Key (to) $name already exists on $table->name.$this->name");
            $this->foreignKeysFrom[$name] = $fk;
            print("  Added extra foreign key $YELLOW$name$NC from column $YELLOW$this->name$NC\n");

            if ($addReverse) {
                // Create the reverse FK on the target table...
                $to     = TRUE;
                $row['comment'] = \Spyc::YAMLDump($commentFrom, FALSE, FALSE, TRUE); // e.g. tab-location: 3
                $toTableObject  = Table::get($toTable, $toSchema); // Will throw
                $toColumnObject = $toTableObject->getColumn($toColumn);
                $fk   = ForeignKey::fromRow($toColumnObject, $to, $row);
                $name = $fk->fullyQualifiedName();
                if (isset($toColumnObject->foreignKeysTo[$name]))
                    throw new \Exception("Foreign Key (from) $name already exists on $toTable.$toColumn");
                $toColumnObject->foreignKeysTo[$name] = $fk;
                print("  Added extra {$YELLOW}reverse{$NC} foreign key $YELLOW$name$NC to column $YELLOW$toTable.$toColumn$NC\n");
            }
        }
    }

    public function db(): DB
    {
        return $this->table->db();
    }

    public function dbLangPath(): string
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

    public function commentValue(string $dotPath, bool $alwaysArray = FALSE)
    {
        // methods.name
        $path  = explode(".", $dotPath);
        $value = $this->parsedComment;
        while ($value 
            && is_array($value)
            && ($step = array_shift($path))
            && isset($value[$step])
        ) {
            $value = $value[$step];
        }

        // If there is path left, we did not arrive
        if ($path) $value = NULL;
        else if ($alwaysArray && !is_array($value)) $value = array($value);

        return $value;
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

    public function isSystem(): bool
    {
        return (array_search($this->name, self::STANDARD_SYSTEM_COLUMNS) !== FALSE);
    }

    public function isTranslatable(): bool
    {
        return (array_search($this->name, self::TRANSLATABLE_COLUMNS) !== FALSE);
    }

    public function isCustom(): bool
    {
        return !$this->isStandard();
    }

    public function isForeignID(): bool
    {
        // id != isForeignID
        // Set YAML columnClass: normal for *_id fields that are not FK fields
        $nameParts = explode('_', $this->name);
        return (!$this->columnClass || $this->columnClass == 'foreign-id') 
            && (count($nameParts) > 1 && end($nameParts) == 'id');
    }

    public function isGenerated(): bool
    {
        return ($this->is_generated != 'NEVER');
    }

    public function hasParentInName(): bool
    {
        return (strstr($this->name, 'parent_') !== FALSE);
    }

    public function relationName(bool $plural = self::SINGULAR): string
    {
        // TODO: This should be static Relation::nameFromColumn(Column $column)
        if ($this->isTheIdColumn()) 
            throw new \Exception("Relation name not possible for ID columns");
        $fieldName = $this->nameWithoutId();
        return ($plural ? Str::plural($fieldName) : $fieldName);
    }

    public function fullyQualifiedName(bool $includeSchema = self::INCLUDE_SCHEMA): string
    {
        $table = &$this->table;
        $fqn   = "$table->name.$this->name";
        if ($includeSchema) $fqn = "$table->schema.$fqn";
        return $fqn;
    }
}
