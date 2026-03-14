<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Serializable;
use Spyc;
use Acorn\CreateSystem\Adapters\Framework;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class PseudoField extends Field {
    // These do not have a column on this table
    // They are extra fields from external from relations
    // and QR code field
    public $isStandard = FALSE;
    public $translationKey;
    public $recordsPerPage;

    public function __construct(Model &$model, array $definition, array $relations = array())
    {
        parent::__construct($model, $definition, Field::NO_COLUMN, $relations);
    }

    public function isStandard(): bool
    {
        return $this->isStandard;
    }

    public function dbObject()
    {
        return NULL;
    }

    public function translationKey(string $name = NULL, bool $forceGeneral = FALSE): string
    {
        // parent::translationKey() will return a local domain key
        // which will use explicit labels if there are any
        $realname = preg_replace('/^_/', '', $this->name);
        return ($this->translationKey && !$this->labels ? $this->translationKey : parent::translationKey($realname, $forceGeneral));
    }
}
