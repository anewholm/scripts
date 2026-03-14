<?php namespace Acorn\CreateSystem\Adapters\Olap;

use DOMDocument;
use DOMNode;
use Exception;
use DateTime;
use Spyc;
use Acorn\CreateSystem\Database\DB;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\View;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class OLAPMeasure {
    public $name;
    public $column;

    public function __construct(string $name, Column $column)
    {
        $this->name   = $name;
        $this->column = $column;
    }

    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        // <Measure name="Num Students" column="student_id" aggregator="distinct-count" formatString="Standard"/>
        if (isset($this->column->labels[$locale])) {
            $title = $this->column->labels[$locale];
        } else {
            $title = $this->name;
        }
        $xMeasure = $xDoc->createElement('Measure');
        $xMeasure->setAttribute('name', $title);
        $xMeasure->setAttribute('column', $this->column->column_name);
        $xMeasure->setAttribute('aggregator', 'distinct-count');
        $xMeasure->setAttribute('formatString', 'Standard');

        return $xMeasure;
    }
}
