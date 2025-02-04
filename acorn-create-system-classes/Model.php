<?php namespace Acorn\CreateSystem;

require_once('Relation.php');
require_once('Field.php');

class Model {
    protected static $models = array();

    public const PLURAL   = TRUE;
    public const SINGULAR = FALSE;
    public const THROW_IF_NOT_ONLY_1 = TRUE;
    public const NULL_IF_NOT_ONLY_1  = FALSE;
    public const RELATION_MODE = TRUE;
    public const NESTED_MODE   = FALSE;

    public $controllers = array();
    public $actionFunctions;
    public $printable;

    public $plugin;
    public $table;
    public $name;

    public $comment;
    public $menu = TRUE;
    public $menuSplitter = FALSE;
    public $menuIndent   = 0;
    public $icon;
    // PHP model methods
    public $attributeFunctions = array();
    public $methods            = array();
    public $staticMethods      = array();

    public $labels;
    public $labelsPlural;

    public $filters;

    // Class components
    public $uses      = array();
    public $traits    = array();
    public $behaviors = array();

    public function __construct(Plugin|Module &$plugin, Table &$table)
    {
        // name is NOT unique
        $this->plugin  = &$plugin;
        $this->table   = &$table;
        $this->name    = $table->modelName();

        $this->actionFunctions = array();
        foreach ($table->actionFunctions as $fnName => $definition) {
            $fnNameParts = explode('_', $fnName);
            $nameParts   = array_slice($fnNameParts, 5);
            $name        = implode('_', $nameParts);

            $commentDef  = \Spyc::YAMLLoadString($definition['comment']);
            $enDevLabel  = Str::title(implode(' ', $nameParts));
            if (!isset($commentDef['labels']['en'])) $commentDef['labels']['en'] = $enDevLabel;

            $this->actionFunctions[$name] = array_merge(array(
                'fnName'     => $fnName,
                'parameters' => $definition['parameters'],
            ), $commentDef);
        }

        // Adopt some of the tables comment statements
        $this->comment = $table->comment;
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) $this->$nameCamel = $value;
        }

        // Link back
        $this->table->model = &$this;

        self::$models[$this->fullyQualifiedName()] = &$this;
    }

    public function addController(Controller &$controller)
    {
        if (isset($this->controllers[$controller->name])) throw new \Exception("Controller [$controller->name] already exists on Model [$this->name]");
        $this->controllers[$controller->name] = &$controller;
    }

    public function controller(bool $throwIfNotOnly1 = self::THROW_IF_NOT_ONLY_1): Controller|NULL
    {
        $controller = NULL;

        if (count($this->controllers) == 0) {
            if ($throwIfNotOnly1) throw new \Exception("No controllers found on [$this->name]");
        } else if (count($this->controllers) > 1) {
            if ($throwIfNotOnly1) throw new \Exception("Several controllers found on [$this->name]");
        } else $controller = end($this->controllers);

        return $controller;
    }

    public function dbObject()
    {
        return $this->table;
    }

    // ----------------------------------------- Semantic Info
    public function isOurs(): bool
    {
        return $this->table->isOurs();
    }

    public function isAcornEvent(): bool
    {
        return ($this->fullyQualifiedName() == 'Acorn\\Calendar\\Models\\Event');
    }

    public function isAcornUser(): bool
    {
        return ($this->fullyQualifiedName() == 'Acorn\\User\\Models\\User');
    }

    public function isKnownAcornPlugin(): bool
    {
        return $this->table->isKnownAcornPlugin();
    }

    public function hasField(string $name): bool
    {
        return $this->table->hasColumn($name);
    }

    public function isDistributed(): bool
    {
        return $this->table->hasUUIDs();
    }

    public function hasSoftDelete(): bool
    {
        return $this->table->hasColumn('deleted-at', 'timestamp');
    }

    public function dirName(): string
    {
        // Squished lower case
        // user_groups => UserGroups => usergroups
        return strtolower($this->name);
    }

    public function langSectionName(): string
    {
        // Squished lower case
        // user_groups => UserGroups => usergroups
        return $this->dirName();
    }

    public function author(): string
    {
        return $this->plugin->author;
    }

    public function crudControllerName()
    {
        return $this->table->crudControllerName();
    }

    public function devEnTitle(bool $plural = self::SINGULAR): string
    {
        // Development EN title
        // This is only used in the absence of multi-lingual labels:
        $title = str_replace('_', ' ', Str::title($this->table->subName()));
        if (!$plural) $title = Str::singular($title);
        return $title;
    }

    public function staticCallClause(string $staticMethod, bool $bare = TRUE): string
    {
        $fqn = $this->fullyQualifiedName();
        $parenthesis = ($bare ? '' : '()');
        return "$fqn::$staticMethod$parenthesis";
    }

    // ----------------------------------------- Display
    public function __toString(): string
    {
        return $this->fullyQualifiedName();
    }

    public function show(int $indent = 0)
    {
        global $GREEN, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$this\n");

        foreach ($this->controllers as $controller) {
            $controller->show($indent + 1);
        }

        // Relations
        $previousClass = NULL;
        foreach ($this->relations() as &$relation) {
            $classParts = explode('\\', get_class($relation));
            $class      = end($classParts);
            if ($previousClass != $class) print("${indentString}  $class:\n");
            $relation->show($indent+2);
            $previousClass = $class;
        }

        print("${indentString}  Fields:\n");
        foreach ($this->fields() as &$field) {
            $field->show($indent+2);
        }

        //if ($this->name == 'Legalcase') {var_dump($this->table);exit(9);}
    }

    public function dropdownOptionsCall(): string
    {
        $absoluteFullyQualifiedName = $this->absoluteFullyQualifiedName();
        return "$absoluteFullyQualifiedName::dropdownOptions";
    }

    public function fullyQualifiedName(bool $withClassString = FALSE): string
    {
        $classString = ($withClassString ? '::class' : '');
        $pluginFullyQualifiedName = $this->plugin->fullyQualifiedName();
        return "$pluginFullyQualifiedName\\Models\\$this->name$classString";
    }

    public function absoluteFullyQualifiedName(bool $withClassString = FALSE): string
    {
        return '\\' . $this->fullyQualifiedName($withClassString);
    }

    public function standardTargetModelFieldDefinitions(Column &$column, array &$relations, array &$fieldDefinition)
    {
        // TODO: This needs to be rationalised with Column->standardFieldDefinitions()
        $modifiers = array();

        if ($this->isAcornEvent()) {
            $modifiers = array(
                'fieldKeyQualifier' => '[start]',
                'fieldType'  => 'datepicker',
                'columnType' => 'timetense',
                'sqlSelect'  => "(select aacep.start from acorn_calendar_event_part aacep where aacep.event_id = $column->column_name order by aacep.start limit 1)",
                'autoFKType' => 'Xto1', // Because these fields also appear on pivot tables, causing them to be XtoXSemi
                'autoRelationCanFilter' => TRUE,

                // Filter settings
                'canFilter'  => TRUE,
                'filterType' => 'daterange',
                'yearRange'  => 10,
                'conditions' => "((select aacep.start from acorn_calendar_event_part aacep where aacep.event_id = $column->column_name order by start limit 1) between ':after' and ':before')",
            );
        } else if ($this->isAcornUser()) {
            $modifiers = array(
                'fieldType'  => 'text',
                'columnType' => 'text',
                'sqlSelect'  => "(select aauu.name from acorn_user_users aauu where aauu.id = $column->column_name)",
                'autoFKType' => 'Xto1', // Because these fields also appear on pivot tables, causing them to be XtoXSemi
                'autoRelationCanFilter' => TRUE,

                // Filter settings
                'canFilter'  => TRUE,
            );
        }

        $fieldDefinition = array_merge($fieldDefinition, $modifiers);
    }

    // ----------------------------------------- Relations
    public function relations(Column &$forColumn = NULL): array
    {
        // foreignKeysTo this column (ID)
        $r2 = $this->relations1from1($forColumn); // 1to1
        $r4 = $this->relations1fromX($forColumn); // Xto1
        $r7 = $this->relationsXfromXSemi($forColumn); // XtoXsemi <= semi-pivot
        $r6 = $this->relationsXfromX($forColumn); // XtoX <= pivot
        // foreignKeysFrom this column
        $r1 = $this->relationsSelf($forColumn);   // self
        $r3 = $this->relations1to1($forColumn);   // 1to1
        $r5 = $this->relationsXto1($forColumn);   // Xto1

        $conflicts = array_intersect_key($r1, $r2, $r3, $r4, $r5, $r6, $r7);
        if (count($conflicts)) throw new Exception("Relation conflicts for [$this]");

        return array_merge($r1, $r2, $r3, $r4, $r5, $r6, $r7);
    }

    public function relationsSelf(Column &$forColumn = NULL): array
    {
        $relations = array();

        foreach ($this->table->columns as &$column) {
            foreach ($column->foreignKeysFrom as &$foreignKeyFrom) {
                if ($foreignKeyFrom->shouldProcess()) {
                    // Returns true also if isLeaf()
                    if ($foreignKeyFrom->isSelfReferencing() && (is_null($forColumn) || $forColumn->name == $column->name)) {
                        $finalContentTable = &$foreignKeyFrom->tableTo;
                        $finalColumnTo     = &$foreignKeyFrom->columnTo;
                        if ($finalContentTable != $this->table)    throw new \Exception("Self-referencing [$foreignKeyFrom] on [$this->table.$column] is not to the same table");
                        if (!$finalColumnTo->isTheIdColumn())      throw new \Exception("Self-referencing [$foreignKeyFrom] on [$this->table.$column] is not to the id column [$finalColumnTo->name]");
                        $finalModel   = &$finalContentTable->model;
                        $relationName = $foreignKeyFrom->columnFrom->relationName();
                        if (isset($relations[$relationName])) throw new \Exception("Relation for [$relationName] already exists on [$this->name] on [$this->table.$column]");
                        $relations[$relationName] = new RelationSelf($this, $foreignKeyFrom->columnFrom, $foreignKeyFrom);
                    }
                }
            }
        }

        return $relations;
    }

    public function relations1from1(Column &$forColumn = NULL): array
    {
        // 1-1 & leaf relations
        $relations = array();

        // 1 column pointing to the parent content table
        if ($idColumn = $this->table->idColumn()) {
            foreach ($idColumn->foreignKeysTo as &$foreignKeyTo) {
                if ($foreignKeyTo->shouldProcess()) {
                    // Returns true also if isLeaf()
                    if ($foreignKeyTo->is1to1() && (is_null($forColumn) || $forColumn->name == $idColumn->name)) {
                        $finalTableFrom  = &$foreignKeyTo->tableFrom;
                        $finalColumnFrom = &$foreignKeyTo->columnFrom;

                        // created_at_event_id is 1to1 and can be from a pivot table
                        // so there is no final model to report
                        if (!$finalTableFrom->isPivotTable()) {
                            if (!$finalTableFrom->model)            throw new \Exception("Foreign key [$foreignKeyTo] on [$this->table.id] has no to model");
                            if ($finalColumnFrom->isTheIdColumn())  throw new \Exception("Foreign 1to1 key [$foreignKeyTo] on [$this->table.id] is from an id column");
                            $finalModel   = &$finalTableFrom->model;
                            $relationName = $foreignKeyTo->columnFrom->fromRelationName();
                            if (isset($relations[$relationName])) throw new \Exception("Relation for [$relationName] on [$this->table.id] already exists on [$this->name]");
                            $relations[$relationName] = new Relation1from1($this, $finalModel, $foreignKeyTo->columnFrom, $foreignKeyTo);
                        }
                    }
                }
            }
        }

        return $relations;
    }

    public function relations1to1(Column &$forColumn = NULL): array
    {
        // 1-1 & leaf relations
        $relations = array();

        // 1 column pointing to the parent content table
        foreach ($this->table->columns as &$column) {
            foreach ($column->foreignKeysFrom as &$foreignKeyFrom) {
                if ($foreignKeyFrom->shouldProcess()) {
                    // Returns true also if isLeaf()
                    if ($foreignKeyFrom->is1to1() && (is_null($forColumn) || $forColumn->name == $column->name)) {
                        $finalContentTable = &$foreignKeyFrom->tableTo;
                        $finalColumnTo     = &$foreignKeyFrom->columnTo;
                        if (!$finalContentTable->isContentTable()) throw new \Exception("Final Content Table of [$foreignKeyFrom] on [$this->table.$column] is not type content");
                        if (!$finalContentTable->model)            throw new \Exception("Foreign key [$foreignKeyFrom] on [$this->table.$column] has no to model");
                        if (!$finalColumnTo->isTheIdColumn())      throw new \Exception("Foreign 1to1 key [$foreignKeyFrom] on [$this->table.$column] is not to the id column [$finalColumnTo->name]");

                        $finalModel   = &$finalContentTable->model;
                        $relationName = $foreignKeyFrom->columnFrom->relationName();
                        if (isset($relations[$relationName])) throw new \Exception("Relation for [$relationName] already exists on [$this->name] on [$this->table.$column]");
                        $relations[$relationName] = ($foreignKeyFrom->isLeaf()
                            ? new RelationLeaf($this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom)
                            : new Relation1to1($this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom)
                        );
                    }
                }
            }
        }

        return $relations;
    }

    public function relations1fromX(Column &$forColumn = NULL): array
    {
        $relations = array();

        // All content tables pointing to this id
        if ($idColumn = $this->table->idColumn()) {
            foreach ($idColumn->foreignKeysTo as &$foreignKeyTo) {
                if ($foreignKeyTo->shouldProcess()) {
                    if ($foreignKeyTo->isXto1() && (is_null($forColumn) || $forColumn->name == $idColumn->name)) {
                        $finalContentTable = &$foreignKeyTo->tableFrom;

                        // created_at_event_id is 1to1 and can be from a pivot table
                        // so there is no final model to report
                        if (!$finalContentTable->isPivotTable()) {
                            if (!$finalContentTable->isContentTable() && !$finalContentTable->isSemiPivotTable())
                                throw new \Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] is not type content");
                            if (!$finalContentTable->model)
                                throw new \Exception("Foreign key from table for [$foreignKeyTo] on [$this->table.id] has no model");
                            $finalModel   = &$finalContentTable->model;
                            $relationName = $foreignKeyTo->columnFrom->fromRelationName();
                            if (isset($relations[$relationName])) throw new \Exception("Relation for [$relationName] on [$this->table.id] already exists on [$this->name]");
                            $relations[$relationName] = new Relation1fromX($this, $finalModel, $foreignKeyTo->columnFrom, $foreignKeyTo);
                        }
                    }
                }
            }
        }

        return $relations;
    }

    public function relationsXto1(Column &$forColumn = NULL): array
    {
        $relations = array();

        // All this tables foreign *_id columns pointing to an id column
        foreach ($this->table->columns as &$column) {
            foreach ($column->foreignKeysFrom as &$foreignKeyFrom) {
                if ($foreignKeyFrom->shouldProcess()) {
                    if (($foreignKeyFrom->isXto1() || $foreignKeyFrom->isXtoXSemi()) && (is_null($forColumn) || $forColumn->name == $column->name)) {
                        $finalContentTable = &$foreignKeyFrom->tableTo;
                        if ($column->isTheIdColumn())              throw new \Exception("Xto1 [$foreignKeyFrom] on [$this->table.$column] from column is id");
                        if (!$foreignKeyFrom->columnTo->isTheIdColumn()) throw new \Exception("Xto1 [$foreignKeyFrom] on [$this->table.$column] to column not id");
                        if (!$finalContentTable->isContentTable()) throw new \Exception("Final Content Table for [$foreignKeyFrom] on [$this->table.$column] is not type content");
                        if (!$finalContentTable->model)            throw new \Exception("Foreign key from table for [$foreignKeyFrom] on [$this->table.$column] has no model");
                        $finalModel   = &$finalContentTable->model;
                        $relationName = $foreignKeyFrom->columnFrom->relationName();
                        if (isset($relations[$relationName])) throw new \Exception("Relation for [$relationName] on [$this->table.$column] already exists on [$this->name]");
                        $relations[$relationName] = new RelationXto1($this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom);
                    }
                }
            }
        }

        /*
        if ($this->table == 'acorn_user_users') {
            var_dump(array_keys($relations));
            exit(9);
        }
        */

        return $relations;
    }

    public function relationsXfromXSemi(Column &$forColumn = NULL): array
    {
        // These are XfromX relations with a pivot table,
        // but also an ID and extra content columns
        $relations = array();

        // All pivot tables pointing to this id
        if ($idColumn = $this->table->idColumn()) {
            foreach ($idColumn->foreignKeysTo as &$foreignKeyTo) {
                if ($foreignKeyTo->shouldProcess()) {
                    if ($foreignKeyTo->isXtoXSemi() && (is_null($forColumn) || $forColumn->name == $idColumn->name)) {
                        // We have a pivot table pointing to this id column
                        // Where does its other foreign key point?
                        $pivotTable = &$foreignKeyTo->tableFrom;
                        if (!$pivotTable->isSemiPivotTable()) throw new \Exception("Semi-Pivot (Through) table for [$foreignKeyTo] on [$this->table.id] on XtoXSemi is not a semi-pivot table");
                        if (!$pivotTable->hasIdColumn())      throw new \Exception("Semi-Pivot (Through) table for [$foreignKeyTo] on [$this->table.id] on XtoXSemi has no ID column");
                        if (!$pivotTable->model)              throw new \Exception("Semi-Pivot (Through) table for [$foreignKeyTo] on [$this->table.id] on XtoXSemi has no model");
                        $pivotModel = &$pivotTable->model;

                        // The other throughColumn should have exactly 1 FK pointing to the other content table
                        // However, it is a semi so there may be other foreign IDs. We choose the first in ordinal_position order
                        $throughColumn = $pivotTable->throughColumn($foreignKeyTo->columnFrom, Table::FIRST_ONLY);
                        if (!$throughColumn) throw new \Exception("Semi-Pivot Table [$pivotTable->name] has no custom foreign ID columns");
                        if (count($throughColumn->foreignKeysFrom) == 0) throw new \Exception("Semi-Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has no foreign keys");
                        if (count($throughColumn->foreignKeysFrom) > 1)  throw new \Exception("Semi-Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has multiple foreign keys");

                        $secondForeignKey  = array_values($throughColumn->foreignKeysFrom)[0];
                        $finalContentTable = $secondForeignKey->tableTo;
                        if (!$finalContentTable->isContentTable()) throw new \Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] is not type content");
                        if (!$finalContentTable->model)            throw new \Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] has no model");
                        $finalModel   = &$finalContentTable->model;

                        $relationName = $foreignKeyTo->columnFrom->fromRelationName(Column::PLURAL);
                        if (!$finalModel) throw new \Exception("Foreign key from table on [$foreignKeyTo] has no model");

                        $relations[$relationName] = new RelationXfromXSemi($this,
                            $finalModel,               // User
                            $pivotModel,               // LegalcaseProsecutor
                            $foreignKeyTo->columnFrom, // pivot.legalcase_id
                            $throughColumn,            // pivot.user_id
                            $foreignKeyTo
                        );
                    }
                }
            }
        }

        return $relations;
    }

    public function relationsXfromX(Column &$forColumn = NULL): array
    {
        $relations = array();

        // All pivot tables pointing to this id
        if ($idColumn = $this->table->idColumn()) {
            foreach ($idColumn->foreignKeysTo as &$foreignKeyTo) {
                if ($foreignKeyTo->shouldProcess()) {
                    if ($foreignKeyTo->isXtoX() && (is_null($forColumn) || $forColumn->name == $idColumn->name)) {
                        // We have a pivot table pointing to this id column
                        // Where does its other foreign key point?
                        $pivotTable = &$foreignKeyTo->tableFrom;
                        if (!$pivotTable->isPivotTable()) throw new \Exception("Through table for [$foreignKeyTo] on [$this->table.id] on XtoX is not a pivot table");

                        // The other throughColumn should have exactly 1 FK pointing to the other content table
                        $throughColumn = $pivotTable->throughColumn($foreignKeyTo->columnFrom);
                        if (!$throughColumn) throw new \Exception("Pivot Table [$pivotTable->name] has no custom foreign ID columns");
                        if (count($throughColumn->foreignKeysFrom) == 0) throw new \Exception("Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has no foreign keys");
                        if (count($throughColumn->foreignKeysFrom) > 1)  throw new \Exception("Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has multiple foreign keys");

                        $secondForeignKey  = array_values($throughColumn->foreignKeysFrom)[0];
                        $finalContentTable = $secondForeignKey->tableTo;
                        if (!$finalContentTable->isContentTable()) throw new \Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] is not type content");
                        if (!$finalContentTable->model)            throw new \Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] has no model");
                        $finalModel   = &$finalContentTable->model;
                        $relationName = $foreignKeyTo->columnFrom->fromRelationName(Column::PLURAL);
                        if (!$finalModel) throw new \Exception("Foreign key from table on [$foreignKeyTo] on [$this->table.id] has no model");

                        $relations[$relationName] = new RelationXfromX($this,
                            $finalModel,               // User
                            $pivotTable,
                            $foreignKeyTo->columnFrom, // pivot.legalcase_id
                            $throughColumn,            // pivot.user_id
                            $foreignKeyTo
                        );
                    }
                }
            }
        }

        return $relations;
    }

    public static function nestedFieldName(string $localFieldName, array $relation1to1Path = array(), bool $relationMode = TRUE, string $valueFrom = NULL): string
    {
        // $localFieldName may be:
        //   a ForeignID, with a valueFrom to show the dropdown list
        //   a normal text field without valueFrom
        // $localFieldName is appended, and $valueFrom will be appended in NESTED_MODE
        $nestedFieldName = $localFieldName;

        if (count($relation1to1Path)) {
            if ($relationMode) {
                // name, [office, location, address] => office_location_address_name
                // For use with relation and select directives
                // searchable and sortable will also work with this
                $nestedFieldName = '';
                foreach ($relation1to1Path as $fieldObj) {
                    if ($fieldObj instanceof Field) $fieldObj = $fieldObj->name;
                    $nestedFieldName .= "${fieldObj}_";
                }
                $nestedFieldName .= $localFieldName;
            } else {
                // name, [office, location, address] => office[location][address][name]
                // select does not work with this. It would select the value from the first step, office
                // relation does not work with this
                // searchable and sortable also will not work
                $firstFieldObj    = array_shift($relation1to1Path); // office obj
                $path             = '';
                foreach ($relation1to1Path as $fieldObj) {
                    // [location][address]...[name]
                    if ($fieldObj instanceof Field) $fieldObj = $fieldObj->name;
                    $path .= "[$fieldObj]";
                }
                $nestedFieldName = "$firstFieldObj->name${path}[$localFieldName]";    // office[location][address][name]
                if ($valueFrom) $nestedFieldName .= "[$valueFrom]";
            }
        }

        return $nestedFieldName;
    }

    public function fields(array $relation1to1Path = array()): array
    {
        global $YELLOW, $GREEN, $RED, $NC;

        // TODO: Relations should reference their Fields, not columns
        $plugin = &$this->plugin;
        $fields = array();
        $maxTabLocation     = 0;
        $nestLevel          = count($relation1to1Path);
        $isNested           = (bool)$nestLevel;
        $topLevelNest       = ($nestLevel == 1);
        $useRelationManager = TRUE; //!$isNested;

        // ---------------------------------------------------------------- Normal Columns
        foreach ($this->table->columns as $columnName => &$column) {
            if ($column->shouldProcess()) {
                $relations       = $this->relations($column);
                $fieldObj        = Field::createFromColumn($this, $column, $relations);
                $comment         = '';

                // Debug
                $fieldClassParts = explode('\\', get_class($fieldObj));
                $fieldClass      = end($fieldClassParts);
                $fieldObj->debugComment = "$fieldClass for column $column->column_name on $plugin->name.$this->name";

                // --------------------- + Nested Models
                if ($fieldObj instanceof ForeignIdField && ($relationModel = $fieldObj->embedRelation1Model())) {
                    // Static 1to1 whole form include. Most fields, not ID
                    // e.g. location[name]
                    // RECURSIVE!
                    // TODO: Embedding of AA User will not go well. It's tables are not annotated, so we need to embed its fields.yaml instead...
                    $thisRelation1to1Path = $relation1to1Path; // Local scope
                    array_push($thisRelation1to1Path, $fieldObj);

                    $relationFields = NULL;
                    if ($relationModel->plugin->isCreateSystemPlugin()) {
                        // create-system made this plugin
                        // so the database columns => fields() will describe the interface correctly
                        // whereas a non-create-system plugin, only its custom fields.yaml will
                        // describe its interface correctly

                        // Non-empty $thisRelation1to1Path will cause fields() to return nested field names
                        // Depending on the type of field, this could be:
                        //   relation1_relation2_name:   (searchable and sortable)
                        //   relation1[relation2][name]: (not searchable nor sortable)
                        // with associated relevant relation: relation1 and select: directives
                        $relationFields = $relationModel->fields($thisRelation1to1Path);

                        // includeContext is applied in this ->fields() recurive call below
                        foreach ($relationFields as $nestedFieldName => $subFieldObj) {
                            // Exclude fields that have the same local name as fields in the parent form
                            // this naturally exlcudes id and created_*
                            // TODO: created_* is not being excluded
                            $isDuplicateField = isset($fields[$subFieldObj->name]);
                            if (!$isDuplicateField) {
                                $fields[$nestedFieldName] = $subFieldObj;
                                if ($subFieldObj->tabLocation > $maxTabLocation) $maxTabLocation = $subFieldObj->tabLocation;
                            }
                        }
                    } else {
                        // This is a non acorn-create-system Plugin
                        // so the database columns do not describe the fields necessarily
                        // only its custom fields.yaml will describe its interface correctly
                        // TODO: Copy fields from a non-create-system plugin
                        print("    $relationModel->plugin is not a create-system plugin so embedding its database->columns() will not work...\n");
                        /*
                        print("Temporary solution: refuse all PseudoFields");
                        $relationFields = $relationModel->fields($thisRelation1to1Path);
                        foreach ($relationFields as $nestedFieldName => $subFieldObj) {
                            if ($subFieldObj instanceof PseudoField) unset($relationFields[$nestedFieldName]);
                        }
                        */

                        // TODO: setting: directive and 1to1 image fields do not work with include: 1to1
                        print("    Temporary solution: use include: 1to1\n");
                        $fieldObj->include      = '1to1';
                        $fieldObj->includeModel = $relationModel->absoluteFullyQualifiedName();
                        $fields[$fieldObj->name] = $fieldObj;
                    }
                } else {
                    // Direct entry in fields array
                    $fields[$fieldObj->name] = $fieldObj;
                    if ($fieldObj->tabLocation > $maxTabLocation) $maxTabLocation = $fieldObj->tabLocation;
                }
            }
        }

        /* ---------------------------------------------------------------- Fields.yaml: reverse FKs
        * FKs _to_ this table id
        * For example: foreign defendants.legalcase_id => this legalcase.id table
        * This means that this table form and columns should consider those foreign objects for editing, filtering & display
        * FK comments:
        *   type: 1fromX|XtoX
        *   nameObject: true
        * NOTE: WinterCMS/Laravel does not support create mode management of 1-1[1-X] sub-relations, e.g. legalcase[legalcase_categories]
        * but it DOES seem to support _update_ mode management of them
        *
        * ---------- type: 1from1|leaf ($belongsTo):
        * legalcase.id <= defendants.leagalcase_id
        * so there is no interface
        * but we have added the $relations
        */

        /* ---------- type: self:
        * This is a _reverse_ FK that will appear on _this_ table
        * legalcase_type.id <= legalcase_type.parent_leagalcase_type_id
        * we will present a children selection tab
        */
        foreach ($this->relationsSelf() as $name => &$relation) {
            $nameFrom  = 'fully_qualified_name';
            $tab       = $relation->from->translationKey(Model::PLURAL); // Reverse relation, so it is from!
            $relations = array($name => $relation);
            $comment     = '';
            if ($relation->status == 'broken') continue;

            print("      Creating tab multi-select for ${YELLOW}$relation${NC}\n");
            $fieldObj  = new PseudoFromForeignIdField($this, array(
                '#'            => "Tab multi-select for $relation",
                'name'         => 'children',
                'labels'       => $relation->labelsPlural,
                'fieldType'    => ($useRelationManager ? 'relationmanager' : 'relation'),
                'nameFrom'     => $nameFrom,
                'cssClasses'   => array('single-tab', 'single-tab-self', ($useRelationManager ? '' : 'selected-only')),
                'tabLocation'  => $relation->tabLocation,
                'debugComment' => "Tab multi-select for $relation on $plugin->name.$this->name",
                'commentHtml'  => TRUE,
                'relatedModel' => $relation->to->fullyQualifiedName(),
                'comment'      => $relation->comment,
                'icon'         => $relation->to->icon,
                'tab'          => $tab,
                'dependsOn'    => array('_paste' => TRUE),
                // TODO: Select and Add ButtonFields
                // TODO: Create button popup

                // List
                'columnType'    => 'partial',
                'columnPartial' => 'multi',
                'searchable'    => FALSE, // These fields don't exist
            ), $relations);
            $fields['children'] = $fieldObj;

            if ($fieldObj->tabLocation > $maxTabLocation) $maxTabLocation = $fieldObj->tabLocation;
        }

        /* ---------- type: 1fromX ($hasMany) => this table.id:
        * For example: foreign defendants(plural).legalcase_id (X)=>(1) this legalcase.id table
        * This relation is identified by the plurality of the foreign table, thus a table-type: content table
        * Present in manageable lists, probably in form tabs, with create new popups
        *
        * X are only meant for this 1 record
        * That is X have an FK name_id column for this table, and some other fields
        * So just a full:
        *   _create_popup, and a
        *   relation list
        */
        foreach ($this->relations1fromX() as $name => &$relation) {
            $nameFrom    = 'fully_qualified_name';
            $dependsOn   = array('_paste' => TRUE);
            // TODO: The tab should inherit the labels local key
            $tab         = $relation->to->translationKey(Model::PLURAL);
            $comment     = '';
            $valueFrom   = ($relation->to->hasField('name') ? 'name' : NULL); // For searcheable
            if ($relation->status == 'broken') continue;

            print("      Creating tab multi-select for ${YELLOW}$relation${NC}\n");
            $buttons = array();
            if (!$useRelationManager) {
                if ($controller = $relation->to->controller(Model::NULL_IF_NOT_ONLY_1)) {
                    // Controller necessary for popup rendering
                    // TODO: Translatable "create new" comment
                    $dataFieldName = "_lc_$name";
                    $title         = $relation->to->devEnTitle(Model::PLURAL);
                    $controllerFQN = $controller->fullyQualifiedName();
                    $controllerFQNEscaped = str_replace('\\', '\\\\', $controllerFQN);
                    $comment       = "<span class='create-new action'>create new <a href='#' class='popup-add' data-field-name='$dataFieldName' data-handler='onPopupRoute' data-request-data=\"route:'$controllerFQNEscaped@create',fieldName:'$dataFieldName'\" data-control='popup' tabindex='-1'>$title</a></span>";
                    $dependsOn[$dataFieldName] = TRUE;

                    $buttonName = "_create_$name";
                    $buttons[$buttonName] = new ButtonField($this, array(
                        'name'       => $buttonName,
                        'isStandard' => TRUE, // => models.general.create
                        'fieldType'  => 'partial',
                        'span'       => 'storm',
                        'cssClasses' => array('p-0', 'hug-left', 'nolabel', 'popup-hide', 'interface-component'),
                        'bootstraps' => array('xs' => 1, 'sm' => 1),
                        'partial'    => 'create_button',
                        'controller' => $controller,
                        'tab'        => 'INHERIT',
                    ));
                    $dependsOn[$buttonName] = TRUE;
                }
            }

            $thisIdRelation = array($name => $relation);
            $fieldObj       = new PseudoFromForeignIdField($this, array(
                '#'            => "Tab multi-select for $relation",
                'name'         => $name,
                'translationKey' => $tab,
                'labels'       => $relation->labelsPlural, // Overrides translationKey to force a local key
                'fieldType'    => ($useRelationManager ? 'relationmanager' : 'relation'),
                'nameFrom'     => $nameFrom,
                'cssClasses'   => array('single-tab', 'single-tab-1fromX', ($useRelationManager ? '' : 'selected-only')),
                'bootstraps'   => $relation->bootstraps,
                'dependsOn'    => $dependsOn,
                'buttons'      => $buttons,
                'tabLocation'  => $relation->tabLocation,
                'icon'         => $relation->to->icon,
                'fieldComment' => $comment,
                'debugComment' => "Tab multi-select for $relation on $plugin->name.$this->name",
                'comment'      => $relation->comment,
                'commentHtml'  => TRUE,
                'relatedModel' => $relation->to->fullyQualifiedName(),
                'canFilter'    => FALSE, // These are linked only to the content table
                'tab'          => 'INHERIT',

                // List
                'columnType'    => 'partial',
                'columnPartial' => 'multi',
                // For searching
                'relation'      => $name,
                'searchable'    => (bool) $valueFrom,
                'valueFrom'     => $valueFrom, // Necessary for search to work, is removed in nested scenario
            ), $thisIdRelation);
            $fields[$name] = $fieldObj;

            if ($fieldObj->tabLocation > $maxTabLocation) $maxTabLocation = $fieldObj->tabLocation;
        }

        /* ---------- type: XtoXSemi ($hasMany) => this table.id:
        * For example FK: foreign users.id(plural) (X)=> this defendant_user(singular semi-pivot).user_id
        *   & this defendant_user.legalcase_id =>(X) this legalcase.id table
        * This relation is identified by the singularity of the direct FK foreign table (pivot only)
        * Present in manageable lists, probably in form tabs, with add and create popups
        *
        * X are meant for any of these X records, BUT table_from is the singular semi-pivot table
        * That is table_from has:
        *   an ID column & 2 IDs:
        *   one for this table and
        *   one for the other content table (ModelOther)
        *   and other content-type fields, including other foreign IDs
        * So a full:
        *   select existing ModelOther & add
        *   _create_popup ModelOther, and a
        *   relation list
        *
        * TODO: This is just the same as 1fromX above at the moment
        */
        foreach ($this->relationsXfromXSemi() as $name => &$relation) {
            $nameFrom    = 'fully_qualified_name';
            $tab         = $relation->pivotModel->translationKey(Model::PLURAL);
            $dependsOn   = array('_paste' => TRUE);
            $comment     = '';
            $valueFrom   = ($relation->to->hasField('name') ? 'name' : NULL); // For searcheable
            if ($relation->status == 'broken') continue;

            print("      Creating tab multi-select for ${YELLOW}$relation${NC}\n");
            $buttons = array();

            if (!$useRelationManager) {
                if ($controller = $relation->to->controller(Model::NULL_IF_NOT_ONLY_1)) {
                    // Controller necessary for popup rendering
                    // TODO: Translatable "create new" comment
                    $dataFieldName = "_lc_$name";
                    $title         = $relation->to->devEnTitle(Model::PLURAL);
                    $controllerFQN = $controller->fullyQualifiedName();
                    $controllerFQNEscaped = str_replace('\\', '\\\\', $controllerFQN);
                    $comment       = "<span class='create-new action'>create new <a href='#' class='popup-add' data-field-name='$dataFieldName' data-handler='onPopupRoute' data-request-data=\"route:'$controllerFQNEscaped@create',fieldName:'$dataFieldName'\" data-control='popup' tabindex='-1'>$title</a></span>";
                    $dependsOn[$dataFieldName] = TRUE;

                    $buttonName = "_$name";
                    $buttons[$buttonName] = $dropdownField = new PseudoField($this, array(
                        'name'         => $buttonName,
                        'translationKey' => $tab,
                        'fieldType'    => 'dropdown',
                        'fieldOptions' => $relation->to->staticCallClause('dropdownOptions'),
                        'nameFrom'     => 'fully_qualified_name',
                        'cssClasses'   => array('interface-component'),
                        'span'         => 'storm',
                        'bootstraps'   => array('xs' => 11, 'sm' => 4),
                        'placeholder'  => 'backend::lang.form.select',
                        'tab'          => $tab,
                    ));

                    $buttonName = "_add_$name";
                    $buttons[$buttonName] = new ButtonField($this, array(
                        'name'       => $buttonName,
                        'isStandard' => TRUE, // => models.general.create
                        'fieldType'  => 'partial',
                        'span'       => 'storm',
                        'cssClasses' => array('p-0', 'hug-left', 'nolabel', 'popup-hide', 'interface-component'),
                        'bootstraps' => array('xs' => 1, 'sm' => 1),
                        'partial'    => 'add_button',
                        'controller' => $controller,
                        'tab'        => $tab,
                    ));
                    $dependsOn[$buttonName] = TRUE;

                    $buttonName = "_create_$name";
                    $buttons[$buttonName] = new ButtonField($this, array(
                        'name'       => $buttonName,
                        'isStandard' => TRUE, // => models.general.create
                        'fieldType'  => 'partial',
                        'span'       => 'storm',
                        'cssClasses' => array('p-0', 'hug-left', 'nolabel', 'popup-hide', 'interface-component'),
                        'bootstraps' => array('xs' => 1, 'sm' => 1),
                        'partial'    => 'create_button',
                        'controller' => $controller,
                        'tab'        => 'INHERIT',
                    ));
                    $dependsOn[$buttonName] = TRUE;

                    $dropdownField->dependsOn = $dependsOn;
                }
            }

            $thisIdRelation = array($name => $relation);
            $rlButtons      = array(
                'create' => TRUE,
                'delete' => TRUE,
                'link'   => TRUE,
                'unlink' => TRUE,
            );
            $fieldObj       = new PseudoFromForeignIdField($this, array(
                '#'              => "Tab multi-select for $relation",
                'name'           => $name,
                'translationKey' => $tab,
                'labels'         => $relation->labelsPlural, // Overrides translationKey
                'fieldType'      => ($useRelationManager ? 'relationmanager' : 'relation'),
                'recordsPerPage' => FALSE, // TODO: Currently does not work for XtoXSemi
                'nameFrom'       => $nameFrom,
                'cssClasses'     => array('single-tab', 'single-tab-1fromX', ($useRelationManager ? '' : 'selected-only')),
                'bootstraps'     => $relation->bootstraps,
                'buttons'        => $buttons,
                'rlButtons'      => $rlButtons,
                'tabLocation'    => $relation->tabLocation,
                'icon'           => $relation->to->icon,
                'fieldComment'   => $comment,
                'debugComment'   => "Tab multi-select for $relation on $plugin->name.$this->name",
                'comment'        => $relation->comment,
                'commentHtml'    => TRUE,
                'relatedModel'   => $relation->to->fullyQualifiedName(),
                'canFilter'      => TRUE,
                'tab'            => 'INHERIT',
                'dependsOn'      => $dependsOn,

                // List
                'columnType'    => 'partial',
                'columnPartial' => 'multi',
                // For searching
                'relation'      => $name,
                'searchable'    => (bool) $valueFrom,
                'valueFrom'     => $valueFrom, // Necessary for search to work, is removed in nested scenario
            ), $thisIdRelation);
            $fields[$name] = $fieldObj;

            if ($fieldObj->tabLocation > $maxTabLocation) $maxTabLocation = $fieldObj->tabLocation;
        }

        /* ---------- type: XtoX ($hasManyThrough) => this table.id:
        * For example: foreign users(plural) (X)=> defendant_user(singular pivot).user_id & defendant_user.legalcase_id =>(X) this legalcase.id table
        * This relation is identified by the singularity of the direct FK foreign table (pivot only)
        * Present in manageable lists, probably in form tabs, with add and create popups
        *
        * X are meant for any of these X records, and table_from is the singular pivot table
        * That is table_from has 2 IDs:
        *   one for this table and
        *   one for the other content table (ModelOther)
        * So a full:
        *   select existing ModelOther & add
        *   _create_popup ModelOther, and a
        *   relation list
        */
        foreach ($this->relationsXfromX() as $name => &$relation) {
            $nameFrom    = 'fully_qualified_name';
            $tab         = $relation->to->translationKey(Model::PLURAL);
            $dependsOn   = array('_paste' => TRUE);
            $comment     = '';
            $valueFrom   = ($relation->to->hasField('name') ? 'name' : NULL); // For searcheable
            if ($relation->status == 'broken') continue;

            // TODO: Translatable "create new" comment
            $dataFieldName = "_lc_$name";
            //$comment     = "create new <a href='#' class='popup-add' data-field-name='$dataFieldName' data-handler='onPopupRoute' data-request-data=\"route:'${table_from_controller//\\/\\\\}@create',fieldName:'$dataFieldName'\" data-control='popup' tabindex='-1'>${table_from_name_singular//_/-}</a>"
            $dependsOn[$dataFieldName] = TRUE;

            $buttons = array();
            if (!$useRelationManager) {
                if ($controller = $relation->to->controller(Model::NULL_IF_NOT_ONLY_1)) {
                    // Controller necessary for popup rendering
                    $buttonName = "_$name";
                    $buttons[$buttonName] = $dropdownField = new PseudoField($this, array(
                        'name'         => $buttonName,
                        'translationKey' => $tab,
                        'fieldType'    => 'dropdown',
                        'fieldOptions' => $relation->to->staticCallClause('dropdownOptions'),
                        'nameFrom'     => 'fully_qualified_name',
                        'cssClasses'   => array('interface-component'),
                        'span'         => 'storm',
                        'bootstraps'   => array('xs' => 11, 'sm' => 4),
                        'placeholder'  => 'backend::lang.form.select',
                        'tab'          => $tab,
                    ));

                    $buttonName = "_add_$name";
                    $buttons[$buttonName] = new ButtonField($this, array(
                        'name'       => $buttonName,
                        'isStandard' => TRUE, // => models.general.create
                        'fieldType'  => 'partial',
                        'span'       => 'storm',
                        'cssClasses' => array('p-0', 'hug-left', 'nolabel', 'popup-hide', 'interface-component'),
                        'bootstraps' => array('xs' => 1, 'sm' => 1),
                        'partial'    => 'add_button',
                        'controller' => $controller,
                        'tab'        => $tab,
                    ));
                    $dependsOn[$buttonName] = TRUE;

                    $buttonName = "_create_$name";
                    $buttons[$buttonName] = new ButtonField($this, array(
                        'name'       => $buttonName,
                        'isStandard' => TRUE, // => models.general.create
                        'fieldType'  => 'partial',
                        'span'       => 'storm',
                        'cssClasses' => array('p-0', 'hug-left', 'nolabel', 'popup-hide', 'interface-component'),
                        'bootstraps' => array('xs' => 1, 'sm' => 1),
                        'partial'    => 'create_button',
                        'controller' => $controller,
                        'tab'        => $tab,
                    ));
                    $dependsOn[$buttonName] = TRUE;

                    $dropdownField->dependsOn = $dependsOn;
                }
            }

            print("      Creating tab multi-select with (${GREEN}create button${NC}) for ${YELLOW}$relation${NC}\n");
            $thisIdRelation = array($name => $relation);
            $rlButtons      = array(
                'create' => TRUE,
                'delete' => TRUE,
                'link'   => TRUE,
                'unlink' => TRUE,
            );
            $fieldObj       = new PseudoFromForeignIdField($this, array(
                '#'              => "Tab multi-select for $relation",
                'name'           => $name,
                'translationKey' => $tab,
                'labels'         => $relation->labelsPlural, // Overrides translationKey
                'fieldType'      => ($useRelationManager ? 'relationmanager' : 'relation'),
                'recordsPerPage' => FALSE, // TODO: Currently does not work for XtoXSemi
                'nameFrom'       => $nameFrom,
                'cssClasses'     => array('single-tab', 'single-tab-XfromX', ($useRelationManager ? '' : 'selected-only')),
                'bootstraps'     => $relation->bootstraps,
                'placeholder'    => $relation->placeholder,
                'buttons'        => $buttons,
                'rlButtons'      => $rlButtons,
                'tabLocation'    => $relation->tabLocation,
                'comment'        => $relation->comment,
                'icon'           => $relation->to->icon,
                'debugComment'   => "Tab multi-select for $relation on $plugin->name.$this->name",
                'commentHtml'    => TRUE,
                'relatedModel'   => $relation->to->fullyQualifiedName(),
                'canFilter'      => TRUE,
                'tab'            => $tab,
                'dependsOn'      => $dependsOn,

                // List
                'columnType'    => 'partial',
                'columnPartial' => 'multi',
                // For searching
                'relation'      => $name,
                'searchable'    => (bool) $valueFrom,
                'valueFrom'     => $valueFrom, // Necessary for search to work, is removed in nested scenario
            ), $thisIdRelation);
            $fields[$name] = $fieldObj;

            if ($fieldObj->tabLocation > $maxTabLocation) $maxTabLocation = $fieldObj->tabLocation;
        }

        // ---------------------------------------------------------------- QR code support fields
        print("      Injecting _qrcode field\n");
        // TODO: Move to QRCode FormField when available
        $fields['_qrcode'] = new PseudoField($this, array(
            'name'        => '_qrcode',
            'isStandard'  => TRUE,
            'fieldType'   => 'partial',
            'contexts'    => array('update' => TRUE, 'preview' => TRUE),
            'span'        => 'storm',
            'tabLocation' => ($maxTabLocation == 3 ? 3 : NULL),
            'cssClasses'  => ($maxTabLocation == 3 ? array('bottom') : NULL),
            'bootstraps'  => array('xs' => 6),
            'partial'        => 'qrcode',
            'includeContext' => 'exclude',

            // List
            'columnType'    => 'partial',
            'columnPartial' => 'qrcode',
            'sortable'    => FALSE,
            'searchable'  => FALSE,
            'invisible'   => TRUE,
        ));

        // ---------------------------------------------------------------- Actions
        // These also appear in columns.yaml
        print("      Injecting list actions column\n");
        $fields['_actions'] = new PseudoField($this, array(
            'name'          => '_actions',
            'hidden'        => TRUE,
            'columnType'    => 'partial',
            'columnPartial' => 'actions',
            'sortable'      => FALSE,
            'searchable'    => FALSE,
            'invisible'     => FALSE,
        ));

        // ------------------------------------------------------------- Custom filters
        foreach ($fields as $localFieldName => &$fieldObj) {
            if ($conditions = $this->filters[$localFieldName] ?? NULL) {
                if (count($fieldObj->relations)) {
                    $relation1 = current($fieldObj->relations);
                    $relation1->canFilter = TRUE;
                }
                $fieldObj->canFilter  = TRUE;
                $fieldObj->conditions = $conditions;
            }
        }

        // ------------------------------------------------------------- Debug
        foreach ($fields as $name => &$field) {
            // Nested fields will already have been annotated
            if (!$field->nested) {
                $dbLangPath = $field->dbObject()?->dbLangPath();
                $disabled   = ($dbLangPath ? '' : 'disabled="disabled"');
                $dbComment  = str_replace(" ", '&nbsp;', $field->comment); // Prevent YAML indentation normalization

                $field->fieldComment .= <<<HTML
                    <div class='debug debug-field'>
                        <div class="title">$name</div>
                        $field->debugComment
                        <div class="create-system">
                            <pre class="create-system-comment">$dbComment</pre>
                            <div class="create-system-db-lang-path">$dbLangPath</div>
                            <a class="create-system-comment-edit-link" $disabled href="#" title="$dbLangPath">edit</a>
                        </div>
                    </div>
HTML;
                if (is_array($field->buttons)) {
                    foreach ($field->buttons as $buttonName => &$buttonField) {
                        // $buttonField can be FALSE
                        if ($buttonField) {
                            if (!$buttonField->debugComment) $buttonField->debugComment = $buttonField->partial;
                            $buttonField->fieldComment .= <<<HTML
                                <div class='debug debug-field'>
                                    <div class="title">$buttonName</div>
                                    $buttonField->debugComment
                                </div>
HTML;
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------- Nesting
        // A $relation1to1Path indicates that the caller routine, also this method, wants these fields nested
        // columns.yaml searching and sorting:
        //   Single level 1-1 nesting of primitive columns should be based on relation: location, for sorting and searching
        //   Single level 1-1,1-X should also be based on relation: location, with _multi display, as this also allows searching
        //   relation: based columns should use relationMode columnKey: relation1_relation2_name:
        if ($nestLevel) {
            foreach ($fields as $localFieldName => &$fieldObj) {
                if ($fieldObj->includeContext != 'exclude') {
                    $columnName        = $fieldObj->column?->name;
                    $singleNestParent  = ($nestLevel ? $relation1to1Path[0] : NULL);

                    // TODO: All of this should be moved to the Field class
                    $fieldObj->nested    = TRUE;
                    $fieldObj->nestLevel = $nestLevel;

                    // ----------------------------- Columns.yaml setup
                    // We try to make the column sortable and searchable
                    // RELATION_MODE: relation1_relation2_name: + relation:
                    $fieldObj->searchable = TRUE;
                    $fieldObj->sortable   = TRUE;
                    $fieldObj->canFilter  = FALSE;
                    $nestedColumnKey      = $this->nestedFieldName($localFieldName, $relation1to1Path, self::RELATION_MODE);
                    $fieldObj->relation   = $singleNestParent->name;

                    // Special case #1: Our Event fields
                    // TODO: This should probably be set already in the main fields area: Field::standardFieldSettings() or whatever
                    // select: and relation:
                    if ($topLevelNest && $fieldObj instanceof ForeignIdField && $fieldObj->relation1 && $fieldObj->relation1->to->isAcornEvent()) {
                        // Returns a DateTime object: aacep.start
                        $fieldObj->debugComment .= ' Single level embedded Event.';
                        $fieldObj->valueFrom     = NULL;
                    }

                    // Special case #2: Our User fields
                    // select: and relation:
                    else if ($topLevelNest && $fieldObj instanceof ForeignIdField && $fieldObj->relation1 && $fieldObj->relation1->to->isAcornUser()) {
                        // Returns the User name
                        $fieldObj->debugComment .= ' Single level embedded User.';
                        $fieldObj->valueFrom     = NULL;
                    }

                    // Shallow nesting of normal fields
                    // no select:, just relation: and valueFrom: as the fieldName is RELATION_MODE, not the column name
                    //   legalcase_something_name: with relation: & valueFrom:
                    // Id fields with ?from? relationships will not be included here
                    else if ($topLevelNest && count($fieldObj->relations) == 0) {
                        $fieldObj->sqlSelect     = $columnName; // valueFrom cannot be sorted
                        $fieldObj->debugComment .= ' Single level embedded normal primitive, no to/from relations.';
                    }

                    // NOT SUPPORTED YET
                    /*
                    else if ($topLevelNest && $fieldObj instanceof PseudoFromForeignIdField && $fieldObj->relation1 && $fieldObj->relation1 instanceof RelationXfromX) {
                        print("      ${RED}WARNING${NC}: Rejected tab multi-select for (${GREEN}$nestedColumnKey${NC}) because 1-1 => X-X hasManyDeep is not supported yet\n");
                        unset($fields[$localFieldName]);
                        continue;
                    }
                    */

                    // Deep nesting: legalcase[another_relation][name]:
                    // Cannot shallow nest, so we give up
                    // Id fields with ?from? relationships included here
                    else {
                        // select & valueFrom: does not work with NESTED_MODE
                        // instead, it is inserted to the end of the nested field name
                        // If there is no ...[attribute] then Winter will use the whole field name again
                        $valueFrom = 'name';
                        if (property_exists($fieldObj, 'sqlSelect') && $fieldObj->sqlSelect) {
                            if ($fieldObj->valueFrom) throw new \Exception("select and valueFrom on not allowed on same field [$fieldObj->name]");
                            $valueFrom = $fieldObj->sqlSelect;
                            $fieldObj->sqlSelect = NULL;
                        }
                        else if ($fieldObj->valueFrom) {
                            $valueFrom = $fieldObj->valueFrom;
                            $fieldObj->valueFrom = NULL;
                        }
                        $fieldObj->relation   = NULL;
                        $fieldObj->searchable = FALSE;
                        $fieldObj->sortable   = FALSE;
                        $nestedColumnKey      = $this->nestedFieldName($localFieldName, $relation1to1Path, self::NESTED_MODE, $valueFrom);

                        // Debug
                        $fieldClass           = preg_replace('/.*\\\\/', '', get_class($fieldObj));
                        $relationCount        = count($fieldObj->relations);
                        $relationTo           = (count($fieldObj->relations) ? 'to ' . current($fieldObj->relations)->to->name : '');
                        $fieldObj->debugComment .= " Normal nest of $fieldClass, level $nestLevel with $relationCount relations $relationTo. Searching and Sorting disabled.";
                    }
                    $fieldObj->columnKey = $nestedColumnKey;

                    // ----------------------------- Fields.yaml setup
                    // type: remationmanager does not use nested names
                    // because they relate to config_relation.yaml entries only
                    $isRelationManager  = ($fieldObj->fieldType == 'relationmanager');
                    $nestingMode        = ($isRelationManager ? self::RELATION_MODE : self::NESTED_MODE);
                    $fieldObj->fieldKey = $this->nestedFieldName(
                        $localFieldName,
                        $relation1to1Path,
                        $nestingMode,
                        // nameFrom should not be included in the fields.yaml name:
                        // as it will be applied to the output in the nested scenario
                    );

                    // TODO: dependsOn morphing
                }
            }
        }

        return $fields;
    }

    public function translationKey(bool $plural = self::SINGULAR): string
    {
        /* Translation:
         *  For foreign keys:           acorn.user::lang.models.usergroup.label (pointing TO the user plugin)
         *  For explicit translations:  acorn.finance::lang.models.invoice.user_group: Payee Group
         *  For qualified foreign keys: acorn.finance::lang.models.invoice.payee_user_group (payee_ makes it qualified)
         * is_qualified: Does the field name, [user_group]_id, have the same name as the table it points to, acorn_user_[user_group]s?
         * if not, then it is qualified, and we need a local translation
         */
        $domain   = $this->plugin->translationDomain(); // acorn.user
        $group    = 'models';
        $subgroup = $this->dirName(); // squished usergroup | invoice
        $name     = ($plural ? 'label_plural' : 'label');

        return "$domain::lang.$group.$subgroup.$name";
    }
}
