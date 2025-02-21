<?php namespace Acorn\CreateSystem;

class Field {
    public const NO_COLUMN = NULL;

    public $model;
    public $column;    // Can be Null
    public $relations; // Can be empty array()
    public $autoFKType;

    public $comment;     // From column->comment
    public $name;        // => fieldName & columnName
    public $order;
    public $yamlComment; // # field comment
    public $nested = FALSE;
    public $nestLevel = 0;
    // Translation arrays
    public $labels;
    public $labelsPlural;

    // fieldName & columnName
    // fields.yaml <name>: and columns.yaml <name>: can be different
    // fields.yaml <name>: is always 1to1 nested like this[that]:
    // whereas columns.yaml name we want to use this_that: with a relation:
    // to enable sorting and searching wherever possible
    public $oid; // From column or FK or the like

    // Forms fields.yaml
    public $fieldKey;
    public $fieldKeyQualifier; // Should always be added on to the fields.yaml name
    public $fieldType;
    public $length;
    public $hidden       = FALSE; // Set during __construct
    public $disabled     = FALSE;
    public $required     = TRUE;
    public $readOnly     = FALSE;
    public $newRow       = FALSE; // From column comment
    public $noLabel      = FALSE; // From column comment
    public $contexts     = array();
    public $span         = 'storm';
    public $cssClasses;
    public $bootstraps   = array('xs' => 6);
    public $popupClasses;
    public $nameFrom;
    public $partial;
    public $placeholder;
    public $debugComment;
    public $fieldComment;
    public $permissions = array(); // Resultant Fields.yaml permissions: directive
    public $permissionSettings;    // Database column Input settings
    public $commentHtml  = TRUE;
    public $hierarchical;
    public $optionsStaticMethod = 'dropdownOptions';
    public $fieldOptions;
    public $fieldOptionsModel;
    public $dependsOn = array();
    public $containerAttributes;
    public $tab;
    public $icon;
    public $tabLocation;  // primary|secondary|tertiary
    public $relatedModel; // For relationmanagers only
    // For type fileupload
    public $mode;
    public $imageHeight;
    public $imageWidth;
    public $thumbOptions;
    public $fieldConfig;
    public $setting; // Only show the column if a Setting is TRUE
    public $env;     // Only show the column if an env VAR is TRUE

    // Custom AA directives that indicate the field is an dynamic include form
    public $phpAttributeCalculation;
    public $include;
    public $includeModel;
    public $includePath;
    public $includeContext;
    public $buttons      = array(); // Of new ButtonField()s
    public $rlButtons    = array(); // On the relationmanager
    public $goto;
    public $rules = array();
    public $controller; // For popups

    // Lists columns.yaml
    public $columnKey;
    public $invisible    = FALSE; // Set during __construct
    public $columnType   = 'text';
    public $searchable   = TRUE;
    public $sortable     = FALSE;
    public $valueFrom;
    public $columnPartial;
    public $sqlSelect;
    public $relation;  // relation: user_group
    public $columnConfig;

    // Filter config_filter.yaml
    public $canFilter = FALSE;
    public $filterType;
    public $yearRange;
    public $conditions;
    public $autoRelationCanFilter;

    // --------------------------------------------- Construction
    protected function __construct(Model &$model, array $definition, Column $column = NULL, array $relations = array())
    {
        // TODO: Ambiguos fields problem: 2 x amount fields with relation
        $this->oid       = $column?->oid;
        $this->model     = &$model;
        $this->column    = $column;
        $this->relations = $relations;

        // Overwrite all defaults
        foreach ($definition as $name => $value) {
            if ($name == '#') $name = 'yamlComment';
            if (!property_exists($this, $name)) throw new \Exception("Property [$name] with value [$value] does not exist on Field");
            if (!is_null($value)) $this->$name = $value;
        }

        // Defaults
        if (!$this->fieldKey)      $this->fieldKey      = $this->name;
        if (!$this->columnKey)     $this->columnKey     = $this->name;
        if (!$this->columnType)    $this->columnType    = $this->fieldType;
        if (!$this->columnPartial) $this->columnPartial = $this->partial;

        $classParts = explode('\\', get_class($this));
        $className  = end($classParts);
        $this->yamlComment = "$className: $this->yamlComment";

        // Checks
        if (!$this->name) throw new \Exception("Field has no name");
    }

