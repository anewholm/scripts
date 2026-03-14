<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Serializable;
use Spyc;
use Acorn\CreateSystem\Adapters\Framework;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class IdField extends Field {
    public $translationKey;

    public function __construct(Model &$model, array $definition, Column &$column, array &$relations)
    {
        parent::__construct($model, $definition, $column, $relations);

        /* TODO: Multiple 1toX => tabs
         * if ($this->relation1 instanceof RelationXto1) {
            $buttons      = array('create' => new ButtonField($model, ...));
            $dependsOn
        }
        */
    }
}
