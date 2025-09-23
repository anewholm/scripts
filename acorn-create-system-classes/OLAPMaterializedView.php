<?php namespace Acorn\CreateSystem;

class OLAPMaterializedView extends MaterializedView {
    public static function fromRow(DB &$db, array $row)
    {
        return new OLAPMaterializedView($db, ...$row);
    }
}
