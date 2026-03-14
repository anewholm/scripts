<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class RelationXto1 extends Relation {
    public static $rlButtonsDefault = array('create', 'delete');

    public function __construct(
        string $name,
        Model  $from,
        Model  $to,
        Column $column,
        ForeignKey|NULL $foreignKey = NULL,
        bool $isCount = FALSE,
        string|NULL $conditions = NULL
    ) {
        parent::__construct($name, $from, $to, $column, $foreignKey, $isCount, $conditions);

        // Only RelationXto1|1fromX can be required or not
        // For example: event.id <= lecture.event_id can be nullable or not
        if (!isset($this->required) && $this->foreignKey) {
            $this->required = $this->foreignKey->columnFrom->isRequired();
        }

        // Only the derived relation can know its default buttons
        if (!isset($this->rlButtons)) $this->rlButtons = self::$rlButtonsDefault;
    }

    public function canFilterDefault(): bool
    {
        return TRUE;
    }
}
