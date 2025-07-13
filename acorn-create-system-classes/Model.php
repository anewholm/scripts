<?php namespace Acorn\CreateSystem;

use Acorn\CreateSystem\Relation1to1;
use Acorn\CreateSystem\RelationHasManyDeep;
use Exception;

require_once('Relation.php');
require_once('Field.php');

class Model {
    protected static $models = array();

    public const PRINT     = TRUE;
    public const NO_OUTPUT = FALSE;
    public const PLURAL    = TRUE;
    public const SINGULAR  = FALSE;
    public const THROW_IF_NOT_ONLY_1 = TRUE;
    public const NULL_IF_NOT_ONLY_1  = FALSE;
    public const RELATION_MODE = TRUE;
    public const NESTED_MODE   = FALSE;
    public const NO_VALUE_FROM = NULL;
    public const RECURSING     = TRUE;
    public const WITH_HAS_MANY_DEEP     = TRUE;
    public const NO_HAS_MANY_DEEP     = FALSE;
    public const WITH_FROMS = TRUE;
    public const NO_FROMS = FALSE;

    public $controllers = array();
    public $actionFunctions;
    public $printable;
    public $readOnly;
    public $defaultSort;
    public $showSorting;
    public $qrCodeScan;

    public $plugin;
    protected $table; // To mimick Winter Models. See getTable()
    public $name;

    public $comment;
    public $menu = TRUE;
    public $menuSplitter = FALSE;
    public $menuIndent   = 0;
    public $icon;
    // Assemble all field permission-settings directives names
    // for Plugin registerPermissions()
    // Permission names (keys) are fully-qualified
    //   permission-settings:
    //      NOT=legalcases__owner_user_group_id__update@update:
    //         field:
    //         readOnly: true
    //         disabled: true
    //         labels: 
    //           en: Update owning Group
    public $permissionSettings; // Database column Input settings
    // PHP model methods
    public $attributeFunctions = array();
    public $methods            = array();
    public $staticMethods      = array();

    public $labels;
    public $labelsPlural;

    public $filters;
    public $globalScope; // Limits all related models to here by the selection
    public $import;
    public $export;
    public $batchPrint;

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
            $fnNameBare  = str_replace($this->table->subName(), 'table', $fnName);
            $fnNameParts = explode('_', $fnNameBare);
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

        if (!isset($this->readOnly) && $table instanceof View) $this->readOnly = TRUE;

        // Link back
        $this->table->model = &$this;

