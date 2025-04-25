<?php namespace Acorn\CreateSystem;

use Acorn\CreateSystem\Relation1to1;
use Acorn\CreateSystem\RelationHasManyDeep;
use Exception;

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
    public $readOnly;

    public $plugin;
    public $table;
    public $name;

    public $comment;
    public $menu = TRUE;
    public $menuSplitter = FALSE;
    public $menuIndent   = 0;
    public $icon;
    public $permissionSettings; // Database column Input settings
    // PHP model methods
    public $attributeFunctions = array();
    public $methods            = array();
    public $staticMethods      = array();

    public $labels;
    public $labelsPlural;

    public $filters;
    public $globalScope; // Limits all related models to here by the selection

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
            // Normalise names
            foreach ($commentDef as $commentName => $commentValue) {
                $camelName = Str::camel($commentName);
                if ($commentName != $camelName) {
                    $commentDef[$camelName] = $commentValue;
                    unset($commentDef[$commentName]);
                }
            }

            $this->actionFunctions[$name] = array_merge(array(
                'fnDatabaseName' => $fnName,
                'parameters'     => $definition['parameters'],
                'returnType'     => $definition['returnType'],
            ), $commentDef);
        }

        // Adopt some of the tables comment statements
        $this->comment = $table->comment;
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) $this->$nameCamel = $value;
        }

        if (!isset($readOnly) && $table instanceof View) $this->readOnly = TRUE;

        // Link back
        $this->table->model = &$this;

        self::$models[$this->fullyQualifiedName()] = &$this;
    }

    public function addController(Controller &$controller)
    {
        if (isset($this->controllers[$controller->name])) 
            throw new Exception("Controller [$controller->name] already exists on Model [$this->name]");
        $this->controllers[$controller->name] = &$controller;
    }

    public function controller(bool $throwIfNotOnly1 = self::THROW_IF_NOT_ONLY_1): Controller|NULL
    {
        $controller = NULL;

        if (count($this->controllers) == 0) {
            if ($throwIfNotOnly1) throw new Exception("No controllers found on [$this->name]");
        } else if (count($this->controllers) > 1) {
            if ($throwIfNotOnly1) throw new Exception("Several controllers found on [$this->name]");
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

    public function isAcornUserGroup(): bool
    {
        return ($this->fullyQualifiedName() == 'Acorn\\User\\Models\\UserGroup');
    }

    public function isKnownAcornPlugin(): bool
    {
        return $this->table->isKnownAcornPlugin();
    }

    public function isSelfReferencingHierarchy(): bool
    {
        $hasSelfReferencingParentColumn = FALSE;
        foreach ($this->relationsSelf() as $relation) {
            if ($relation->column->name == 'parent_id') $hasSelfReferencingParentColumn = TRUE;
        }
        return $hasSelfReferencingParentColumn;
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

    public function standardBareReferencingField(): string
    {
        // For a UserGroup model, we mean a from FK reference of user_group_id
        $subNameSingular = $this->table->subNameSingular();
        if (is_null($subNameSingular)) throw new Exception("$this has no sub-name singular");
        return "{$subNameSingular}_id";
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
        if ($this->plugin->isCreateSystemPlugin()) { // Non-create-system relations require Class::belongsTo
            $previousClass = NULL;
            foreach ($this->relations() as &$relation) {
                $classParts = explode('\\', get_class($relation));
                $class      = end($classParts);
                if ($previousClass != $class) print("{$indentString}  $class:\n");
                $relation->show($indent+2);
                $previousClass = $class;
            }
            
            print("{$indentString}  Fields:\n");
            foreach ($this->fields() as &$field) {
                $field->show($indent+2);
            }
        }
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
            // This modifier is for when we set only the date,
            // using Event::setStartAttribute()
            $is1to1Include = (count($relations) == 1 && end($relations) instanceof Relation1to1);
            if ($is1to1Include) {
                // 1to1 nested include fields.yaml will happen
            } else {
                $modifiers = array(
                    'fieldKeyQualifier' => '[start]',
                    'fieldType'     => 'datepicker',
                    'columnType'    => 'partial',
                    'columnPartial' => 'datetime',
                    'sqlSelect'     => "(select aacep.start from acorn_calendar_event_parts aacep where aacep.event_id = $column->column_name order by aacep.start limit 1)",
                    'autoFKType'    => 'Xto1', // Because these fields also appear on pivot tables, causing them to be XtoXSemi
                    'autoRelationCanFilter' => TRUE,

                    // Filter settings
                    'canFilter'  => TRUE,
                    'filterType' => 'daterange',
                    'yearRange'  => 10,
                    'conditions' => "((select aacep.start from acorn_calendar_event_parts aacep where aacep.event_id = $column->column_name order by start limit 1) between ':after' and ':before')",
                );
            }
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

    // ----------------------------------------- Permissions
    public function allPermissionNames(): array
    {
        // Assemble all model & field permission-settings directives names
        // for Plugin registerPermissions()
        // Return permission names (keys) will be fully-qualified
        //   permission-settings:
        //      trials__access:
        //         labels: 
        //         en: Create a Trial
        $permissions = array();

        if ($this->permissionSettings) {
            foreach ($this->permissionSettings as $permissionDirective => &$config) {
                // Copied from Trait MorphConfig
                $typeParts = explode('=', $permissionDirective);
                $negation  = FALSE;
                if (count($typeParts) == 2) {
                    if ($typeParts[0] == 'NOT') $negation = TRUE;
                    $permissionDirective = $typeParts[1];
                }
                $contextParts = explode('@', $permissionDirective);
                $permContext  = NULL;
                if (count($contextParts) == 2) {
                    $permContext         = $contextParts[1];
                    $permissionDirective = $contextParts[0];
                }
                // End copy

                // Permission keys _must_ be un-qualified in this scenario
                // we prepend the same model plugin that the model is part of
                $qualifiedPermissionName = $permissionDirective;
                $isQualifiedName = (strstr($qualifiedPermissionName, '.') !== FALSE);
                if ($isQualifiedName) {
                    throw new Exception("Model permission [$qualifiedPermissionName] cannot be qualified");
                } else {
                    $pluginDotPath = $this->plugin->dotName();
                    $qualifiedPermissionName = "$pluginDotPath.$qualifiedPermissionName";
                }

                // Dev setting so labels are not necessary
                if (!isset($config['labels'])) {
                    $permissionNameParts = explode('.', $qualifiedPermissionName);
                    $permissionNameLast = end($permissionNameParts);
                    $config['labels'] = array('en' => Str::title($permissionNameLast));
                }

                $permissions[$qualifiedPermissionName] = $config;
            }
        }

        // Printable can have permissions (and a condition)
        if ($this->printable 
            && is_array($this->printable)
            && isset($this->printable['permissions'])
        ) {
            $printPermissions = (is_array($this->printable['permissions']) ? $this->printable['permissions'] : array($this->printable['permissions']));
            foreach ($printPermissions as $permissionDirective => $config) {
                // Permission keys _must_ be un-qualified in this scenario
                // we prepend the same model plugin that the model is part of
                $qualifiedPermissionName = $permissionDirective;
                $isQualifiedName = (strstr($qualifiedPermissionName, '.') !== FALSE);
                if (!$isQualifiedName) {
                    $pluginDotPath = $this->plugin->dotName();
                    $qualifiedPermissionName = "$pluginDotPath.$qualifiedPermissionName";
                }
                $permissions[$qualifiedPermissionName] = $config;
            }
        }
        
        // The field->allPermissionNames() keys are already fully-qualified
        foreach ($this->fields() as &$field) {
            $permissions = array_merge($permissions, $field->allPermissionNames());
        }

        // Check these permissions keys are fully qualified
        foreach ($permissions as $fullyQualifiedKey => &$config) {
            $isQualifiedName = (strstr($fullyQualifiedKey, '.') !== FALSE);
            if (!$isQualifiedName) throw new Exception("Permission [$fullyQualifiedKey] is not qualified");
        }

        return $permissions;
    }

    // ----------------------------------------- Relations
    public function winterModel()
    {
        $modelFQN = $this->fullyQualifiedName();
        if (!class_exists($modelFQN))
            throw new Exception("Call for " . __FUNCTION__ . "() on non-create-system plugin, model [$modelFQN] not loaded");
        return new $modelFQN();
    }

    protected function isRelationConfigToModel(array|string $config, Model $modelTo): bool
    {
        $modelToFQN = $modelTo->fullyQualifiedName();
        return (is_string($config) && $config == $modelToFQN)
            || (isset($config[0]) && $config[0] == $modelToFQN);
    }

    public function relations(Column &$forColumn = NULL): array
    {
        // foreignKeysTo this column (ID)
        $r2 = $this->relations1from1($forColumn); // 1to1
        $r4 = $this->relations1fromX($forColumn); // Xto1
        $r7 = $this->relationsXfromXSemi($forColumn); // XtoXsemi <= semi-pivot
        $r6 = $this->relationsXfromX($forColumn); // XtoX <= pivot
        // foreignKeysFrom this column
        $r0 = $this->relationsHasManyDeep($forColumn);        // ?
        $r1 = $this->relationsSelf($forColumn);   // self
        $r3 = $this->relations1to1($forColumn);   // 1to1
        $r5 = $this->relationsXto1($forColumn);   // Xto1

        $conflicts = array_intersect_key($r0, $r1, $r2, $r3, $r4, $r5, $r6, $r7);
        if (count($conflicts)) 
            throw new Exception("Relation conflicts for [$this]");

        return array_merge($r0, $r1, $r2, $r3, $r4, $r5, $r6, $r7);
    }

    public function relationsSelf(Column &$forColumn = NULL): array
    {
        $relations = array();

        if ($this->plugin->isCreateSystemPlugin()) {
            foreach ($this->table->columns as &$column) {
                foreach ($column->foreignKeysFrom as &$foreignKeyFrom) {
                    if ($foreignKeyFrom->shouldProcess()) {
                        // Returns true also if isLeaf()
                        if ($foreignKeyFrom->isSelfReferencing() && (is_null($forColumn) || $forColumn->name == $column->name)) {
                            $finalContentTable = &$foreignKeyFrom->tableTo;
                            $finalColumnTo     = &$foreignKeyFrom->columnTo;
                            if ($finalContentTable != $this->table)    throw new Exception("Self-referencing [$foreignKeyFrom] on [$this->table.$column] is not to the same table");
                            if (!$finalColumnTo->isTheIdColumn())      throw new Exception("Self-referencing [$foreignKeyFrom] on [$this->table.$column] is not to the id column [$finalColumnTo->name]");
                            $finalModel   = &$finalContentTable->model;
                            $relationName = $foreignKeyFrom->columnFrom->relationName();
                            if (isset($relations[$relationName])) throw new Exception("Relation for [$relationName] already exists on [$this->name] on [$this->table.$column]");
                            $relations[$relationName] = new RelationSelf($relationName, $this, $foreignKeyFrom->columnFrom, $foreignKeyFrom);
                        }
                    }
                }
            }
        } else {
            // Non-create system plugins do not represent their FKs correctly
            // so we need to read the actual class definition, not the database FKs
            $winterModel = $this->winterModel();
            $modelFQN    = $this->fullyQualifiedName();
            foreach ($winterModel->belongsTo as $relationName => &$config) {
                if ($this->isRelationConfigToModel($config, $this) && isset($config['key'])) {
                    $columnFrom       = Column::dummy($this->table, $config['key']);
                    $relations[$relationName] = new RelationSelf($relationName, $this, $columnFrom);
                }
            }
        }

        return $relations;
    }

    public function relations1from1(Column &$forColumn = NULL): array
    {
        // 1-1 & leaf relations
        $relations = array();

        if ($this->plugin->isCreateSystemPlugin()) {
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
                                if (!$finalTableFrom->model)            throw new Exception("Foreign key [$foreignKeyTo] on [$this->table.id] has no to model");
                                if ($finalColumnFrom->isTheIdColumn())  throw new Exception("Foreign 1to1 key [$foreignKeyTo] on [$this->table.id] is from an id column");
                                $finalModel   = &$finalTableFrom->model;
                                $relationName = $foreignKeyTo->columnFrom->fromRelationName();
                                if (isset($relations[$relationName])) throw new Exception("Relation for [$relationName] on [$this->table.id] already exists on [$this->name]");
                                $relations[$relationName] = new Relation1from1($relationName, $this, $finalModel, $foreignKeyTo->columnFrom, $foreignKeyTo);
                            }
                        }
                    }
                }
            }
        } else {
            // TODO: Non-create-system relations
        }

        return $relations;
    }

    public function relations1to1(Column &$forColumn = NULL): array
    {
        // 1-1 & leaf relations
        $relations = array();

        // Non-create system plugins do not declare 1to1 nature
        if ($this->plugin->isCreateSystemPlugin()) {
            // 1 column pointing to the parent content table
            foreach ($this->table->columns as &$column) {
                foreach ($column->foreignKeysFrom as &$foreignKeyFrom) {
                    if ($foreignKeyFrom->shouldProcess()) {
                        // Returns true also if isLeaf()
                        if ($foreignKeyFrom->is1to1() && (is_null($forColumn) || $forColumn->name == $column->name)) {
                            $finalContentTable = &$foreignKeyFrom->tableTo;
                            $finalColumnTo     = &$foreignKeyFrom->columnTo;
                            if (!$finalContentTable->isContentTable()) throw new Exception("Final Content Table of [$foreignKeyFrom] on [$this->table.$column] is not type content");
                            if (!$finalContentTable->model)            throw new Exception("Foreign key [$foreignKeyFrom] on [$this->table.$column] has no to model");
                            if (!$finalColumnTo->isTheIdColumn())      throw new Exception("Foreign 1to1 key [$foreignKeyFrom] on [$this->table.$column] is not to the id column [$finalColumnTo->name]");

                            $finalModel   = &$finalContentTable->model;
                            $relationName = $foreignKeyFrom->columnFrom->relationName();
                            if (isset($relations[$relationName])) throw new Exception("Relation for [$relationName] already exists on [$this->name] on [$this->table.$column]");
                            $relations[$relationName] = ($foreignKeyFrom->isLeaf()
                                ? new RelationLeaf($relationName, $this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom)
                                : new Relation1to1($relationName, $this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom)
                            );
                        }
                    }
                }
            }
        } else {
            // TODO: Non-create-system relations
        }

        return $relations;
    }

    public function relationsHasManyDeep(Column &$forColumn = NULL): array
    {
        // Builds off relations1to1() below
        return $this->recursive1to1Relations($this, $forColumn);
    }

    protected function recursive1to1Relations(Model $forModel, Column $forColumn = NULL, Model $stepModel = NULL, array $throughRelations = array()): array
    {
        if (is_null($stepModel)) $stepModel = $forModel;

        $relations = array();
        foreach ($stepModel->relations1to1($forColumn) as $name => &$relation) {
            $isLeaf       = ($relation instanceof RelationLeaf);
            $nameObject   = $relation->nameObject;
            $modelTo      = &$relation->to;
            $subRelations = array_merge(
                $modelTo->relations1fromX(),
                $modelTo->relationsXfromX(),
                $modelTo->relationsXfromXSemi(),
                $modelTo->relationsSelf(),
                // We also want a relation entry for this 1to1 step
                $modelTo->relations1to1(), 
                // We do not want to chain other sub-HasManyDeep relations
            );
            $thisThroughRelations        = $throughRelations;
            $thisThroughRelations[$name] = $relation; // Still in order for array_keys()

            // Normal relations
            foreach ($subRelations as $subName => &$deepRelation) {
                $subthroughRelations           = $thisThroughRelations;
                $subthroughRelations[$subName] = $deepRelation;
                $subthroughRelationsNames      = array_keys($subthroughRelations);
                $deepName = Model::nestedFieldName('', $subthroughRelationsNames);
                if (isset($relations[$deepName])) 
                    throw new Exception("Conflicting relations with [$deepName] on [$stepModel->name]");

                $relations[$deepName] = new RelationHasManyDeep(
                    $deepName,
                    $forModel,         // model from
                    $deepRelation->to, // model to
                    $relation->column,
                    $relation->foreignKey,
                    // name => relation
                    $subthroughRelations, 
                    $isLeaf,
                    // All steps must be nameObjects
                    ($nameObject && $deepRelation->nameObject), 
                    // Type is important because we can immediately identify 
                    // fully 1to1 deep relations for embedding
                    // 1to1 means all steps are 1to1
                    // because $relation above will only be 1to1 traversal
                    // other (XfromX, etc.) indicates the LAST step only
                    $deepRelation->type()
                );
            }

            // Deep 1to1 relation recursion
            $relations = array_merge($relations, $this->recursive1to1Relations($forModel, NULL, $modelTo, $thisThroughRelations));
        }

        return $relations;
    }

    public function relations1fromX(Column &$forColumn = NULL): array
    {
        $relations = array();

        if ($this->plugin->isCreateSystemPlugin()) {
            // All content tables pointing to this id
            if ($idColumn = $this->table->idColumn()) {
                foreach ($idColumn->foreignKeysTo as &$foreignKeyTo) {
                    if ($foreignKeyTo->shouldProcess()) {
                        if ($foreignKeyTo->isXto1() && (is_null($forColumn) || $forColumn->name == $idColumn->name)) {
                            $finalContentTable = &$foreignKeyTo->tableFrom;

                            // created_at_event_id is 1to1 and can be from a pivot table
                            // so there is no final model to report
                            if (!$finalContentTable->isPivotTable()) {
                                if (!$finalContentTable->isContentTable() 
                                    && !$finalContentTable->isSemiPivotTable()
                                    && !$finalContentTable->isReportTable()
                                )
                                    throw new Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] is not type content");
                                if (!$finalContentTable->model)
                                    throw new Exception("Foreign key from table for [$foreignKeyTo] on [$this->table.id] has no model");
                                $finalModel   = &$finalContentTable->model;
                                $relationName = $foreignKeyTo->columnFrom->fromRelationName();
                                if (isset($relations[$relationName])) throw new Exception("Relation for [$relationName] on [$this->table.id] already exists on [$this->name]");
                                $relations[$relationName] = new Relation1fromX($relationName, $this, $finalModel, $foreignKeyTo->columnFrom, $foreignKeyTo);
                            }
                        }
                    }
                }
            }
        } else {
            // Non-create system plugins do not represent their FKs correctly
            // so we need to read the actual class definition, not the database FKs
            $model = $this->winterModel();
            // TODO: 1fromX class relations
        }
    
        return $relations;
    }

    public function relationsXto1(Column &$forColumn = NULL): array
    {
        $relations = array();

        if ($this->plugin->isCreateSystemPlugin()) {
            // All this tables foreign *_id columns pointing to an id column
            foreach ($this->table->columns as &$column) {
                foreach ($column->foreignKeysFrom as &$foreignKeyFrom) {
                    if ($foreignKeyFrom->shouldProcess()) {
                        if (($foreignKeyFrom->isXto1() || $foreignKeyFrom->isXtoXSemi()) && (is_null($forColumn) || $forColumn->name == $column->name)) {
                            $finalContentTable = &$foreignKeyFrom->tableTo;
                            if ($column->isTheIdColumn())              throw new Exception("Xto1 [$foreignKeyFrom] on [$this->table.$column] from column is id");
                            if (!$foreignKeyFrom->columnTo->isTheIdColumn()) throw new Exception("Xto1 [$foreignKeyFrom] on [$this->table.$column] to column not id");
                            if (!$finalContentTable->isContentTable()) throw new Exception("Final Content Table for [$foreignKeyFrom] on [$this->table.$column] is not type content");
                            if (!$finalContentTable->model)            throw new Exception("Foreign key from table for [$foreignKeyFrom] on [$this->table.$column] has no model");
                            $finalModel   = &$finalContentTable->model;
                            $relationName = $foreignKeyFrom->columnFrom->relationName();
                            if (isset($relations[$relationName])) throw new Exception("Relation for [$relationName] on [$this->table.$column] already exists on [$this->name]");
                            $relations[$relationName] = new RelationXto1($relationName, $this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom);
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
        } else {
            // TODO: Non-create-system relations
        }

        return $relations;
    }

    public function relationsXfromXSemi(Column &$forColumn = NULL): array
    {
        // These are XfromX relations with a pivot table,
        // but also an ID and extra content columns
        $relations = array();

        if ($this->plugin->isCreateSystemPlugin()) {
            // All pivot tables pointing to this id
            if ($idColumn = $this->table->idColumn()) {
                foreach ($idColumn->foreignKeysTo as &$foreignKeyTo) {
                    if ($foreignKeyTo->shouldProcess()) {
                        if ($foreignKeyTo->isXtoXSemi() && (is_null($forColumn) || $forColumn->name == $idColumn->name)) {
                            // We have a pivot table pointing to this id column
                            // Where does its other foreign key point?
                            $pivotTable = &$foreignKeyTo->tableFrom;
                            if (!$pivotTable->isSemiPivotTable()) throw new Exception("Semi-Pivot (Through) table for [$foreignKeyTo] on [$this->table.id] on XtoXSemi is not a semi-pivot table");
                            if (!$pivotTable->hasIdColumn())      throw new Exception("Semi-Pivot (Through) table for [$foreignKeyTo] on [$this->table.id] on XtoXSemi has no ID column");
                            if (!$pivotTable->model)              throw new Exception("Semi-Pivot (Through) table for [$foreignKeyTo] on [$this->table.id] on XtoXSemi has no model");
                            $pivotModel = &$pivotTable->model;

                            // The other throughColumn should have exactly 1 FK pointing to the other content table
                            // However, it is a semi so there may be other foreign IDs. We choose the first in ordinal_position order
                            $throughColumn = $pivotTable->throughColumn($foreignKeyTo->columnFrom, Table::FIRST_ONLY);
                            if (!$throughColumn) throw new Exception("Semi-Pivot Table [$pivotTable->name] has no custom foreign ID columns");
                            if (count($throughColumn->foreignKeysFrom) == 0) throw new Exception("Semi-Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has no foreign keys");
                            if (count($throughColumn->foreignKeysFrom) > 1)  throw new Exception("Semi-Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has multiple foreign keys");

                            $secondForeignKey  = array_values($throughColumn->foreignKeysFrom)[0];
                            $finalContentTable = $secondForeignKey->tableTo;
                            if (!$finalContentTable->isContentTable()) throw new Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] is not type content");
                            if (!$finalContentTable->model)            throw new Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] has no model");
                            $finalModel   = &$finalContentTable->model;

                            $relationName = $foreignKeyTo->columnFrom->fromRelationName(Column::PLURAL);
                            if (!$finalModel) throw new Exception("Foreign key from table on [$foreignKeyTo] has no model");

                            $relations[$relationName] = new RelationXfromXSemi($relationName, $this,
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
        } else {
            // TODO: Non-create-system relations
        }

        return $relations;
    }

    public function relationsXfromX(Column &$forColumn = NULL): array
    {
        $relations = array();

        if ($this->plugin->isCreateSystemPlugin()) {
            // All pivot tables pointing to this id
            if ($idColumn = $this->table->idColumn()) {
                foreach ($idColumn->foreignKeysTo as &$foreignKeyTo) {
                    if ($foreignKeyTo->shouldProcess()) {
                        if ($foreignKeyTo->isXtoX() && (is_null($forColumn) || $forColumn->name == $idColumn->name)) {
                            // We have a pivot table pointing to this id column
                            // Where does its other foreign key point?
                            $pivotTable = &$foreignKeyTo->tableFrom;
                            if (!$pivotTable->isPivotTable()) throw new Exception("Through table for [$foreignKeyTo] on [$this->table.id] on XtoX is not a pivot table");

                            // The other throughColumn should have exactly 1 FK pointing to the other content table
                            $throughColumn = $pivotTable->throughColumn($foreignKeyTo->columnFrom);
                            if (!$throughColumn) throw new Exception("Pivot Table [$pivotTable->name] has no custom foreign ID columns");
                            if (count($throughColumn->foreignKeysFrom) == 0) throw new Exception("Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has no foreign keys");
                            if (count($throughColumn->foreignKeysFrom) > 1)  throw new Exception("Pivot Table for [$foreignKeyTo] on [$this->table.id] through column has multiple foreign keys");

                            $secondForeignKey  = array_values($throughColumn->foreignKeysFrom)[0];
                            $finalContentTable = $secondForeignKey->tableTo;
                            if (!$finalContentTable->isContentTable()) throw new Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] is not type content");
                            if (!$finalContentTable->model)            throw new Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] has no model");
                            $finalModel   = &$finalContentTable->model;
                            $relationName = $foreignKeyTo->columnFrom->fromRelationName(Column::PLURAL);
                            if (!$finalModel) throw new Exception("Foreign key from table on [$foreignKeyTo] on [$this->table.id] has no model");

                            $relations[$relationName] = new RelationXfromX($relationName, $this,
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
        } else {
            // TODO: Non-create-system relations
        }

        return $relations;
    }

    public static function nestedFieldName(string $localFieldName, array $relation1to1Path = array(), bool $relationMode = TRUE, string $valueFrom = NULL): string
    {
        // $localFieldName may be:
        //   a ForeignID, with a valueFrom to show the dropdown list
        //   a normal text field without valueFrom
        // $localFieldName is appended, and $valueFrom will be appended in NESTED_MODE
        if ($localFieldName) array_push($relation1to1Path, $localFieldName);
        if ($valueFrom)      array_push($relation1to1Path, $valueFrom);

        if (!count($relation1to1Path))
            throw new Exception("Request for empty nested field name");

        $nestedFieldName = '';
        foreach ($relation1to1Path as $fieldObj) {
            if ($fieldObj instanceof Field) $fieldObj = $fieldObj->name;
            if (empty($fieldObj))
                throw new Exception("Empty step in [$nestedFieldName]");
            if ($relationMode) {
                // name, [office, location, address] => office_location_address_name
                // For use with relation and select directives
                // searchable and sortable will also work with this
                if ($nestedFieldName) $nestedFieldName .= '_';
                $nestedFieldName .= $fieldObj;
            } else {
                // name, [office, location, address] => office[location][address][name]
                // select does not work with this. It would select the value from the first step, office
                // relation does not work with this
                // searchable and sortable also will not work
                if ($nestedFieldName) $nestedFieldName .= "[$fieldObj]";
                else                  $nestedFieldName .= $fieldObj;
            }
        }

        return $nestedFieldName;
    }

    public static function nameToArray($string)
    {
        // Copied from HtmlHelper
        $result = [$string];

        if (strpbrk($string, '[]') === false) {
            return $result;
        }

        if (preg_match('/^([^\]]+)(?:\[(.+)\])+$/', $string, $matches)) {
            if (count($matches) < 2) {
                return $result;
            }

            $result = explode('][', $matches[2]);
            array_unshift($result, $matches[1]);
        }

        $result = array_filter($result, function ($val) {
            return strlen($val) > 0;
        });

        return $result;
    }

    protected static function arrayToName(array $fieldPath): string
    {
        $fieldName = $fieldPath[0];
        if (count($fieldPath) > 1) {
            $fieldNests = implode('][', array_slice($fieldPath, 1));
            $fieldName .= "[$fieldNests]";
        }
        return $fieldName;
    }

    protected static function nestField(string|array $nest, string|array $fieldName, int &$nestlevel = NULL): string
    {
        if (!is_array($nest))      $nest      = self::nameToArray($nest);
        if (!is_array($fieldName)) $fieldName = self::nameToArray($fieldName);
        $nestedFieldPath = array_merge($nest, $fieldName);
        $nestlevel       = count($nestedFieldPath);
        return self::arrayToName($nestedFieldPath);
    }

    protected static function isNested(string $fieldName): bool
    {
        return (count(self::nameToArray($fieldName)) > 1);
    }

    protected static function isPseudo(string $fieldName): bool
    {
        return ($fieldName && $fieldName[0] == '_');
    }

    protected function fieldsFromYamlConfig(array $fieldsConfigs, array $columnsConfigs, int $tabLocation = NULL): array 
    {
        $fieldObjects = array();
        foreach ($fieldsConfigs as $fieldName => $fieldConfig) {
            $columnConfig = (isset($columnsConfigs[$fieldName]) ? $columnsConfigs[$fieldName] : NULL);
            $fieldObjects[$fieldName] = Field::createFromYamlConfigs($this, $fieldName, $fieldConfig, $columnConfig, $tabLocation);
        }
        return $fieldObjects;
    }

    public function fields(array $relation1to1Path = array()): array
    {
        global $YELLOW, $GREEN, $RED, $NC;

        // TODO: Relations should reference their Fields, not columns
        $plugin = &$this->plugin;
        $fields = array();
        $useRelationManager = TRUE; //!$isNested;

        if ($this->plugin->isCreateSystemPlugin()) {
            // ---------------------------------------------------------------- Database Columns => Fields
            foreach ($this->table->columns as $columnName => &$column) {
                if ($column->shouldProcess()) { // !system && !todo
                    $relations       = $this->relations($column); // Includes HasManyDeep
                    $fieldObj        = Field::createFromColumn($this, $column, $relations);

                    // Debug
                    $fieldClassParts = explode('\\', get_class($fieldObj));
                    $fieldClass      = end($fieldClassParts);
                    $fieldObj->debugComment = "$fieldClass for column $column->column_name on $plugin->name.$this->name";
                    
                    if ($fieldObj instanceof ForeignIdField) {
                        // 1to1, leaf & hasManyDeep(1to1) relations.
                        // Known AA plugins are Final
                        // they do not continue 1to1 hasManyDeep recursion
                        if ($relations1to1 = $fieldObj->relations1to1()) {
                            $nextRelation1to1Path = $relation1to1Path; // Local scope
                            array_push($nextRelation1to1Path, $fieldObj);
                            $nestLevel          = count($nextRelation1to1Path);
                            $topLevelNest       = ($nestLevel == 1);
                            
                            foreach ($relations1to1 as $relation1to1Name => &$relation1to1) {
                                // Static 1to1 whole form/list include
                                //   fields.yaml:  entity[user_group][name]
                                //   columns.yaml: name: name, relation: entity_user_group
                                
                                if ($relation1to1 instanceof RelationHasManyDeep && $topLevelNest) {
                                    // -------------------------------------------------- Nested columns
                                    // HasManyDeep only
                                    // HasManyDeep should include the immediate 1-1 level, and chained 1-1 levels
                                    // This allows sorting and searching of 1-1 relation columns
                                    // that is not possible with nested 1-1 columns
                                    // RELATION_MODE: relation: <has_many_deep_name>
                                    //
                                    // This call also returns Fields from non-create-system Yaml. See below
                                    // NOT RECURSIVE: topLevelNest only
                                    $relation1to1Fields = $relation1to1->to->fields($nextRelation1to1Path);

                                    foreach ($relation1to1Fields as $subFieldName => $subFieldObj) {
                                        // Exclude fields that have the same local name as fields in the parent form
                                        // this naturally exlcudes id and created_*
                                        // TODO: created_* is not being excluded
                                        $isDuplicateField  = isset($fields[$subFieldObj->name]);
                                        $includeContext    = ($subFieldObj->includeContext != 'no-include');
                                        // Pseudo fields relate to dependsOn as well
                                        // but are for form functionality and should not interfere
                                        $isPseudoFieldName = self::isPseudo($subFieldName);
                                        // We could change the id name to also allow them...
                                        $isSpecialField    = ($subFieldName == 'id');
                                        // We cannot do anything with nested fields
                                        $isAlreadyNested   = self::isNested($subFieldName);
                                        // Sub relation fields should generate another HasManyDeep and include them
                                        $hasSubRelation    = isset($subFieldObj->relation);
                                        // Normal field
                                        $noRelations       = (count($subFieldObj->relations) == 0);
                                        
                                        if (!$isSpecialField
                                            && $includeContext 
                                            && !$isDuplicateField
                                            && !$isPseudoFieldName
                                            && !$hasSubRelation
                                            && !$isAlreadyNested
                                        ) {
                                            $subFieldObj->columnKey = $subFieldName;
                                            $subFieldObj->relation  = $relation1to1Name;
                                            // Custom relation scopes based on relations, not SQL
                                            // Will set filter[relationCondition] = <the name of the relevant relation>, e.g. belongsTo['language']
                                            // Filters the listed models based on a filtered: of selected related models
                                            // Probably because it is nested
                                            // TODO: This is actually the _un-nested_ relation
                                            // TODO: Write these in to the Model Relations, not here
                                            $subFieldObj->useRelationCondition = TRUE;

                                            // Special case: Our Event & User fields
                                            // TODO: This should probably be set already in the main fields area: Field::standardFieldSettings() or whatever
                                            if ($relation1to1->to->isAcornEvent()) {
                                                // Returns a DateTime object: aacep.start
                                                $subFieldObj->debugComment .= ' Single level embedded Event.';
                                                $subFieldObj->valueFrom     = NULL;
                                            }    
                                            else if ($relation1to1->to->isAcornUser()) {
                                                // Returns the User name
                                                $subFieldObj->debugComment .= ' Single level embedded User.';
                                                $subFieldObj->valueFrom     = NULL;
                                            }    
                                            else if ($relation1to1->to->isAcornUserGroup()) {
                                                // Returns the User name
                                                $subFieldObj->debugComment .= ' Single level embedded User.';
                                                $subFieldObj->valueFrom     = NULL;
                                            }    

                                            // Shallow nesting of normal fields
                                            // no select:, just relation: and valueFrom: 
                                            // as the fieldName is RELATION_MODE, not the column name
                                            //   legalcase_something_name: with relation: & valueFrom:
                                            // Id fields with ?from? relationships will not be included here    
                                            else if ($noRelations) {
                                                if (!isset($subFieldObj->sqlSelect)) {
                                                    // valueFrom cannot be sorted
                                                    // UnQualified 'name' will cause ambiguity
                                                    $subFieldObj->sqlSelect = $subFieldObj->column->fullyQualifiedName(); 
                                                }    
                                                $subFieldObj->debugComment .= ' Single level embedded normal primitive, no to/from relations.';
                                            }    

                                            // NOT SUPPORTED YET
                                            /*
                                            else if ($subFieldObj instanceof PseudoFromForeignIdField 
                                                && $relation1to1 instanceof RelationXfromX
                                            ) {
                                                print("      {$RED}WARNING{$NC}: Rejected tab multi-select for ({$GREEN}$nestedColumnKey{$NC}) because 1-1 => X-X hasManyDeep is not supported yet\n");
                                                unset($fields[$localFieldName]);
                                                continue;
                                            }    
                                            */

                                            // Unhandled
                                            else {
                                                throw new Exception("[$subFieldName] not handled");
                                            }

                                            $fields[$subFieldName] = $subFieldObj;
                                        }
                                    }
                                }

                                else if ($relation1to1 instanceof Relation1to1) {
                                    // -------------------------------------------------- Nested fields
                                    // Requires full recursive embedding
                                    // stepping along the chain 1-1 belongsTo relations
                                    // A $relation1to1Path indicates that the caller routine, also this method, wants these fields nested
                                    // TODO: dependsOn morphing
                                    // TODO: All of this should be moved to the Field class
                                    // RECURSIVE!!
                                    $relation1to1Fields = $relation1to1->to->fields($nextRelation1to1Path);

                                    foreach ($relation1to1Fields as $subFieldName => $subFieldObj) {
                                        // Exclude fields that have the same local name as fields in the parent form
                                        // this naturally exlcudes id and created_*
                                        // TODO: created_* is not being excluded
                                        $includeContext    = ($subFieldObj->includeContext != 'no-include');
                                        // Pseudo fields relate to dependsOn as well
                                        // but are for form functionality and should not interfere
                                        $isPseudoFieldName = self::isPseudo($subFieldName);
                                        $isDuplicateField  = isset($fields[$subFieldObj->name]);
                                        // We could change the id name to also allow them...
                                        $isSpecialField    = ($subFieldName == 'id');
                                        $isAlreadyNested   = self::isNested($subFieldName);
                                        
                                        if (!$isSpecialField
                                            && $includeContext 
                                            && !$isDuplicateField
                                            && !$isPseudoFieldName
                                        ) {
                                            $subFieldObj->nested     = TRUE;
                                            $subFieldObj->nestLevel  = $nestLevel;
                                            // Prevent this field displaying as a column
                                            // canDisplayAsColumn() checks columnType
                                            $subFieldObj->columnType = NULL;
                                            
                                            // type: remationmanager does not use nested names
                                            // because they relate to config_relation.yaml entries only
                                            $isRelationManager     = ($subFieldObj->fieldType == 'relationmanager');
                                            $nestingMode           = ($isRelationManager ? self::RELATION_MODE : self::NESTED_MODE);
                                            $subFieldObj->fieldKey = $this->nestedFieldName(
                                                $subFieldName,
                                                $nextRelation1to1Path,
                                                $nestingMode,
                                                // nameFrom should not be included in the fields.yaml name:
                                                // as it will be applied to the output in the nested scenario
                                            );    
                                            $fields[$subFieldObj->fieldKey] = $subFieldObj;
                                        }
                                    }
                                }
                            }
                        } 
                    } else {
                        // Direct entry in fields array
                        $fields[$fieldObj->name] = $fieldObj;
                    }
                }
            }
        } else {
            // ---------------------------------------------------------------- Yaml => Fields
            // Load the config yaml files
            $fieldsPath       = $this->plugin->framework->modelFileDirectoryPath($this, 'fields.yaml');
            $subFieldsConfig  = $this->plugin->framework->yamlFileLoad($fieldsPath, Framework::NO_CACHE, Framework::THROW);
            $subFieldsConfig  = (object) $subFieldsConfig;
            print("      Loaded {$YELLOW}$fieldsPath{$NC}\n");
            $columnsPath      = $this->plugin->framework->modelFileDirectoryPath($this, 'columns.yaml');
            $subColumnsConfig = $this->plugin->framework->yamlFileLoad($columnsPath, Framework::NO_CACHE, Framework::THROW);
            $subColumnsConfig = (object) $subColumnsConfig;
            print("      Loaded {$YELLOW}$columnsPath{$NC}\n");

            // Inject fields, and tab fields
            if (property_exists($subFieldsConfig, 'fields')) {
                $subFields = $this->fieldsFromYamlConfig($subFieldsConfig->fields, $subColumnsConfig->columns);
                $fields    = array_merge($fields, $subFields);
            }
            if (property_exists($subFieldsConfig, 'tabs') && isset($subFieldsConfig->tabs['fields'])) {
                $subFields = $this->fieldsFromYamlConfig($subFieldsConfig->tabs['fields'], $subColumnsConfig->columns, 1);
                $fields    = array_merge($fields, $subFields);
            }
            if (property_exists($subFieldsConfig, 'secondaryTabs') && isset($subFieldsConfig->secondaryTabs['fields'])) {
                $subFields = $this->fieldsFromYamlConfig($subFieldsConfig->secondaryTabs['fields'], $subColumnsConfig->columns, 2);
                $fields    = array_merge($fields, $subFields);
            }
            if (property_exists($subFieldsConfig, 'tertiaryTabs') && isset($subFieldsConfig->tertiaryTabs['fields'])) {
                $subFields = $this->fieldsFromYamlConfig($subFieldsConfig->tertiaryTabs['fields'], $subColumnsConfig->columns, 3);
                $fields    = array_merge($fields, $subFields);
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
        print("    Relations:\n");
        foreach ($this->relationsSelf() as $name => &$relation) {
            $nameFrom  = 'fully_qualified_name';
            $tab       = $relation->from->translationKey(Model::PLURAL); // Reverse relation, so it is from!
            $relations = array($name => $relation);
            $comment     = '';
            if ($relation->status == 'broken') continue;

            print("      Creating tab multi-select for {$YELLOW}$relation{$NC}\n");
            $fieldObj  = new PseudoFromForeignIdField($this, array(
                '#'            => "Tab multi-select for $relation",
                'name'         => 'children',
                'labels'       => $relation->labelsPlural,
                'fieldType'    => ($useRelationManager ? 'relationmanager' : 'relation'),
                'nameFrom'     => $nameFrom,
                'cssClasses'   => $relation->cssClass('single-tab-self', $useRelationManager),
                'tabLocation'  => $relation->tabLocation,
                'debugComment' => "Tab multi-select for $relation on $plugin->name.$this->name",
                'commentHtml'  => TRUE,
                'relatedModel' => $relation->to->fullyQualifiedName(),
                'comment'      => $relation->comment,
                'icon'         => $relation->to->icon,
                'tab'          => $tab,
                'dependsOn'    => array('_paste' => TRUE),
                'readOnly'     => $relation->readOnly,
                'multi'        => $relation->multi,
                // TODO: Select and Add ButtonFields
                // TODO: Create button popup

                // List
                'columnType'    => 'partial',
                'columnPartial' => 'multi',
                'searchable'    => FALSE, // These fields don't exist
            ), $relations);
            $fields['children'] = $fieldObj;
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

            print("      Creating tab multi-select for {$YELLOW}$relation{$NC}\n");
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
                'cssClasses'   => $relation->cssClass('single-tab-1fromX', $useRelationManager),
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
                'readOnly'     => $relation->readOnly,
                'multi'        => $relation->multi,
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

            print("      Creating tab multi-select for {$YELLOW}$relation{$NC}\n");
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
                'cssClasses'     => $relation->cssClass('single-tab-1fromX', $useRelationManager),
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
                'readOnly'       => $relation->readOnly,
                'tab'            => 'INHERIT',
                'multi'          => $relation->multi,
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
            //$comment     = "create new <a href='#' class='popup-add' data-field-name='$dataFieldName' data-handler='onPopupRoute' data-request-data=\"route:'{$table_from_controller//\\/\\\\}@create',fieldName:'$dataFieldName'\" data-control='popup' tabindex='-1'>{$table_from_name_singular//_/-}</a>"
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

            print("    Creating tab multi-select with ({$GREEN}create button{$NC}) for {$YELLOW}$relation{$NC}\n");
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
                'cssClasses'     => $relation->cssClass('single-tab-XfromX', $useRelationManager),
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
                'readOnly'       => $relation->readOnly,
                'tab'            => $tab,
                'multi'          => $relation->multi,
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
        }

        // ---------------------------------------------------------------- QR code support fields
        print("    Injecting _qrcode field\n");
        // TODO: Move to QRCode FormField when available
        $fields['_qrcode'] = new PseudoField($this, array(
            'name'        => '_qrcode',
            'isStandard'  => TRUE,
            'fieldType'   => 'partial',
            'contexts'    => array('update' => TRUE, 'preview' => TRUE),
            'span'        => 'storm',
            'tabLocation' => 3,
            'cssClasses'  => array('bottom'),
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
        print("    Injecting list actions column\n");
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

        return $fields;
    }

    public function localTranslationKey(): string
    {
        $group    = 'models';
        $subgroup = $this->dirName(); // squished usergroup | invoice
        return "$group.$subgroup";
    }

    public function translationDomain(): string
    {
        /* Translation:
         *  For foreign keys:           acorn.user::lang.models.usergroup.label (pointing TO the user plugin)
         *  For explicit translations:  acorn.finance::lang.models.invoice.user_group: Payee Group
         *  For qualified foreign keys: acorn.finance::lang.models.invoice.payee_user_group (payee_ makes it qualified)
         * is_qualified: Does the field name, [user_group]_id, have the same name as the table it points to, acorn_user_[user_group]s?
         * if not, then it is qualified, and we need a local translation
         */
        $domain = $this->plugin->translationDomain(); // acorn.user
        $localTranslationKey = $this->localTranslationKey();
        return "$domain::lang.$localTranslationKey";
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
        $domain   = $this->translationDomain(); // acorn.user::lang.models.user
        $name     = ($plural ? 'label_plural' : 'label');

        return "$domain.$name";
    }
}