    public static function createFromColumn(Model &$model, Column &$column, array &$relations): Field
    {
        $fieldDefinition = array(
            '#'          => "From $column",
            'name'       => $column->nameWithoutId(),
            'hidden'     => $column->isStandard(Column::DATA_COLUMN_ONLY), // Doesn't include name
            'invisible'  => $column->isStandard(Column::DATA_COLUMN_ONLY),
            'sqlSelect'  => $column->sqlSelect,
            'columnType' => $column->columnType,
            'valueFrom'  => $column->valueFrom,
        );

        if ($column->is_nullable == 'YES' || $column->column_default) {
            $fieldDefinition['required']    = FALSE;
            $fieldDefinition['placeholder'] = 'backend::lang.form.select';
        }

        if ($column->is_generated != 'NEVER') {
            $fieldDefinition['disabled'] = TRUE;
            $fieldDefinition['required'] = FALSE;
            $fieldDefinition['contexts'] = array('update' => TRUE);
        }

        // ---------------------------------- Field type
        $fieldDefinition['fieldType'] = 'text';
        switch ($column->data_type) {
            case 'double precision':
            case 'double':
            case 'int':
            case 'bigint':
            case 'integer':
                $fieldDefinition['fieldType'] = 'number';
                break;
            case 'timestamp with time zone':
            case 'timestamp without time zone':
            case 'date':
            case 'datetime':
                $fieldDefinition['fieldType']     = 'datepicker';
                $fieldDefinition['columnType']    = 'partial';
                $fieldDefinition['columnPartial'] = 'datetime'; // 2 line with tooltip
                break;
            case 'boolean':
            case 'bool':
                $fieldDefinition['fieldType']     = 'switch';
                $fieldDefinition['columnType']    = 'partial';
                $fieldDefinition['columnPartial'] = 'tick';
                break;
            case 'char':
                $fieldDefinition['length']     = 1;
                break;
            case 'text':
                $fieldDefinition['fieldType']     = 'richeditor';
                break;
            case 'money':
                $tableName = $column->table->name;
                $fieldDefinition['sqlSelect'] = "$tableName.$column->name::numeric";
                break;
            case 'path':
                // File uploads are NOT stored in the actual column
                if (!$column->is_nullable) throw new \Exception("File upload column $column->column_name(path) must be nullable, because it does not store the path");
                $uploadDefinition = array(
                    'fieldType'    => 'fileupload',
                    'mode'         => 'image',
                    'columnType'   => 'image',   // Set to FALSE for !canDisplayAsColumn()
                    'required'     => FALSE,
                    'imageHeight'  => 260,
                    'imageWidth'   => 260,
                    'thumbOptions' => array(
                        'mode'      => 'crop',
                        'offset'    => array(0,0),
                        'quality'   => 90,
                        'sharpen'   => 0,
                        'interlace' => FALSE,
                        'extension' => 'auto',
                    ),
                );
                $fieldDefinition = array_merge($fieldDefinition, $uploadDefinition);
                break;
        }

        // Chance for the relation destination Model to dictate field types
        // For example: FK to Acorn\Calendar\Models\Event
        // could suggest a datepicker type
        if (count($relations) == 1) end($relations)->to->standardTargetModelFieldDefinitions($column, $relations, $fieldDefinition);

        // Inherit Column comment values
        // Include label translations
        $fieldDefinition['comment'] = $column->comment;
        foreach (\Spyc::YAMLLoadString($column->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            $fieldDefinition[$nameCamel] = $value;
        }

        if      ($column->isTheIdColumn()) $field = new IdField(       $model, $fieldDefinition, $column, $relations);
        else if ($column->isForeignID())   $field = new ForeignIdField($model, $fieldDefinition, $column, $relations); // Includes RelationSelf
        else $field = new Field($model, $fieldDefinition, $column, $relations);

        return $field;
    }

    public function dbObject()
    {
        return $this->column;
    }

    // --------------------------------------------- Display
    public function __toString(): string
    {
        return "$this->name($this->fieldType)";
    }

    public function show(int $indent = 0)
    {
        global $YELLOW, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$YELLOW$this$NC\n");

        if ($this->model->table->isOurs() && !$this->model->table->isKnownAcornPlugin()) {
            $translationKey = $this->translationKey();
            print("$indentString  label: $translationKey\n");
        }
    }

    // --------------------------------------------- Info
    public function isStandard(): bool {
        if (!$this->column) throw new \Exception("Field [$this->name] is not related to a column");
        return $this->column->isStandard();
    }

    public function isCustom():   bool {
        // TODO: Change this to Field name checks to include _qrcode etc.?
        if (!$this->column) throw new \Exception("Field [$this->name] is not related to a column");
        return $this->column->isCustom();
    }

    public function canDisplayAsColumn(): bool
    {
        return (bool) $this->columnType;
    }

    public function devEnTitle(bool $plural = Model::SINGULAR): string
    {
        // Development EN title
        // This is only used in the absence of multi-lingual labels:
        $title = str_replace('_', ' ', Str::title($this->name));
        if ($plural) $title = Str::plural($title);
        return $title;
    }

    public function sqlFullyQualifiedName(): string
    {
        if (!$this->column) throw new \Exception("Field [$this->name] is not related to a column");
        return $this->column->fullyQualifiedName();
    }

    public function cssClasses(): array
    {
        // Array cssClasses
        $cssClasses = ($this->cssClasses ?: array());
        if (is_string($cssClasses)) $cssClasses = array($cssClasses);

        // Array bootstraps
        // bootstraps:
        //   sm: 12
        //   xs: 4
        if ($this->bootstraps) {
            if (!is_array($this->bootstraps)) throw new \Exception("bootstraps must be an array on [$this]");
            foreach ($this->bootstraps as $size => $columns) {
                array_push($cssClasses, "col-$size-$columns");
            }
        }

        // Popups, including bootstraps
        if ($this->popupClasses) {
            if (!is_array($this->popupClasses)) throw new \Exception("popupClasses must be an array on [$this]");
            foreach ($this->popupClasses as $name => $value) {
                if ($name == 'bootstraps') {
                    if (!is_array($value)) throw new \Exception("All bootstraps must be YAML arrays of size: columns when processing [$this]");
                    foreach ($value as $size => $columns) {
                        array_push($cssClasses, "popup-col-$size-$columns");
                    }
                } else {
                    array_push($cssClasses, "popup-$value");
                }
            }
        }

        // Individual settings
        if ($this->newRow)  array_push($cssClasses, 'new-row');
        if ($this->noLabel) array_push($cssClasses, 'nolabel');

        return $cssClasses;
    }

    public function allPermissionNames(): array
    {
        // Assemble all field permission-settings directives names
        // for Plugin registerPermissions()
        // Permission names (keys) are fully-qualified
        //   permission-settings:
        //      NOT=legalcases__owner_user_group_id__update@update:
        //         field:
        //         readOnly: true
        //         disabled: true
        //         labels: 
        //         en: Update owning Group
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

                // Permission keys _can_ be qualified in this scenario
                // because they can reference permissions from other plugins
                // however, we default to the same model plugin that the field in attached to
                $qualifiedPermissionName = $permissionDirective;
                $isQualifiedName = (strstr($qualifiedPermissionName, '.') !== FALSE);
                if (!$isQualifiedName) {
                    $pluginDotPath = $this->model->plugin->dotName();
                    $qualifiedPermissionName = "$pluginDotPath.$qualifiedPermissionName";
                }

                // Dev setting so labels are not necessary
                if (!isset($config['labels'])) {
                    $permissionNameParts = explode('.', $qualifiedPermissionName);
                    $permissionNameLast = end($permissionNameParts);
                    $config['labels'] = array('en' => Str::title($permissionNameLast));
                }

                // Only fully Qualified permission names
                $permissions[$qualifiedPermissionName] = $config;
            }
        }

