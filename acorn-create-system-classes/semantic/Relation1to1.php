<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class Relation1to1 extends Relation {
    public $required = TRUE;

    public function __construct(
        string $name,
        Model  $from,
        Model  $to,
        Column $column,
        ForeignKey $foreignKey = NULL,
        bool $isCount = FALSE,
        string $conditions = NULL
    ) {
        parent::__construct($name, $from, $to, $column, $foreignKey, $isCount, $conditions);

        // Only the derived relation can know its default buttons
        // TODO: 1to1 should never be a relationmanager
        if (!isset($this->rlButtons)) $this->rlButtons = FALSE;
    }
}
