<?php namespace Acorn\CreateSystem;

use Acorn\CreateSystem\Relation1to1;
use Acorn\CreateSystem\RelationHasManyDeep;
use Exception;
use Spyc;

require_once('Relation.php');
require_once('Field.php');

class Model {
    protected static $models = array();
    protected $fieldsCacheDirect = NULL;
    protected $fieldsCacheRecursing = NULL;

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
    public const HAS_MANY_DEEP_INCLUDE = TRUE;
    public const WITH_CLASS_STRING = TRUE;

    public $controllers = array();
    public $actionAliases; // courseplanner => index
    public $beforeFunctions;
    public $afterFunctions;
    public $actionFunctions;
    public $actionLinks;
    public $alesFunctions;
    public $printable;
    public $readOnly;
    public $defaultSort;
    public $showSorting;
    public $qrCodeScan;
    public $allControllers;
    
    public $plugin;
    protected $table; // To mimick Winter Models. See getTable()
    public $order;
    public $name;
    public $bodyClasses; // Controller

    public $comment;
    public $formComment;   // Appears as a section on the top of forms
    public $formCommentContexts;
    public $commentHtml;   // For form-comment
    public $menu = TRUE;
    public $menuSplitter = FALSE;
    public $menuIndent   = 0;
    public $menuTaskItems; // array
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
    public $hints;
    // PHP model methods
    public $attributeFunctions = array();
    public $methods            = array();
    public $staticMethods      = array();

    public $labels;
    public $labelsPlural;

    public $filters;
    public $listRecordUrl;
    public $globalScope; // Limits all related models to here by the selection
    public $globalScopeCssTheme; // CSS class applied to body when the global scope has a fixed value
    public $import;
    public $export;
    public $batchPrint;
    public $visibleColumnActions;
    public $noRelationManagerDefault;
    public $canFilterDefault;
    public $labelsFrom = array(); // Inherit labels from another table. Useful for views

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