        return $permissions;
    }

    public function cssClass(): string
    {
        return implode(' ', $this->cssClasses());
    }

    public function isLocalTranslationKey(): bool
    {
        // $domain
        $translationKey = $this->translationKey();
        return (explode('::', $translationKey)[0] == $this->model->plugin->translationDomain());
    }

    public function localTranslationKey(): string
    {
        // $group.$subgroup.$name
        $translationKey = $this->translationKey();
        $localTranslationKey = explode('::', $translationKey)[1];
        return preg_replace('/^lang\./', '', $localTranslationKey);
    }

    public function translationKey(): string
    {
        /* Translation:
         *  TODO: Maybe this should be in WinterCMS?
         *  For plugin table fields:    acorn.finance::lang.models.invoice.amount
         *  For explicit translations:  acorn.finance::lang.models.invoice.user_group (translation: comment directive)
         *  For plugin standard fields: acorn.finance::lang.models.general.id | name | created_*
         * Construction: $translation_domain::lang.$translation_group.$translation_subgroup.$translation_name
         */
        $domain   = $this->model->plugin->translationDomain(); // acorn.finance
        $group    = 'models';
        $subgroup = $this->model->dirName(); // squished usergroup | invoice
        $name     = $this->name; // amount | id | name
        if ($this->isStandard()) $subgroup = 'general';

        return "$domain::lang.$group.$subgroup.$name";
    }

}


// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
class IdField extends Field {
    public $translationKey;

    public function __construct(Model &$model, array $definition, Column &$column, array &$relations)
    {
        parent::__construct($model, $definition, $column, $relations);

        /* TODO: Multiple 1toX => tabs
         * if ($this->relation1 instanceof RelationXto1) {
            $buttons      = array('create' => new ButtonField($model, ...));
            $dependsOn
        }
        */
    }
}


// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
class ForeignIdField extends Field {
    public $relation1;

    // Based on relation: so can be searched and sorted
    // > 1 level nesting will turn this off if it cannot be
    public $searchable     = TRUE;
    public $sortable       = TRUE;

    protected function __construct(Model &$model, array $definition, Column &$column, array &$relations)
    {
        parent::__construct($model, $definition, $column, $relations);

        // Always allow QR code scanning
        $this->dependsOn['_qrscan'] = TRUE;

        // We omit some of our own known plugins
        // because they do not conform yet to our naming requirements
        // And all system plugins which do not have correct FK setup!
        if ($this->model->table->isOurs() && !$this->model->table->isKnownAcornPlugin()) {
            // All foreign ids, e.g. legalcase_id, MUST have only 1 Xto1 or 1to1 FK
            if (!count($this->relations)) {
                $foreignKeysFromCount = count($column->foreignKeysFrom);
                $foreignKeysToCount   = count($column->foreignKeysTo);
                $foreignKeysFrom1Type = ($foreignKeysFromCount ? end($column->foreignKeysFrom)->type() : '');
                $foreignKeysTo1Type   = ($foreignKeysToCount   ? end($column->foreignKeysTo)->type()   : '');
                throw new \Exception("ForeignIdField [$this->name] has no relation. FKs from:$foreignKeysFromCount($foreignKeysFrom1Type), to:$foreignKeysToCount($foreignKeysTo1Type)]");
            }
            foreach ($this->relations as $name => &$relation) {
                if ( $relation instanceof Relation1to1 // includes RelationLeaf
                  || $relation instanceof RelationXto1
                  || $relation instanceof RelationSelf // parent_event_id = "parent" qualifier to the same "event" table
                ) {
                    if ($this->relation1) throw new \Exception("Multiple 1to1/X/Self relations on ForeignIdField[$this->name]");
                    $this->relation1 = &$relation;
                }
            }

            // Relation interface management
            // depending on relation type
            // This is a multiple relation: Xto1, XtoX, etc.
            // We only override the default text setting
            // because, for example, created_at_event_id wants to show a datepicker
            // TODO: This morph to a dropdown needs to be rationalised a bit
            if (!isset($this->fieldType) || $this->fieldType == 'text' || $this->fieldType == 'radio' || $this->fieldType == 'dropdown') {
                // ----------------------- Columns.yaml sortable relation
                // We use relation, select and valueFrom because it can be column sorted and searched
                // whereas 1to1 relation[value]: fields cannot
                if (!isset($this->relation))  $this->relation  = $this->column->relationName();
                // We should only set sqlSelect if the relation table has the column
                // otherwise use valueFrom
                // valueFrom will use name() which will consider nameObject relations
                if ($this->relation1 && $this->relation1->to->table->hasColumn('name') && !isset($this->sqlSelect)) {
                    $this->sqlSelect  = 'name';
                    $this->valueFrom  = NULL;
                    $this->sortable   = TRUE;
                    $this->searchable = TRUE;
                } else {
                    $this->sqlSelect  = NULL;
                    $this->valueFrom  = 'name';
                    $this->sortable   = FALSE;
                    $this->searchable = FALSE;
                }

                // ------------------------ Buttons interface???
                // TODO: These should all be in a separate semantic interface class with WinterCMS rendering
                // TODO: Not sure this part is actually working... buttons are made _outside_ this area
                if ($this->relation1->to->plugin->isOurs('User') || $this->hidden == 'true') {
                    // User plugin does not inherit from AA\Model
                    // 3-state deny
                    $this->buttons['create'] = FALSE;
                    $this->buttons['add']    = FALSE;
                } else {
                    $this->dependsOn["_create_$this->name"] = TRUE;
                }

                // ------------------------ Create and select comment help
                if ($this->relation1) {
                    // AA/Models/Server has no controller
                    if ($controller = $this->relation1->to->controller(Model::NULL_IF_NOT_ONLY_1)) {
                        // TODO: Comment and model name translation
                        $controllerUrl = $controller->absoluteBackendUrl();
                        $title         = $this->relation1->to->name;
                        if (is_null($this->fieldComment)) $this->fieldComment = '';
                        $this->fieldComment .= "<span class='view-add-models'>acorn::lang.helpblock.view_add <a tabindex='-1' href='$controllerUrl'>$title</a></span>";
                        $this->fieldComment .= "<a tabindex='-1' target='_blank' href='$controllerUrl' class='goto-form-group-selection'></a>";
                        // TODO: This is actually for annotating checkbox lists, not selects, but it does nothing if it is a dropdown
                        // $goto = $controllerUrl;
                    }
                }

                // ------------------------ Assemble field.yaml permissions: YAML array
                if ($this->relation1) {
                    // Un-qualified permissions of target model
                    //   permission-settings:
                    //      trials__access:
                    //         labels: 
                    //         en: Create a Trial
                    $targetModel = &$this->relation1->to;
                    if ($targetModel->permissionSettings) {
                        foreach ($targetModel->permissionSettings as $localPermissionName => $permissionConfig) {
                            $isQualifiedName = (strstr($localPermissionName, '.') !== FALSE);
                            if ($isQualifiedName) {
                                throw new \Exception("Model [$targetModel->name] permission [$localPermissionName] cannot be qualified (it has a dot)");
                            }

                            // Add the required permission to the Fields.yaml permissions: directive
                            // These must be local permission names
                            array_push($this->permissions, $localPermissionName);
                        }
                    }
                }

                // ----------------------- Fields.yaml Dropdown
                if (!$this->cssClasses) $this->cssClasses = array('popup-col-xs-6');
                if (!$this->bootstraps) $this->bootstraps = array('xs' => 5);
                if ($this->relation1 instanceof RelationSelf) $this->hierarchical = TRUE;
                if (!$this->nameFrom)   $this->nameFrom = 'fully_qualified_name';
                if (!$this->fieldType || $this->fieldType == 'text') $this->fieldType = 'dropdown';
            }

            if ($this->relation1) {
                if (!$this->fieldOptions) $this->fieldOptions = $this->relation1->to->staticCallClause($this->optionsStaticMethod);
            }

            $this->yamlComment = "$this->yamlComment, with $this->relation1";
        } else {
            // !isOurs
            $this->yamlComment = "Not ours/known $this->yamlComment";
        }
    }

