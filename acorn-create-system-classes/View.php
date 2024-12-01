<?php namespace Acorn\CreateSystem;

class View extends Table {
    public $tableType = 'report'; // Read-only

    public static function fromRow(DB &$db, array $row)
    {
        return new View($db, ...$row);
    }

    public function check(): bool
    {
        // Checks
        return TRUE;
    }

    public function loadForeignKeys() {}
    public function loadActionFunctions() {}
}
