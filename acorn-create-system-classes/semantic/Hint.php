<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Serializable;
use Spyc;
use Acorn\CreateSystem\Adapters\Framework;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class Hint extends PseudoField {
    public $content;
    public $contentHtml;
    public $level;

    public function __construct(Model &$model, array $definition, array $relations = array())
    {
        global $YELLOW, $GREEN, $RED, $NC;

        $definition = Framework::camelKeys($definition, FALSE);
        $name       = $definition['name'];
        if (!isset($definition['#']))           $definition['#']           = "Create first Hint for !deferrable [$name]";
        if (!isset($definition['fieldType']))   $definition['fieldType']   = 'hint';
        if (!isset($definition['span']))        $definition['span']        = 'storm';
        if (!isset($definition['bootstraps']))  $definition['bootstraps']  = array('xs' => 6, 'md' => '4');
        if (!isset($definition['level']))       $definition['level']       = 'info';

        $definition['columnExclude'] = TRUE;
        $definition['columnType']    = FALSE;

        parent::__construct($model, $definition, $relations);
    }
}
