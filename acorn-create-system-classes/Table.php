<?php namespace Acorn\CreateSystem;

use Exception;

require_once('Str.php');
require_once('Column.php');
require_once('Trigger.php');

class Table {
    public const FIRST_ONLY = TRUE;
    public const REQUIRE_ONLY_ONE = FALSE;
    public const OMIT_SCHEMA_PUBLIC = TRUE;
    public const INCLUDE_SCHEMA_PUBLIC = FALSE;
    public const OR_LEAF = TRUE;
    public const ALL_COLUMNS = TRUE;
    public const ADD_REVERSE = TRUE;
    public const NO_REVERSE = FALSE;

    // TODO: These should be in the WinterCMS framework abstraction
    protected static $knownAcornPlugins = array('User', 'Location', 'Messaging', 'Calendar', 'Reporting', 'BackendLocalization', 'Rtler');
    protected static $knownWinterPlugins = array('System', 'Backend');

    protected static $tables = array();

    protected $db;

    public $schema;
    public $name; // Un-qualified, see schema 
    public $order;
    protected $owner;
    static $generalOwner;

    public $comment;
    public $parsedComment; // array
    public $packageType; // plugin|module
    public $pluginIcon;
    public $pluginUrl;
    public $system; // Internal do not process
    public $todo;   // TODO: This structure has not been analysed / enabled yet
    public $addMissingColumns; // Add missing columns
    public $permissionSettings;
    public $readOnly;
    // Rotate values => columns in list display
    // by: pivot column
    // 
    public $pivot; 


    public $icon;
    public $tableType; // TODO: create a Derived class instead?
    public $globalScope; // Limits all related models to here by the selection
    public $plural;
    public $singular;
    public $menu;
    public $menuSplitter;
    public $menuIndent;
    public $seedingOther;
    public $seeding;
    public $labelsFrom = array(); // Inherit labels from another table. Useful for views

    // Translation arrays
    public $pluginNames;
    public $pluginDescriptions;
    public $labels;
    public $labelsPlural;
    // PHP model methods
    public $attributeFunctions = array();
    public $methods            = array();
    public $staticMethods      = array();
    public $contraints = array();

    public $defaultSort;
    public $showSorting;
    public $columns;
    public $actionFunctions;
    public $actionLinks;
    public $alesFunctions;
    public $triggers;
    public $printable;
    public $import;
    public $export;
    public $batchPrint;
    public $qrCodeScan;
    public $allControllers;

    public $filters = array();
    public $listRecordUrl;
    public $showColumnActions;
    public $noRelationManagerDefault;
    public $canFilterDefault;

    // This is set when models are created
    public $model;

    // ----------------------------------------- Construction
    public static function fromRow(DB &$db, array $row)
    {
        return new Table($db, ...$row);
    }

    public static function &get(string $name, string $schema = NULL): Table
    {
        // Allow search with or without schema, with or without dot notation
        // Note that the Lojistiks system uses 2 schemas: public and product
        if ($schema) {
            $qualifiedName = "$schema.$name";
        } else {
            $nameParts  = explode('.', $name);
            $tableName  = (count($nameParts) == 2 ? $nameParts[1] : $nameParts[0]);
            $schemaName = (count($nameParts) == 2 ? $nameParts[0] : 'public');
            $qualifiedName = "$schemaName.$tableName";
        }
        if (!isset(self::$tables[$qualifiedName])) 
            throw new Exception("Table [$qualifiedName] not in static list");
        return self::$tables[$qualifiedName];
    }

    public static function dummy(DB &$db, string $name, string $schema = NULL, array $columns = array()): Table
    {
        // Allow search with or without schema, with or without dot notation
        // Note that the Lojistiks system uses 2 schemas: public and product
        if (!$schema) {
            $nameParts  = explode('.', $name);
            $name       = (count($nameParts) == 2 ? $nameParts[1] : $nameParts[0]);
            $schema     = (count($nameParts) == 2 ? $nameParts[0] : 'public');
        }

        return new Table($db, array(
            'name'    => $name,
            'schema'  => $schema,
            'columns' => $columns
        ));
    }

    protected function __construct(DB &$db, ...$properties)
    {
        $this->db = &$db;
        foreach ($properties as $name => $value) {
            if (property_exists($this, $name)) $this->$name = $value;
        }
        $this->parsedComment = \Spyc::YAMLLoadString($this->comment);
        foreach ($this->parsedComment as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) self::blockingAlert("Property [$nameCamel] does not exist on [$this->name]");
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }

        if (!isset($this->columns)) 
            $this->columns = $this->tableColumns(); // Will not return system columns

