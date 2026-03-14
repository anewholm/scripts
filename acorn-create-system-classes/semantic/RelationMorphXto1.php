<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class RelationMorphXto1 extends Relation {
    // Specifically included because of the UserGroup::morphMany['translations']
}
