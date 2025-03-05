<?php namespace Acorn\CreateSystem;

class Relation {
    public $oid;
    public $from; // Model
    public $to;   // Model
    public $column;
    public $foreignKey;

    public $comment;
    public $status; // ok|exclude|broken
    public $multi;  // _multi.php config
    public $type;   // explicit typing
    public $delete; // Relation delete: true will cause reverse cascade deletion of associated object
    public $isFrom      = TRUE; // From this column, attached to it
    public $nameObject  = FALSE;
    public $readOnly;
    public $cssClasses;
    public $placeholder = 'backend::lang.form.select';
    public $newRow;
    public $bootstraps;
    public $tabLocation; // primary|secondary|tertiary

    // Filter config_filter.yaml
    public $canFilter = FALSE;

    // Translation arrays
    public $labels;
    public $labelsPlural;

    public function __construct(Model &$from, Model &$to, Column $column, ForeignKey $foreignKey)
    {
        // Relations are DIRECTIONAL, unlike FKs
        // That is, from Relations, like Relation1from1, is attached to its FK to ID column,
        // when the actually FK is attached to the FK from column, as always.
        //
        // Relation?to?   (NORMAL relations)  will use the column->foreignKeysFrom collection
        //   because those are the FKs attached to this column
        // Relation?from? (REVERSE relations) will use the column->foreignKeysTo collection
        //   they are attached to other tables and reference this table ID column
        $this->oid        = $foreignKey->oid;
        $this->from       = &$from;
        $this->to         = &$to;
        $this->column     = &$column;
        $this->foreignKey = &$foreignKey;

        // Inherit FK comment values
        $this->comment = $this->foreignKey->comment;
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) $this->$nameCamel = $value;
        }
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

    public function direction()
    {
        return ($this->isFrom ? '=>' : '<=');
    }

    public function type(): string
    {
        $classParts = explode('\\', get_class($this));
        return preg_replace('/Relation/', '', end($classParts));
    }

    public function show(int $indent = 0)
    {
        global $YELLOW, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$YELLOW$this$NC\n");
    }

    public function qualifier(): string
    {
        // Foreign ID Fields are qualified if they have a custom prefix before the to table name
        // [payee_]user_group_id => user_group (acorn_user_user_groups)
        // This changes the translation domain construction
        // Without ID
        // payee_user_group
        $fieldName = $this->column->nameWithoutId();
        // From table name
        // acorn_user_user_groups => user_group | invoice
        $otherModel = ($this->isFrom ? $this->to : $this->from);
        $baseName   = $otherModel->table->unqualifiedForeignKeyColumnBaseName();

        // We omit some of our own known plugins
        // because they do not conform yet to our naming requirements
        // TODO: If pointing to a Module, like AA...
        if (strstr($fieldName, $baseName) === FALSE
            && $otherModel->isOurs()
            && !$otherModel->isKnownAcornPlugin()
        ) {
            $thisModel = ($this->isFrom ? $this->from : $this->to);
            $tableName = $thisModel->table->name;
            throw new \Exception("Foreign table base name [$baseName] not found in foreign column field name [$fieldName] on [$tableName]");
        }

        // payee
        return trim(str_replace($baseName, '', $fieldName), '_');
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

class RelationSelf extends Relation1fromX {
    public function __construct(Model &$from, Column &$column, ForeignKey &$foreignKey)
    {
        parent::__construct($from, $from, $column, $foreignKey);
    }

    public function direction()
    {
        return 'O';
    }
}

class Relation1from1 extends RelationFrom {
    public $isFrom = FALSE;
}

class RelationXto1 extends Relation {
    public function __construct(Model &$from, Model &$to, Column &$column, ForeignKey &$foreignKey)
    {
        parent::__construct($from, $to, $column, $foreignKey);

        // Do either of our Models indicate that the field canFilter?
        $relations = array($this);
        $fieldDefinitions = array();
        $from->standardTargetModelFieldDefinitions($column, $relations, $fieldDefinitions); // &$fieldDefinitions pass-by-reference
        $to->standardTargetModelFieldDefinitions(  $column, $relations, $fieldDefinitions); // &$fieldDefinitions pass-by-reference
        $this->canFilter = (isset($fieldDefinitions['canFilter']) ? $fieldDefinitions['canFilter'] : FALSE);
    }
}

class RelationXfromXSemi extends RelationFrom {
    public $pivot;
    public $pivotModel;
    public $keyColumn;
    public $canFilter = TRUE;

    public function __construct(
        Model  &$from,          // Legalcase
        Model  &$to,            // User
        Model  &$pivotModel,    // LegalcaseProsecutor
        Column &$keyColumn,     // pivot.legalcase_id
        Column &$throughColumn, // pivot.user_id
        ForeignKey &$foreignKey
    ) {
        parent::__construct($from, $to, $throughColumn, $foreignKey);

        $this->pivotModel = &$pivotModel;
        $this->pivot      = &$pivotModel->table;
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
        Model  &$from,          // Legalcase
        Model  &$to,            // User
        Table  &$pivot,         // acorn_criminal_legalcase_category
        Column &$keyColumn,     // pivot.legalcase_id
        Column &$throughColumn, // pivot.user_id
        ForeignKey &$foreignKey
    ) {
        parent::__construct($from, $to, $throughColumn, $foreignKey);

        $this->pivot     = &$pivot;
        $this->keyColumn = &$keyColumn;
    }

    public function __toString()
    {
        return parent::__toString() . " through [$this->pivot]";
    }
}