    public function embedRelation1Model(): Model|bool
    {
        $shouldEmbed = ($this->model->table->isOurs()
            && !$this->model->table->isKnownAcornPlugin()
            && $this->relation1 instanceof Relation1to1 // Includes RelationLeaf
        );
        return ($shouldEmbed ? $this->relation1->to : FALSE);
    }

    public function translationKey(): string
    {
        /* Translation:
         *  For foreign keys:           acorn.user::lang.models.usergroup.label (pointing TO the user plugin)
         *  For explicit translations:  acorn.finance::lang.models.invoice.user_group: Payee Group
         *  For qualified foreign keys: acorn.finance::lang.models.invoice.payee_user_group (payee_ makes it qualified)
         * is_qualified: Does the field name, [user_group]_id, have the same name as the table it points to, acorn_user_[user_group]s?
         * if not, then it is qualified, and we need a local translation
         */
        $qualifier               = $this->relation1->qualifier();
        $hasExplicitTranslations = ($this->labels && count($this->labels));
        if ($qualifier || $hasExplicitTranslations) {
            // Point to our local plugin translations
            $key = parent::translationKey();
        } else {
            // Point to foreign label
            // acorn.user::lang.models.usergroup.label
            // acorn::lang.models.server.label
            $key = $this->relation1->to->translationKey();
        }

        return $key;
    }
}

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
class PseudoField extends Field {
    // These do not have a column on this table
    // They are extra fields from external from relations
    // and QR code field
    public $required   = FALSE;
    public $isStandard = FALSE;
    public $translationKey;
    public $recordsPerPage = 10;

