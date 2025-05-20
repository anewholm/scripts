<?php namespace Acorn\CreateSystem;

class MaterializedView extends View {
    public static function fromRow(DB &$db, array $row)
    {
        return new MaterializedView($db, ...$row);
    }
}