        // Name and registration
        $nameParts  = explode('.', $this->name);
        if (count($nameParts) > 1)
            throw new Exception("Name [$this->name] is already qualified. Use schema instead");
        $qualifiedName = "$this->schema.$this->name";
        self::$tables[$qualifiedName] = $this;
    }

    static protected function blockingAlert(string $message, string $level = 'WARNING'): void
    {
        global $YELLOW, $NC;

        print("$YELLOW$level$NC: $message. Continue (y)? ");
        $yn = readline();
        if (strtolower($yn) == 'n') exit(0);
    }

    public function tableColumns(bool $allColumns = FALSE): array
    {
        return $this->db->tableColumns($this, $allColumns);
    }

    public function check(): bool
    {
        global $YELLOW, $RED, $NC;

        // Will return TRUE if changes were made
        // indicating that the DB schema should be re-read
        $changes = FALSE;

        // Checks & auto-creates
        // We omit some of our own known plugins
        // because they do not conform yet to our naming requirements
        if (   $this->shouldProcess() // !system && !todo
            && $this->addMissingColumns !== FALSE
            && $this->isOurs()        // Acorn author
            && !$this->isKnownAcornPlugin() // $knownAcornPlugins (non-create-system) above
            && !$this->isModule()
            // 1-1 & leaf checks happen below in hasCustom1to1FK() 
        ) {
            $strPlural   = Str::plural($this->name);
            $strSingular = Str::singular($this->name);
            
            // We don't really know the ideal owner, so we just check it is consistent
            if (!self::$generalOwner) {
                self::$generalOwner = $this->owner;
                print("Set general owner to [$YELLOW$this->owner$NC]\n");
            } else if ($this->owner != self::$generalOwner)
                throw new Exception("Table $this->name is owned by $this->owner, not " . self::$generalOwner);

            // ------------------------------------ Content tables
            if ($this->isContentTable()) {
                if (!$this->hasColumn('id', 'uuid', 'gen_random_uuid()')) {
                    // TODO: Offer to add it?
                    throw new Exception("Content table [$this->name] has no id(uuid/gen_random_uuid()) column");
                }

                // ------------------------ name
                $columnCheck = 'name';
                if (!$this->hasColumn($columnCheck) 
                    && !$this->hasCustom1to1FK() 
                    && !$this->hasCustomNameObjectFK()
                    && !$this->hasPHPMethod($columnCheck)
                    && !$this->hasAttributeFunction($columnCheck)
                ) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] column, 1to1, name-object or name PHP method";
                    print("{$RED}WARNING$NC: $error\n");
                    $gen = readline("Create a generated [$columnCheck] with clause [<clause>|n] (id) ?");
                    if ($gen != 'n') {
                        if (!$gen) $gen = 'id';
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'character varying(1024)', $gen);
                        print("Added [$columnCheck] with clause [$gen]\n");
                        $changes = TRUE;
                    }
                }

                // ------------------------ description (Notes)
                $columnCheck = 'description';
                if (!$this->hasColumn($columnCheck)
                    && !$this->hasCustom1to1FK() 
                    && !$this->hasCustomNameObjectFK()
                    && !$this->hasPHPMethod($columnCheck)
                    && !$this->hasAttributeFunction($columnCheck)
                ) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create a [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'text', NULL, Column::NULLABLE);
                        print("Added [$columnCheck]\n");
                        $changes = TRUE;
                    }
                }
                if ($this->hasColumn($columnCheck) && FALSE) {
                    $column = $this->columns[$columnCheck];
                    if ($column->commentValue('tab-location') != 1) {
                        $error = "Content table [$YELLOW$this->name$NC] column [$YELLOW$columnCheck$NC] is not at tab-location: 1";
                        print("{$RED}WARNING$NC: $error\n");
                        $yn = readline("Adjust [$columnCheck] comment (y) ?");
                        if ($yn != 'n') {
                            $this->db->setCommentValue($this->fullyQualifiedName(), $columnCheck, 'tab-location', 1);
                        }    
                    }
                    $tab = 'acorn::lang.models.general.description';
                    if ($column->commentValue('tab') != $tab) {
                        $error = "Content table [$YELLOW$this->name$NC] column [$YELLOW$columnCheck$NC] is not on a tab";
                        print("{$RED}WARNING$NC: $error\n");
                        $yn = readline("Adjust [$columnCheck] comment (y) ?");
                        if ($yn != 'n') {
                            $this->db->setCommentValue($this->fullyQualifiedName(), $columnCheck, 'tab', $tab);
                        }    
                    }
                    $cssClasses = $column->commentValue('css-classes', Column::ALWAYS_ARRAY);
                    if (is_null($cssClasses) || !in_array('single-tab', $cssClasses)) {
                        $error = "Content table [$YELLOW$this->name$NC] column [$YELLOW$columnCheck$NC] does not have single-tab class";
                        print("{$RED}WARNING$NC: $error\n");
                        $yn = readline("Adjust [$columnCheck] comment (y) ?");
                        if ($yn != 'n') {
                            $this->db->appendCommentValue($this->fullyQualifiedName(), $columnCheck, 'css-classes', 'single-tab');
                        }    
                    }
                }

                // ----------------------- up|created_at
                $columnCheck = 'created_at';
                if (!$this->hasColumn($columnCheck) && !$this->hasCustom1to1FK()) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        // timestamp(0) => seconds only, not seconds.milliseconds, for Laravel standard date format
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'timestamp(0) without time zone', NULL, Column::NOT_NULL, 'now()');
                        print("Added [$columnCheck] with FK\n");
                        $changes = TRUE;
                    }
                }
                $columnCheck = 'updated_at';
                if (!$this->hasColumn($columnCheck) && !$this->hasCustom1to1FK()) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        // timestamp(0) => seconds only, not seconds.milliseconds, for Laravel standard date format
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'timestamp(0) without time zone', NULL, TRUE);
                        print("Added [$columnCheck] with FK\n");
                        $changes = TRUE;
                    }
                }

                // -------------------- compile names view
                static $firstNameTablesViewEntry = TRUE;
                $tablesView = array();
                $modelClass     = $this->fullyQualifiedModelName();
                $nameColumn     = ($this->hasColumn('name') ? 'name::character varying(1024)' : 'NULL');
                $standardFields = "'$modelClass' as model_type, id as model_id, '$this->name' as \"table\"";

                if ($this->hasColumn('name'))        array_push($tablesView, "select $standardFields, 'name' as \"field\", name::text as content from $this->name");
                if ($this->hasColumn('description')) array_push($tablesView, "select $standardFields, 'description' as \"field\", description::text as content from $this->name");
                
                if ($tablesView) {
                    $tablesViewString = implode("\nunion all\n", $tablesView);
                    if (!$firstNameTablesViewEntry) $tablesViewString = "\nunion all\n$tablesViewString";
                    file_put_contents('name_tables_view.sql', $tablesViewString, FILE_APPEND);
                    $firstNameTablesViewEntry = FALSE;
                }

                // -------------------- compile created_by users
                static $firstUserTablesViewEntry = TRUE;
                $tablesView = array();

                if ($this->hasColumn('created_by_user_id')) array_push($tablesView, "select $standardFields, 0 as \"update\", created_by_user_id as \"by\" from $this->name");
                if ($this->hasColumn('updated_by_user_id')) array_push($tablesView, "select $standardFields, 1 as \"update\", updated_by_user_id as \"by\" from $this->name");
                
                if ($tablesView) {
                    $tablesViewString = implode("\nunion all\n", $tablesView);
                    if (!$firstUserTablesViewEntry) $tablesViewString = "\nunion all\n$tablesViewString";
                    file_put_contents('acorn_created_bys_view.sql', $tablesViewString, FILE_APPEND);
                    $firstUserTablesViewEntry = FALSE;
                }                

                // -------------------- compile created|updated_at[_event_id] fields for calendar
                // to use in its special activity event instance view
                // TODO: Should this date_tables_view.sql be in the Model instead? We need the external_url from the Controller facade
                static $firstDateTablesViewEntry = TRUE;
                $tablesView = array();
                $nameColumn     = ($this->hasColumn('name') ? 'name::character varying(1024)' : 'NULL');
                $standardFields = "'$modelClass' as model_type, id as model_id, '$this->name' as \"table\", $nameColumn as \"name\"";

                // TODO: Old system: remove *_event_id (revert_timestamps.sql)
                // table name, create|update, event_id
                if ($this->hasColumn('created_at_event_id')) array_push($tablesView, "select $standardFields, 0 as \"update\", created_at_event_id as event_id from $this->name");
                if ($this->hasColumn('updated_at_event_id')) array_push($tablesView, "select $standardFields, 1 as \"update\", updated_at_event_id as event_id from $this->name");
                // TODO: New system, normal timestamps
                if ($this->hasColumn('created_at')) array_push($tablesView, "select $standardFields, 0 as \"update\", created_at as datetime from $this->name");
                if ($this->hasColumn('updated_at')) array_push($tablesView, "select $standardFields, 1 as \"update\", updated_at as datetime from $this->name");
                
                if ($tablesView) {
                    $tablesViewString = implode("\nunion all\n", $tablesView);
                    if (!$firstDateTablesViewEntry) $tablesViewString = "\nunion all\n$tablesViewString";
                    file_put_contents('date_tables_view.sql', $tablesViewString, FILE_APPEND);
                    $firstDateTablesViewEntry = FALSE;
                }

                // -------------------- created_by[_user_id]
                $columnCheck = 'created_by_user_id';
                if (!$this->hasColumn($columnCheck) && !$this->hasCustom1to1FK()) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'uuid', NULL);
                        $this->db->addForeignKey($this->fullyQualifiedName(), $columnCheck, 'acorn_user_users');
                        print("Added [$columnCheck] NULLABLE with FK\n");
                        $changes = TRUE;
                    }
                }
                if ($this->hasColumn($columnCheck) && !$this->getColumnFK($columnCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] FK";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] FK (y) ?");
                    if ($yn != 'n') {
                        $this->db->addForeignKey($this->fullyQualifiedName(), $columnCheck, 'acorn_user_users');
                        print("Added [$columnCheck] FK\n");
                        $changes = TRUE;
                    }
                }
                $triggerCheck = 'fn_acorn_created_by_user_id';
                if ($this->hasColumn($columnCheck) && !$this->hasTrigger($triggerCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has [$YELLOW$columnCheck$NC] column but no trigger [$YELLOW$triggerCheck$NC]";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$triggerCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addTrigger($this->fullyQualifiedName(), $triggerCheck, 'BEFORE', array('INSERT'));
                        print("Added [$triggerCheck]\n");
                        $changes = TRUE;
                    }
                }
                $columnCheck = 'created_by';
                if ($this->hasColumn($columnCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has a depreceated [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Remove [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->deleteColumn($this->fullyQualifiedName(), $columnCheck);
                        print("Deleted [$columnCheck]\n");
                        $changes = TRUE;
                    }
                }

                // --------------------- updated_by[_user_id]
                $columnCheck = 'updated_by_user_id';
                if (!$this->hasColumn($columnCheck) && !$this->hasCustom1to1FK()) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'uuid', NULL, Column::NULLABLE);
                        $this->db->addForeignKey($this->fullyQualifiedName(), $columnCheck, 'acorn_user_users');
                        print("Added [$columnCheck] NULLABLE with FK\n");
                        $changes = TRUE;
                    }
                }
                if ($this->hasColumn($columnCheck) && !$this->getColumnFK($columnCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] FK";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] FK (y) ?");
                    if ($yn != 'n') {
                        $this->db->addForeignKey($this->fullyQualifiedName(), $columnCheck, 'acorn_user_users');
                        print("Added [$columnCheck] FK\n");
                        $changes = TRUE;
                    }
                }
                $triggerCheck = 'fn_acorn_updated_by_user_id';
                if ($this->hasColumn($columnCheck) && !$this->hasTrigger($triggerCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has [$YELLOW$columnCheck$NC] column but no trigger [$YELLOW$triggerCheck$NC]";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$triggerCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addTrigger($this->fullyQualifiedName(), $triggerCheck, 'BEFORE', array('UPDATE'));
                        print("Added [$triggerCheck]\n");
                        $changes = TRUE;
                    }
                }
                $columnCheck = 'updated_by';
                if ($this->hasColumn($columnCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has a depreceated [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Remove [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->deleteColumn($this->fullyQualifiedName(), $columnCheck);
                        print("Deleted [$columnCheck]\n");
                        $changes = TRUE;
                    }
                }

                // ---------------------- server_id
                $columnCheck = 'server_id';
                if (!$this->hasColumn($columnCheck) && !$this->hasCustom1to1FK()) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'uuid');
                        $this->db->addForeignKey($this->fullyQualifiedName(), $columnCheck, 'acorn_servers');
                        print("Added [$columnCheck] NULLABLE with FK\n");
                        $changes = TRUE;
                    }
                }
                $triggerCheck = 'fn_acorn_server_id';
                if ($this->hasColumn($columnCheck) && !$this->hasTrigger($triggerCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has [$YELLOW$columnCheck$NC] column but no trigger [$YELLOW$triggerCheck$NC]";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$triggerCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addTrigger($this->fullyQualifiedName(), $triggerCheck, 'BEFORE', array('INSERT'));
                        print("Added [$triggerCheck]\n");
                        $changes = TRUE;
                    }
                }
                if ($this->hasColumn($columnCheck) && !$this->getColumnFK($columnCheck)) {
                    $error = "Content table [$YELLOW$this->name$NC] has no [$YELLOW$columnCheck$NC] FK";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] FK (y) ?");
                    if ($yn != 'n') {
                        $this->db->addForeignKey($this->fullyQualifiedName(), $columnCheck, 'acorn_servers');
                        print("Added [$columnCheck] FK\n");
                        $changes = TRUE;
                    }
                }
            } 
            
            // ------------------------------------ Pivot tables
            else if ($this->isPivotTable()) {
                if ($this->hasColumn('id')) {
                    throw new Exception("Pivot table [$this->name] ($this->plural/$strPlural) ($this->singular/$strSingular) has id column");
                }
                if (count($this->customForeignIdColumns()) != 2) {
                    $customForeignIdColumns = implode(', ', array_keys($this->customForeignIdColumns()));
                    throw new Exception("Pivot table [$this->name] does not have 2 custom foreign id columns [$customForeignIdColumns]");
                }
            }

            foreach ($this->columns as &$column) {
                if ($column->isForeignID() && count($column->foreignKeysFrom) == 0) 
                    throw new Exception("Custom Foreign ID column [$this->name.$column->name] has no FK");
            }

            // ------------------------------------ Any tables
            if ($this->hasColumn('parent_id')) {
                // Add check the nest_left|right|depth columns
                // These are system columns so they are not included
                // TODO: Check it is self-referencing
                $allColumns = $this->tableColumns(self::ALL_COLUMNS);
                $columnCheck = 'nest_left';
                if (!isset($allColumns[$columnCheck])) {
                    $error = "Table [$YELLOW$this->name$NC] has a [{$YELLOW}parent_id$NC] but no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'integer', NULL, FALSE, 0);
                        print("Added [$columnCheck]\n");
                        $changes = TRUE;
                    }
                }
                $columnCheck = 'nest_right';
                if (!isset($allColumns[$columnCheck])) {
                    $error = "Table [$YELLOW$this->name$NC] has a [{$YELLOW}parent_id$NC] but no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'integer', NULL, FALSE, 0);
                        print("Added [$columnCheck]\n");
                        $changes = TRUE;
                    }
                }
                $columnCheck = 'nest_depth';
                if (!isset($allColumns[$columnCheck])) {
                    $error = "Table [$YELLOW$this->name$NC] has a [{$YELLOW}parent_id$NC] but no [$YELLOW$columnCheck$NC] column";
                    print("{$RED}WARNING$NC: $error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'integer', NULL, FALSE, 0);
                        print("Added [$columnCheck]\n");
                        $changes = TRUE;
                    }
                }
            }
        }

        // --------------------------------- Update acorn_location_linked_view
        // Check all columns that foreign key to the locations table
        static $firstLocationLinkedViewEntry = TRUE;
        $locationsTable = Table::get('acorn_location_locations');
        $tablesView     = array();
        $modelName      = $this->fullyQualifiedModelName();
        $idField        = ($this->hasIdColumn() ? 'id' : 'NULL::uuid');
        foreach ($this->columns as $tableColumn) {
            $columnCheck = $tableColumn->column_name;
            if ($fk = $this->getColumnFK($columnCheck)) {
                if ($fk->tableTo == $locationsTable && $fk->columnTo->isTheIdColumn()) {
                    array_push($tablesView, <<<SQL
                        select 
                                "$columnCheck" as event_id,
                                '$this->schema'::character varying(2048) as schema, 
                                '$this->name'::character varying(2048) as table, 
                                '$columnCheck'::character varying(2048) as column, 
                                '$modelName' as model_type,
                                $idField as model_id
                        from $this->name
SQL
                    );
                }
            }
        }
        if ($tablesView) {
            $tablesViewString = implode("\nunion all\n", $tablesView);
            if (!$firstLocationLinkedViewEntry) $tablesViewString = "\nunion all\n$tablesViewString";
            file_put_contents('acorn_location_linked_view.sql', $tablesViewString, FILE_APPEND);
            $firstLocationLinkedViewEntry = FALSE;
        }

        // --------------------------------- Update acorn_location_linked_address_view
        // Check all columns that foreign key to the locations table
        static $firstLocationLinkedAddressViewEntry = TRUE;
        $addressesTable = Table::get('acorn_location_addresses');
        $tablesView     = array();
        $modelName      = $this->fullyQualifiedModelName();
        $idField        = ($this->hasIdColumn() ? 'id' : 'NULL::uuid');
        foreach ($this->columns as $tableColumn) {
            $columnCheck = $tableColumn->column_name;
            if ($fk = $this->getColumnFK($columnCheck)) {
                if ($fk->tableTo == $addressesTable && $fk->columnTo->isTheIdColumn()) {
                    array_push($tablesView, <<<SQL
                        select 
                                "$columnCheck" as event_id,
                                '$this->schema'::character varying(2048) as schema, 
                                '$this->name'::character varying(2048) as table, 
                                '$columnCheck'::character varying(2048) as column, 
                                '$modelName' as model_type,
                                $idField as model_id
                        from $this->name
SQL
                    );
                }
            }
        }
        if ($tablesView) {
            $tablesViewString = implode("\nunion all\n", $tablesView);
            if (!$firstLocationLinkedAddressViewEntry) $tablesViewString = "\nunion all\n$tablesViewString";
            file_put_contents('acorn_location_linked_address_view.sql', $tablesViewString, FILE_APPEND);
            $firstLocationLinkedAddressViewEntry = FALSE;
        }

        // --------------------------------- Update acorn_calendar_linked_events_view
        // Check all columns that foreign key to the calendar events table
        static $firstCalendarLinkedEventsViewEntry = TRUE;
        $calendarEventsTable = Table::get('acorn_calendar_events');
        $tablesView          = array();
        $modelName           = $this->fullyQualifiedModelName();
        $idField             = ($this->hasIdColumn() ? 'id' : 'NULL::uuid');
        foreach ($this->columns as $tableColumn) {
            $columnCheck = $tableColumn->column_name;
            if ($fk = $this->getColumnFK($columnCheck)) {
                if ($fk->tableTo == $calendarEventsTable && $fk->columnTo->isTheIdColumn()) {
                    array_push($tablesView, <<<SQL
                        select 
                                "$columnCheck" as event_id,
                                '$this->schema'::character varying(2048) as schema, 
                                '$this->name'::character varying(2048) as table, 
                                '$columnCheck'::character varying(2048) as column, 
                                '$modelName' as model_type,
                                $idField as model_id
                        from $this->name
SQL
                    );
                }
            }
        }
        if ($tablesView) {
            $tablesViewString = implode("\nunion all\n", $tablesView);
            if (!$firstCalendarLinkedEventsViewEntry) $tablesViewString = "\nunion all\n$tablesViewString";
            file_put_contents('acorn_calendar_linked_events_view.sql', $tablesViewString, FILE_APPEND);
            $firstCalendarLinkedEventsViewEntry = FALSE;
        }

        return $changes;
    }

    public function shouldProcess(): bool
    {
        return (!$this->system && !$this->todo);
    }

    public function loadForeignKeys(bool $addReverse = NULL)
    {
        foreach ($this->columns as &$column) {
            if ($column->shouldProcess()) $column->loadForeignKeys($addReverse);
        }
    }

    public function loadConstraints(): void
    {
        $this->contraints = $this->db->contraintsForTable($this);
        foreach ($this->columns as $columnName => &$column) {
            foreach ($this->contraints['columns'] as $constraintColumnName => $constraints) {
                if ($columnName == $constraintColumnName) {
                    foreach ($constraints as $constraint) {
                        if ($constraint instanceof UniqueConstraint)
                           $column->addUniqueConstraint($constraint);
                    }
                }
            }
        }
    }

    public function loadActionFunctions()
    {
        $this->actionFunctions = $this->db->actionFunctionsForTable($this->name);
    }

    public function loadALESFunctions()
    {
        $this->alesFunctions = $this->db->alesFunctionsForTable($this->name);
    }
    

    public function loadTriggers()
    {
        $this->triggers = $this->db->triggers($this);
    }

    public function allForeignKeysFrom(): array
    {
        $fks = array();
        foreach ($this->columns as &$column) {
            if ($column->shouldProcess()) {
                $fks = array_merge($fks, $column->foreignKeysFrom);
            }
        }
        return $fks;
    }

    public function allForeignKeysTo(): array
    {
        $fks = array();
        foreach ($this->columns as &$column) {
            if ($column->shouldProcess()) {
                $fks = array_merge($fks, $column->foreignKeysTo);
            }
        }
        return $fks;
    }

    public function allForeignKeys(): array
    {
        return array_merge($this->allForeignKeysFrom(), $this->allForeignKeysTo());
    }

    public function db(): DB
    {
        return $this->db;
    }

    public function isEmpty(): bool
    {
        return $this->db->isEmpty($this->fullyQualifiedName());
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
        $isPivotTable       = ($this->isPivotTable() ? '*' : '');
        $fullyQualifiedName = $this->fullyQualifiedName();
        return "$fullyQualifiedName$isPivotTable";
    }

    public function show(int $indent = 0)
    {
        global $YELLOW, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$YELLOW$this$NC\n");
        foreach ($this->columns as $column) {
            $column->show($indent+1);
        }
        print("\n");
    }

    // ------------------------------------------------ Table interrogation
    public function &getColumn(string $name): Column
    {
        if (!isset($this->columns[$name])) 
            throw new Exception("Column $name does not exist on table $this->name");
        return $this->columns[$name];
    }

    public function isFrameworkTable(): bool
    {
        return $this->db->isFrameworkTable($this->name);
    }

    public function isFrameworkModuleTable(): bool
    {
        return $this->db->isFrameworkModuleTable($this->name);
    }

    public function idColumn(): ?Column
    {
        return (isset($this->columns['id']) ? $this->columns['id'] : NULL);
    }

    public function hasIdColumn(): bool
    {
        return (bool) $this->idColumn();
    }

    public function hasColumn(string $name, string $type = NULL, string $default = NULL): bool
    {
        $has = FALSE;
        if (isset($this->columns[$name])) {
            $column    = $this->columns[$name];
            $firstType = explode(' ', $column->data_type)[0];
            if (is_null($type) || $column->data_type == $type || $firstType == $type) {
                $has = (is_null($default) || $column->column_default == $default);
            }
        }
        return $has;
    }

    public function hasColumnOfType(string $type): bool
    {
        return (bool) count($this->columnsOfType($type));
    }

    public function hasTrigger(string $function): bool
    {
        $has = FALSE;
        foreach ($this->triggers as $trigger) {
            if ($trigger->function == $function) {
                $has = TRUE;
                break;
            }
        }
        return $has;
    }

    public function getColumnFK(string $columnName): ForeignKey|NULL
    {
        $fk = NULL;
        if (isset($this->columns[$columnName])) {
            $column = $this->columns[$columnName];
            if (count($column->foreignKeysFrom)) $fk = end($column->foreignKeysFrom);
        }

        return $fk;
    }

    public function hasColumnDefault(string $columnName)
    {
        $default = NULL;
        if (isset($this->columns[$columnName])) {
            $default = $this->columns[$columnName]->column_default;
        }

        return $default;
    }

    public function hasCustom1to1FK(bool $orLeaf = self::OR_LEAF): bool
    {
        $has = FALSE;
        foreach ($this->columns as $column) {
            if ($column->isCustom()) {
                foreach ($column->foreignKeysFrom as $fk) {
                    if ($fk->type == '1to1' || ($orLeaf && $fk->type == 'leaf')) {
                        $has = TRUE;
                        break;
                    }
                }
            }
        }
        return $has;
    }

    public function hasCustomNameObjectFK(bool $orLeaf = self::OR_LEAF): bool
    {
        $has = FALSE;
        foreach ($this->columns as $column) {
            if ($column->isCustom()) {
                foreach ($column->foreignKeysFrom as $fk) {
                    if ($fk->nameObject == TRUE || ($orLeaf && $fk->type == 'leaf')) {
                        $has = TRUE;
                        break;
                    }
                }
            }
        }
        return $has;
    }

    public function hasPHPMethod(string $method): bool
    {
        return (bool) $this->commentValue("methods.$method");
    }

    public function hasAttributeFunction(string $method): bool
    {
        return (bool) $this->commentValue("attribute-functions.$method");
    }

    public function dateColumns(): array
    {
        return $this->columnsOfType('timestamp');
    }

    public function columnsOfType(string $type): array
    {
        $columns = array();
        foreach ($this->columns as &$column) {
            $firstType = explode(' ', $column->data_type)[0];
            if ($column->data_type == $type || $firstType == $type) {
                $columns[$column->name] = &$column;
            }
        }
        return $columns;
    }

    public function hasServer(): bool
    {
        return $this->hasColumn('server_id', 'uuid');
    }

    public function hasUUIDs(): bool
    {
        return $this->hasColumnOfType('uuid');
    }

    public function hasSoftDelete(): bool
    {
        return $this->hasColumn('deleted_at', 'timestamp');
    }

    // ------------------------------------------------ Names
    public function dbLangPath()
    {
        // Used for creating easy user language translations file and AJAX dot paths
        // array(public.acorn, lojistiks, measurement, units)
        $tableDotPathParts = explode('_', $this->fullyQualifiedName(self::INCLUDE_SCHEMA_PUBLIC));
        // public.acorn.lojistiks.measurement_units
        $tableDotPath      = $tableDotPathParts[0];
        if (isset($tableDotPathParts[1])) $tableDotPath .= '.' . $tableDotPathParts[1];
        if (isset($tableDotPathParts[2])) $tableDotPath .= '.' . implode('_', array_slice($tableDotPathParts, 2));
        // tables.public.acorn.lojistiks.measurement.units
        return "tables.$tableDotPath";
    }

    public function nameSingular(): string
    {
        // acorn_user_user_group | acorn_finance_invoice
        return ($this->singular ?: Str::singular($this->name));
    }

    public function namePlural(): string
    {
        // acorn_user_user_groups | acorn_finance_invoices
        return ($this->plural ?: Str::plural($this->name));
    }

    public function isSingular(): bool
    {
        return ($this->name == $this->nameSingular());
    }

    public function isPlural(): bool
    {
        return !$this->isSingular();
    }

    public function subNameSingular(): string|NULL
    {
        // Singular: user_group | invoice
        $subName = NULL;
        $tableNameParts  = explode('_', $this->nameSingular());
        if (count($tableNameParts) >= 3) {
            $subName = implode('_', array_slice($tableNameParts, 2));
        }
        return $subName;
    }

    public function associatedFunctionNameBase(): string
    {
        // fn_acorn_calendar
        $subName = NULL;
        $tableNameParts  = explode('_', $this->name);
        $subName = implode('_', array_slice($tableNameParts, 0, 2));
        return "fn_$subName";
    }

    public function subName()
    {
        // Plural: user_groups | invoices
        $subName = NULL;
        $tableNameParts  = explode('_', $this->name);
        if (count($tableNameParts) >= 3) {
            $subName = implode('_', array_slice($tableNameParts, 2));
        }
        return $subName;
    }

    public function fullyQualifiedName(bool $omitPublic = self::OMIT_SCHEMA_PUBLIC): string
    {
        $name = $this->name;
        if (!$omitPublic || $this->schema != 'public') $name = "$this->schema.$name";
        return $name;
    }

    public function unqualifiedForeignKeyColumnBaseName(): string
    {
        // Unqualified base name for acorn_user_user_groups is user_group
        // Foreign column user_group_id => acorn_user_user_groups.id
        // Qualified [payee_]user_group_id => acorn_user_user_groups.id
        $tableNameParts = explode('_', $this->name);
        if ($this->isModule()) {
            if ($this->isFrameworkTable()) {
                $subName = $this->name;
            } else {
                // Acorn, System, Backend
                $subName = implode('_', array_slice($tableNameParts, 1));
            }
        } else if (count($tableNameParts) == 2 && $this->packageType == 'plugin') {
            // e.g. acorn_calendars
            $subName = $tableNameParts[1];
        } else {
            // 3 parts required!
            $subName = $this->subName();
        }
        if (!$subName) throw new Exception("Could not calculate model name for table [$this->name]");

        return Str::singular($subName);
    }

    public function relationName(): string
    {
        // finance_invoices
        $relationName = strtolower($this->isModule() ? $this->moduleName() : $this->pluginName());
        if (!$relationName) 
            throw new Exception("Table [$this->name] has no plugin-name during relation name construction");
        $subName      = $this->subName();
        if ($subName) $relationName = "{$relationName}_$subName";
        return $relationName;
    }

    public function standardColumns(): array
    {
        $columns = array();
        foreach ($this->columns as &$column) {
            if ($column->isStandard()) $columns[$column->name] = &$column;
        }
        return $columns;
    }

    public function customColumns(): array
    {
        $columns = array();
        foreach ($this->columns as &$column) {
            if ($column->isCustom()) $columns[$column->name] = &$column;
        }
        return $columns;
    }

    public function customForeignIdColumns(): array
    {
        $columns = array();
        foreach ($this->columns as &$column) {
            if ($column->isCustom() && $column->isForeignID()) $columns[$column->name] = &$column;
        }
        return $columns;
    }

    public function throughColumn(Column &$otherColumn, bool $firstOnly = self::REQUIRE_ONLY_ONE): Column
    {
        $throughColumn = NULL;

        foreach ($this->customForeignIdColumns() as &$fromTableColumn) {
            if ($fromTableColumn != $otherColumn) {
                if ($throughColumn) {
                    $customForeignIdColumns = implode(', ', array_keys($this->customForeignIdColumns()));
                    throw new Exception("Pivot Table [$this->name] has too many custom foreign ID columns [$customForeignIdColumns] when ignoring [$otherColumn->name]");
                }
                $throughColumn = &$fromTableColumn;
                if ($firstOnly) break;
            }
        }

        // Checks
        if ($firstOnly  && !$this->isSemiPivotTable()) throw new Exception("First only through column requested on non-semi-pivot table [$this->name] to [$otherColumn->name]");
        if (!$firstOnly && !$this->isPivotTable())     throw new Exception("Through column requested on non-pivot table [$this->name] to [$otherColumn->name]");
        if ($throughColumn && !$throughColumn->isForeignID())          throw new Exception("Through column [$this->name.$throughColumn->name] is not a foreign ID column");
        if ($throughColumn && !count($throughColumn->foreignKeysFrom)) throw new Exception("Through column [$this->name.$throughColumn->name] has no foreign keys from");

        return $throughColumn;
    }

    // ---------------------------------------------- Ownership, authors & plugins
    public function isOurs(): bool
    {
        return ($this->authorName() == 'Acorn');
    }

    public function isKnownAcornPlugin(): bool
    {
        return (!$this->pluginName() || array_search($this->pluginName(), self::$knownAcornPlugins) !== FALSE);
    }

    public function authorName(): string
    {
        // Pascal case
        if ($this->isFrameworkTable() || $this->isFrameworkModuleTable()) {
            $authorName = 'Winter';
        } else {
            $tableNameParts = explode('_', $this->name);
            $authorName     = ucfirst($tableNameParts[0]);
            if ($authorName == 'Acorn') $authorName = 'Acorn';
        }

        return $authorName;
    }

    public function moduleName(): string|NULL
    {
        // Pascal case
        if ($this->isFrameworkTable()) {
            $moduleName = 'Winter';
        } else {
            // Acorn, System, Backend, Cms
            $tableNameParts = explode('_', $this->name);
            $moduleName      = ucfirst($tableNameParts[0]);
            if ($moduleName == 'Acorn') $moduleName = 'Acorn';
        }
        return $moduleName;
    }

    public function pluginName(): string|NULL
    {
        // Pascal case
        // e.g. University
        $tableNameParts = explode('_', $this->name);
        $firstName      = ucfirst($tableNameParts[0]);

        $plugin = NULL;
        if ($this->isFrameworkTable() || $this->isFrameworkModuleTable()) {
            // Winter framework or modules
        } else if (count($tableNameParts) >= 3 || $this->packageType == 'plugin') {
            // e.g. acorn_calendars
            $plugin = ucfirst($tableNameParts[1]);
        } else if (count($tableNameParts) == 2 && $this->isOurs()) {
            // It's our Acorn module
            // e.g. acorn_servers
        } else {
            throw new Exception("Not sure how to classify [$this->name]");
        }

        return $plugin;
    }

    public function isPlugin(): bool
    {
        return (bool) $this->pluginName();
    }

    public function isModule(): bool
    {
        return is_null($this->pluginName());
    }

    public function modelName(): string
    {
        // e.g. Exam
        $tableNameParts = explode('_', $this->name);
        if ($this->isModule()) {
            if ($this->isFrameworkTable()) {
                $subName = $this->name;
            } else {
                // Acorn, System, Backend
                $subName = implode('_', array_slice($tableNameParts, 1));
            }
        } else if (count($tableNameParts) == 2 && $this->packageType == 'plugin') {
            // e.g. acorn_calendars
            $subName = $tableNameParts[1];
        } else {
            // 3 parts required!
            $subName = $this->subName();
        }
        if (!$subName) throw new Exception("Could not calculate model name for table [$this->name]");
        $singular  = Str::singular($subName);
        $modelName = Str::studly($singular);
        // print("$subName => $singular => $modelName\n");

        return $modelName;
    }

    public function fullyQualifiedModelName(): string
    {
        $author = $this->authorName();
        $plugin = $this->pluginName();
        $model  = $this->modelName();
        return "$author\\$plugin\\Models\\$model";
    }

    public function crudControllerName(): string
    {
        $tableNameParts = explode('_', $this->name);
        if ($this->isModule()) {
            $subName = implode('_', array_slice($tableNameParts, 1));
        } else if (count($tableNameParts) == 2 && $this->packageType == 'plugin') {
            // e.g. acorn_calendars
            $subName = $tableNameParts[1];
        } else {
            $subName = $this->subName();
        }
        if (!$subName) throw new Exception("Could not calculate controller name for table [$this->name]");
        return Str::studly($subName);
    }

    // ------------------------------------------- Table types
    public function type(): string
    {
        return ($this->isContentTable()   ? 'content'
             : ($this->isCentralTable()   ? 'central'
             : ($this->isReportTable()    ? 'report'
             : ($this->isSemiPivotTable() ? 'semi-pivot'
             : ($this->isPivotTable()     ? 'pivot'
             : 'unknown'
        )))));
    }

    public function isContentTable(): bool
    {
        // Tables that have more than 2 custom foreign IDs cannot be considered as pivot
        // The associated Models cannot be programmatically ascertained anyway
        // and additional data-entry is required to make the data
        $schemaIs = (
               $this->db->nc->isContentTable($this)
        );
        $explicitIs  = ($this->tableType == 'content' || $this->tableType == 'central');
        $explicitNot = ($this->tableType && !$explicitIs);
        return (!$explicitNot && ($schemaIs || $explicitIs));
    }

    public function isCentralTable(): bool
    {
        $explicitIs  = ($this->tableType == 'central');
        $explicitNot = ($this->tableType && !$explicitIs);
        return (!$explicitNot && $explicitIs);
    }

    public function isSemiPivotTable(): bool
    {
        // This is a pivot table (singular), but with an ID and extra fields
        // Like a user => legalcase pivot, but with role
        // It will cause an XfromX relation,
        // but the forms will respect the additional fields
        $schemaIs = (
               $this->db->nc->isSemiPivotTable($this) // Singular
            && $this->hasColumn('id', 'uuid')
        );
        $explicitIs  = ($this->tableType == 'semi-pivot');
        $explicitNot = ($this->tableType && !$explicitIs);
        return (!$explicitNot && ($schemaIs || $explicitIs));
    }

    public function isPivotTable(): bool
    {
        // Pure pivot tables have no ID field
        // but they still have standard created_* information
        $schemaIs = (
               $this->db->nc->isPivotTable($this) // Singular
            && !$this->hasColumn('id', 'uuid')
        );
        $explicitIs  = ($this->tableType == 'pivot');
        $explicitNot = ($this->tableType && !$explicitIs);
        return (!$explicitNot && ($schemaIs || $explicitIs));
    }

    public function isReportTable(): bool
    {
        // Read-only tables like views
        $explicitIs  = ($this->tableType == 'report');
        $explicitNot = ($this->tableType && !$explicitIs);
        return (!$explicitNot && $explicitIs);
    }
}
