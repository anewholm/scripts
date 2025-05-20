<?php namespace Acorn\CreateSystem;

class View extends Table {
    public $tableType = 'report'; // Read-only

    public static function fromRow(DB &$db, array $row)
    {
        return new View($db, ...$row);
    }

    public function check(): bool
    {
        // Checks: Views do not have any structural standards currently
        // IDs are nice for update screens, but not necessary currently
        $changes = FALSE;
        return $changes;
    }
}

