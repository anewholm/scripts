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

class OLAPTimeDimension extends OLAPDimension {
    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        // <Dimension name="Time" type="TimeDimension" foreignKey="student_id">
        //     <Hierarchy hasAll="true" primaryKey="id">
        //         <Table name="university_mofadala_students"/>
        //         <Level name="Year" type="Numeric" uniqueMembers="true" levelType="TimeYears">
        //          <KeyExpression><SQL dialect="postgres">extract(year from university_mofadala_students.created_at)</SQL></KeyExpression>
        //         </Level>
        //         <Level name="Month" type="String" uniqueMembers="false" levelType="TimeMonths">
        //          <KeyExpression><SQL dialect="postgres">TO_CHAR(university_mofadala_students.created_at, 'Month')</SQL></KeyExpression>
        //         </Level>
        //         <Level name="Day" type="Numeric" uniqueMembers="false" levelType="TimeDays">
        //          <KeyExpression><SQL dialect="postgres">extract(day from university_mofadala_students.created_at)</SQL></KeyExpression>
        //         </Level>
        //         <Level name="Hour" type="Numeric" uniqueMembers="false" levelType="TimeHours">
        //          <KeyExpression><SQL dialect="postgres">extract(hour from university_mofadala_students.created_at)</SQL></KeyExpression>
        //         </Level>
        //     </Hierarchy>
        // </Dimension>
        $xDimension = parent::node($xDoc, $locale);
        $xDimension->setAttribute('type', 'TimeDimension');
        $columnFQN  = $this->column->fullyQualifiedName(Column::INCLUDE_SCHEMA, Column::NOT_SCHEMA_PUBLIC);

        $xHierarchy = $xDimension->appendChild($xDoc->createElement('Hierarchy'));
        $xHierarchy->setAttribute('hasAll', 'true');
        $xHierarchy->setAttribute('primaryKey', 'id');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Year');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'true');
        $xLevel->setAttribute('levelType', 'TimeYears');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(year from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Month');
        $xLevel->setAttribute('type', 'String');
        $xLevel->setAttribute('uniqueMembers', 'false');
        $xLevel->setAttribute('levelType', 'TimeMonths');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "TO_CHAR($columnFQN, 'Month')"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Day');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'false');
        $xLevel->setAttribute('levelType', 'TimeDays');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(day from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Hour');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'true');
        $xLevel->setAttribute('levelType', 'TimeHours');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(hour from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        return $xDimension;
    }
}
