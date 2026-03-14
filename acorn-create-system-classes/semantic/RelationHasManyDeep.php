<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class RelationHasManyDeep extends Relation {
    // Type is important because we can immediately identify
    // fully 1to1 deep relations for embedding
    // 1to1 means all steps are 1to1
    // because $relation above will only be 1to1 traversal
    // other (XfromX, etc.) indicates the LAST step only
    public $type;
    public $repeatingModels;
    // Important that the keys are
    // the correct names of the array entires on the target Model
    public $throughRelations;
    public $containsLeaf;
    public $nameObject;
    public $fieldExclude; // canDisplayAsField()
    public $containsNon1to1s;

    public function __construct(
        string $name,
        Model  $from,          // Entity
        Model  $to,            // User
        Column $column,
        ForeignKey|NULL $lastForeignKey, // WinterModels will not have an FK associated
        array $throughRelations, // name => relation
        bool  $containsLeaf,
        bool  $nameObject,
        string $type, // Last relation type
        string|NULL $conditions = NULL,
        // Fake means that chain contains non-1to1 steps
        // thus the last relation type does not really indicate the true type
        // For example, a last relation of 1to1 in a chain that has Xto1 is not really a 1to1
        // the same goes for parent & isSelfReferencing concepts
        bool $containsNon1to1s = FALSE
    ) {
        $firstRelation = current($throughRelations);
        $lastRelation  = end($throughRelations);
        $isCount       = $lastRelation->isCount;

        // Relation chain properties
        // Check for Model repetition
        // which can cause duplicated tables in the from clause
        // TODO: At the moment, we do not know how to alias the tables in same model joins
        $fieldExclude       = FALSE;
        $columnExclude      = FALSE;
        $repeatingModels    = FALSE;
        $hasManyDeepInclude = FALSE;
        $throughModels      = array();
        foreach ($throughRelations as &$throughRelation) {
            if ($throughRelation->fieldExclude       === TRUE) $fieldExclude  = TRUE;
            if ($throughRelation->columnExclude      === TRUE) $columnExclude = TRUE;
            if ($throughRelation->hasManyDeepInclude === TRUE) $hasManyDeepInclude = TRUE;

            // Repeating models
            $modeToName = $throughRelation->to->name;
            if (isset($throughModels[$modeToName])) $repeatingModels = TRUE;
            $throughModels[$modeToName] = TRUE;
        }

        // Last relation requirements
        $validRelation = (
            $lastRelation instanceof Relation1fromX ||
            $lastRelation instanceof RelationXfromX || // Includes RelationXfromXSemi
            $lastRelation instanceof RelationXto1      // user_user_languages apparently... User::$hasMany
        );
        if (!$validRelation) $fieldExclude  = TRUE;
        if (!$validRelation) $columnExclude = TRUE;

        // isCount will be processed by the parent
        parent::__construct($name, $from, $to, $column, $lastForeignKey, $isCount, $conditions);

        $this->type               = $type;
        $this->throughRelations   = $throughRelations;
        $this->containsLeaf       = $containsLeaf;
        $this->nameObject         = $nameObject;
        $this->repeatingModels    = $repeatingModels;
        $this->containsNon1to1s   = $containsNon1to1s;
        $this->hasManyDeepInclude = $hasManyDeepInclude;
        // 1toX, XtoX, XtoXSemi
        if (!isset($this->fieldExclude))  $this->fieldExclude     = $fieldExclude;
        if (!isset($this->columnExclude)) $this->columnExclude    = $columnExclude;
        $this->rlButtons        = $lastRelation->rlButtons;

        if ($this->containsNon1to1s) {
            if (!is_array($this->flags)) $this->flags = array();
            $this->flags['containsNon1to1s'] = TRUE;
        }

        $this->eagerLoad = FALSE;

        // Adopt stuff
        $this->fieldsSettings = $firstRelation->fieldsSettings;

        if ($firstRelation->hasManyDeepSettings && isset($firstRelation->hasManyDeepSettings[$this->name])) {
            // Settings adopt
            // If there are explicit settings it can cause containsNon1to1s fields / columns to render
            // The first relation in the chain takes precedence over later has-many-deep-settings
            $this->hasManyDeepSettings = $firstRelation->hasManyDeepSettings[$this->name];

            foreach ($this->hasManyDeepSettings as $name => $value) {
                $nameCamel = Str::camel($name);
                if (!property_exists($this, $nameCamel))
                    throw new Exception("Property [$nameCamel] does not exist on [$this]");
                $this->$nameCamel = $value;
            }
        }
    }

    protected function checkQualifier($fieldName, $otherModel, $baseName): string|NULL
    {
        // Column names are not related to the deep final model
        return NULL;
    }

    public function lastRelation(): Relation
    {
        return end($this->throughRelations);
    }

    public function isSelfReferencing(): bool
    {
        return (!$this->containsNon1to1s && parent::isSelfReferencing());
    }

    public function __toString()
    {
        // Including (count) label
        $parentString = parent::__toString();

        // Last Relation
        $lastRelation   = $this->lastRelation();
        $lastClassParts = explode('\\', get_class());
        $lastClass      = end($lastClassParts);

        // Steps
        $to1String    = '{';
        foreach ($this->throughRelations as $name => $relation) {
            $to1String .= "=[$name";
            if ($relation->columnExclude)   $to1String .= ' Cx';
            if ($relation->fieldExclude)    $to1String .= ' Fx';
            if ($relation == $lastRelation) $to1String .= " $lastClass";
            $to1String .= "]> ";
        }
        $to1String   .= '}';

        return "$to1String$parentString";
    }

    public function type(): string
    {
        return $this->type;
    }
}
