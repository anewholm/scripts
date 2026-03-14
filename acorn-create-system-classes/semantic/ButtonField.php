<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Serializable;
use Spyc;
use Acorn\CreateSystem\Adapters\Framework;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

/*
class ButtonField extends PseudoField {
    // These do not have a column on this table
    // They are extra fields from external from relations
    // and QR code field

    public function __construct(Model &$model, array $definition, array $relations = array())
    {
        parent::__construct($model, $definition, $relations);
    }

    public function isStandard(): bool
    {
        return FALSE;
    }
}
*/
