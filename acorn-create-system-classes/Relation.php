<?php namespace Acorn\CreateSystem;

use Exception;

class Relation {
    public $name;
    public $oid;
    public $from; // Model
    public $to;   // Model
    public $column;
    public $foreignKey;

    public $comment;
    public $fieldComment;
    public $commentHtml;
    public $hidden;
    public $invisible;
    public $fieldExclude;
    public $columnExclude;
    public $hasManyDeepSettings; // HasManyDeep control
    public $status; // ok|exclude|broken
    public $multi;  // _multi.php config
    public $type;   // explicit typing
    public $delete; // Relation delete: true will cause reverse cascade deletion of associated object
    public $isFrom      = TRUE; // From this column, attached to it
    public $nameObject;
    public $readOnly;
    public $required;
    public $cssClasses;
    public $placeholder = 'backend::lang.form.select';
    public $newRow;
    public $bootstraps;
    public $tab;
    public $advanced;
    public $showFilter; // In relationmanager, default: TRUE
    public $showSearch; // In relationmanager, default: TRUE
    public $tabLocation; // primary|secondary|tertiary
    public $span;
    public $rlButtons;

    // Filter config_filter.yaml
    public $canFilter;
    public $globalScope; // Chaining from|to
    public $hasManyDeepInclude; // Process this non 1-1 has many deep link
    public $conditions;  // config_relation.yaml conditions
    public $filterConditions;
    public $isCount;
    public $order;
    public $dependsOn;  // Array of field names
    public $flags; // e.g. hierarchy flag for global scope
    public $noRelationManager;
    public $nameFrom;
    public $explicitLabelKey;
    public $filterSearchNameSelect; // Special select useful for 1to1 filter term search

    // Translation arrays
    public $labels;
    public $labelsPlural;

