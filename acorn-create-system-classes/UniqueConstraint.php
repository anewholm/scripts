<?php namespace Acorn\CreateSystem;

use Exception;

class UniqueConstraint {
    public $columns;
    public $oid;
    public $name;
    public $comment;

    public function __construct(Table &$table, array $columns, ...$properties)
    {
        $this->table   = &$table;
        $this->columns = $columns;

        foreach ($properties as $name => $value) {
            // This will write also $this->comment
            if (property_exists($this, $name)) $this->$name = $value;
        }
        foreach (\Spyc::YAMLLoadString(preg_replace('/^\t/m', '    ', $this->comment)) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) 
                throw new Exception("Property [$nameCamel] does not exist on [$this->name]");
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }
    }

    public function isSingularColumn(): bool
    {
        return count($this->columns) == 1;
    }
}
