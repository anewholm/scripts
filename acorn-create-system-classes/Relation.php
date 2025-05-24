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
    public $hidden;
    public $invisible;
    public $fieldExclude;
    public $columnExclude;
    public $status; // ok|exclude|broken
    public $multi;  // _multi.php config
    public $type;   // explicit typing
    public $delete; // Relation delete: true will cause reverse cascade deletion of associated object
    public $isFrom      = TRUE; // From this column, attached to it
    public $nameObject;
    public $readOnly;
    public $cssClasses;
    public $placeholder = 'backend::lang.form.select';
    public $newRow;
    public $bootstraps;
    public $tabLocation; // primary|secondary|tertiary

    // Filter config_filter.yaml
    public $canFilter;
    public $globalScope; // Chaining from|to
    public $conditions;  // config_relation.yaml conditions

    // Translation arrays
    public $labels;
    public $labelsPlural;

    public function __construct(
        string $name, 
        Model $from, 
        Model $to, 
        Column $column, 
        ForeignKey $foreignKey = NULL
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

        // Inherit FK comment values
        $this->comment = $this->foreignKey?->comment;
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) $this->$nameCamel = $value;
        }
        if (!isset($this->nameObject)) $this->nameObject = $this->foreignKey?->nameObject;
        if (!isset($this->canFilter))  $this->canFilter  = TRUE;
        if (!isset($this->readOnly))   $this->readOnly   = $this->to->readOnly;
    }

    public function __toString()
    {
        $qualifier = $this->qualifier();
        $qualifierString = ($qualifier ? " ($qualifier)" : '');
        return "$this->foreignKey$qualifierString";
    }

    public function cssClass(array|string $defaultCssClasses = NULL, bool $useRelationManager = TRUE): string
    {
        $cssClassesReturn = NULL;

        if ($this->cssClasses) {
            $cssClassesReturn = (is_array($this->cssClasses) ? $this->cssClasses : array($this->cssClasses));
        } else if (is_array($defaultCssClasses)) {
            $cssClassesReturn = $defaultCssClasses;
        } else {
            $cssClassesReturn = array('single-tab');
            if (is_string($defaultCssClasses)) array_push($cssClassesReturn, $defaultCssClasses);
        }
        if (!$useRelationManager) array_push($cssClassesReturn, 'selected-only');

        return implode(' ', $cssClassesReturn);
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
}

class RelationLeaf extends Relation1to1 {
}

class Relation1fromX extends RelationFrom {
    public $isFrom    = FALSE;
}

class Relation1from1 extends RelationFrom {
    public $isFrom = FALSE;
}

class RelationXto1 extends Relation {
    public function __construct(
        string $name, 
        Model  $from, 
        Model  $to, 
        Column $column, 
        ForeignKey $foreignKey = NULL
    ) {
        parent::__construct($name, $from, $to, $column, $foreignKey);

        // Do either of our Models indicate that the field canFilter?
        $relations = array($this);
        $fieldDefinitions = array();
        $from->standardTargetModelFieldDefinitions($column, $relations, $fieldDefinitions); // &$fieldDefinitions pass-by-reference
        $to->standardTargetModelFieldDefinitions(  $column, $relations, $fieldDefinitions); // &$fieldDefinitions pass-by-reference
        $this->canFilter = (isset($fieldDefinitions['canFilter']) ? $fieldDefinitions['canFilter'] : TRUE);
    }
}

class RelationXfromXSemi extends RelationFrom {
    public $pivot;
    public $pivotModel;
    public $keyColumn;
    public $canFilter = TRUE;

    public function __construct(
        string $name, 
        Model  $from,          // Legalcase
        Model  $to,            // User
        Model  $pivotModel,    // LegalcaseProsecutor
        Column $keyColumn,     // pivot.user_group_id
        Column $throughColumn, // pivot.user_id
        ForeignKey|NULL $foreignKey = NULL
    ) {
        parent::__construct($name, $from, $to, $throughColumn, $foreignKey);

        $table            = $pivotModel->getTable();
        $this->pivotModel = &$pivotModel;
        $this->pivot      = &$table;
        $this->keyColumn  = &$keyColumn;
    }

    public function __toString()
    {
        return parent::__toString() . " through semi [$this->pivot]";
    }
}

class RelationXfromX extends RelationFrom {
    public $pivot;
    public $keyColumn;
    public $canFilter = TRUE;

    public function __construct(
        string $name, 
        Model  $from,          // Legalcase
        Model  $to,            // User
        Table  $pivot,         // acorn_criminal_user_group_category
        Column $keyColumn,     // pivot.user_group_id
        Column $throughColumn, // pivot.user_id
        ForeignKey|NULL $foreignKey = NULL
    ) {
        parent::__construct($name, $from, $to, $throughColumn, $foreignKey);

        $this->pivot     = &$pivot;
        $this->keyColumn = &$keyColumn;
    }

    public function __toString()
    {
        return parent::__toString() . " through [$this->pivot]";
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

    public function __construct(
        string $name, 
        Model  $from,          // Entity
        Model  $to,            // User
        Column $column,
        ForeignKey $lastForeignKey,
        array $throughRelations, // name => relation
        bool  $containsLeaf,
        bool  $nameObject,
        string $type // Last relation type
    ) {
        parent::__construct($name, $from, $to, $column, $lastForeignKey);

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
        $to1String    = '';
        $parentString = parent::__toString();
        foreach ($this->throughRelations as $name => $relation) $to1String .= "=[$name]> ";
        return "$to1String$parentString";
    }

    public function type(): string
    {
        return $this->type;
    }
}
