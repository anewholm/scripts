<?php namespace Acorn\CreateSystem;

use Exception;

class ForeignKey {
    protected $column;
    public $oid;
    public $name;

    // Display ONLY
    // These semantically indicate the *usage* of this Foreign Key
    // To this column, not attached to it
    // allowing the FK to display itself appropriately
    public $to   = FALSE;
    public $from = TRUE;

    // From our DB custom FK query
    public $table_from_schema;
    public $table_from_name;
    public $table_from_column;

    public $table_to_schema;
    public $table_to_name;
    public $table_to_column;

    // Objects
    public $tableFrom;
    public $columnFrom;
    public $tableTo;
    public $columnTo;

    static public $implied1to1 = array();

    // Comment
    public $comment;
    public $fieldComment;
    public $hidden;
    public $invisible;
    public $fieldExclude;
    public $columnExclude;
    public $hasManyDeepSettings; // HasManyDeep control
    public $fieldsSettings; // Adjust embedded 3rd party fields.yaml
    public $fieldsSettingsTo; // Adjust 3rd party embedded columns.yaml
    public $order;  // Appearance in tab pools. See DB::foreignKeys() SQL request
    public $type;
    public $multi;  // _multi.php config
    public $delete; // Relation delete: true will cause reverse cascade deletion of associated object
    public $system; // Internal constraint only. Do not process
    public $todo;   // TODO: This column structure has not been analysed / enabled yet
    public $status; // ok|exclude|broken
    public $include;
    public $advanced;
    public $prefix;
    public $suffix;
    public $nameObject;
    public $readOnly;
    public $cssClasses;
    public $newRow;
    public $bootstraps;
    public $tab;
    public $tabLocation; // primary|secondary|tertiary
    public $span;
    public $conditions;  // config_relation.yaml conditions

    // Translation arrays
    public $labels;
    public $labelsPlural;

    public $globalScope; // Chaining from|to
    public $noRelationManager;
    public $filterConditions;
    public $hasManyDeepInclude; // Process this non 1-1 has many deep link
    public $showFilter; // In relationmanager, default: TRUE
    public $showSearch; // In relationmanager, default: TRUE
    public $canFilter;
    public $dependsOn;  // Array of field names
    public $flags; // e.g. hierarchy flag for global scope
    public $filterSearchNameSelect; // Special select useful for 1to1 filter term search
    public $rlButtons; // On the relationmanager

    public static function fromRow(Column &$column, bool $to, array $row)
    {
        return new self($column, $to, ...$row);
    }

    protected function __construct(Column &$column, bool $to, ...$properties)
    {
        $this->column = &$column;
        $this->to     = $to;
        $this->from   = !$to;

        foreach ($properties as $name => $value) {
            // This will write also $this->comment
            if (property_exists($this, $name)) $this->$name = $value;
        }
        foreach (\Spyc::YAMLLoadString(preg_replace('/^\t/m', '    ', $this->comment)) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) {
                $valueString = var_export($value, TRUE);
                throw new Exception("Property [$nameCamel] does not exist on [$this->table_from_name.$column->name] => [$this->name] with value [$valueString]");
            }
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }

        // Objects
        $this->tableFrom  = Table::get($this->table_from_name, $this->table_from_schema);
        $this->columnFrom = &$this->tableFrom->columns[$this->table_from_column];
        $this->tableTo    = Table::get($this->table_to_name, $this->table_to_schema);
        $this->columnTo   = &$this->tableTo->columns[$this->table_to_column];

        if ($this->shouldProcess()) {
            // Standard fields also appear on Pivot tables
            // which can confuse the FK type understandings
            // e.g. created_at_event_id, created_by_user_id
            // so we can auto-hint from the column settings here
            if ($this->columnFrom->autoFKType) $this->type = $this->columnFrom->autoFKType;
            if ($this->columnTo->autoFKType)   $this->type = $this->columnTo->autoFKType;

            // Checks
            $this->check();
        }

