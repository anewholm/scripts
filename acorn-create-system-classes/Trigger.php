<?php namespace Acorn\CreateSystem;

class Trigger {
    protected $table;

    public $name;
    public $action_timing;
    public $event_manipulation;
    public $event_object_schema;
    public $event_object_table;
    public $action_statement;
    public $function;
    
    // Comment
    public $comment;

    public static function fromRow(Table &$table, array $row): Trigger   
    {
        return new self($table, ...$row);
    }

    protected function __construct(Table &$table, ...$properties)
    {
        $this->table = &$table;

        foreach ($properties as $name => $value) {
            if (property_exists($this, $name)) $this->$name = $value;
        }
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) 
                throw new \Exception("Property [$nameCamel] does not exist on [$this->name]");
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }
    }

    protected function db(): DB
    {
        return $this->table->db();
    }

    public function dbLangPath(): string
    {
        $tableLangPath = $this->table->dbLangPath();
        return "$tableLangPath.triggers.$this->name";
    }

    // ----------------------------------------- Display
    public function __toString(): string
    {
        return $this->fullyQualifiedName();
    }

    public function show(int $indent = 0, bool $full = FALSE, string $colour = NULL)
    {
        global $GREEN, $NC;
        if (is_null($colour)) $colour = $GREEN;

        $indentString = str_repeat(' ', $indent * 2);
        $toString = $this->fullyQualifiedName($full);
        print("$indentString$colour$toString$NC\n");
    }

    public function fullyQualifiedName(): string
    {
        return $this->name;
    }
}
