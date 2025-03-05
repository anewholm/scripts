<?php namespace Acorn\CreateSystem;

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

    // Comment
    public $comment;
    public $order;  // Appearance in tab pools
    public $type;
    public $multi;  // _multi.php config
    public $delete; // Relation delete: true will cause reverse cascade deletion of associated object
    public $system; // Internal constraint only. Do not process
    public $todo;   // TODO: This column structure has not been analysed / enabled yet
    public $status; // ok|exclude|broken
    public $include;
    public $nameObject;
    public $readOnly;
    public $cssClasses;
    public $newRow;
    public $bootstraps;
    public $tabLocation; // primary|secondary|tertiary
    // Translation arrays
    public $labels;
    public $labelsPlural;

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
            if (property_exists($this, $name)) $this->$name = $value;
        }
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) 
                throw new \Exception("Property [$nameCamel] does not exist on [$this->table_from_name.$column->name.$this->name]");
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
    }

    protected function check()
    {
        $tableName = $this->column->table->name;
        $columnFQN = "$tableName.$this->column";
        if ($this->columnFrom->name == 'id')
            throw new \Exception("FK type [$this->type] on column objects [$columnFQN] is from the ID column");
        if ($this->columnTo->name != 'id')
            throw new \Exception("FK type [$this->type] on column objects [$columnFQN] is not to an ID column");
        if ($this->to   && $this->column->name != $this->table_to_column)
            throw new \Exception("FK type [$this->type] on column objects [$columnFQN] is different to column to data [$this->table_to_name.$this->table_to_column]");
        if ($this->from && $this->column->name != $this->table_from_column)
            throw new \Exception("FK type [$this->type] on column objects [$columnFQN] is different to column from data [$this->table_from_name.$this->table_from_column]");
        if ($this->isUnknownType()) {
            $direction = $this->directionName();
            $details   = array(
                $this->isSelfReferencing(),
                $this->tableFrom->isContentTable(),
                $this->columnFrom->isForeignID(),
                $this->tableTo->isContentTable(),
                $this->columnTo->isTheIdColumn()
            );
            $detailsString = implode('|', $details);
            throw new \Exception("Foreign Key [$this->name] on [$this->tableFrom] $direction [$columnFQN] has no type with [$detailsString]");
        }
    }

    protected function db()
    {
        return $this->column->db();
    }

    public function dbLangPath()
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

    // ----------------------------------------- Sematic information
    // Foreign Keys are single directional, from (attached column) => to
    // Always from = the column they are attached to, usually (always) to an ID PK column on a foreign table
    // and to, the column they point to, usually (always) an ID column
    // Self-referencing of course will be on the same table, but still an Xto1 pointing to an ID column
    public function is1to1(): bool
    {
        // Foreign ID => ID
        // 1to1 cannot be ascertained programmatically
        // because the schema is identical to 1toX
        $explicitIs = ($this->type == '1to1');
        return ($explicitIs || $this->isLeaf());
    }

    public function isXto1(): bool
    {
        // Foreign ID => ID
        $isExplicitNot = ($this->type && $this->type != 'Xto1');
        $explicitIs    = ($this->type == 'Xto1');
        $schemaIs      = (
              !$this->isSelfReferencing()
            && $this->tableFrom->isContentTable()
            && $this->columnFrom->isForeignID()
            && $this->tableTo->isContentTable()  // True still if central
            && !$this->tableTo->isCentralTable()
            && $this->columnTo->isTheIdColumn()
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
              !$this->isSelfReferencing()
            && $this->tableFrom->isPivotTable()
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
              !$this->isSelfReferencing()
            && $this->tableFrom->isSemiPivotTable() // It has an ID column
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
            ($this->isSelfReferencing() ? 'self' :
            ($this->isLeaf() ? 'leaf' :
            ($this->is1to1() ? '1to1' :
            ($this->isXtoXSemi() ? 'XtoXSemi' :
            ($this->isXtoX() ? 'XtoX' :
            ($this->isXto1() ? 'Xto1' :
            'unknown'
        ))))));
    }

    public function isUnknownType(): bool
    {
        return ($this->type() == 'unknown');
    }
}
