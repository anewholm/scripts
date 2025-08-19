<?php namespace Acorn\CreateSystem;

use Exception;

require_once('Str.php');

class Schema {
    protected static $schemas = array();

    protected $db;

    public $name;
    protected $owner;

    public $comment;
    public $parsedComment; // array
    public $noRelationManagerDefault;
    public $canFilterDefault;

    // ----------------------------------------- Construction
    public static function fromRow(DB &$db, array $row)
    {
        return new Schema($db, ...$row);
    }

    public static function &get(string $name): Schema
    {
        // Allow search with or without schema, with or without dot notation
        // Note that the Lojistiks system uses 2 schemas: public and product
        if (!isset(self::$schemas[$name])) 
            throw new Exception("Schema [$name] not in static list");
        return self::$schemas[$name];
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
            if (!property_exists($this, $nameCamel)) 
                self::blockingAlert("Property [$nameCamel] does not exist on [$this->name]");
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }

        self::$schemas[$name] = $this;
    }

    static protected function blockingAlert(string $message, string $level = 'WARNING'): void
    {
        global $YELLOW, $NC;

        print("$YELLOW$level$NC: $message. Continue (y)? ");
        $yn = readline();
        if (strtolower($yn) == 'n') exit(0);
    }

    public function db(): DB
    {
        return $this->db;
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
        return $this->name;
    }

    public function show(int $indent = 0)
    {
        global $YELLOW, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$YELLOW$this$NC\n");
        print("\n");
    }
}