    public function __construct(
        string $name, 
        Model $from, 
        Model $to, 
        Column $column, 
        ForeignKey $foreignKey = NULL,
        bool $isCount = FALSE,
        string $conditions = NULL
    ) {
        // Relations are DIRECTIONAL, unlike FKs
        // That is, from Relations, like Relation1from1, is attached to its FK to ID column,
        // when the actually FK is attached to the FK from column, as always.
        //
        // Relation?to?   (NORMAL relations)  will use the column->foreignKeysFrom collection
        //   because those are the FKs attached to this column
        // Relation?from? (REVERSE relations) will use the column->foreignKeysTo collection
        //   they are attached to other tables and reference this table ID column
        $this->name       = $name;
        $this->oid        = $foreignKey?->oid;
        $this->from       = &$from;
        $this->to         = &$to;
        $this->column     = &$column;
        $this->foreignKey = &$foreignKey;
        $this->isCount    = $isCount;
        $this->conditions = $conditions;

        // Inherit FK comment values
        $this->comment = $this->foreignKey?->comment;
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) $this->$nameCamel = $value;
        }
        if (!isset($this->nameObject)) $this->nameObject = $this->foreignKey?->nameObject;
        if (!isset($this->readOnly))   $this->readOnly   = $this->to->readOnly;
        if (!isset($this->span))       $this->span       = 'storm';
        if (!isset($this->advanced))   $this->advanced   = $this->foreignKey?->advanced;
        if (!isset($this->columnExclude)) {
            // Causes slow-down for large user sets in column views, and usless
            // leave to the fields view
            if ($this->to->isAcornUser() && !$this->isCount) $this->columnExclude = TRUE;
        }
        // Only RelationXto1|1fromX, shown as dropdowns, can be required or not
        // For example: event.id <= lecture.event_id can be nullable or not
        // RelationXto1|1fromX::__construct() will set required based on Column::isRequired()
        if (!isset($this->required)) $this->required = FALSE;
        if (!isset($this->fieldExclude) && $this->isCount) $this->fieldExclude = TRUE;
    }

    public function canFilterDefault(): bool
    {
        return TRUE;
    }

    public function __toString()
    {
        $qualifier = $this->qualifier();
        $qualifierString = ($qualifier ? " ($qualifier)" : '');
        if ($this->isCount) $qualifierString .= '(count)';
        return "$this->foreignKey$qualifierString";
    }

    public function cssClass(bool $useRelationManager = TRUE, bool $singleTab = TRUE, array $extraClasses = array()): string
    {
        return implode(' ', $this->cssClasses($useRelationManager, $singleTab, $extraClasses));
    }

    public function cssClasses(bool $useRelationManager = TRUE, bool $singleTab = TRUE, array $extraClasses = array()): array
    {
        // Adopt explicit extraClasses
        $cssClassesReturn = $extraClasses;

        // Merge in any $this->cssClasses setting
        if ($this->cssClasses) {
            $cssClasses       = (is_array($this->cssClasses) ? $this->cssClasses : array($this->cssClasses));
            $cssClassesReturn = array_merge($cssClassesReturn, $cssClasses);
        }

        if ($singleTab) {
            array_push($cssClassesReturn, 'single-tab');
            if ($this->span == 'storm') array_push($cssClassesReturn, 'col-xs-12');
        }
        // Relation managers should always not have a label
        // because the toolbar demonstrates which Model it operates on
        array_push($cssClassesReturn, 'nolabel');

        // single-tab-1fromX
        $type = $this->type();
        array_push($cssClassesReturn, "single-tab-$type");

        // selected-only will cause checkbox lists to only display checked rows
        if (!$useRelationManager) array_push($cssClassesReturn, 'selected-only');

        return array_unique($cssClassesReturn);
    }

    public function direction(): string
    {
        return ($this->isFrom ? '=>' : '<=');
    }

    public function type(): string
    {
        $classParts = explode('\\', get_class($this));
        return preg_replace('/Relation/', '', end($classParts));
    }

    public function is1to1(): bool
    {
        // This will include HasManyDeep(1to1), Leaf and 1to1
        return ($this instanceof Relation1to1 || $this->type() == '1to1');
    }

    public function isNameObject(): bool
    {
        return (bool) $this->nameObject;
    }

    public function isSelfReferencing(): bool
    {
        return ($this->foreignKey ? $this->foreignKey->isSelfReferencing() : FALSE);
    }

    public function canDisplayAsFilter(): bool
    {
        return (bool) $this->canFilter;
    }

    public function show(int $indent = 0)
    {
        global $YELLOW, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$YELLOW$this$NC\n");
    }

    public function qualifier(): string
    {
        // Foreign ID Fields can be qualified if they have a custom prefix before the to table name
        // [payee_]user_group_id => user_group (acorn_user_user_groups)
        // This changes the translation domain construction
        // Without ID
        // payee_user_group
        $fieldName = $this->column->nameWithoutId();
        // From table name
        // acorn_user_user_groups => user_group | invoice
        $otherModel = ($this->isFrom ? $this->to : $this->from);
        $baseName   = $otherModel->getTable()->unqualifiedForeignKeyColumnBaseName();

        if ($error = $this->checkQualifier($fieldName, $otherModel, $baseName))
            throw new Exception($error);

        // payee
        return trim(str_replace($baseName, '', $fieldName), '_');
    }

    protected function checkQualifier($fieldName, $otherModel, $baseName): string|NULL
    {
        // Foreign ID Fields can be qualified if they have a custom prefix before the to table name
        // [payee_]user_group_id => user_group (acorn_user_user_groups)
        // This changes the translation domain construction
        // Without ID
        // payee_user_group
        $error = NULL;
        
        // We omit some of our own known plugins
        // because they do not conform yet to our naming requirements
        // TODO: If pointing to a Module, like AA...
        if (strstr($fieldName, $baseName) === FALSE
            && $otherModel->isOurs()
            && !$otherModel->isKnownAcornPlugin()
            && !$this->isSelfReferencing() // parent_id is allowed
        ) {
            $thisModel = ($this->isFrom ? $this->from : $this->to);
            $tableName = $thisModel->getTable()->name;
            $error     = "Foreign table base name [$baseName] not found in foreign column field name [$fieldName] on [$tableName]";
        }
        
        return $error;
    }
}

class RelationFrom extends Relation {
}

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

class RelationLeaf extends Relation1to1 {
}

class Relation1fromX extends RelationFrom {
    public $isFrom    = FALSE;
    public static $rlButtonsDefault = array('create', 'delete');

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