        self::$models[$this->fullyQualifiedName()] = &$this;
    }

    public static function get(string $modelFQN): self|NULL
    {
        return (isset(self::$models[$modelFQN]) ? self::$models[$modelFQN] : NULL);
    }

    public function getFromTable(string $tableName, bool $createIfNotFound = TRUE): self|NULL
    {
        $model = NULL;
        foreach (self::$models as &$searchModel) {
            if ($searchModel->getTable() == $tableName) {
                $model = &$searchModel;
                break;

            }
        }
        if (!$model && $createIfNotFound) {
            $table = Table::get($tableName);
            $model = new Model($this->plugin, $table);
        }
        return $model;
    }

    public function getTable(): Table
    {
        return $this->table;
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
    public function is(Model $other): bool
    {
        return ($this->fullyQualifiedName() == $other->fullyQualifiedName());
    }

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

    public function hasSelfReferencingRelations(): bool
    {
        $hasSelfReferencingRelations = FALSE;
        foreach ($this->relations() as $relation) {
            if ($relation->isSelfReferencing()) {
                $hasSelfReferencingRelations = TRUE;
                break;
            }
        }
        return $hasSelfReferencingRelations;
    }

    public function hasAttribute(string $name): bool
    {
        // Alias for hasField()
        return $this->hasField($name);
    }

    public function hasField(string $name): bool
    {
        return $this->table->hasColumn($name);
    }

    public function hasMethod(string $name): bool
    {   
        return isset($this->methods[$name]);
    }

    public function hasNameAttributeMethod(): bool
    {
        return $this->hasAttributeMethod('name');
    }

    public function hasAttributeMethod(string $name): bool
    {   
        return isset($this->attributeFunctions[$name]);
    }

    public function attributeFunctions(): array
    {
        $attributeFunctions = $this->attributeFunctions;

        // Auto getNameAttribute() following name relation(s)
        if (   !$this->hasNameAttributeMethod() 
            && !$this->table->hasColumn('name')
        ) {
            // FALSE = plain text, delimeter = ::
            $attributeFunctions['name'] = "return \$this->buildNameFromRelations();";
        }
        if (!$this->hasAttributeMethod('htmlName')
            && !$this->table->hasColumn('html_name')
        ) {
            // TRUE = HTML, delimeter = ::
            $attributeFunctions['htmlName'] = "return \$this->buildNameFromRelations(TRUE);";
        }

        return $attributeFunctions;
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
            foreach ($this->fields(self::PRINT) as &$field) {
                $field->show($indent+2);
            }
        }
    }

    public function dropdownOptionsCall(): string
    {
        $absoluteFullyQualifiedName = $this->absoluteFullyQualifiedName();
        return "$absoluteFullyQualifiedName::dropdownOptions";
    }

    public function fullyQualifiedDotName():string
    {
        $pluginDirName = $this->plugin->dotName();
        $dirName = $this->dirName();
        return "$pluginDirName.$dirName";
    }

    public function permissionFQN(): string
    {
        return $this->fullyQualifiedDotName();
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
                    'filterConditions' => "((select aacep.start from acorn_calendar_event_parts aacep where aacep.event_id = $column->column_name order by start limit 1) between ':after' and ':before')",
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

        // Standard view menu item
        // acorn.university.entity
        $view           = 'View';
        $menuitemPlural = Str::plural(Str::title($this->name));
        $permissions[$this->permissionFQN()] = array(
            'labels' => array('en' => "$view $menuitemPlural")
        );

        if ($this->permissionSettings) {
            foreach ($this->permissionSettings as $permissionDirective => $config) {
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
        foreach ($permissions as $fullyQualifiedKey => $config) {
            $isQualifiedName = (strstr($fullyQualifiedKey, '.') !== FALSE);
            if (!$isQualifiedName) throw new Exception("Permission [$fullyQualifiedKey] is not qualified");
        }

        return $permissions;
    }

    // ----------------------------------------- Relations
    public function winterModel(bool $throwIfNotFound = TRUE, string $modelFQN = NULL): object|null
    {
        if (!$modelFQN) $modelFQN = $this->fullyQualifiedName();
        $classExists = class_exists($modelFQN);
        if (!$classExists && $throwIfNotFound)
            throw new Exception("Call for " . __FUNCTION__ . "() on non-create-system plugin, model [$modelFQN] not loaded");
        return ($classExists ? new $modelFQN() : NULL);
    }

    protected function relationConfigModelFQN(array|string $relationConfig): string
    {
        $modelFQN = (is_string($relationConfig) ? $relationConfig
            : (isset($relationConfig[0]) ? $relationConfig[0] 
            : NULL
        ));
        return $modelFQN;
    }

    protected function relationConfigModel(array|string $relationConfig): self|NULL
    {
        $modelFQN = $this->relationConfigModelFQN($relationConfig);
        $model    = self::get($modelFQN);
        return $model;
    }

    protected function isRelationConfigModelTo(array|string $relationConfig, Model $modelTo): bool
    {
        $checkModelToFQN    = $modelTo->fullyQualifiedName();
        $relationModelToFQN = $this->relationConfigModelFQN($relationConfig);
        return ($relationModelToFQN == $checkModelToFQN);
    }

    public function relations(
        Column &$forColumn   = NULL, 
        bool $andHasManyDeep = self::WITH_HAS_MANY_DEEP, 
        bool $andFroms       = self::WITH_FROMS
    ): array {
        // Forieng table foreignKeysTo pointing to this table/column(id)
        $r2 = ($andFroms ? $this->relations1from1($forColumn) : array()); // 1to1
        $r4 = ($andFroms ? $this->relations1fromX($forColumn) : array()); // Xto1
        $r7 = ($andFroms ? $this->relationsXfromXSemi($forColumn) : array()); // XtoXsemi <= semi-pivot
        $r6 = ($andFroms ? $this->relationsXfromX($forColumn) : array()); // XtoX <= pivot
        // Local table foreignKeysFrom from this column (*_id) pointing to a foreign table/column(id)
        $r3 = $this->relations1to1($forColumn);   // 1to1
        $r5 = $this->relationsXto1($forColumn);   // Xto1
        $r0 = ($andHasManyDeep ? $this->relationsHasManyDeep($forColumn) : array());        // ?

        $conflicts = array_intersect_key($r0, $r2, $r3, $r4, $r5, $r6, $r7);
        if (count($conflicts)) 
            throw new Exception("Relation conflicts for [$this]");

        return array_merge($r0, $r2, $r3, $r4, $r5, $r6, $r7);
    }

    public function relations1from1(Column &$forColumn = NULL): array
    {
        // $foreignKeysTo this column
        // All foreign $tableFrom ForeignIdField(*_id) $columns 
        // pointing to (1-1) $this->table ($tableTo) $columnTos(id)
        // The DB-FK-to is located on the foreign $tableFrom->columnFrom(*_id)
        // All from relations always point to $this->table->idColumn() only
        // Same as the relationsXto1() below, but FK comment annotated as type: 1to1
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
                                $relationName = $foreignKeyTo->fromRelationName();
                                if (isset($relations[$relationName])) throw new Exception("Relation for [$relationName] on [$this->table.id] already exists on [$this->name]");
                                $relations[$relationName] = new Relation1from1($relationName, $this, $finalModel, $foreignKeyTo->columnFrom, $foreignKeyTo);
                            }
                        }
                    }
                }
            }
        } else {
            // Non-create-system relations
            // cannot have 1-1 relations
            // because there is no annotation
            // to distinguish them from X-1
        }

        return $relations;
    }

    public function relations1to1Name(Column &$forColumn = NULL): array
    {
        $relationsName = array();
        foreach ($this->relations1to1($forColumn) as $name => $relation) {
            if ($relation->isNameObject()) $relationsName[$name] = $relation;
        }
        return $relationsName;
    }

    public function relationsName(Column &$forColumn = NULL): array
    {
        $relationsName = array();
        foreach ($this->relations($forColumn, Model::NO_HAS_MANY_DEEP, Model::NO_FROMS) as $name => $relation) {
            if ($relation->isNameObject()) $relationsName[$name] = $relation;
        }
        return $relationsName;
    }

    public function relations1to1(Column &$forColumn = NULL): array
    {
        // 1-1 & leaf relations
        // $foreignKeysFrom this column: All $this->table's ($tableFrom) ForeignIdField(*_id) $columns 
        // pointing to (1-1) foreign $tableTo $columnTos(id)
        // The DB-FK-to is located on $this->table->column(*_id)
        // Same as the relationsXto1() below, but FK comment annotated as type: 1to1
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
            // Non-create-system relations
            // cannot have 1-1 relations
            // because there is no annotation
            // to distinguish them from X-1
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
        global $YELLOW, $GREEN, $RED, $NC;

        if (is_null($stepModel)) $stepModel = $forModel;

        $relations = array();
        // relations1to1() returns empty for non-Create-System models
        foreach ($stepModel->relations1to1($forColumn) as $name => $relation) {
            $isLeaf       = ($relation instanceof RelationLeaf);
            $nameObject   = $relation->nameObject;
            $modelTo      = &$relation->to;
            $subRelations = array_merge(
                $modelTo->relations1fromX(),
                $modelTo->relationsXfromX(),
                $modelTo->relationsXfromXSemi(),
                // We also want a relation entry for this 1to1 step
                $modelTo->relations1to1(), 
                // We do not want to chain other sub-HasManyDeep relations
            );
            $thisThroughRelations        = $throughRelations;
            $thisThroughRelations[$name] = $relation; // Still in order for array_keys()

            // Normal relations
            foreach ($subRelations as $subName => $deepRelation) {
                $subthroughRelations           = $thisThroughRelations;
                $subthroughRelations[$subName] = $deepRelation;
                $subthroughRelationsNames      = array_keys($subthroughRelations);
                $deepName = Model::nestedFieldName($subthroughRelationsNames);
                if (isset($relations[$deepName])) 
                    throw new Exception("Conflicting relations with [$deepName] on [$stepModel->name]");

                if ($deepRelation->conditions)
                    print("      {$RED}WARNING{$NC}: Relation HasManyDeep $deepName has conditions\n");

                $relations[$deepName] = new RelationHasManyDeep(
                    $deepName,
                    $forModel,       // model from
                    $deepRelation->to, // model to
                    $relation->column,
                    // If the last relation has a real FK, use it, for the comment
                    // otherwise use this first one
                    $deepRelation->foreignKey ?: $relation->foreignKey,
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
                    $deepRelation->type(),
                    $deepRelation->conditions
                );
            }

            // Deep 1to1 relation recursion
            $relations = array_merge($relations, $this->recursive1to1Relations($forModel, NULL, $modelTo, $thisThroughRelations));
        }

        return $relations;
    }

    public function relations1fromX(Column &$forColumn = NULL): array
    {
        // $foreignKeysTo this column
        // All foreign $tableFrom ForeignIdField(*_id) $columns 
        // pointing to (X-1) $this->table ($tableTo) $columnTos(id)
        // The DB-FK-to is located on the foreign $tableFrom->columnFrom(*_id)
        // All from relations always point to $this->table->idColumn() only
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
                                if (   !$finalContentTable->isContentTable() 
                                    && !$finalContentTable->isSemiPivotTable()
                                    && !$finalContentTable->isReportTable()
                                )
                                    throw new Exception("Final Content Table for [$foreignKeyTo] on [$this->table.id] is not type content");
                                if (!$finalContentTable->model)
                                    throw new Exception("Foreign key from table for [$foreignKeyTo] on [$this->table.id] has no model");
                                $finalModel   = &$finalContentTable->model;
                                $relationName = $foreignKeyTo->fromRelationName();
                                if (isset($relations[$relationName])) 
                                    throw new Exception("Relation for [$relationName] on [$this->table.id] already exists on [$this->name]");
                                $relations[$relationName] = new Relation1fromX($relationName, $this, $finalModel, $foreignKeyTo->columnFrom, $foreignKeyTo);
                            }
                        }
                    }
                }
            }
        } else {
            // Non-create system plugins do not represent their FKs correctly
            // so we need to read the actual class definition relations, not the database FKs
            if ($winterModel = $this->winterModel(FALSE)) {
                foreach ($winterModel->hasMany as $relationName => $config) {
                    // If the relation config has a ModelTo setting, usually config[0]
                    $finalModel = $this->relationConfigModel($config);
                    $key        = (isset($config['key']) ? $config['key'] : $this->standardBareReferencingField());
                    $conditions = (isset($config['conditions']) ? $config['conditions'] : NULL);
                    $columnFrom = Column::dummy($finalModel->table, $key);
                    if (is_null($forColumn) || $forColumn->name == $columnFrom->name)
                        $relations[$relationName] = new RelationXto1($relationName, $this, $finalModel, $columnFrom, NULL, FALSE, $conditions);
                }
            }
        }
    
        return $relations;
    }

    public function relationsXto1(Column &$forColumn = NULL): array
    {
        // $foreignKeysFrom this column: All $this->table's ($tableFrom) ForeignIdField(*_id) $columns 
        // pointing to (X-1) foreign $tableTo $columnTos(id)
        // The DB-FK-to is located on $this->table->column(*_id)
        $relations = array();

        if ($this->plugin->isCreateSystemPlugin()) {
            foreach ($this->table->columns as &$column) {
                foreach ($column->foreignKeysFrom as &$foreignKeyFrom) {
                    if ($foreignKeyFrom->shouldProcess()) {
                        if (($foreignKeyFrom->isXto1() || $foreignKeyFrom->isXtoXSemi()) 
                            && (is_null($forColumn) || $forColumn->name == $column->name)
                        ) {
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
        } else {
            // Non-create system plugins do not represent all their FKs necessarily, 
            // nor with our or standard naming conventions
            // so we need to read the actual class definition relations, not the database FKs
            if ($winterModel = $this->winterModel(FALSE)) {
                foreach ($winterModel->belongsTo as $relationName => $config) {
                    // If the relation config has a ModelTo setting, usually config[0]
                    $finalModel = $this->relationConfigModel($config);
                    $isCount    = (isset($config['count']) && $config['count']);
                    $table      = NULL;
                    if ($finalModel) {
                        $table = $finalModel->getTable();
                    } else {
                        $modelFQN   = $this->relationConfigModelFQN($config);
                        $finalModel = $this->winterModel(TRUE, $modelFQN);
                        // Winter Model $table is protected
                        $table      = Table::get($finalModel->getTable());
                    }
                    $key        = (isset($config['key']) ? $config['key'] : $this->standardBareReferencingField());
                    $conditions = (isset($config['conditions']) ? $config['conditions'] : NULL);
                    $columnFrom = Column::dummy($table, $key);
                    if (is_null($forColumn) || $forColumn->name == $columnFrom->name)
                        $relations[$relationName] = new RelationXto1($relationName, $this, $finalModel, $columnFrom, NULL, $isCount, $conditions);
                }
            }
        }

        return $relations;
    }

    public function relationsXfromXSemi(Column &$forColumn = NULL): array
    {
        // $foreignKeysTo this column from a pivot table:
        // All foreign $tableFrom ForeignIdField(*_id) $columns 
        // pointing to (X-1) $this->table ($tableTo) $columnTos(id)
        // The DB-FK-to is located on the foreign $tableFrom->columnFrom(*_id) pivot table
        // All from relations always point to $this->table->idColumn() only

        // These X*X relations have a pivot table with an ID and extra content columns
        // So the DB-FK tableFrom is a pivot table
        // but the finalModel is the _other_ content table, that the pivot table points to
        // See: $pivotTable->throughColumn($foreignKeyTo->columnFrom, Table::FIRST_ONLY);
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

                            $relationName = $foreignKeyTo->fromRelationName(Column::PLURAL);
                            if (!$finalModel) throw new Exception("Foreign key from table on [$foreignKeyTo] has no model");

                            $relations[$relationName] = new RelationXfromXSemi($relationName, $this,
                                $finalModel,               // User
                                $pivotModel,               // LegalcaseProsecutor
                                $foreignKeyTo->columnFrom, // pivot.user_group_id
                                $throughColumn,            // pivot.user_id
                                $foreignKeyTo
                            );
                        }
                    }
                }
            }
        } else {
            // Non-create-system relations
            // are loaded as XfromX, not XtoXSemi
        }

        return $relations;
    }

    public function relationsXfromX(Column &$forColumn = NULL): array
    {
        // $foreignKeysTo this column from a pivot table:
        // All foreign $tableFrom ForeignIdField(*_id) $columns 
        // pointing to (X-1) $this->table ($tableTo) $columnTos(id)
        // The DB-FK-to is located on the foreign $tableFrom->columnFrom(*_id) pivot table
        // All from relations always point to $this->table->idColumn() only

        // These X*X relations have a standard simple 2-FK pivot table
        // So the DB-FK tableFrom is a pivot table
        // but the finalModel is the _other_ content table, that the pivot table points to
        // See: $pivotTable->throughColumn($foreignKeyTo->columnFrom, Table::FIRST_ONLY);
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
                            $relationName = $foreignKeyTo->fromRelationName(Column::PLURAL);
                            if (!$finalModel) throw new Exception("Foreign key from table on [$foreignKeyTo] on [$this->table.id] has no model");

                            $relations[$relationName] = new RelationXfromX(
                                $relationName, 
                                $this,
                                $finalModel,               // User
                                $pivotTable,
                                $foreignKeyTo->columnFrom, // pivot.user_group_id
                                $throughColumn,            // pivot.user_id
                                $foreignKeyTo
                            );
                        }
                    }
                }
            }
        } else {
            // Non-create system plugins do not represent their FKs correctly
            // so we need to read the actual class definition relations, not the database FKs
            // From WinterCMS bleongsToMany section:        // UserGroup X-X => User
            // $belongsToMany = ['users' => [
            //   $finalModelToFQN,                          // User::class with $table = acorn_user_users
            //   'table'    => $relation->pivot->name,      // acorn_user_user_group
            //   'key'      => $relation->keyColumn->name,  // pivot.user_group_id
            //   'otherKey' => $relation->column->name,     // pivot.user_id
            // ]]
            if ($winterModel = $this->winterModel(FALSE)) {
                foreach ($winterModel->belongsToMany as $relationName => $config) {
                    // If the relation config has a ModelTo setting, usually config[0]
                    $db            = $this->table->db();
                    $isCount       = (isset($config['count']) && $config['count']);
                    $finalModel    = $this->relationConfigModel($config);
                    $key           = (isset($config['key'])      ? $config['key']      : $this->standardBareReferencingField());
                    $conditions    = (isset($config['conditions']) ? $config['conditions'] : NULL);
                    $otherKey      = (isset($config['otherKey']) ? $config['otherKey'] : $finalModel->standardBareReferencingField());
                    if (!isset($config['table'])) 
                        throw new Exception("[$relationName] on [$this->name] has no table config");
                    $table         = $config['table'];
                    $pivotTable    = Table::get($table);
                    if (!$pivotTable) $pivotTable = Table::dummy($db, $table);
                    $columnFrom    = Column::dummy($finalModel->table, $key);
                    $throughColumn = Column::dummy($finalModel->table, $otherKey);
                    if (is_null($forColumn) || $forColumn->name == $columnFrom->name)
                        $relations[$relationName] = new RelationXfromX(
                            $relationName, 
                            $this, 
                            $finalModel, 
                            $pivotTable,
                            $columnFrom,
                            $throughColumn,
                            NULL,
                            $isCount,
                            $conditions
                        );
                }
            }
        }

        return $relations;
    }

    public static function nestedFieldName(
        string|array|Field|Relation $relation1to1Path, 
        string|array|Field|Relation $localFieldNames = NULL, 
        string $nameValueFrom = NULL,
        bool $relationMode    = self::RELATION_MODE
    ): string {
        // $localFieldName may be:
        //   a ForeignID, with a valueFrom to show the dropdown list
        //   a normal text field without valueFrom
        // $localFieldName is appended
        // $valueFrom will be appended in NESTED_MODE
        if ($relation1to1Path instanceof Field)    $relation1to1Path = $relation1to1Path->name;
        if ($relation1to1Path instanceof Relation) $relation1to1Path = $relation1to1Path->name;
        if (is_string($relation1to1Path))   $relation1to1Path = self::nameToArray($relation1to1Path);
        
        if ($localFieldNames) {
            if ($localFieldNames instanceof Field)    $localFieldNames = $localFieldNames->name;
            if ($localFieldNames instanceof Relation) $localFieldNames = $localFieldNames->name;
            if (is_string($localFieldNames))   $localFieldNames = self::nameToArray($localFieldNames);
            $relation1to1Path = array_merge($relation1to1Path, $localFieldNames);
        }
        
        // NESTED_MODE: this[that][nameValueFrom]:
        if ($nameValueFrom && $relationMode == self::NESTED_MODE) {
            array_push($relation1to1Path, $nameValueFrom);
        }

        if (!count($relation1to1Path))
            throw new Exception("Request for empty nested field name");

        $nestedFieldName = '';
        foreach ($relation1to1Path as $fieldObj) {
            if ($fieldObj instanceof Field)    $fieldObj = $fieldObj->name;
            if ($fieldObj instanceof Relation) $fieldObj = $fieldObj->name;
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
            $fieldNameParts = explode('@', $fieldName);
            $fieldName      = $fieldNameParts[0];
            $nameContext    = (isset($fieldNameParts[1]) ? $fieldNameParts[1] : NULL);
            $columnConfig   = (isset($columnsConfigs[$fieldName]) ? $columnsConfigs[$fieldName] : NULL);
            $fieldObjects[$fieldName] = Field::createFromYamlConfigs($this, $fieldName, $nameContext, $fieldConfig, $columnConfig, $tabLocation);
        }
        return $fieldObjects;
    }

    public function fields(bool $print = self::NO_OUTPUT, int $recursing = 0): array
    {
        global $YELLOW, $GREEN, $RED, $NC;

        // TODO: Relations should reference their Fields, not columns
        $plugin = &$this->plugin;
        $fields = array();
        $useRelationManager = TRUE; //!$isNested;
        $indentString       = str_repeat(' ', $recursing*2);
        // Output Buffer level++, discarded at end
        // No need to do it when recursing because the outer call is buffering
        $suppressOutput = !$print;
        if ($suppressOutput) ob_start(); 

        if ($this->plugin->isCreateSystemPlugin()) {
            // ---------------------------------------------------------------- Database Columns => Fields
            foreach ($this->table->columns as $columnName => &$column) {
                if ($column->shouldProcess()) { // !system && !todo
                    $relations       = $this->relations($column); // Includes HasManyDeep
                    $fieldObj        = Field::createFromColumn($this, $column, $relations);
                    $recursingNext   = $recursing + 1;

                    // Debug
                    $fieldClassParts = explode('\\', get_class($fieldObj));
                    $fieldClass      = end($fieldClassParts);
                    $fieldObj->debugComment = "$fieldClass for column $column->column_name on $plugin->name.$this->name";

                    // 1to1 embedding 
                    if (   $fieldObj instanceof ForeignIdField
                        && $relations1to1 = $fieldObj->relations1to1() // Includes HasManyDeep(1to1)
                    ) {
                        // 1to1, leaf & hasManyDeep(1to1) relations.
                        // Known AA plugins are Final
                        // they do not continue 1to1 hasManyDeep recursion
                        foreach ($relations1to1 as &$relation1to1) {
                            // Static 1to1 whole form/list include
                            //   fields.yaml:  entity[user_group][name]
                            //   columns.yaml: name: name, relation: entity_user_group
                            $modelTo            = &$relation1to1->to;
                            $modelToClass       = $modelTo->name;
                            $classParts         = explode('\\', get_class($relation1to1));
                            $relationClass      = end($classParts);
                            $type               = $relation1to1->type();

                            if (!$recursing) {
                                // -------------------------------------------------- HasManyDeep(*to*) & immediate 1to1 relation: columns
                                // HasManyDeep(*to*) has chained 1-1 levels
                                // which allows sorting and searching of 1-1 relation columns
                                // that is not possible with nested 1-1 columns
                                // RELATION_MODE: relation: <has_many_deep_name>
                                //
                                // This call also returns Fields from non-create-system Yaml. See below
                                // NOT RECURSIVE: !$recursing only
                                print("      {$indentString}Processing 1to1 columns for $relationClass({$YELLOW}$relation1to1->name{$NC})->is1to1($type) @level {$YELLOW}$recursingNext{$NC} on ForeignIdField({$YELLOW}$columnName{$NC})\n");
                                $relation1to1Fields = $modelTo->fields($print, $recursing+1);
                                $columnUsed         = FALSE;
                                foreach ($relation1to1Fields as $subFieldName => $subFieldObj) {
                                    // Exclude fields that have the same local name as fields in the parent form
                                    // this naturally exlcudes id and created_*
                                    // TODO: created_* is not being excluded
                                    $isDuplicateField   = isset($fields[$subFieldName]);
                                    $includeContext     = $subFieldObj->shouldInclude();
                                    // Pseudo fields relate to dependsOn as well
                                    // but are for form functionality and should not interfere
                                    $isPseudoFieldName  = self::isPseudo($subFieldName);
                                    // We could change the id name to also allow them...
                                    $isSpecialField     = ($subFieldName == 'id');
                                    // We cannot do anything with nested fields
                                    $isAlreadyNested    = self::isNested($subFieldName);
                                    // Sub relation fields should generate another HasManyDeep and include them
                                    $hasSubRelation     = isset($subFieldObj->relation);
                                    // Normal field
                                    $noRelations        = (count($subFieldObj->relations) == 0);
                                    // If this comes from a field only field
                                    // columnKey & columnType === FALSE
                                    $canDisplayAsColumn = $subFieldObj->canDisplayAsColumn();

                                    if (   !$isSpecialField
                                        && $canDisplayAsColumn
                                        && $includeContext 
                                        && !$isDuplicateField
                                        && !$isPseudoFieldName
                                        && !$hasSubRelation
                                        && !$isAlreadyNested
                                    ) {
                                        $subFieldObj->nested        = TRUE;
                                        $subFieldObj->nestLevel     = 1;
                                        $subFieldObj->debugComment .= " Single level embedded [$relationClass => $modelToClass::$subFieldName with relation: $relation1to1->name] for column";

                                        // Prevent this field displaying as a field
                                        // canDisplayAsField() checks fieldType
                                        $subFieldObj->fieldType = FALSE;
                                        $subFieldObj->fieldKey  = FALSE;

                                        // We use relation: and the single <name>:
                                        // For 1-1 Models, also a name|valueFrom: nested[field][name]
                                        // using nameFromPath()
                                        if ($subFieldObj->relation) {
                                            // throw new Exception("$modelTo->name::$subFieldName on $relationClass($relation1to1->name) column already has a relation [$subFieldObj->relation] during shallow column embed");
                                            print("      $indentString{$RED}WARNING{$NC}: $modelTo->name::$subFieldName on $relationClass($relation1to1->name) column already has a relation [$subFieldObj->relation] during shallow column embed");
                                        }
                                        $subFieldObj->columnKey = $subFieldName;
                                        $subFieldObj->relation  = $relation1to1->name;
                                        // Custom relation scopes based on relations, not SQL
                                        // Will set filter[relationCondition] = <the name of the relevant relation>, e.g. belongsTo['language']
                                        // Filters the listed models based on a filtered: of selected related models
                                        // Probably because it is nested
                                        // TODO: This is actually the _un-nested_ relation
                                        // TODO: Write these in to the Model Relations, not here
                                        $subFieldObj->useRelationCondition = TRUE;

                                        // valueFrom cannot be sorted
                                        // UnQualified 'name' will cause ambiguity
                                        // Also, these relation embeds need a select: for the value apparently
                                        if (!isset($subFieldObj->sqlSelect)) {
                                            $subFieldObj->sqlSelect = $subFieldObj->column->fullyQualifiedName(); 
                                        }    

                                        $columnUsed = TRUE;
                                        $fields[$subFieldObj->columnKey] = $subFieldObj;
                                    } else {
                                        $explanation = '';
                                        if ($isSpecialField)      $explanation .= "special($subFieldName) ";
                                        if (!$canDisplayAsColumn) $explanation .= "cannot display as column($subFieldName) ";
                                        if (!$includeContext)     $explanation .= '!include ';
                                        if ($isDuplicateField)    $explanation .= "duplicate($subFieldObj->fieldKey) ";
                                        if ($isPseudoFieldName)   $explanation .= "pseudo($subFieldName) ";
                                        if ($hasSubRelation)      $explanation .= "hasSubRelation($subFieldObj->relation) ";
                                        if ($isAlreadyNested)     $explanation .= "alreadyNested($subFieldName) ";
                                        print("      $indentString{$YELLOW}WARNING{$NC}: [$modelToClass::$subFieldName] column ignored ($explanation)\n");
                                    }

                                    if (!$columnUsed) {
                                        print("      $indentString{$YELLOW}WARNING{$NC}: $type($relation1to1->name) had no suitable columns\n");
                                    }
                                }
                            }

                            if (!$relation1to1 instanceof RelationHasManyDeep) {
                                // -------------------------------------------------- Nested fields
                                // Requires full recursive embedding
                                // stepping along the chain 1-1 belongsTo relations
                                // A $relation1to1Path indicates that the caller routine, also this method, wants these fields nested
                                // TODO: dependsOn morphing
                                print("      {$indentString}Processing 1to1 fields for $relationClass({$YELLOW}$relation1to1->name{$NC})->is1to1($type) @level {$YELLOW}$recursingNext{$NC} on ForeignIdField({$YELLOW}$columnName{$NC})\n");
                                $relation1to1Fields = $modelTo->fields($print, $recursing+1);
                                foreach ($relation1to1Fields as $subFieldName => $subFieldObj) {
                                    // Exclude fields that have the same local name as fields in the parent form
                                    // this naturally exlcudes id and created_*
                                    // TODO: created_* is not being excluded
                                    $includeContext    = $subFieldObj->shouldInclude();
                                    // Pseudo fields relate to dependsOn as well
                                    // but are for form functionality and should not interfere
                                    $isPseudoFieldName = self::isPseudo($subFieldName);
                                    // We could change the id name to also allow them...
                                    $isSpecialField    = ($subFieldName == 'id');
                                    // If this comes from a column only field
                                    // fieldKey & fieldType === FALSE
                                    // we do not want to recurse on the column onlys and make them fields
                                    $canDisplayAsField = $subFieldObj->canDisplayAsField();

                                    // type: relationmanager does not use nested names
                                    // because they relate to config_relation.yaml entries only
                                    // nameFrom should not be included in the fields.yaml name:
                                    // as it will be applied to the output in the nested scenario
                                    $isRelationManager = ($subFieldObj->fieldType == 'relationmanager');
                                    $nestingMode       = ($isRelationManager ? self::RELATION_MODE : self::NESTED_MODE);
                                    
                                    // Final field key
                                    $fieldKey          = $this->nestedFieldName(
                                        $relation1to1,
                                        $subFieldName,
                                        self::NO_VALUE_FROM,
                                        $nestingMode,
                                    );
                                    $isDuplicateField  = isset($fields[$fieldKey]);
                                    if ($nestingMode == self::RELATION_MODE) 
                                        print("      $indentString{$YELLOW}WARNING{$NC}: [$modelToClass::$subFieldName] field will have a relation style name [$fieldKey]\n");

                                    if (   !$isSpecialField
                                        && $includeContext 
                                        && $canDisplayAsField
                                        && !$isDuplicateField
                                        && !$isPseudoFieldName
                                    ) {
                                        $subNestLevel            = ($subFieldObj->nestLevel ?: 0);
                                        $subFieldObj->nestLevel  = $subNestLevel + 1;
                                        $subFieldObj->nested     = TRUE;
                                        $subFieldObj->debugComment .= " Recursing(level $recursing) [$relationClass => $modelToClass::$subFieldName with relation: $relation1to1->name] for field\n";

                                        // Prevent this field displaying as a column
                                        // canDisplayAsColumn() checks columnType
                                        $subFieldObj->columnType = FALSE;
                                        $subFieldObj->columnKey  = FALSE;
                                        // Nested sub relations cannot be columns or filters
                                        $subFieldObj->canFilter = FALSE; 

                                        if ($subFieldObj->fieldType == 'fileupload') {
                                            // TODO: Fix embedded 1to1 file uploads
                                            print("      $indentString{$RED}WARNING{$NC}: $modelTo->name::$fieldKey($subFieldObj->fieldType) on $relationClass($relation1to1->name) field cannot work on @create during deep field embed. Thus disabled\n");
                                            $subFieldObj->contexts = array('update' => TRUE);
                                        }

                                        if ($subFieldObj->fieldType == 'relation') {
                                            // TODO: Handle type: relation deep embed these situations
                                            // throw new Exception("$modelTo->name::$fieldKey($subFieldObj->fieldType) on $relationClass($relation1to1->name) field already has a relation [$subFieldObj->relation] during deep field embed");
                                            print("      $indentString{$RED}WARNING{$NC}: $modelTo->name::$fieldKey($subFieldObj->fieldType) on $relationClass($relation1to1->name) field already has a relation [$subFieldObj->relation] during deep field embed\n");
                                        } else {
                                            // Force field display
                                            if (!$subFieldObj->fieldType) $subFieldObj->fieldType = 'text';
                                            
                                            $subFieldObj->fieldKey = $fieldKey;
                                            $fields[$fieldKey] = $subFieldObj;
                                        }
                                    } else {
                                        $explanation = '';
                                        if ($isSpecialField)     $explanation .= "special($subFieldName) ";
                                        if (!$includeContext)    $explanation .= '!include ';
                                        if (!$canDisplayAsField) $explanation .= "cannot display as field($subFieldName) ";
                                        if ($isDuplicateField)   $explanation .= "duplicate($subFieldObj->fieldKey) ";
                                        if ($isPseudoFieldName)  $explanation .= "pseudo($subFieldName) ";
                                        print("      $indentString{$YELLOW}WARNING{$NC}: [$modelToClass::$subFieldName] field ignored ($explanation)\n");
                                    }
                                }
                            }
                        }
                    } else {
                        // Direct entry in fields array
                        $fields[$fieldObj->name] = $fieldObj;
                    }
                } else {
                    print("      $indentString{$YELLOW}WARNING{$NC}: [$columnName] shouldNotProcess()\n");
                }
            }
        } else {
            // ---------------------------------------------------------------- Yaml => Fields
            // Load the config yaml files
            // No 1to1 recursion because normal Laravel does not indicate 1to1s
            $fieldsPath       = $this->plugin->framework->modelFileDirectoryPath($this, 'fields.yaml');
            $subFieldsConfig  = $this->plugin->framework->yamlFileLoad($fieldsPath, Framework::NO_CACHE, Framework::THROW);
            $subFieldsConfig  = (object) $subFieldsConfig;
            print("      {$indentString}Loaded {$YELLOW}$fieldsPath{$NC}\n");
            $columnsPath      = $this->plugin->framework->modelFileDirectoryPath($this, 'columns.yaml');
            $subColumnsConfig = $this->plugin->framework->yamlFileLoad($columnsPath, Framework::NO_CACHE, Framework::THROW);
            $subColumnsConfig = (object) $subColumnsConfig;
            print("      {$indentString}Loaded {$YELLOW}$columnsPath{$NC}\n");

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
            foreach ($fields as $name => $field) {
                $field->fromYaml = TRUE;
                $typeString = ($field->fieldType ?: '<no field type>') . ' / ' . ($field->columnType ?: '<no column type>');
                print("      $indentString+[{$YELLOW}$name{$NC}]($typeString)\n");
            }
        }

        /* ---------------------------------------------------------------- Fields.yaml: reverse FKs
        * We do not see HasManyDeep relations processed here
        * as they are only used for columns. Fields use recursively created nested field names
        *
        * FKs _to_ this table id
        * For example: foreign defendants.user_group_id => this legalcase.id table
        * This means that this table form and columns should consider those foreign objects for editing, filtering & display
        * FK comments:
        *   type: 1fromX|XtoX
        *   nameObject: true
        * NOTE: WinterCMS/Laravel does not support create mode management of 1-1[1-X] sub-relations, e.g. legalcase[user_group_categories]
        * but it DOES seem to support _update_ mode management of them
        *
        * ---------- type: 1from1|leaf ($belongsTo):
        * legalcase.id <= defendants.leagalcase_id
        * so there is no interface
        * but we have added the $relations
        */

        /* ---------- type: HasManyDeep relation managers and column _multi's 
        */
        foreach ($this->relationsHasManyDeep() as $name => &$relation) {
            $relationClass   = get_class($relation);
            $relationType    = $relation->type();
            $valueFrom       = ($relation->to->hasField('name') || $this->hasNameAttributeMethod() ? 'name' : NULL); // For searcheable
            $tab             = ($relation->tab ?: 'INHERIT'); 
            $translationKey  = $relation->to->translationKey(Model::PLURAL);
            $cssClasses      = $relation->cssClasses($useRelationManager);

            print("    {$indentString}Creating column _multi for HasManyDeep({$YELLOW}$relation{$NC})\n");
            $thisIdRelation  = array($name => $relation);
            $fieldDefinition = array(
                '#'              => "Tab multi-select for relations1fromX($relationClass($relationType) $relation)",
                'name'           => $name,
                'labels'         => $relation->labelsPlural, // Overrides translationKey to force a local key
                'invisible'      => $relation->invisible,
                'columnExclude'  => $relation->columnExclude,
                'icon'           => $relation->to->icon,
                'debugComment'   => "Column _multi for $relation on $plugin->name.$this->name",
                'canFilter'      => TRUE, // These are linked only to fieldTabthe content table
                'columnType'     => 'partial',
                'columnPartial'  => 'multi',
                'multi'          => $relation->multi,
                'nameObject'     => $relation->lastRelation()->nameObject,
                'relation'       => $name,
                'searchable'     => (bool) $valueFrom,
                'valueFrom'      => $valueFrom, // Necessary for search to work, is removed in nested scenario
                'readOnly'       => $relation->readOnly,
                'fieldComment'   => $relation->fieldComment,
                'commentHtml'    => $relation->commentHtml,
                
                // The relation decides about its presentation with fieldExclude
                // Essentially, only for 1toX and XtoX final relations
                // that need a relationmanager
                // TODO: $relation->isToMany() ? 'relationmanager' : 'relation'
                'fieldType'      => 'relationmanager',
                'fieldExclude'   => $relation->fieldExclude,
                'advanced'       => $relation->advanced,
                'hidden'         => $relation->hidden,
                'span'           => $relation->span,
                'tab'            => $tab,
                'cssClasses'     => $cssClasses,
                'rlButtons'      => $relation->rlButtons,
                'tabLocation'    => $relation->tabLocation,
            );
            if ($relation->isCount) {
                $fieldDefinition = array_merge($fieldDefinition, array(
                    'columnType'       => 'partial',
                    'columnPartial'    => 'count',
                    'multi'            => NULL,
                    'useRelationCount' => TRUE,
                    'searchable'       => FALSE,
                    'valueFrom'        => NULL,
                    'canFilter'        => FALSE,
                ));
            }
            $fields[$name] = new PseudoFromForeignIdField($this, $fieldDefinition, $thisIdRelation);
        }

        /* ---------- type: 1fromX ($hasMany) => this table.id:
        * For example: foreign defendants(plural).user_group_id (X)=>(1) this legalcase.id table
        * This relation is identified by the plurality of the foreign table, thus a table-type: content table
        * Present in manageable lists, probably in form tabs, with create new popups
        * NOTE: This includes isSelfReferencing() children relations
        *
        * X are only meant for this 1 record
        * That is X have an FK name_id column for this table, and some other fields
        * So just a full:
        *   _create_popup, and a
        *   relation list
        */
        foreach ($this->relations1fromX() as $name => &$relation) {
            $nameFrom      = 'fully_qualified_name';
            $relationClass = get_class($relation);
            $relationType  = $relation->type();
            $dependsOn     = array('_paste' => TRUE);
            // TODO: The tab should inherit the labels local key
            $tab           = ($relation->tab ?: (
                $relation->isSelfReferencing()
                ? 'acorn::lang.models.general.children'
                : $relation->to->translationKey(Model::PLURAL)
            ));
            $cssClasses    = $relation->cssClasses($useRelationManager);
            $comment       = '';
            $valueFrom     = ($relation->to->hasField('name') || $this->hasNameAttributeMethod() ? 'name' : NULL); // For searcheable
            if ($relation->status == 'broken') continue;

            print("    {$indentString}Creating tab multi-select for {$YELLOW}$relation{$NC}\n");
            $thisIdRelation = array($name => $relation);
            $fieldObj       = new PseudoFromForeignIdField($this, array(
                '#'              => "Tab multi-select for relations1fromX($relationClass($relationType) $relation)",
                'name'           => $name,
                'translationKey' => $tab,
                'labels'         => $relation->labelsPlural, // Overrides translationKey to force a local key
                'fieldType'      => ($useRelationManager ? 'relationmanager' : 'relation'),
                'hidden'         => $relation->hidden,
                'invisible'      => $relation->invisible,
                'fieldExclude'   => $relation->fieldExclude,
                'columnExclude'  => $relation->columnExclude,
                'nameFrom'       => $nameFrom,
                'cssClasses'     => $cssClasses,
                'bootstraps'     => $relation->bootstraps,
                'dependsOn'      => $dependsOn,
                'tabLocation'    => $relation->tabLocation,
                'advanced'       => $relation->advanced,
                'icon'           => $relation->to->icon,
                'fieldComment'   => $comment,
                'debugComment'   => "Tab multi-select for $relation on $plugin->name.$this->name",
                'comment'        => $relation->comment,
                'commentHtml'    => TRUE,
                'relatedModel'   => $relation->to->fullyQualifiedName(),
                'canFilter'      => FALSE, // These are linked only to the content table
                'readOnly'       => $relation->readOnly,
                'multi'          => $relation->multi,
                'nameObject'     => $relation->nameObject,
                'span'           => $relation->span,
                'tab'            => 'INHERIT',

                // List
                'columnType'     => 'partial',
                'columnPartial'  => 'multi',
                // For searching
                'relation'       => $name,
                'searchable'     => (bool) $valueFrom,
                'valueFrom'      => $valueFrom, // Necessary for search to work, is removed in nested scenario
            ), $thisIdRelation);
            $fields[$name] = $fieldObj;
        }

        /* ---------- type: XtoXSemi ($hasMany) => this table.id:
        * For example FK: foreign users.id(plural) (X)=> this defendant_user(singular semi-pivot).user_id
        *   & this defendant_user.user_group_id =>(X) this legalcase.id table
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
            $nameFrom        = 'fully_qualified_name';
            $relationClass   = get_class($relation);
            $relationType    = $relation->type();
            $tab             = ($relation->tab ?: 'INHERIT'); 
            $translationKey  = $relation->pivotModel->translationKey(Model::PLURAL);
            $dependsOn       = array('_paste' => TRUE);
            $comment         = '';
            $cssClasses      = $relation->cssClasses($useRelationManager);
            $valueFrom       = ($relation->to->hasField('name') || $this->hasNameAttributeMethod() ? 'name' : NULL); // For searcheable
            if ($relation->status == 'broken') continue;

            print("    {$indentString}Creating tab multi-select for {$YELLOW}$relation{$NC}\n");
            $thisIdRelation         = array($name => $relation);
            $fieldObj       = new PseudoFromForeignIdField($this, array(
                '#'              => "Tab multi-select for relationsXfromXSemi($relationClass($relationType) $relation)",
                'name'           => $name,
                'translationKey' => $translationKey,
                'labels'         => $relation->labelsPlural, // Overrides translationKey
                'fieldType'      => ($useRelationManager ? 'relationmanager' : 'relation'),
                'hidden'         => $relation->hidden,
                'invisible'      => $relation->invisible,
                'fieldExclude'   => $relation->fieldExclude,
                'columnExclude'  => $relation->columnExclude,
                'recordsPerPage' => FALSE, // TODO: Currently does not work for XtoXSemi
                'nameFrom'       => $nameFrom,
                'cssClasses'     => $cssClasses,
                'bootstraps'     => $relation->bootstraps,
                'rlButtons'      => $relation->rlButtons,
                'tabLocation'    => $relation->tabLocation,
                'advanced'       => $relation->advanced,
                'icon'           => $relation->to->icon,
                'fieldComment'   => $comment,
                'debugComment'   => "Tab multi-select for $relation on $plugin->name.$this->name",
                'comment'        => $relation->comment,
                'commentHtml'    => TRUE,
                'relatedModel'   => $relation->to->fullyQualifiedName(),
                'canFilter'      => TRUE,
                'readOnly'       => $relation->readOnly,
                'span'           => $relation->span,
                'tab'            => 'INHERIT',
                'multi'          => $relation->multi,
                'nameObject'     => $relation->nameObject,
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
        * For example: foreign users(plural) (X)=> defendant_user(singular pivot).user_id & defendant_user.user_group_id =>(X) this legalcase.id table
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
            $nameFrom        = 'fully_qualified_name';
            $relationClass   = get_class($relation);
            $relationType    = $relation->type();
            $tab             = ($relation->tab ?: 'INHERIT'); 
            $translationKey  = $relation->to->translationKey(Model::PLURAL);
            $dependsOn       = array('_paste' => TRUE);
            $comment         = '';
            $cssClasses      = $relation->cssClasses($useRelationManager);
            $valueFrom       = ($relation->to->hasField('name') || $this->hasNameAttributeMethod() ? 'name' : NULL); // For searcheable
            if ($relation->status == 'broken') continue;

            // TODO: Translatable "create new" comment
            $dataFieldName = "_lc_$name";
            //$comment     = "create new <a href='#' class='popup-add' data-field-name='$dataFieldName' data-handler='onPopupRoute' data-request-data=\"route:'{$table_from_controller//\\/\\\\}@create',fieldName:'$dataFieldName'\" data-control='popup' tabindex='-1'>{$table_from_name_singular//_/-}</a>"
            $dependsOn[$dataFieldName] = TRUE;

            print("    {$indentString}Creating tab multi-select with for {$YELLOW}$relation{$NC}\n");
            $thisIdRelation         = array($name => $relation);
            $fieldObj = new PseudoFromForeignIdField($this, array(
                '#'              => "Tab multi-select for relationsXfromX($relationClass($relationType) $relation)",
                'name'           => $name,
                'translationKey' => $translationKey,
                'labels'         => $relation->labelsPlural, // Overrides translationKey
                'fieldType'      => ($useRelationManager ? 'relationmanager' : 'relation'),
                'hidden'         => $relation->hidden,
                'invisible'      => $relation->invisible,
                'fieldExclude'   => $relation->fieldExclude,
                'columnExclude'  => $relation->columnExclude,
                'recordsPerPage' => FALSE, // TODO: Currently does not work for XtoXSemi
                'nameFrom'       => $nameFrom,
                'cssClasses'     => $cssClasses,
                'bootstraps'     => $relation->bootstraps,
                'placeholder'    => $relation->placeholder,
                'rlButtons'      => $relation->rlButtons,
                'tabLocation'    => $relation->tabLocation,
                'advanced'       => $relation->advanced,
                'comment'        => $relation->comment,
                'icon'           => $relation->to->icon,
                'debugComment'   => "Tab multi-select for $relation on $plugin->name.$this->name",
                'commentHtml'    => TRUE,
                'relatedModel'   => $relation->to->fullyQualifiedName(),
                'canFilter'      => TRUE,
                'readOnly'       => $relation->readOnly,
                'span'           => $relation->span,
                'tab'            => $tab,
                'multi'          => $relation->multi,
                'nameObject'     => $relation->nameObject,
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
        print("    {$indentString}Injecting _qrcode field\n");
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
        print("    {$indentString}Injecting list actions column\n");
        $fields['_actions'] = new PseudoField($this, array(
            'name'          => '_actions',
            'hidden'        => TRUE,
            'columnType'    => 'partial',
            'columnPartial' => 'actions',
            'sortable'      => FALSE,
            'searchable'    => FALSE,
            'invisible'     => FALSE,
        ));

        // ------------------------------------------------------------- Debug / Checks
        $relations = $this->relations();
        foreach ($fields as $name => &$field) {
            if (   $field->fieldKey 
                && $field->fieldType == 'relationmanager' 
                && !isset($relations[$field->fieldKey])
            )
                throw new Exception("Model [$this->name] relation [$field->fieldKey] is missing for RelationManager field [$field->fieldKey]");

            if ($field->columnKey 
                && in_array($field->columnType, array('richeditor' , 'relationmanager'))
            )
                throw new Exception("Model [$this->name] column [$field->columnKey] has illegal type [$field->columnType]");

            if ($field->sortable) {
                if (!$field->sqlSelect)
                    throw new Exception("[$this->name::$name] field is sortable but without (fully qualified) select clause. This will cause ambiguity issues");
                else if (strstr($field->sqlSelect, '.') === FALSE)
                    throw new Exception("[$this->name::$name] field is sortable but the select: is not fully qualified: [$field->sqlSelect] This will cause ambiguity issues");
            }

            if ($field->nested) {
                if ($field->columnType && !$field->relation)
                    throw new Exception("[$name] column is nested but without a relation:");
            } 
            // Nested fields will already have been annotated
            else {
                $dbLangPath = $field->dbObject()?->dbLangPath();
                $disabled   = ($dbLangPath ? '' : 'disabled="disabled"');
                $dbComment  = str_replace(" ", '&nbsp;', $field->comment); // Prevent YAML indentation normalization

                if (!$field->fromYaml) { // Let's not overwrite YAML comments
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
                }

                /*
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
                */
            }
        }
        if ($suppressOutput) ob_end_clean();

        return $fields;
    }

    public function nameFromPath(bool $fullyQualifiedName = FALSE): string|NULL
    {
        $attributeObjectPath = $this->attributeObjectPath($fullyQualifiedName ? 'fully_qualified_name' : 'name');
        return ($attributeObjectPath
            ? $this->nestedFieldName(array_keys($attributeObjectPath), NULL, NULL, self::NESTED_MODE)
            : NULL
        );
    }

    public function attributeObjectPath(string $name, bool $appendName = TRUE): array|NULL
    {
        // options: Acorn\Lojistiks\Models\ProductInstance::dropdownOptions
        // nameFrom: entity[user_group][name]
        // AA/Model::dropdownOptions() 
        //   => AA/Collection::lists($value, $key)
        //   => nameToArray() & parts
        // $model->hasMethod($name), e.g. name()
        $nameObjectPath = array();
        $model          = $this;

        if (!$name)
            throw new Exception("Name blank in attributeObjectPath()");

        do {
            // Check for a name indicators
            if ($model->hasAttribute($name) || $model->hasAttributeMethod($name)) break;
            
            // Go to next model in chain
            // 1-1 & leaf relations only. No HasManyDeep(1to1)
            if ($nameRelations = $model->relations1to1Name()) {
                // It is a singular path, so we only accept 1
                if (count($nameRelations) > 1)
                    throw new Exception("Mulitple name relations on [$model->name]");
            
                $nameObjectPath = array_merge($nameObjectPath, $nameRelations);
                $model          = array_pop($nameRelations)->to;
            } else $model = NULL;
        } while ($model);
        
        if (is_null($model)) $nameObjectPath = NULL;
        else if ($appendName)       $nameObjectPath[$name] = TRUE;
        
        return $nameObjectPath;
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
