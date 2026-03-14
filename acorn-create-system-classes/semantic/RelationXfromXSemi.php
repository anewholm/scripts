<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class RelationXfromXSemi extends RelationFrom {
    public $pivot;
    public $pivotModel;
    public $keyColumn;
    public static $rlButtonsDefault = array('create', 'delete', 'link', 'unlink');

    public function __construct(
        string $name,
        Model  $from,          // Legalcase
        Model  $to,            // User
        Model  $pivotModel,    // LegalcaseProsecutor
        Column $keyColumn,     // pivot.user_group_id
        Column $throughColumn, // pivot.user_id
        ForeignKey|NULL $foreignKey = NULL,
        string $conditions = NULL
    ) {
        parent::__construct($name, $from, $to, $throughColumn, $foreignKey, FALSE, $conditions);

        $table            = $pivotModel->getTable();
        $this->pivotModel = &$pivotModel;
        $this->pivot      = &$table;
        $this->keyColumn  = &$keyColumn;

        // Only the derived relation can know its default buttons
        if (!isset($this->rlButtons)) $this->rlButtons = self::$rlButtonsDefault;
    }

    public function __toString()
    {
        return parent::__toString() . " through semi [$this->pivot]";
    }

    public function canFilterDefault(): bool
    {
        return TRUE;
    }
}
