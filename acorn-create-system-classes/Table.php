<?php namespace Acorn\CreateSystem;

require_once('Str.php');
require_once('Column.php');

class Table {
    public const FIRST_ONLY = TRUE;
    public const REQUIRE_ONLY_ONE = FALSE;

    // TODO: These should be in the WinterCMS framework abstraction
    protected static $knownAcornPlugins = array('User', 'Location', 'Messaging', 'Calendar');
    protected static $knownWinterPlugins = array('System', 'Backend');

    protected static $tables = array();

    protected $db;

    public $schema;
    public $name;
    protected $order;

    public $comment;
    public $packageType; // plugin|module
    public $pluginIcon;
    public $system; // Internal do not process
    public $todo;   // TODO: This structure has not been analysed / enabled yet

    public $icon;
    public $tableType; // TODO: create a Derived class instead?
    public $plural;
    public $singular;
    public $menu;
    public $menuSplitter;
    public $menuIndent;
    public $seeding;
    // Translation arrays
    public $pluginNames;
    public $pluginDescriptions;
    public $labels;
    public $labelsPlural;
    // PHP model methods
    public $attributeFunctions = array();
    public $methods            = array();
    public $staticMethods      = array();

    public $columns;
    public $actionFunctions;
    public $printable;

    public $filters = array();

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
        if (!isset(self::$tables[$qualifiedName])) throw new \Exception("Table [$qualifiedName] not in static list");
        return self::$tables[$qualifiedName];
    }

    static protected function blockingAlert(string $message, string $level = 'WARNING'): void
    {
        global $YELLOW, $NC;

        print("$YELLOW$level$NC: $message. Continue (y)? ");
        $yn = readline();
        if (strtolower($yn) == 'n') exit(0);
    }

    protected function __construct(DB &$db, ...$properties)
    {
        $this->db = &$db;
        foreach ($properties as $name => $value) {
            if (property_exists($this, $name)) $this->$name = $value;
        }
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) self::blockingAlert("Property [$nameCamel] does not exist on [$this->name]");
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }

        $this->columns = $db->tableColumns($this);

        if ($this->shouldProcess()) $this->check();

        $qualifiedName = "$this->schema.$this->name";
        self::$tables[$qualifiedName] = $this;
    }

    public function check(): bool
    {
        // Checks
        // We omit some of our own known plugins
        // because they do not conform yet to our naming requirements
        if ($this->isOurs() && !$this->isKnownAcornPlugin()) {
            $strPlural   = Str::plural($this->name);
            $strSingular = Str::singular($this->name);
            if ($this->isContentTable()) {
                if (!$this->hasColumn('id', 'uuid', 'gen_random_uuid()')) {
                    throw new \Exception("Content table [$this->name] has no id(uuid/gen_random_uuid()) column");
                }

                /*
                $columnCheck = 'name';
                if (!$this->hasColumn($columnCheck)) {
                    $error = "Content table [$this->name] has no [$columnCheck] column";
                    print("$error\n");
                    $gen = readline("Create a generated [$columnCheck] with clause [<clause>|n] (id) ?");
                    if ($gen != 'n') {
                        if (!$gen) $gen = 'id';
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'character varying(1024)', $gen);
                        print("Added [$columnCheck] with clause [$gen]\n");
                    }
                }

                $columnCheck = 'created_at_event_id';
                if (!$this->hasColumn($columnCheck)) {
                    $error = "Content table [$this->name] has no [$columnCheck] column";
                    print("$error\n");
                    $yn = readline("Create [$columnCheck] (y) ?");
                    if ($yn != 'n') {
                        $this->db->addColumn($this->fullyQualifiedName(), $columnCheck, 'uuid');
                        // TODO: $this->db->addForeignKey($this->fullyQualifiedName(), $columnCheck, 'character varying(1024)');
                        print("Added [$columnCheck]\n");
                    }
                }

                // TODO: auto-add other standard columns and FKs
                */
            } else if ($this->isPivotTable()) {
                if ($this->hasColumn('id')) {
                    throw new \Exception("Pivot table [$this->name] ($this->plural/$strPlural) ($this->singular/$strSingular) has id column");
                }
                if (count($this->customForeignIdColumns()) != 2) {
                    $customForeignIdColumns = implode(', ', array_keys($this->customForeignIdColumns()));
                    throw new \Exception("Pivot table [$this->name] does not have 2 custom foreign id columns [$customForeignIdColumns]");
                }
            }
        }
        return TRUE;
    }

    public function shouldProcess(): bool
    {
        return (!$this->system && !$this->todo);
    }

    public function loadForeignKeys()
    {
        foreach ($this->columns as &$column) {
            if ($column->shouldProcess()) $column->loadForeignKeys();
        }
    }

    public function loadActionFunctions()
    {
        $this->actionFunctions = $this->db->actionFunctionsForTable($this->name);
    }

    public function db()
    {
        return $this->db;
    }

    public function isEmpty(): bool
    {
        return $this->db->isEmpty($this->name);
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

    // ----------------------------------------- Table basic details
    public function dbLangPath()
    {
        $tableDotPathParts = explode('_', $this->fullyQualifiedName(FALSE));
        $tableDotPath      = "$tableDotPathParts[0].$tableDotPathParts[1]." . implode('_', array_slice($tableDotPathParts, 2));
        return "tables.$tableDotPath";
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

    protected function nameSingular(): string
    {
        // acorn_user_user_group | acorn_finance_invoice
        return ($this->singular ?: Str::singular($this->name));
    }

    protected function namePlural(): string
    {
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

    protected function subNameSingular(): string|NULL
    {
        // Plural: user_groups | invoices
        $subName = NULL;
        $tableNameParts  = explode('_', $this->nameSingular());
        if (count($tableNameParts) >= 3) {
            $subName = implode('_', array_slice($tableNameParts, 2));
        }
        return $subName;
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

    public function fullyQualifiedName(bool $omitPublic = TRUE): string
    {
        $name = $this->name;
        if (!$omitPublic || $this->schema != 'public') $name = "$this->schema.$name";
        return $name;
    }

    // ----------------------------------------- Table semantic information
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
            // e.g. acorn_calendar
            $subName = $tableNameParts[1];
        } else {
            // 3 parts required!
            $subName = $this->subName();
        }
        if (!$subName) throw new \Exception("Could not calculate model name for table [$this->name]");

        return Str::singular($subName);
    }

    public function relationName(): string
    {
        // finance_invoices
        $relationName = strtolower($this->isModule() ? $this->moduleName() : $this->pluginName());
        if (!$relationName) throw new \Exception("Table [$this->name] has no plugin-name during relation name construction");
        $subName      = $this->subName();
        if ($subName) $relationName = "${relationName}_$subName";
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
                    throw new \Exception("Pivot Table [$this->name] has too many custom foreign ID columns [$customForeignIdColumns] when ignoring [$otherColumn->name]");
                }
                $throughColumn = &$fromTableColumn;
                if ($firstOnly) break;
            }
        }

        // Checks
        if ($firstOnly  && !$this->isSemiPivotTable()) throw new \Exception("First only through column requested on non-semi-pivot table [$this->name] to [$otherColumn->name]");
        if (!$firstOnly && !$this->isPivotTable())     throw new \Exception("Through column requested on non-pivot table [$this->name] to [$otherColumn->name]");
        if ($throughColumn && !$throughColumn->isForeignID())          throw new \Exception("Through column [$this->name.$throughColumn->name] is not a foreign ID column");
        if ($throughColumn && !count($throughColumn->foreignKeysFrom)) throw new \Exception("Through column [$this->name.$throughColumn->name] has no foreign keys from");

        return $throughColumn;
    }

    // ---------------------------------------------- Ownership, authors & plugins
    public function isOurs(): bool
    {
        return ($this->authorName() == 'Acorn');
    }

    public function isKnownAcornPlugin(): bool
    {
        return (array_search($this->pluginName(), self::$knownAcornPlugins) !== FALSE);
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
        $tableNameParts = explode('_', $this->name);
        $firstName      = ucfirst($tableNameParts[0]);

        $plugin = NULL;
        if ($this->isFrameworkTable() || $this->isFrameworkModuleTable()) {
            // Winter framework or modules
        } else if (count($tableNameParts) >= 3 || $this->packageType == 'plugin') {
            // e.g. acorn_calendar
            $plugin = ucfirst($tableNameParts[1]);
        } else if (count($tableNameParts) == 2 && $this->isOurs()) {
            // It's our Acorn module
            // e.g. acorn_servers
        } else {
            throw new \Exception("Not sure how to classify [$this->name]");
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
        $tableNameParts = explode('_', $this->name);
        if ($this->isModule()) {
            if ($this->isFrameworkTable()) {
                $subName = $this->name;
            } else {
                // Acorn, System, Backend
                $subName = implode('_', array_slice($tableNameParts, 1));
            }
        } else if (count($tableNameParts) == 2 && $this->packageType == 'plugin') {
            // e.g. acorn_calendar
            $subName = $tableNameParts[1];
        } else {
            // 3 parts required!
            $subName = $this->subName();
        }
        if (!$subName) throw new \Exception("Could not calculate model name for table [$this->name]");
        $modelName = Str::studly(Str::singular($subName));

        return $modelName;
    }

    public function crudControllerName(): string
    {
        $tableNameParts = explode('_', $this->name);
        if ($this->isModule()) {
            $subName = implode('_', array_slice($tableNameParts, 1));
        } else if (count($tableNameParts) == 2 && $this->packageType == 'plugin') {
            // e.g. acorn_calendar
            $subName = $tableNameParts[1];
        } else {
            $subName = $this->subName();
        }
        if (!$subName) throw new \Exception("Could not calculate controller name for table [$this->name]");
        return Str::studly($subName);
    }

    // ------------------------------------------- Table types
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
