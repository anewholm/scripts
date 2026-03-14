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

class OLAPSimpleIncludedDimension extends OLAPDimension {
    public function __construct(string $name, Column $column)
    {
        parent::__construct($name, $column);
    }

    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        // <Dimension name="Material">
        //   <Hierarchy hasAll="true" primaryKey="id">
        //     <Level name="Material" column="material_id" nameColumn="material_name" uniqueMembers="false"/>
        //   </Hierarchy>
        // </Dimension>
        $columnStub = $this->column->nameWithoutId();
        $columnName = "{$columnStub}_name";

        if (isset($this->column->labels[$locale])) {
            $title = $this->column->labels[$locale];
        } else {
            $title = $this->name;
        }
        $xDimension = parent::node($xDoc, $locale);
        $xHierarchy = $xDimension->appendChild($xDoc->createElement('Hierarchy'));
        $xHierarchy->setAttribute('hasAll', 'true');
        $xHierarchy->setAttribute('primaryKey', 'id');
        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', $title);
        $xLevel->setAttribute('column', $this->column->column_name);
        $xLevel->setAttribute('nameColumn', $columnName);
        $xLevel->setAttribute('uniqueMembers', 'true');

        return $xDimension;
    }
}
