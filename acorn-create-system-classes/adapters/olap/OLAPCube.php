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

class OLAPCube {
    public $olapView;
    protected $dimensions;
    protected $measures;
    protected $defaultMeasure;

    public function __construct(View $olapView, array $dimensions, array $measures) {
        $this->olapView   = $olapView;
        $this->dimensions = $dimensions;
        $this->measures   = $measures;

        $this->defaultMeasure = 'Count';
    }

    public function title(string $locale = 'en'): string|NULL
    {
        // [olap.]acorn_enrollment_olapcube => Enrollment
        // [olap.]acorn_enrollment_olapcube_things => Enrollment Things
        if (isset($this->olapView->labels[$locale])) {
            $title = $this->olapView->labels[$locale];
        } else {
            $viewNameParts  = explode('_', $this->olapView->name);
            $viewNameParts  = array_filter($viewNameParts, function($value){return $value != 'olapcube';});
            $viewTitleParts = array_slice($viewNameParts, 1);
            $title          = Str::title(implode(' ', $viewTitleParts));
            if ($locale != 'en') $title .= " ($locale)";
        }
        return $title;
    }

    public function description(string $locale = 'en'): string|NULL
    {
        // form-comment:
        //   en: ...
        return (isset($this->olapView->formComment[$locale]) ? $this->olapView->formComment[$locale] : NULL);
    }

    public function document(string $locale = 'en'): DOMDocument
    {
        $xDoc = new DOMDocument();

        // Cube
        $cubeNode = $xDoc->appendChild($xDoc->createElement('Cube'));
        $cubeNode->setAttribute('name', $this->title($locale));
        $cubeNode->setAttribute('description', $this->description($locale));
        $cubeNode->setAttribute('locale', $locale);
        $cubeNode->setAttribute('for-view', $this->olapView->name);
        if ($this->defaultMeasure) $cubeNode->setAttribute('defaultMeasure', $this->defaultMeasure);

        // ----------------------------- Set Primary table
        // <Table name="university_mofadala_marks" schema="whatever">
        //     <AggName name="agg_c_count_fact">
        //         <AggFactCount column="id"/>
        //         <AggLevel name="[Time].[Year]" column="id" />
        //     </AggName>
        // </Table>
        $xTable   = $cubeNode->appendChild($xDoc->createElement('Table'));
        $xTable->setAttribute('name', $this->olapView->name);
        if ($this->olapView->schema && $this->olapView->schema != 'public')
            $xTable->setAttribute('schema', $this->olapView->schema);
        $xAggName = $xTable->appendChild($xDoc->createElement('AggName'));
        $xAggName->setAttribute('name', 'agg_c_count_fact');
        $xAggFactCount = $xAggName->appendChild($xDoc->createElement('AggFactCount'));
        $xAggFactCount->setAttribute('column', 'id');

        // ----------------------------- Add dimensions & Measures
        foreach ($this->dimensions as $dimension) {
            $cubeNode->appendChild($dimension->node($xDoc, $locale));
        }
        foreach ($this->measures as $measure) {
            $cubeNode->appendChild($measure->node($xDoc, $locale));
        }

        return $xDoc;
    }
}
