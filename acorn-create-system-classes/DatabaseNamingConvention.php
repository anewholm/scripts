<?php namespace Acorn\CreateSystem;

class DatabaseNamingConvention {
    // TODO: All schema structure definitions be placed here
    // That is, that isSemiPivotTable() should also require an ID column
    // currently the schema definitions are in class Table is*()

    public function isContentTable(Table &$table): bool
    {
        return $table->isPlural();
    }

    public function isPivotTable(Table &$table): bool
    {
        return $table->isSingular();
    }

    public function isSemiPivotTable(Table &$table): bool
    {
        // A pivot table with an ID field and other content columns
        return $this->isPivotTable($table);
    }
}

class AcornNamingConvention extends DatabaseNamingConvention
{
}