        if (!isset($this->nameObject)) {
            if ($this->isLeaf()) $this->nameObject = TRUE;
            else $this->nameObject = FALSE;
        }
    }

    protected function check(): bool
    {
        $changes   = FALSE;
        $tableName = $this->column->table->name;
        $columnFQN = "$tableName.$this->column";
        if ($this->columnFrom->name == 'id')
            throw new Exception("FK type [$this->type] on column objects [$columnFQN] is from the ID column");
        if ($this->columnTo->name != 'id')
            throw new Exception("FK type [$this->type] on column objects [$columnFQN] is not to an ID column");
        if ($this->to   && $this->column->name != $this->table_to_column)
            throw new Exception("FK type [$this->type] on column objects [$columnFQN] is different to column to data [$this->table_to_name.$this->table_to_column]");
        if ($this->from && $this->column->name != $this->table_from_column)
            throw new Exception("FK type [$this->type] on column objects [$columnFQN] is different to column from data [$this->table_from_name.$this->table_from_column]");
        if ($this->isUnknownType()) {
            $direction = $this->directionName();
            $details   = array(
                $this->isSelfReferencing(),
                $this->tableFrom->isContentTable(),
                $this->tableFrom->isReportTable(),
                $this->columnFrom->isForeignID(),
                $this->tableTo->isContentTable(),
                $this->columnTo->isTheIdColumn()
            );
            $detailsString = implode('|', $details);
            throw new Exception("Foreign Key [$this->name] on [$this->tableFrom] $direction [$columnFQN] has no type with [$detailsString]");
        }

        return $changes;
    }

    protected function db(): DB
    {
        return $this->column->db();
    }

    public function dbLangPath(): string
    {
        $tableLangPath = $this->tableFrom->dbLangPath();
        return "$tableLangPath.foreignkeys.$this->name";
    }

    // ----------------------------------------- Display
    public function __toString(): string
    {
        return $this->fullyQualifiedName();
    }

    public function directionName(): string
    {
        return ($this->to ? 'to' : 'from');
    }

    public function show(int $indent = 0, bool $full = FALSE, string $colour = NULL)
    {
        global $GREEN, $NC;
        if (is_null($colour)) $colour = $GREEN;

        $indentString = str_repeat(' ', $indent * 2);
        $toString = $this->fullyQualifiedName($full);
        print("$indentString$colour$toString$NC\n");
    }

    public function fullyQualifiedName(bool $full = FALSE): string
    {
        $tableFromName  = $this->tableFrom->name;
        $columnFromName = $this->columnFrom->name;
        $tableToName    = $this->tableTo->name;
        $columnToName   = $this->columnTo->name;

        $from = "$tableFromName($columnFromName)";
        $to   = "$tableToName($columnToName)";
        $type = $this->type();

        if ($full)          $fullyQualifiedName = "$from =[$type]> $to";
        else if ($this->to) $fullyQualifiedName = "<[$type]= $from";
        else                $fullyQualifiedName = "=[$type]> $to";

        return $fullyQualifiedName;
    }

    public function fromRelationName(bool $plural = Column::SINGULAR): string
    {
        // This (Column) is the *_id foreign column, e.g. entity.user_group_id
        // This Relation*from* will be attached to a local id column
        // but the DB-FK is on the foreign table *_id column
        // e.g. Relation1fromX attached to user_group.id <= DB-FK on entity.my_user_group_id
        //
        // For the relation name:
        // We cannot use the local   Field name id that the Relation*from* is attached to
        // we cannot use the foreign Field name *_id because it could repeat on this Model, e.g. *.user_group_id
        // There could also be 2 FKs from the same foreign table pointing to the local id
        // so we cannot just use the foreign table name
        // so we use foreign <this table name>_<this column name> for uniqueness
        // e.g. user_groups_user_group
        //
        // TODO: This should be static Relation::fromNameFromColumn(Column $column)
        if ($this->columnFrom->isTheIdColumn()) 
            throw new Exception("From relation name not possible for ID columns");
        $tableRelationName = $this->columnFrom->table->relationName(); // user_groups
        $relationName      = $this->columnFrom->relationName($plural); // user_group[s]

        if ($this->isSelfReferencing() && $plural) $relationName = 'children';

        return "{$tableRelationName}__$relationName";
    }

    // ----------------------------------------- Sematic information
    // Foreign Keys are single directional, from (attached column) => to
    // Always from = the column they are attached to, usually (always) to an ID PK column on a foreign table
    // and to, the column they point to, usually (always) an ID column
    // Self-referencing of course will be on the same table, but still an Xto1 pointing to an ID column
    public function is1to1(): bool
    {
        // Foreign ID => ID
        // 1to1 can be ascertained programmatically: 
        //   1toX WITH a UNIQUE CONSTRAINT on the ForeignIDField
        // for example: entities.user_group_id
        $schemaIs   = (
            $this->columnFrom->isSingularUnique()
        );
        if ($schemaIs) self::$implied1to1[$this->name] = $this;
        $explicitIs = ($this->type == '1to1');
        return ($explicitIs || $schemaIs || $this->isLeaf());
    }

    public function isXto1(): bool
    {
        // Foreign ID => ID
        $isExplicitNot = ($this->type && $this->type != 'Xto1');
        $explicitIs    = ($this->type == 'Xto1');
        $schemaIs      = (
              ($this->tableFrom->isContentTable() || $this->tableFrom->isReportTable())
            && $this->columnFrom->isForeignID()
            && $this->tableTo->isContentTable()  // True still if central
            && !$this->tableTo->isCentralTable()
            && $this->columnTo->isTheIdColumn()
            && !$this->columnFrom->isSingularUnique() // 1to1s do this
        );
        return (!$isExplicitNot && ($schemaIs || $explicitIs));
    }

    public function isSelfReferencing()
    {
        // ID (parent) Field => ID
        // A form of Xto1
        // on a parent_<basename>_id column
        // pointing to the ID column
        return ($this->tableFrom == $this->tableTo
            && $this->columnTo->isTheIdColumn()
            && $this->columnFrom->hasParentInName()
        );
    }

    public function isLeaf(): bool
    {
        // Leaf means that the parent table gets no controller
        // and access to its forms will be re-directed to the leaf table forms
        // which include the central tables fields
        // Location  => Office
        // LegalCase => Criminal LegalCase
        $schemaIs      = (
             $this->tableTo->isCentralTable()
        );
        $isExplicitNot = ($this->type && $this->type != 'leaf');
        $explicitIs    = ($this->type == 'leaf');
        return (!$isExplicitNot && ($explicitIs || $schemaIs));
    }

    public function isXtoX(): bool
    {
        // Remember: the from is the column the FK is attached to
        // So it must be a pivot table
        // NOTE: standardColumnsForeignKeyType() will auto-set the type on pivot tables to Xto1
        $isExplicitNot = ($this->type && $this->type != 'XtoX');
        $explicitIs    = ($this->type == 'XtoX');
        $schemaIs      = (
               $this->tableFrom->isPivotTable()
            && $this->columnFrom->isForeignID()
            && $this->tableTo->isContentTable()
            && $this->columnTo->isTheIdColumn()
        );
        return (!$isExplicitNot && ($schemaIs || $explicitIs));
    }

    public function isXtoXSemi(): bool
    {
        // Remember: the from is the column the FK is attached to
        // So it must be a semi-pivot table
        // NOTE: standardColumnsForeignKeyType() will auto-set the type on pivot tables to Xto1
        $isExplicitNot = ($this->type && $this->type != 'XtoXSemi');
        $explicitIs    = ($this->type == 'XtoXSemi');
        $schemaIs      = (
               $this->tableFrom->isSemiPivotTable() // It has an ID column
            && $this->columnFrom->isForeignID()
            && $this->tableTo->isContentTable()
            && $this->columnTo->isTheIdColumn()
        );
        return (!$isExplicitNot && ($schemaIs || $explicitIs));
    }

    public function shouldProcess(): bool
    {
        return ($this->tableFrom->shouldProcess() 
            &&  $this->columnFrom->shouldProcess()
            &&  $this->tableTo->shouldProcess()
            &&  $this->columnTo->shouldProcess()
            && !$this->system && !$this->todo
        );
    }

    public function type(): string
    {
        return
            ($this->isLeaf() ? 'leaf' :
            ($this->is1to1() ? '1to1' :
            ($this->isXtoXSemi() ? 'XtoXSemi' :
            ($this->isXtoX() ? 'XtoX' :
            ($this->isXto1() ? 'Xto1' :
            'unknown'
        )))));
    }

    public function isUnknownType(): bool
    {
        return ($this->type() == 'unknown');
    }
}
