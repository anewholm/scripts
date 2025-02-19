<?php namespace AcornAssociated\CreateSystem;

class View extends Table {
    public $tableType = 'report'; // Read-only

    public static function fromRow(DB &$db, array $row)
    {
        return new View($db, ...$row);
    }

    public function check(): bool
    {
        // Checks
        $changes = FALSE;
        return $changes;
    }

    public function loadForeignKeys() {}
    public function loadActionFunctions() {}
}