        // Only RelationXto1|1fromX can be required or not
        // For example: event.id <= lecture.event_id can be nullable or not
        if (!isset($this->required) && $this->foreignKey) {
            $this->required = $this->foreignKey->columnFrom->isRequired();
        }

        // Only the derived relation can know its default buttons
        if (!isset($this->rlButtons)) $this->rlButtons = self::$rlButtonsDefault;
    }
}

class Relation1from1 extends RelationFrom {
    public $isFrom   = FALSE;
    public $required = TRUE;
}

class RelationXto1 extends Relation {
    public static $rlButtonsDefault = array('create', 'delete');

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

        // Do either of our Models indicate that the field canFilter?
        $relations = array($this);
        $fieldDefinitions = array();
        $from->standardTargetModelFieldDefinitions($column, $relations, $fieldDefinitions); // &$fieldDefinitions pass-by-reference
        $to->standardTargetModelFieldDefinitions(  $column, $relations, $fieldDefinitions); // &$fieldDefinitions pass-by-reference

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

class RelationXfromX extends RelationFrom {
    public $pivot;
    public $keyColumn;

    public static $rlButtonsDefault = array('create', 'delete', 'link', 'unlink');

    public function __construct(
        string $name, 
        Model  $from,          // Legalcase
        Model  $to,            // User
        Table  $pivot,         // acorn_criminal_user_group_category
        Column $keyColumn,     // pivot.user_group_id
        Column $throughColumn, // pivot.user_id
        ForeignKey|NULL $foreignKey = NULL,
        bool $isCount = FALSE,
        string $conditions = NULL
    ) {
        parent::__construct($name, $from, $to, $throughColumn, $foreignKey, $isCount, $conditions);

        $this->pivot     = &$pivot;
        $this->keyColumn = &$keyColumn;

        // Only the derived relation can know its default buttons
        if (!isset($this->rlButtons)) $this->rlButtons = self::$rlButtonsDefault;
    }

    public function __toString()
    {
        return parent::__toString() . " through [$this->pivot]";
    }

    public function canFilterDefault(): bool
    {
        return TRUE;
    }
}

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
        string $conditions = NULL
    ) {
        $firstRelation = current($throughRelations);
        $lastRelation  = end($throughRelations);
        $isCount       = $lastRelation->isCount;
        $fieldExclude  = FALSE;
        $columnExclude = FALSE;
        
        // Any relation in the chain can exclude
        foreach ($throughRelations as &$relation) {
            if ($relation->fieldExclude  === TRUE) $fieldExclude  = TRUE;
            if ($relation->columnExclude === TRUE) $columnExclude = TRUE;
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
        
        // Check for Model repetition
        // which can cause duplicated tables in the from clause
        // TODO: At the moment, we do not know how to alias the tables in same model joins
        $repeatingModels = FALSE;
        /*
        $throughModels   = array();
        foreach ($throughRelations as $throughRelation) {
            $modeToName = $throughRelation->to->name;
            if (isset($throughModels[$modeToName])) $repeatingModels = TRUE;
            $throughModels[$modeToName] = TRUE;
        }
        */

        $this->type             = $type;
        $this->throughRelations = $throughRelations;
        $this->containsLeaf     = $containsLeaf;
        $this->nameObject       = $nameObject;
        $this->repeatingModels  = $repeatingModels;
        // 1toX, XtoX, XtoXSemi
        if (!isset($this->fieldExclude))  $this->fieldExclude     = $fieldExclude;
        if (!isset($this->columnExclude)) $this->columnExclude    = $columnExclude;
        $this->rlButtons        = $lastRelation->rlButtons;

        if ($firstRelation->hasManyDeepSettings) {
            if (isset($firstRelation->hasManyDeepSettings[$this->name])) {
                $settings = $firstRelation->hasManyDeepSettings[$this->name];
                foreach ($settings as $name => $value) {
                    $nameCamel = Str::camel($name);
                    if (!property_exists($this, $nameCamel)) 
                        throw new Exception("Property [$nameCamel] does not exist on [$this]");
                    $this->$nameCamel = $value;
                }
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
