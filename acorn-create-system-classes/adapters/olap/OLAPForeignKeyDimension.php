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

class OLAPForeignKeyDimension extends OLAPDimension {
    protected $fk;

    public function __construct(string $name, ForeignKey $fk)
    {
        parent::__construct($name, $fk->columnFrom);

        $this->fk = $fk;
    }

    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        switch ($this->fk->type()) {
            case 'Xto1':
                // Fact table: something_id => public.something_table.id
                // <Dimension name="Religion" foreignKey="religion_id">
                //     <Hierarchy hasAll="true" primaryKey="id" primaryKeyTable="acorn_user_religions">
                //         <Table name="acorn_user_religions"/>
                //         <Level name="Religion" column="id" uniqueMembers="true">
                //             <NameExpression>
                //                 <SQL dialect="postgres">
                //                     fn_acorn_translate(
                //                         acorn_exam_calculations.name,
                //                         'acorn_exam_calculations',
                //                         acorn_exam_calculations.id,
                //                         'ar'
                //                     )
                //                 </SQL>
                //             </NameExpression>
                //         </Level>
                //     </Hierarchy>
                // </Dimension>
                $xDimension = parent::node($xDoc, $locale);
                $xDimension->setAttribute('foreignKey', $this->fk->columnFrom->column_name);

                $xHierarchy = $xDimension->appendChild($xDoc->createElement('Hierarchy'));
                $xHierarchy->setAttribute('hasAll', 'true');
                $xHierarchy->setAttribute('primaryKey', 'id');
                // Schema not necessary apparently...
                $xHierarchy->setAttribute('primaryKeyTable', $this->fk->tableTo->name);

                /* TODO: Remove this old complex join
                $xJoin = $xHierarchy->appendChild($xDoc->createElement('Join'));
                $xJoin->setAttribute('leftKey',  $this->fk->columnFrom->column_name);
                $xJoin->setAttribute('rightKey', 'id');
                $xTable = $xJoin->appendChild($xDoc->createElement('Table'));
                $xTable->setAttribute('name',  $this->fk->tableFrom->name);
                if ($this->fk->tableFrom->schema && $this->fk->tableFrom->schema != 'public')
                    $xTable->setAttribute('schema',  $this->fk->tableFrom->schema);
                $xTable = $xJoin->appendChild($xDoc->createElement('Table'));
                $xTable->setAttribute('name',  $this->fk->tableTo->name);
                if ($this->fk->tableTo->schema && $this->fk->tableTo->schema != 'public')
                    $xTable->setAttribute('schema',  $this->fk->tableTo->schema);
                */
                // New single direct foreign table statement
                $xTable = $xHierarchy->appendChild($xDoc->createElement('Table'));
                $xTable->setAttribute('name',  $this->fk->tableTo->name);
                if ($this->fk->tableTo->schema && $this->fk->tableTo->schema != 'public')
                    $xTable->setAttribute('schema',  $this->fk->tableTo->schema);

                if (isset($this->column->labels[$locale])) {
                    $title = $this->column->labels[$locale];
                } else {
                    $title = $this->name;
                }
                $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
                $xLevel->setAttribute('name', $title);
                $xLevel->setAttribute('column', 'id');
                $xLevel->setAttribute('uniqueMembers', 'true');

                $this->addTranslateableName($xLevel, $this->fk->tableTo, $locale);

                break;
        }

        return $xDimension;
    }
}
