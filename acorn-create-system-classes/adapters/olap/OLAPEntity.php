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

class OLAPEntity {
    public function addTranslateableName(DOMNode &$xElement, Table $tableTo, string $locale): void
    {
        if ($locale == 'en') {
            $xElement->setAttribute('nameColumn', 'name');
        } else {
            // Translation
            //   <NameExpression>
            //      <SQL dialect="postgres">
            //          fn_acorn_translate(
            //              acorn_exam_calculations.name,
            //              'acorn_exam_calculations',
            //              acorn_exam_calculations.id,
            //              'ar'
            //          )
            //      </SQL>
            //   </NameExpression>
            $tableTo = $tableTo->fullyQualifiedName();
            $sql     = "fn_acorn_translate($tableTo.name, '$tableTo', $tableTo.id, '$locale')";
            $xNameExpression = $xElement->appendChild($xElement->ownerDocument->createElement('NameExpression'));
            $xSQL = $xNameExpression->appendChild($xElement->ownerDocument->createElement('SQL', $sql));
            $xSQL->setAttribute('dialect', 'postgres');
        }
    }
}
