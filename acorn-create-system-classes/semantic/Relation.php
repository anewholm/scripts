<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

class Relation {
    public $name;
    public $oid;
    public $from; // Model
    public $to;   // Model
    public $column;
    public $foreignKey;
    public $eagerLoad;

    public $comment;
    public $fieldComment;
    public $columnType;
    public $columnPartial;
    public $commentHtml;
    public $hidden;
    public $invisible;
    public $fieldExclude;
    public $columnExclude;
    public $hasManyDeepSettings; // HasManyDeep control
    public $fieldsSettings; // Adjust embedded 3rd party fields.yaml
    public $fieldsSettingsTo; // Adjust 3rd party embedded columns.yaml
    public $hints;
    public $status; // ok|exclude|broken
    public $multi;  // _multi.php config
    public $prefix;
    public $suffix;
    public $contexts;
    public $recordUrl;
    public $recordOnClick;
    public $recordsPerPage;
    public $extraTranslations; // array
    public $trigger;  // field trigger field/action/conditions
    public $valueFrom;
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
    public $rlTitle;

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
    public $defaultSort;

    // Translation arrays
    public $labels;
    public $labelsPlural;

    public function __construct(
        string $name, 
        Model $from, 
        Model $to, 
        Column $column, 
        ForeignKey|NULL $foreignKey = NULL,
        bool $isCount = FALSE,
        string|NULL $conditions = NULL
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
        if (!isset($this->required))  $this->required  = FALSE;
        if (!isset($this->fieldExclude) && $this->isCount) $this->fieldExclude = TRUE;

        if ($this->eagerLoad && $this->globalScope) 
            throw new Exception("Eager loading on [$this] is not compatible with Global Scope");
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

    public function defaultSortString(): string|NULL
    {
        $defaultSort = $this->defaultSort;
        return (is_array($defaultSort)
            ? trim("$defaultSort[column] $defaultSort[direction]")
            : $defaultSort
        );
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

    public function isFromLeaf(): bool
    {
        return ($this->type == 'leaf');
    }

    public function isNameObject(): bool
    {
        return (bool) $this->nameObject;
    }

    public function isSelfReferencing(): bool
    {
        return ($this->foreignKey ? $this->foreignKey->isSelfReferencing() : FALSE);
    }

    public function nullable(): bool
    {
        // Is the from column nullable?
        return ($this->foreignKey ? $this->foreignKey->nullable() : FALSE);
    }

    public function deferrable(): bool
    {
        // For Laravel Deferred Bindings
        // https://wintercms.com/docs/v1.2/docs/database/relations#deferred-binding
        // The from column must be NULLable in order to make the record without the FK relation
        // and then update it later after the FK relation has been created
        return ($this->from 
            && $this->foreignKey 
            && $this->nullable() 
            && $this->foreignKey->tableFrom::class == Table::class // No Views please
        );
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