    public function __construct(Model &$model, array $definition, array $relations = array())
    {
        parent::__construct($model, $definition, Field::NO_COLUMN, $relations);
    }

    public function isStandard(): bool
    {
        return $this->isStandard;
    }

    public function dbObject()
    {
        return NULL;
    }

    public function translationKey(): string
    {
        // parent::translationKey() will return a local domain key
        // which will use explicit labels if there are any
        return ($this->translationKey && !$this->labels ? $this->translationKey : parent::translationKey());
    }
}


// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
class PseudoFromForeignIdField extends PseudoField {
    // These do not have a column on this table
    // They are extra fields from external from relations
    // TODO: Use these PseudoFromForeignIdField
    public $relation1;

    public function __construct(Model &$model, array $definition, array $relations = array())
    {
        parent::__construct($model, $definition, $relations);

        foreach ($this->relations as $name => &$relation) {
            if (   $relation instanceof Relation1from1 // includes RelationLeaf
                || $relation instanceof RelationXfrom1
                || $relation instanceof Relation1fromX
                || $relation instanceof RelationXfromX
            ) {
                if ($this->relation1) throw new \Exception("Multiple X/1from1/X relations on PseudoFromForeignIdField[$this->name]");
                $this->relation1 = &$relation;
                $this->oid       = $this->relation1->oid;
            }
        }

        // ------------------------ Assemble field.yaml permissions: YAML array
        if ($this->relation1) {
            // Un-qualified permissions of target model
            //   permission-settings:
            //      trials__access:
            //         labels: 
            //         en: Create a Trial
            $targetModel = &$this->relation1->to;
            if ($targetModel->permissionSettings) {
                foreach ($targetModel->permissionSettings as $localPermissionName => $permissionConfig) {
                    $isQualifiedName = (strstr($localPermissionName, '.') !== FALSE);
                    if ($isQualifiedName) {
                        throw new \Exception("Model [$targetModel->name] permission [$localPermissionName] cannot be qualified (it has a dot)");
                    }

                    // Add the required permission to the Fields.yaml permissions: directive
                    // These must be local permission names
                    array_push($this->permissions, $localPermissionName);
                }
            }
        }
    }

    public function dbObject()
    {
        return (count($this->relations) == 1
            ? end($this->relations)->foreignKey
            : NULL
        );
    }
}


// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
class ButtonField extends PseudoField {
    // These do not have a column on this table
    // They are extra fields from external from relations
    // and QR code field
    public $required = FALSE;

    public function __construct(Model &$model, array $definition, array $relations = array())
    {
        parent::__construct($model, $definition, $relations);
    }

    public function isStandard(): bool
    {
        return FALSE;
    }
}