        // Adopt some of the tables comment statements
        $this->comment = $table->comment;
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) $this->$nameCamel = $value;
        }

        // Functions and links, adorned with stage
        $this->alesFunctions   = $table->alesFunctions;
        $this->actionFunctions = $this->reorganiseDBFuncSpecs($table->actionFunctions, 'action');
        $this->beforeFunctions = $this->reorganiseDBFuncSpecs($table->beforeFunctions, 'before');
        $this->afterFunctions  = $this->reorganiseDBFuncSpecs($table->afterFunctions,  'after');
        if ($this->actionLinks)   foreach ($this->actionLinks   as $name => &$definition) $definition['stage'] = 'link';
        if ($this->alesFunctions) foreach ($this->alesFunctions as $name => &$definition) $definition['stage'] = 'ales';

        if (!isset($this->readOnly) && $table instanceof View) $this->readOnly = TRUE;

        // Turn labels-from tables into Table
        foreach ($this->labelsFrom as &$labelsFromTableName) {
            $labelsFromTableName = Table::get($labelsFromTableName);
            if (is_null($labelsFromTableName))
                throw new Exception("labels-from [$labelsFromTableName] table not found");
        }

        // Link back
        $this->table->model = &$this;

        self::$models[$this->fullyQualifiedName()] = &$this;
    }

    public function reorganiseDBFuncSpecs(array|NULL $dbFunctionSpecs, string|NULL $stage = NULL): array
    {
        // ------------------ Result: 
        // 'add_to_hierarchy' => [
        //     'fnDatabaseName' => 'fn_acorn_university_after_courses_add_to_hierarchy',
        //     'parameters' => [
        //         'p_model_id' => 'uuid',
        //         'p_user_id' => 'uuid',
        //         'p_add' => 'bool',
        //         ...
        //     ],
        //     'resultAction' => ...
        //     'returnType' => 'unknown',
        //     'labels' => [
        //         'en' => 'Add to your organisation',
        //     ],
        //     'conditions' => 'select count(*) ...',
        //     'fields' => [
        //         'p_add' => [
        //             'commentHtml' => TRUE,
        //             'comment' => [
        //                 'en' => 'Add this course to your organisation for the <b>current year</b>',
        //             ],
        //             'tabLocation' => 3,
        //             ...
        //         ]
        //     ],
        //     'stage' => 'after'
        // ], ...
        $modelFunctionSpecs = array();
        if ($dbFunctionSpecs) {
            foreach ($dbFunctionSpecs as $fnName => $definition) {
                // Name parts
                $fnNameBare  = str_replace($this->table->subName(), 'table', $fnName);
                $fnNameParts = explode('_', $fnNameBare);
                $nameParts   = array_slice($fnNameParts, 5);
                $name        = implode('_', $nameParts);
                // Camel top-level keys only
                $definition  = Framework::camelKeys($definition, FALSE);

                // Process comment yaml
                $commentDef  = Spyc::YAMLLoadString($definition['comment']);
                $commentDef  = Framework::camelKeys($commentDef, FALSE);
                $enDevLabel  = Str::title(implode(' ', $nameParts));
                if (!isset($commentDef['labels']['en'])) $commentDef['labels']['en'] = $enDevLabel;

                // Camel field properties
                if (isset($commentDef['fields'])) {
                    foreach ($commentDef['fields'] as $fieldName => &$fieldDefinition) {
                        $fieldDefinition = Framework::camelKeys($fieldDefinition);
                    }
                }

                $modelFunctionSpecs[$name] = array_merge(array(
                    'fnDatabaseName' => $fnName,
                    'parameters'     => $definition['parameters'],
                    'returnType'     => $definition['returnType'],
                ), $commentDef);
                if ($stage) $modelFunctionSpecs[$name]['stage'] = $stage;
            }
        }
        return $modelFunctionSpecs;
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

    public function isCreateSystem(): bool
    {
        return $this->plugin->isCreateSystem();
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

    public function hasNameObjectRelation(): bool
    {
        $has = FALSE;
        foreach ($this->relations() as $relation) {
            if ($relation->isNameObject()) {
                $has = TRUE;
                break;
            }
        }
        return $has;
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
        return $this->table->hasColumn('deleted_at', 'timestamp');
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
        if ($this->isCreateSystem()) { // Non-create-system relations require Class::belongsTo
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

    public function fullyQualifiedDotName():string
    {
        $pluginDirName = $this->plugin->dotName();
        $dirName = $this->dirName();
        return "$pluginDirName.$dirName";
    }

    public function permissionFQN(string|array $qualifier = NULL): string
    {
        // acorn.university.student [_<qualifier>]
        if (is_array($qualifier)) $qualifier = implode('_', $qualifier);

        $permissionFQN = $this->fullyQualifiedDotName();
        if ($qualifier) $permissionFQN .= "_$qualifier";
        return $permissionFQN;
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

        $columnNameFQN = $column->fullyQualifiedName(); // To reference the outer table
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
                    'sqlSelect'     => "(select aacep.start from acorn_calendar_event_parts aacep where aacep.event_id = $columnNameFQN order by aacep.start limit 1)",
                    'autoFKType'    => 'Xto1', // Because these fields also appear on pivot tables, causing them to be XtoXSemi

                    // Filter settings
                    'canFilter'  => TRUE, // $this->isAcornEvent()
                    'filterType' => 'daterange',
                    'yearRange'  => 10,
                    'filterConditions' => "((select aacep.start from acorn_calendar_event_parts aacep where aacep.event_id = $columnNameFQN order by start limit 1) between ':after' and ':before')",
                );
            }
        } else if ($this->isAcornUser()) {
            $modifiers = array(
                'fieldType'  => 'text',
                'columnType' => 'text',
                'sqlSelect'  => "(select aauu.name from acorn_user_users aauu where aauu.id = $columnNameFQN)",
                'autoFKType' => 'Xto1', // Because these fields also appear on pivot tables, causing them to be XtoXSemi

                // Filter settings
                'canFilter'  => TRUE, // $this->isAcornUser()
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
        $permissions    = array();
        $menuitemPlural = Str::plural(Str::title($this->name));

        // TODO: Translation
        // Standard view menu item: acorn.university.entity_view_menu
        $labelAction = 'View menu for ';
        $permissions[$this->permissionFQN('view_menu')] = array(
            'labels' => array('en' => "$labelAction $menuitemPlural")
        );
        // Standard create: acorn.university.entity_create
        $labelAction = 'Create';
        $permissions[$this->permissionFQN('create')] = array(
            'labels' => array('en' => "$labelAction $menuitemPlural")
        );
        // Standard update: acorn.university.entity_update
        $labelAction = 'Update';
        $permissions[$this->permissionFQN('update')] = array(
            'labels' => array('en' => "$labelAction $menuitemPlural")
        );
        $labelAction = 'Print';
        $permissions[$this->permissionFQN('print')] = array(
            'labels' => array('en' => "$labelAction $menuitemPlural")
        );
        // Standard delete: acorn.university.entity_delete
        $labelAction = 'Delete';
        $permissions[$this->permissionFQN('delete')] = array(
            'labels' => array('en' => "$labelAction $menuitemPlural")
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

        // View all fields|columns: acorn.university.entity_view|change_all_fields
        $labelAction = 'View all fields for';
        $permissions[$this->permissionFQN('view_all_fields')] = array(
            'labels' => array('en' => "$labelAction $menuitemPlural")
        );
        $labelAction = 'Change all fields for';
        $permissions[$this->permissionFQN('change_all_fields')] = array(
            'labels' => array('en' => "$labelAction $menuitemPlural")
        );

        // Befores and Afters function permissions
        // These are added to all their fields automatically
        $stageFunctions = array_merge(
            $this->beforeFunctions ?: array(), 
            $this->afterFunctions ?: array()
        );
        foreach ($stageFunctions as $name => &$functionSpec) {
            if (isset($functionSpec['parameters'])) {
                foreach ($functionSpec['parameters'] as $paramName => $paramSpec) {
                    switch ($paramName) {
                        case 'model_id':
                        case 'p_model_id':
                        case 'user_id':
                        case 'p_user_id':
                            break;
                        default:
                            // Some parameters must come from the new, as yet not created, model
                            // TODO: Translate the function name
                            $fieldName = preg_replace('/^p_/', '', $paramName);
                            if (!$this->hasAttribute($fieldName)) {
                                $permissions[$this->permissionFQN("{$name}_{$paramName}_use")] = array(
                                    'labels' => array(
                                        'en' => "Use function $name",
                                        'ku' => "Fonksiyonê $name bikar bîne",
                                        'ar' => "$name استخدم الوظيفة",
                                    ),
                                );
                            }
                    }
                }
            }
        }

        if ($this->menuTaskItems) { 
            foreach ($this->menuTaskItems as $tk_menuKey => $tk_menuConfig) {
                if (is_numeric($tk_menuKey)) $tk_menuKey = $tk_menuConfig;
                $tk_permissionFQN = $this->permissionFQN("use_task_$tk_menuKey");
                $permissions[$tk_permissionFQN] = array(
                    'labels' => array(
                        'en' => "Use task $tk_menuKey $menuitemPlural",
                    ),
               );
            }
        }

        // The field->allPermissionNames() keys are already fully-qualified
        // They will already include the view|change_all_fields above
        // but we add them twice for documentation purposes
        foreach ($this->fields() as &$field) {
            $permissions = array_merge($permissions, $field->allPermissionNames());
        }

        if ($this->globalScope) {
            $permissions[$this->permissionFQN(['globalscope', 'view'])] = array(
                'labels' => array('en' => "View $menuitemPlural Global Scope")
            );
            $permissions[$this->permissionFQN(['globalscope', 'change'])] = array(
                'labels' => array('en' => "Change $menuitemPlural Global Scope")
            );
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

        if ($this->isCreateSystem()) {
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
                                if (!$finalTableFrom->model)            
                                    throw new Exception("Foreign key [$foreignKeyTo] on [$this->table.id] has no to model");
                                if ($finalColumnFrom->isTheIdColumn())  
                                    throw new Exception("Foreign 1to1 key [$foreignKeyTo] on [$this->table.id] is from an id column");
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

    public function inheritsFrom(string $class): bool
    {
        // TODO: Deep recursive inheritsFrom check
        $found = FALSE;
        foreach ($this->relations1to1() as &$relation1to1) {
            if ($relation1to1->to->fullyQualifiedName() == $class) {
                $found = TRUE;
                break;
            }
        }
        return $found;
    }

    public function relations1to1(Column|NULL &$forColumn = NULL, bool $hasManyDeepInclude = FALSE, bool $winterModels = FALSE): array
    {
        // 1-1 & leaf relations
        // $foreignKeysFrom this column: All $this->table's ($tableFrom) ForeignIdField(*_id) $columns 
        // pointing to (1-1) foreign $tableTo $columnTos(id)
        // The DB-FK-to is located on $this->table->column(*_id)
        // Same as the relationsXto1() below, but FK comment annotated as type: 1to1
        $relations = array();

        // Non-create system plugins do not declare 1to1 nature
        if ($this->isCreateSystem()) {
            foreach ($this->table->columns as &$column) {
                // We include foreignKeysTo in case there is a $hasManyDeepInclude
                // 1 column from another table pointing to this table
                if ($hasManyDeepInclude) {
                    foreach ($column->foreignKeysTo as $name => &$foreignKeyTo) {
                        if ($foreignKeyTo->shouldProcess() 
                            && $foreignKeyTo->hasManyDeepInclude
                            && (is_null($forColumn) || $forColumn->name == $column->name)
                        ) {
                            // Relation name needs to be the same as the one on the source model
                            // Copied from Relation1fromX hasMany
                            $relationName = $foreignKeyTo->fromRelationName();
                            if ($foreignKeyTo->type() != 'Xto1')
                                throw new Exception("We are only supporting Xto1 at the moment during $foreignKeyTo->tableFrom::HasManyDeep($relationName) => $this->name");
                            if (isset($relations[$relationName])) 
                                throw new Exception("Relation for [$relationName] already exists on [$this->name] on [$this->table.$column]");
                            // It is not a 1to1 of course...
                            // This relationName will have to be the same as the subsequent relation on the step model
                            $relations[$relationName] = new Relation1fromX(
                                $relationName, // X hierarchy
                                $this,         // Entity
                                $foreignKeyTo->tableFrom->model, // Hierarchy
                                $foreignKeyTo->columnTo,     // entity.id
                                $foreignKeyTo
                            );
                        }
                    }
                }

                // 1 column pointing from this table to the parent content table
                foreach ($column->foreignKeysFrom as $name => &$foreignKeyFrom) {
                    // Returns true also if isLeaf()
                    if ($foreignKeyFrom->shouldProcess()
                        && ($foreignKeyFrom->is1to1()  || ($hasManyDeepInclude && $foreignKeyFrom->hasManyDeepInclude))
                        && (is_null($forColumn) || $forColumn->name == $column->name)
                    ) {
                        $finalContentTable = &$foreignKeyFrom->tableTo;
                        $finalColumnTo     = &$foreignKeyFrom->columnTo;
                        if (!$finalContentTable->isContentTable()) throw new Exception("Final Content Table of [$foreignKeyFrom] on [$this->table.$column] is not type content");
                        if (!$finalContentTable->model)            throw new Exception("Foreign key [$foreignKeyFrom] on [$this->table.$column] has no to model");
                        if (!$finalColumnTo->isTheIdColumn())      throw new Exception("Foreign 1to1 key [$foreignKeyFrom] on [$this->table.$column] is not to the id column [$finalColumnTo->name]");

                        $finalModel   = &$finalContentTable->model;
                        $relationName = $foreignKeyFrom->columnFrom->relationName();
                        if (isset($relations[$relationName])) 
                            throw new Exception("Relation for [$relationName] already exists on [$this->name] on [$this->table.$column]");
                        $relations[$relationName] = ($foreignKeyFrom->isLeaf()
                            ? new RelationLeaf($relationName, $this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom)
                            : new Relation1to1($relationName, $this, $finalModel, $foreignKeyFrom->columnFrom, $foreignKeyFrom)
                        );
                    }
                }
            }
        } else {
            // Non-create system plugins do not represent their FKs correctly
            // so we need to read the actual class definition relations, not the database FKs
            if ($winterModels) {
                if ($winterModel = $this->winterModel(FALSE)) {
                    foreach ($winterModel->belongsTo as $relationName => $config) {
                        // If the relation config has a ModelTo setting, usually config[0]
                        // $finalModel is a create-system Model wrapper
                        $finalModel = $this->relationConfigModel($config);
                        $key        = (isset($config['key']) ? $config['key'] : $this->standardBareReferencingField());
                        $conditions = (isset($config['conditions']) ? $config['conditions'] : NULL);
                        $columnFrom = Column::dummy($finalModel->table, $key);
                        if (is_null($forColumn) || $forColumn->name == $columnFrom->name)
                            $relations[$relationName] = new Relation1to1($relationName, $this, $finalModel, $columnFrom, NULL, FALSE, $conditions);
                    }
                }
            }
        }

        return $relations;
    }

    public function relationsHasManyDeep(Column|NULL &$forColumn = NULL): array
    {
        // Builds off relations1to1() below
        return $this->recursive1to1Relations($this, $forColumn);
    }

    protected function recursive1to1Relations(Model $forModel, Column|NULL $forColumn = NULL, Model $stepModel = NULL, array $throughRelations = array()): array
    {
        global $YELLOW, $GREEN, $RED, $NC;

        if (is_null($stepModel)) $stepModel = $forModel;
        
        $relations = array();
        // relations1to1() returns empty for non-Create-System models
        // because their foreign keys & relations are not adorned
        // It will return ANY from|to relation that is marked as HAS_MANY_DEEP_INCLUDE
        $relations1to1 = $stepModel->relations1to1($forColumn, self::HAS_MANY_DEEP_INCLUDE);
        if (FALSE) {
            // In-depth recursive output
            $depth    = count($throughRelations);
            $depthStr = '      ' . str_repeat('  ', $depth);
            print("$depthStr{$stepModel->name}->relations1to1($forColumn?->column_name, HAS_MANY_DEEP_INCLUDE):\n");
            if ($relations1to1) {
                foreach ($relations1to1 as $name => $relation) {
                    $type = $relation->type();
                    print("  $depthStr$name($type)\n");
                }
            } else {
                print("  $depthStr(empty)\n");
            }
        }

        foreach ($relations1to1 as $name => $relation) {
            if (isset($throughRelations[$name])) {
                // This can happen with parent relations
                print("      HasManyDeep recursion1 detected in {$YELLOW}$forModel->name::$name{$NC}\n");
            } else {
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
                    if (isset($subthroughRelations[$subName])) {
                        // This can happen with parent relations
                        print("      HasManyDeep recursion2 detected in {$YELLOW}$forModel->name::$subName{$NC}\n");
                    } else {
                        $subthroughRelations           = $thisThroughRelations;
                        $subthroughRelations[$subName] = $deepRelation;
                        $subthroughRelationsNames      = array_keys($subthroughRelations);
                        $deepName = Model::nestedFieldName($subthroughRelationsNames);
                        if (isset($relations[$deepName])) 
                            throw new Exception("Conflicting relations with [$deepName] on [$stepModel->name]");

                        if ($deepRelation->conditions)
                            print("      {$RED}WARNING{$NC}: Relation HasManyDeep $deepName has conditions\n");

                        // HasManyDeeps can have non-1to1 relations in them
                        // because of HAS_MANY_DEEP_INCLUDE
                        // In this case the type of the final relation in the chain is a lie
                        // For example, if the final relation is a 1to1, after an Xto1, that is not real
                        // a multi will need to express it
                        // AND it should not be classed as a 1to1 because fields.yaml will start being included and stuff
                        $type = $deepRelation->type(); // The last relation type
                        $containsNon1to1s = FALSE;
                        foreach ($thisThroughRelations as $throughRelation) {
                            if (! $throughRelation instanceof Relation1to1) { // Includes leaf
                                $type = $throughRelation->type();
                                $containsNon1to1s = TRUE;
                                // print("      {$RED}WARNING{$NC}: Relation HasManyDeep $deepName is fake (contains non-1to1 in stub-chain)\n");
                            }
                        }
                        
                        // We create HasManyDeeps for each step of the way
                        // not just the final relation
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
                            $type,
                            $deepRelation->conditions,
                            $containsNon1to1s
                        );
                    }
                }

                // Deep 1to1 relation recursion
                $relations = array_merge($relations, $this->recursive1to1Relations($forModel, NULL, $modelTo, $thisThroughRelations));
            }
        }

        return $relations;
    }

    public function relations1fromX(Column|NULL &$forColumn = NULL): array
    {
        // $foreignKeysTo this column
        // All foreign $tableFrom ForeignIdField(*_id) $columns 
        // pointing to (X-1) $this->table ($tableTo) $columnTos(id)
        // The DB-FK-to is located on the foreign $tableFrom->columnFrom(*_id)
        // All from relations always point to $this->table->idColumn() only
        $relations = array();

        if ($this->isCreateSystem()) {
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
                    // $finalModel is a create-system Model wrapper
                    $finalModel = $this->relationConfigModel($config);
                    $key        = (isset($config['key']) ? $config['key'] : $this->standardBareReferencingField());
                    $conditions = (isset($config['conditions']) ? $config['conditions'] : NULL);
                    $columnFrom = Column::dummy($finalModel->table, $key);
                    if (is_null($forColumn) || $forColumn->name == $columnFrom->name)
                        $relations[$relationName] = new RelationXto1($relationName, $this, $finalModel, $columnFrom, NULL, FALSE, $conditions);
                }
                // TODO: Specifically included because of the UserGroup::morphMany['translations']
                /*
                foreach ($winterModel->morphMany as $relationName => $config) {
                    // If the relation config has a ModelTo setting, usually config[0]
                    // $finalModel is a create-system Model wrapper
                    $finalModel = $this->relationConfigModel($config);
                    $key        = (isset($config['key']) ? $config['key'] : $this->standardBareReferencingField());
                    $conditions = (isset($config['conditions']) ? $config['conditions'] : NULL);
                    $columnFrom = Column::dummy($finalModel->table, $key);
                    if (is_null($forColumn) || $forColumn->name == $columnFrom->name)
                        $relations[$relationName] = new RelationMorphXto1($relationName, $this, $finalModel, $columnFrom, NULL, FALSE, $conditions);
                }
                */
            }
        }
    
        return $relations;
    }

    public function relationsXto1(Column|NULL &$forColumn = NULL): array
    {
        // $foreignKeysFrom this column: All $this->table's ($tableFrom) ForeignIdField(*_id) $columns 
        // pointing to (X-1) foreign $tableTo $columnTos(id)
        // The DB-FK-to is located on $this->table->column(*_id)
        $relations = array();

        if ($this->isCreateSystem()) {
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
                            if (isset($relations[$relationName])) 
                                throw new Exception("Relation for [$relationName] on [$this->table.$column] already exists on [$this->name]");
                            $relations[$relationName] = new RelationXto1(
                                $relationName, 
                                $this, 
                                $finalModel, 
                                $foreignKeyFrom->columnFrom, 
                                $foreignKeyFrom
                            );
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
                    // $finalModel is a create-system Model wrapper
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

        if ($this->isCreateSystem()) {
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

        if ($this->isCreateSystem()) {
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
                    // $finalModel is a create-system Model wrapper
                    $finalModel    = $this->relationConfigModel($config);
                    $db            = $this->table->db();
                    $isCount       = (isset($config['count']) && $config['count']);
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
        // May have a name-context, e.g. password@create
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
        $nameContextPrev = NULL;
        foreach ($relation1to1Path as $fieldObj) {
            $fieldName = NULL;
            if      ($fieldObj instanceof Field)    $fieldName = $fieldObj->name;
            else if ($fieldObj instanceof Relation) $fieldName = $fieldObj->name;
            else                                    $fieldName = $fieldObj;
            if (empty($fieldName))
                throw new Exception("Empty step in [$nestedFieldName]");

            // Name contexts like password@create
            $fieldNameParts = explode('@', $fieldName);
            $fieldName      = $fieldNameParts[0];
            $nameContext    = (isset($fieldNameParts[1]) ? $fieldNameParts[1] : NULL);
            if ($nameContext) {
                if ($nameContextPrev && $nameContext != $nameContextPrev)
                    throw new Exception("Mixed multiple name contexts for $fieldName: $nameContextPrev => $nameContext");
                $nameContextPrev = $nameContext;
            }

            if ($relationMode) {
                // name, [office, location, address] => office_location_address_name
                // For use with relation and select directives
                // searchable and sortable will also work with this
                if ($nestedFieldName) $nestedFieldName .= '_';
                $nestedFieldName .= $fieldName;
            } else {
                // name, [office, location, address] => office[location][address][name]
                // select does not work with this. It would select the value from the first step, office
                // relation does not work with this
                // searchable and sortable also will not work
                if ($nestedFieldName) $nestedFieldName .= "[$fieldName]";
                else                  $nestedFieldName .= $fieldName;
            }
        }

        if ($nameContextPrev)
            $nestedFieldName .= "@$nameContextPrev";

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

    public static function isNestedFieldKey(string $fieldName): bool
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
            // We do not alter the fieldname because fields will overwrite each other
            // for example: User password@create and password@update
            // $fieldName      = $fieldNameParts[0];
            $nameContext    = (isset($fieldNameParts[1]) ? $fieldNameParts[1] : NULL);
            $columnConfig   = (isset($columnsConfigs[$fieldName]) ? $columnsConfigs[$fieldName] : NULL);
            $fieldObjects[$fieldName] = Field::createFromYamlConfigs($this, $fieldName, $nameContext, $fieldConfig, $columnConfig, $tabLocation);
        }
        return $fieldObjects;
    }

    public function getField(string $name, bool $throwIfNotFound = FALSE): Field|NULL
    {
        // TODO: Very slow, cache this fields call...
        $fields = $this->fields();
        if (!isset($fields[$name]) && $throwIfNotFound)
            throw new Exception("Field [$name] not found on $this");
        return (isset($fields[$name]) ? $fields[$name] : NULL);
    }

    public function fields(int $recursing = 0): array
    {
        global $YELLOW, $GREEN, $RED, $NC;

        // Cacheing
        $cacheArray = ($recursing ? $this->fieldsCacheRecursing : $this->fieldsCacheDirect);
        if ($cacheArray) {
            // We clone otherwise property changes will back-affect the cache objects
            $newCacheArray = array();
            foreach ($cacheArray as $name => $fieldObj) $newCacheArray[$name] = clone $fieldObj;
            return $newCacheArray;
        }

        // TODO: Relations should reference their Fields, not columns
        $plugin = &$this->plugin;
        $fields = array();
        $useRelationManager = TRUE; //!$isNestedFieldKey;
        $indentString = str_repeat(' ', $recursing * 2);

        if ($this->isCreateSystem()) {
            // ---------------------------------------------------------------- Database Columns => Fields
            foreach ($this->table->columns as &$column) {
                if ($column->shouldProcess()) { // !system && !todo
                    $relations       = $this->relations($column); // Includes HasManyDeep
                    $fieldObj        = Field::createFromColumn($this, $column, $relations);

                    // Debug
                    $fieldClassParts = explode('\\', get_class($fieldObj));
                    $fieldClass      = end($fieldClassParts);
                    $fieldObj->debugComment = "$fieldClass for column $column->column_name on $plugin->name.$this->name";

                    // 1to1 embedding 
                    // Includes HasManyDeep(1to1) 
                    // and HasManyDeep(containsNon1to1s)
                    if (   $fieldObj instanceof ForeignIdField
                        && ($relations1to1 = $fieldObj->relations1to1()) 
                    ) {
                        // 1to1, leaf & hasManyDeep(1to1) relations.
                        // Known AA plugins are Final
                        // they do not continue 1to1 hasManyDeep recursion
                        foreach ($relations1to1 as $relation1to1) {
                            // Static 1to1 whole form/list include
                            //   fields.yaml:  entity[user_group][name]
                            //   columns.yaml: name: name, relation: entity_user_group
                            $modelTo            = $relation1to1->to;
                            $modelToClass       = $modelTo->name;
                            $classParts         = explode('\\', get_class($relation1to1));
                            $relationClass      = end($classParts);

                            // If it is an fake hasManyDeepInclude then we should include
                            // the actual field still
                            // It is likely to have come here because of further fake 1to1s
                            // for example: hierarchy [Xto1]=> entity (fake HMD) [1to1]=> user_group
                            if ($relation1to1->hasManyDeepInclude) {
                                $fields[$fieldObj->name] = $fieldObj;
                            }

                            if (!$recursing) {
                                // -------------------------------------------------- HasManyDeep(*to*) & immediate 1to1 relation: columns
                                // HasManyDeep(*to*) has chained 1-1 levels
                                // which allows sorting and searching of 1-1 relation columns
                                // that is not possible with nested 1-1 columns
                                // RELATION_MODE: relation: <has_many_deep_name>
                                // 
                                // This call also returns Fields from non-create-system Yaml. See below
                                // NOT RECURSIVE: !$recursing only
                                $relation1to1Fields = $modelTo->fields($recursing+1);
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
                                    // TODO: Remove: We cannot do anything with nested fields
                                    // $isAlreadyNested    = self::isNestedFieldKey($subFieldName);
                                    // Sub relation fields should generate another HasManyDeep and include them
                                    $hasSubRelation     = isset($subFieldObj->relation);
                                    // If this comes from a field only field
                                    // columnKey & columnType === FALSE
                                    $canDisplayAsColumn = $subFieldObj->canDisplayAsColumn();
                                    // If the column is not sortable
                                    // WinterModel loaded probably
                                    // then it may be included in the nested fields +column below
                                    // unless it has a select: clause
                                    $isSortable         = ($subFieldObj->sortable !== FALSE);
                                    $hasSqlClause       = (bool) $subFieldObj->sqlSelect;

                                    if (   !$isSpecialField
                                        && $canDisplayAsColumn
                                        && $includeContext 
                                        && !$isDuplicateField
                                        && !$isPseudoFieldName
                                        && !$hasSubRelation
                                        && ($isSortable || $hasSqlClause)
                                        // && !$isAlreadyNested
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
                                        // unless of course it is a Yaml field without a column
                                        if (!isset($subFieldObj->sqlSelect)) {
                                            $subFieldObj->sqlSelect = $subFieldObj->column?->fullyQualifiedName(); 
                                        }    

                                        // Fields Settings from relation
                                        if (   is_array($relation1to1->fieldsSettings)
                                            && isset($relation1to1->fieldsSettings[$subFieldObj->columnKey])
                                        ) {
                                            $fieldSettings = $relation1to1->fieldsSettings[$subFieldObj->columnKey];
                                            foreach ($fieldSettings as $name => $value) {
                                                $nameCamel = Str::camel($name);
                                                $subFieldObj->$nameCamel = $value;
                                            }
                                        }

                                        $fields[$subFieldObj->columnKey] = $subFieldObj;
                                    } else {
                                        $explanation = '';
                                        if ($isSpecialField)      $explanation .= "special($subFieldName) ";
                                        if (!$canDisplayAsColumn) $explanation .= "cannot display as column($subFieldName) ";
                                        if (!$includeContext)     $explanation .= '!include ';
                                        if ($isDuplicateField)    $explanation .= "duplicate($subFieldObj->fieldKey) ";
                                        if ($isPseudoFieldName)   $explanation .= "pseudo($subFieldName) ";
                                        if ($hasSubRelation)      $explanation .= "hasSubRelation($subFieldObj->relation) ";
                                        // if ($isAlreadyNested)     $explanation .= "alreadyNested($subFieldName) ";
                                        print("  {$indentString}Field $modelTo->name::$subFieldName ignored because $explanation\n");
                                    }
                                }
                            }

                            if (!$relation1to1 instanceof RelationHasManyDeep) {
                                // -------------------------------------------------- Nested fields
                                // Requires full recursive embedding
                                // stepping along the chain 1-1 belongsTo relations
                                // A $relation1to1Path indicates that the caller routine, also this method, wants these fields nested
                                // TODO: dependsOn morphing
                                $relation1to1Fields = $modelTo->fields($recursing+1);
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

                                    // If the column is not sortable
                                    // WinterModel loaded probably
                                    // then it may be included in the nested fields +column
                                    // unless it has a select: clause
                                    $isSortable         = ($subFieldObj->sortable !== FALSE);
                                    $hasSqlClause       = (bool) $subFieldObj->sqlSelect;

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
                                        // because we prefer the sortable HasManyDeep version above
                                        // However, WinterModel may have specified no sorting,
                                        // for example on translations field
                                        if (!$isSortable && !$hasSqlClause) {
                                            print("  {$indentString}Field $modelTo->name::$subFieldName column included because sortable:false and no select: clause\n");
                                            // Nested column version
                                            $subFieldObj->columnKey  = $fieldKey;
                                            $subFieldObj->relation   = NULL;
                                        } else {
                                            $subFieldObj->columnType = FALSE;
                                            $subFieldObj->columnKey  = FALSE;
                                        }
                                        // Nested sub relations cannot be filters
                                        $subFieldObj->canFilter = FALSE; 

                                        if ($subFieldObj->fieldType == 'fileupload') {
                                            // TODO: Fix embedded 1to1 file uploads
                                            $subFieldObj->contexts = array('update' => TRUE);
                                        }

                                        if ($subFieldObj->fieldType == 'relation') {
                                            // TODO: Handle type: relation deep embed these situations
                                            // TODO: Has this not already happened in Field? relation => dropdown
                                            // type: relation fields
                                            // Never nested
                                            // For example: UserGroup(Yaml) columns: type: type: relation
                                            //   => columns: user_group[type]: type: dropdown 
                                            $subFieldObj->debugComment .= 'relationToEmbedMorph';
                                            $subFieldObj->fieldKey  = $fieldKey;
                                            $subFieldObj->fieldType = 'dropdown';

                                            $message = "$modelTo->name::$fieldKey($subFieldObj->fieldType) on $relationClass($relation1to1->name) field already has a relation [$subFieldObj->relation] during deep field embed";
                                            print("  $indentString$message\n");
                                        } else {
                                            // Force field display
                                            if (!$subFieldObj->fieldType) $subFieldObj->fieldType = 'text';
                                            $subFieldObj->fieldKey = $fieldKey;
                                        }

                                        // Fields Settings from relation
                                        if (is_array($relation1to1->fieldsSettings)) {
                                            $fieldsSettings = $relation1to1->fieldsSettings;
                                            if (isset($fieldsSettings[$subFieldObj->fieldKey])) {
                                                $fieldSettings = $fieldsSettings[$subFieldObj->fieldKey];
                                                foreach ($fieldSettings as $name => $value) {
                                                    $nameCamel = Str::camel($name);
                                                    $subFieldObj->$nameCamel = $value;
                                                }
                                            }
                                        }

                                        $fields[$subFieldObj->fieldKey] = $subFieldObj;
                                    } else {
                                        $explanation = '';
                                        if ($isSpecialField)     $explanation .= "special($subFieldName) ";
                                        if (!$includeContext)    $explanation .= '!include ';
                                        if (!$canDisplayAsField) $explanation .= "cannot display as field($subFieldName) ";
                                        if ($isDuplicateField)   $explanation .= "duplicate($subFieldObj->fieldKey) ";
                                        if ($isPseudoFieldName)  $explanation .= "pseudo($subFieldName) ";
                                        print("  {$indentString}Field $modelTo->name::$subFieldName ignored because $explanation\n");
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
            // No 1to1 recursion because normal Laravel does not indicate 1to1s
            $fieldsPath       = $this->plugin->framework->modelFileDirectoryPath($this, 'fields.yaml');
            $subFieldsYaml    = $this->plugin->framework->yamlFileLoad($fieldsPath, Framework::NO_CACHE, Framework::THROW);
            $subFieldsConfig  = (object) $subFieldsYaml;
            $columnsPath      = $this->plugin->framework->modelFileDirectoryPath($this, 'columns.yaml');
            $subColumnsYaml   = $this->plugin->framework->yamlFileLoad($columnsPath, Framework::NO_CACHE, Framework::THROW);
            $subColumnsConfig = (object) $subColumnsYaml;

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
            if ($relation->containsNon1to1s && !$relation->hasManyDeepSettings) {
                // We ignore HasManyDeep(containsNon1to1s) fields at the moment
                print("    HasManyDeep(containsNon1to1s) $name ignored for fields.yaml");
            } else {
                $relationClass   = get_class($relation);
                $relationType    = $relation->type();
                $valueFrom       = ($relation->valueFrom
                    ? $relation->valueFrom 
                    : ($relation->to->hasField('name') || $this->hasNameAttributeMethod() 
                    ? 'name' 
                    : NULL
                )); 
                $translationKey  = $relation->to->translationKey(Model::PLURAL);
                $cssClasses      = $relation->cssClasses($useRelationManager);
                $dependsOn       = ($relation->dependsOn ? $relation->dependsOn : array());
                $dependsOn['_paste'] = TRUE;
                $canFilter       = (isset($relation->canFilter) 
                    ? $relation->canFilter 
                    : (isset($this->canFilterDefault) ? $this->canFilterDefault : $relation->canFilterDefault())
                );

                $thisIdRelation  = array($name => $relation);
                $fieldDefinition = array(
                    '#'              => "Tab multi-select for relations1fromX($relationClass($relationType) $relation)",
                    'name'           => $name,
                    'labels'         => $relation->labelsPlural, // Overrides translationKey to force a local key
                    'invisible'      => $relation->invisible,
                    'columnExclude'  => $relation->columnExclude,
                    'icon'           => $relation->to->icon,
                    'debugComment'   => "Column _multi for $relation on $plugin->name.$this->name",
                    // These are linked only to the content table
                    'canFilter'      => $canFilter, 
                    'columnType'     => ($relation->columnType    ?: 'partial'),
                    'columnPartial'  => ($relation->columnPartial ?: 'multi'),
                    'multi'          => $relation->multi,
                    'nameObject'     => $relation->lastRelation()->nameObject,
                    'contexts'       => $relation->contexts,
                    'recordUrl'      => $relation->recordUrl,
                    'recordsPerPage' => ($relation->recordsPerPage ?: 10),
                    'relation'       => $name,
                    'searchable'     => (bool) $valueFrom,
                    'valueFrom'      => $valueFrom, // Necessary for search to work, is removed in nested scenario
                    'readOnly'       => $relation->readOnly,
                    'fieldComment'   => $relation->fieldComment,
                    'commentHtml'    => $relation->commentHtml,
                    'noRelationManager' => (isset($relation->noRelationManager) ? $relation->noRelationManager : $this->noRelationManagerDefault),
                    'filterSearchNameSelect' => $relation->filterSearchNameSelect,
                    'filterConditions' => $relation->filterConditions,
                    'explicitLabelKey' => $relation->explicitLabelKey,
                    'prefix'           => $relation->prefix,
                    'suffix'           => $relation->suffix,
                    
                    // The relation decides about its presentation with fieldExclude
                    // Essentially, only for 1toX and XtoX final relations
                    // that need a relationmanager
                    // TODO: $relation->isToMany() ? 'relationmanager' : 'relation'
                    'fieldType'      => 'relationmanager',
                    'fieldExclude'   => $relation->fieldExclude,
                    'hints'          => $relation->hints,
                    'advanced'       => $relation->advanced,
                    'hidden'         => $relation->hidden,
                    'required'       => $relation->required,
                    'span'           => $relation->span,
                    'tab'            => ($relation->tab ?: 'INHERIT'),
                    'cssClasses'     => $cssClasses,
                    'rlButtons'      => $relation->rlButtons,
                    'dependsOn'      => $dependsOn,
                    'tabLocation'    => $relation->tabLocation,
                );
                if ($relation->isCount && !$relation->containsNon1to1s) {
                    // containsNon1to1s won't work because there will be multiple results
                    $fieldDefinition = array_merge($fieldDefinition, array(
                        'columnType'       => 'partial',
                        'columnPartial'    => 'count',
                        'multi'            => NULL,
                        'useRelationCount' => TRUE,
                        'searchable'       => FALSE,
                        'valueFrom'        => NULL,
                        'canFilter'        => FALSE, // Count
                    ));
                }
                $fields[$name] = new PseudoFromForeignIdField($this, $fieldDefinition, $thisIdRelation);
            }
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
            $nameFrom      = ($relation->nameFrom ?: 'name');
            $relationClass = get_class($relation);
            $relationType  = $relation->type();
            $dependsOn     = ($relation->dependsOn ? $relation->dependsOn : array());
            $dependsOn['_paste'] = TRUE;
            // TODO: The tab should inherit the labels local key
            $tab           = ($relation->tab ?: (
                $relation->isSelfReferencing()
                ? 'acorn::lang.models.general.children'
                : $relation->to->translationKey(Model::PLURAL)
            ));
            // These 1fromX are linked only to the content table
            $canFilter      = (isset($relation->canFilter) 
                ? $relation->canFilter 
                : (isset($this->canFilterDefault) ? $this->canFilterDefault : $relation->canFilterDefault())
            );
            $cssClasses    = $relation->cssClasses($useRelationManager);
            $comment       = '';
            $valueFrom     = ($relation->valueFrom
                ? $relation->valueFrom 
                : ($relation->to->hasField('name') || $this->hasNameAttributeMethod() 
                ? 'name' 
                : NULL
            )); 
            if ($relation->status == 'broken') continue;

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
                'contexts'       => $relation->contexts,
                'recordUrl'      => $relation->recordUrl,
                'recordsPerPage' => ($relation->recordsPerPage ?: 10),
                'cssClasses'     => $cssClasses,
                'bootstraps'     => $relation->bootstraps,
                'rlButtons'      => $relation->rlButtons,
                'dependsOn'      => $dependsOn,
                'tabLocation'    => $relation->tabLocation,
                'advanced'       => $relation->advanced,
                'icon'           => $relation->to->icon,
                'fieldComment'   => $comment,
                'debugComment'   => "Tab multi-select for $relation on $plugin->name.$this->name",
                'comment'        => $relation->comment,
                'commentHtml'    => TRUE,
                'relatedModel'   => $relation->to->fullyQualifiedName(),
                'deferrable'     => $relation->deferrable(),
                'canFilter'      => $canFilter, 
                'readOnly'       => $relation->readOnly,
                'hints'          => $relation->hints,
                'required'       => $relation->required,
                'multi'          => $relation->multi,
                'nameObject'     => $relation->nameObject,
                'span'           => $relation->span,
                'tab'            => ($relation->tab ?: 'INHERIT'),
                'noRelationManager' => (isset($relation->noRelationManager) ? $relation->noRelationManager : $this->noRelationManagerDefault),
                'filterSearchNameSelect' => $relation->filterSearchNameSelect,
                'explicitLabelKey'  => $relation->explicitLabelKey,

                // List
                'columnType'     => ($relation->columnType    ?: 'partial'),
                'columnPartial'  => ($relation->columnPartial ?: 'multi'),
                // For searching
                'relation'       => $name,
                'searchable'     => (bool) $valueFrom,
                'valueFrom'      => $valueFrom, // Necessary for search to work, is removed in nested scenario
            ), $thisIdRelation);

            // --------------------------- Deferrable FKs
            // This means that the relation can be used during create
            // with deferred binding
            // This is because the foreign id column is nullable
            // the record can be created without an X-1 binding
            // and then updated after the X-1 record has been created
            if (   !$relation->deferrable() 
                && !$fieldObj->fieldExclude
                && !$fieldObj->hidden
            ) {
                // Create first Hints for !deferrable
                // The relation CANNOT use deferred binding
                // if (!$contexts) $contexts = array('update', 'preview'); 
                // TODO: Move all hints from WinterCMS.php to Model.php, and use buildHintYaml() & writeHint()
                // TODO: read-only only when create
                // $readOnly   = TRUE; 
                $dfHintName = "_{$name}_deferred_binding_hint";
                $hintObj    = new Hint($this, array(
                    'name'        => $dfHintName,
                    'tab'         => $fieldObj->tab(),
                    'tabLocation' => $fieldObj->tabLocation,
                    'partial'     => 'hint_deferred_binding',
                    'contexts'    => 'create',
                    'advanced'    => $fieldObj->advanced,
                    'bootstraps'  => array('xs' => 12),
                    'permissions' => $fieldObj->permissions,
                ));
                $fields[$dfHintName] = $hintObj;
            }

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
            $nameFrom        = ($relation->nameFrom ?: 'name');
            $relationClass   = get_class($relation);
            $relationType    = $relation->type();
            $tab             = ($relation->tab ?: 'INHERIT'); 
            $translationKey  = $relation->pivotModel->translationKey(Model::PLURAL);
            $dependsOn       = ($relation->dependsOn ? $relation->dependsOn : array());
            $dependsOn['_paste'] = TRUE;
            $comment         = '';
            $cssClasses      = $relation->cssClasses($useRelationManager);
            $valueFrom       = ($relation->valueFrom
                ? $relation->valueFrom 
                : ($relation->to->hasField('name') || $this->hasNameAttributeMethod() 
                ? 'name' 
                : NULL
            )); 
            if ($relation->status == 'broken') continue;

            $thisIdRelation = array($name => $relation);
            $canFilter      = (isset($relation->canFilter) 
                ? $relation->canFilter 
                : (isset($this->canFilterDefault) ? $this->canFilterDefault : $relation->canFilterDefault())
            );
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
                'recordsPerPage' => ($relation->recordsPerPage ?: 10),
                'nameFrom'       => $nameFrom,
                'contexts'       => $relation->contexts,
                'recordUrl'      => $relation->recordUrl,
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
                'deferrable'     => $relation->deferrable(),
                // These are linked only to the content table
                'canFilter'      => $canFilter, 
                'readOnly'       => $relation->readOnly,
                'required'       => $relation->required,
                'hints'          => $relation->hints,
                'span'           => $relation->span,
                'tab'            => ($relation->tab ?: 'INHERIT'),
                'multi'          => $relation->multi,
                'nameObject'     => $relation->nameObject,
                'dependsOn'      => $dependsOn,
                'noRelationManager' => (isset($relation->noRelationManager) ? $relation->noRelationManager : $this->noRelationManagerDefault),
                'filterSearchNameSelect' => $relation->filterSearchNameSelect,
                'explicitLabelKey'  => $relation->explicitLabelKey,

                // List
                'columnType'     => ($relation->columnType    ?: 'partial'),
                'columnPartial'  => ($relation->columnPartial ?: 'multi'),
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
            $nameFrom        = ($relation->nameFrom ?: 'name');
            $relationClass   = get_class($relation);
            $relationType    = $relation->type();
            $tab             = ($relation->tab ?: 'INHERIT'); 
            $translationKey  = $relation->to->translationKey(Model::PLURAL);
            $dependsOn       = ($relation->dependsOn ? $relation->dependsOn : array());
            $dependsOn['_paste'] = TRUE;
            $comment         = '';
            $cssClasses      = $relation->cssClasses($useRelationManager);
            $valueFrom       = ($relation->valueFrom
                ? $relation->valueFrom 
                : ($relation->to->hasField('name') || $this->hasNameAttributeMethod() 
                ? 'name' 
                : NULL
            )); 
            if ($relation->status == 'broken') continue;
            $canFilter       = (isset($relation->canFilter) 
                ? $relation->canFilter 
                : (isset($this->canFilterDefault) ? $this->canFilterDefault : $relation->canFilterDefault())
            );

            // TODO: Translatable "create new" comment
            $dataFieldName = "_lc_$name";
            //$comment     = "create new <a href='#' class='popup-add' data-field-name='$dataFieldName' data-handler='onPopupRoute' data-request-data=\"route:'{$table_from_controller//\\/\\\\}@create',fieldName:'$dataFieldName'\" data-control='popup' tabindex='-1'>{$table_from_name_singular//_/-}</a>"
            $dependsOn[$dataFieldName] = TRUE;

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
                'recordsPerPage' => ($relation->recordsPerPage ?: 10),
                'nameFrom'       => $nameFrom,
                'contexts'       => $relation->contexts,
                'recordUrl'      => $relation->recordUrl,
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
                'deferrable'     => $relation->deferrable(),
                // These are linked only to the content table
                'canFilter'      => $canFilter, 
                'readOnly'       => $relation->readOnly,
                'hints'          => $relation->hints,
                'required'       => $relation->required,
                'span'           => $relation->span,
                'tab'            => ($relation->tab ?: 'INHERIT'),
                'multi'          => $relation->multi,
                'nameObject'     => $relation->nameObject,
                'dependsOn'      => $dependsOn,
                'noRelationManager' => (isset($relation->noRelationManager) ? $relation->noRelationManager : $this->noRelationManagerDefault),
                'filterSearchNameSelect' => $relation->filterSearchNameSelect,
                'explicitLabelKey'  => $relation->explicitLabelKey,

                // List
                'columnType'     => ($relation->columnType    ?: 'partial'),
                'columnPartial'  => ($relation->columnPartial ?: 'multi'),
                // For searching
                'relation'      => $name,
                'searchable'    => (bool) $valueFrom,
                'valueFrom'     => $valueFrom, // Necessary for search to work, is removed in nested scenario
            ), $thisIdRelation);
            $fields[$name] = $fieldObj;
        }


        // ---------------------------------------------------------------- Translations
        // For directly translated name fields, not 1-1
        // if one is not already there from a 1-1
        if (   isset($fields['name']) 
            && $fields['name']->translatable
            && !isset($fields['translations'])
        ) {
            $fields['translations'] = new PseudoField($this, array(
                'name'             => 'translations',
                'explicitLabelKey' => 'acorn::lang.models.general.translations',
                // Field
                'fieldType'   => 'partial',
                'partial'     => 'translations',
                'span'        => 'storm',
                'bootstraps'  => array('xs' => 6),
                'tabLocation' => 3,
                'contexts'    => 'update',

                // Column
                'columnType'    => 'partial',
                'columnPartial' => 'translations',
                'invisible'     => TRUE,
                'sortable'      => FALSE,
                'searchable'    => FALSE
            ));
        }

        // ---------------------------------------------------------------- QR code support fields
        // TODO: Move to QRCode FormField when available
        $fields['_qrcode'] = new PseudoField($this, array(
            'name'        => '_qrcode',
            'explicitLabelKey' => 'acorn::lang.models.general.qrcode',
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
            'permissions' => array('acorn.view_qrcode'),
        ));

        // ---------------------------------------------------------------- Actions
        // These also appear in columns.yaml
        if ($this->allActionThings()) {
            $fields['_actions'] = new PseudoField($this, array(
                'name'          => '_actions',
                'explicitLabelKey' => 'acorn::lang.models.general.actions',
                'fieldType'     => FALSE,
                'columnType'    => 'partial',
                'columnPartial' => 'actions',
                'sortable'      => FALSE,
                'searchable'    => FALSE,
                // Defaults to visible
                'invisible'     => ($this->visibleColumnActions === FALSE),
            ));
        }

        // ------------------------------------------------------------- Debug / Checks
        $relations = $this->relations();
        foreach ($fields as $name => &$field) {
            if (   $field->fieldKey 
                && $field->fieldType == 'relationmanager' 
                && !isset($relations[$field->fieldKey])
                // && !$field->isNestedFieldKey() // TODO: Do relationmanagers work on nested relations?!?!?
            )
                throw new Exception("Model [$this->name] relation [$field->fieldKey] is missing for RelationManager field [$field->fieldKey]");

            if (   $field->fieldType == 'relationmanager'
                && $field->required
            ) {
                // Actually, only X-1 relations, shown as dropdowns, like event_id, can be required
                throw new Exception("Model [$this->name::$field->fieldKey] is a relationmanager and required. This will enter the field in to the \$rules array as required and prevent saving");
            }

            // Dropdowns (1 item select) that show 1|X-X will error that the value is an array
            // For example:
            //   first_event_part[users]: 
            //     type: dropdown
            if ($field->fieldType == 'dropdown') {
                $nameParts     = self::nameToArray($name);
                $lastNameParts = explode('_', end($nameParts));
                $lastName      = end($lastNameParts);
                $lastNameSing  = Str::singular($lastName);
                if ($lastNameSing != $lastName) {
                    throw new Exception("Field $name ($lastNameSing) looks plural but is handled by a single select dropdown");
                }
            }

            // Lists.php (modules/backend/widgets/Lists.php) will force set valueFrom = column name
            // for all nested[columns]:
            //   elseif (strpos($name, '[') !== false && strpos($name, ']') !== false) {
            //     $config['valueFrom'] = $name;
            // For example, overwriting a valueFrom: name to:
            //   valueFrom: first_event_part[groups]
            // In order to display correctly with a partial: multi 
            // we will need to set our: 
            //   multi: 
            //     valueFrom: name
            if ($field->nested && $field->columnType == 'partial' && $field->columnPartial == 'multi') {
                if (!$field->multi || !isset($field->multi['valueFrom'])) {
                    throw new Exception("Column [$this->name::$field->columnKey] is set to partial multi but has no explicit multi:valueFrom:");
                }
            }

            if ($field->sqlSelect && $field->valueFrom)              
                throw new Exception("select: and valueFrom: are mutually exclusive on [$field->name]");
            
            // Not true
            // if ($field->relation && strstr($field->columnKey, '[')) 
            //     throw new Exception("relation: and nesting are mutually exclusive on [$field->name]");

            if (   $this->isCreateSystem()
                && $field->fieldType == 'relationmanager'
                && !isset($field->rlButtons) // Can be FALSE
            ) {
                throw new Exception("Model [$this->name::$field->fieldKey] is a relationmanager without buttons");
            }

            if ($field->columnKey 
                && in_array($field->columnType, array('richeditor' , 'relationmanager'))
            )
                throw new Exception("Model [$this->name] column [$field->columnKey] has illegal type [$field->columnType]");

            if (!isset($field->fieldType) || !$field->fieldType) {
                $fromYaml = ($field->fromYaml ? '(from YAML)' : '');
                // throw new Exception("Model [$this->name] field [$name]$fromYaml has no field-type");
            }

            if ($field->sortable) {
                if (!$field->sqlSelect)
                    throw new Exception("[$this->name::$name] field is sortable but without (fully qualified) select clause. This will cause ambiguity issues");
                else if (strstr($field->sqlSelect, '.') === FALSE)
                    throw new Exception("[$this->name::$name] field is sortable but the select: is not fully qualified: [$field->sqlSelect] This will cause ambiguity issues");
            }

            if ($field->nested) {
                if ($field->columnType && !$field->relation && $field->sortable)
                    throw new Exception("[$name] column is nested, sortable but without a relation: so it will error");
            } 
            // Nested fields will already have been annotated
            else {
                $dbLangPath = $field->dbObject()?->dbLangPath();
                $disabled   = ($dbLangPath ? '' : 'disabled="disabled"');
                // Prevent YAML indentation normalization
                $dbComment  = str_replace(" ", '&nbsp;', $field->comment); 

                if (!$field->fromYaml) { // Let's not overwrite YAML comments
                    if (is_array($dbComment))
                        throw new Exception("DB comment is array for $field->name");
                    if (is_null($field->actions)) $field->actions = array();
                    $field->actions['debug'] = <<<HTML
                        <div>
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
            }
        }

        // Cacheing
        // We clone otherwise property changes will back-affect the cache objects
        $cacheArray = array();
        foreach ($fields as $name => $fieldObj) $cacheArray[$name] = clone $fieldObj;
        if ($recursing) {
            $this->fieldsCacheRecursing = $cacheArray;
        } else {
            $this->fieldsCacheDirect = $cacheArray;
        }

        return $fields;
    }

    public function allActionThings(): array
    {
        $actionFunctions = array_merge($this->actionFunctions ?: array(), $this->actionLinks ?: array());

        foreach ($this->relations1to1() as $relation) {
            if (method_exists($relation->to, 'allActionThings'))
                $actionFunctions = array_merge($actionFunctions, $relation->to->allActionThings());
        }

        return $actionFunctions;
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

    public function localTranslationKey(string|NULL $group = NULL): string
    {
        // models.<model>
        $area  = 'models';
        $model = $this->dirName(); // squished usergroup | invoice
        $key   = "$area.$model";
        if ($group) $key .= ".$group";
        return $key;
    }

    public function functionsTranslationKey(string|NULL $stage = NULL, string|NULL $name = NULL): string
    {
        // acorn.<plugin>::lang.models.<model>._functions
        // we use an underscore to avoid clashes with a real "functions" label
        $key = $this->translationDomain('_functions');
        if ($stage) $key .= ".$stage";
        if ($name)  $key .= ".$name";
        return $key;
    }

    public function translationDomain(string|NULL $group = NULL): string
    {
        /* Translation:
         *  For foreign keys:           acorn.user::lang.models.usergroup.label (pointing TO the user plugin)
         *  For explicit translations:  acorn.finance::lang.models.invoice.user_group: Payee Group
         *  For qualified foreign keys: acorn.finance::lang.models.invoice.payee_user_group (payee_ makes it qualified)
         * is_qualified: Does the field name, [user_group]_id, have the same name as the table it points to, acorn_user_[user_group]s?
         * if not, then it is qualified, and we need a local translation
         */
        $domain = $this->plugin->translationDomain(); // acorn.user
        $localTranslationKey = $this->localTranslationKey($group);
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
