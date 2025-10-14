<?php namespace Acorn\CreateSystem;

use Exception;
use Serializable;
use Spyc;

class Field {
    public const NO_COLUMN = NULL;
    public const FORCE_GENERAL_LABEL = TRUE;
    public static $inheritedLabels = array();

    public $model;
    public $column;    // Can be Null
    public $relations; // Can be empty array()
    public $autoFKType;
    public $extraForeignKey;
    public $noRelationManager;
    public $fromYaml;
    public $revisionable;

    public $comment;     // From column->comment
    public $name;        // => fieldName & columnName
    public $order;
    public $yamlComment; // # field comment
    public $nested = FALSE;
    public $nestLevel = 0;
    // Translation arrays
    public $labels;
    public $labelsPlural;
    public $extraTranslations; // array
    public $explicitLabelKey; // From YAML Models
    public $prefix; // Supported by _some_ partials
    public $suffix; // Supported by _some_ partials

    // fieldName & columnName
    // fields.yaml <name>: and columns.yaml <name>: can be different
    // fields.yaml <name>: is always 1to1 nested like this[that]:
    // whereas columns.yaml name we want to use this_that: with a relation:
    // to enable sorting and searching wherever possible
    public $oid; // From column or FK or the like
    public $columnClass; // Useful when *_id fields are not FK fields
    public $translatable;
    public $system;

    // ------------------------- Forms fields.yaml
    // array of context specific field settings. Will create extra fields
    public $contextUpdate;  
    public $contextCreate;
    public $contextPreview;

    public $fieldKey;
    public $fieldKeyQualifier; // Should always be added on to the fields.yaml name
    public $fieldType;
    public $descriptionFrom;
    public $typeEditable; // For list-editable row partial
    public $fieldExclude;
    public $columnExclude;
    public $default;
    public $length;
    public $hidden; // Set during __construct
    public $disabled;
    public $required; // !$column->is_nullable == NO && !$column->column_default
    public $trigger;
    public $showSearch;

    public $readOnly;
    public $newRow;  // From column comment
    public $noLabel; // From column comment
    public $contexts;
    public $span;
    public $cssClasses;
    public $bootstraps   = array('xs' => 6);
    public $popupClasses;
    public $nameFrom;
    public $partial;
    public $placeholder;
    public $debugComment;
    public $fieldComment;
    public $permissions = array(); // Resultant Fields.yaml permissions: directive
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
    public $permissionSettings;    // Database column Input settings
    public $commentHtml = TRUE;
    public $hints;
    public $hierarchical;
    public $useRelationCount;
    public $optionsStaticMethod = 'dropdownOptions';
    public $optionsWhere; // Custom AA extension
    public $fieldOptions;
    public $fieldOptionsModel;
    public $dependsOn;
    public $containerAttributes;
    public $attributes;
    public $tab;
    public $icon;
    public $tabLocation;  // primary|secondary|tertiary
    public $relatedModel; // For relationmanagers only
    // For type fileupload
    public $mode; // And datetime
    public $imageHeight;
    public $imageWidth;
    public $thumbOptions;
    public $fieldConfig;
    public $setting; // Only show the column if a Setting is TRUE
    public $settingNot; // Only show the column if a Setting is FALSE
    public $env;     // Only show the column if an env VAR is TRUE

    // DataTable field type
    public $adding;
    public $searching;
    public $deleting;
    public $columns;
    public $keyFrom;

    // Custom AA directives that indicate the field is an dynamic include form
    public $phpAttributeCalculation;
    public $include;
    public $multi;
    public $nameObject;
    public $includeModel;
    public $includePath;
    public $includeContext;
    public $buttons      = array(); // Of new ButtonField()s
    public $rlButtons; // On the relationmanager
    public $goto;
    public $rules = array();
    public $controller; // For popups
    public $advanced; // Toggle advanced to show

    // UnHandled settings, pass through
    // These mostly come from Yaml fields.yaml parsing
    public $preset;
    public $width;
    public $height;
    public $size;
    public $emptyOption;

    // ------------------------- Lists columns.yaml
    public $columnKey;
    public $valueFrom;
    public $format; // text, date, number, etc. Includes suffix & prefix
    public $bar;
    public $cssClassesColumn;
    public $columnPartial;
    public $sqlSelect;
    public $relation;  // relation: user_group
    public $columnConfig;
    public $listEditable; // => partial list_editable
    public $on, $off;
    public $jsonable; // Column type json! :)
    public $qrcodeObject;
    // Set during __construct
    public $invisible; 
    public $columnType;
    public $searchable;
    public $sortable;
    
    // ------------------------- Filter config_filter.yaml
    public $canFilter;
    public $useRelationCondition = FALSE; // Custom filtering system for deep relations
    public $filterType;
    public $yearRange;
    public $filterConditions;
    public $filters; // Custom filters
    public $filterSearchNameSelect;

    public $olap;

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
            if (!property_exists($this, $name)) {
                $value = (is_string($value) ? $value : '?');
                throw new Exception("Property [$name] with value [$value] does not exist on Field");
            }
            if (!is_null($value)) $this->$name = $value;
        }

        // Defaults
        // Set fieldType|columnType to FALSE to prevent canDisplayAs*()
        if (!isset($this->fieldType))     $this->fieldType     = 'text'; 
        if (!isset($this->columnType))    {
            switch ($this->fieldType) {
                case 'richeditor':
                    $this->columnType = 'text';
                    break;
                default:
                    $this->columnType = $this->fieldType;
            }
        }
        // fields|columns.yaml field names:
        if (!isset($this->fieldKey))      $this->fieldKey      = $this->name;
        if (!isset($this->columnKey))     $this->columnKey     = $this->name;
        // Fields.yaml uses partial, columns.yaml uses columnPartial
        if (!isset($this->columnPartial)) $this->columnPartial = $this->partial;
        if (!isset($this->default) && $column) {
            // Strip conversions 'This'::character varying
            if (!is_null($column->column_default)) {
                if (   $column->column_default != 'gen_random_uuid()' 
                    && $column->column_default != 'now()'
                    && substr($column->column_default, 0, 8) != 'nextval('
                ) {
                    $defaultStripped = preg_replace("/::[a-z0-9() ]+\$/", '', $column->column_default);
                    // Change ' to " for JSON compat
                    $defaultStripped = preg_replace("/^'|'\$/", '"', $defaultStripped);
                    $jsonObject      = json_decode($defaultStripped);
                    $this->default   = $jsonObject;
                }
            }
        }
        if (!isset($this->translatable))  $this->translatable = $this->column?->translatable;
        if (!isset($this->system))        $this->system = $this->column?->system;
        
        if (!isset($this->invisible))     $this->invisible  = FALSE;
        if (!isset($this->searchable))    $this->searchable = TRUE;
        if (!isset($this->canFilter))     $this->canFilter  = FALSE; // What would the options be anyway?
        if (!isset($this->sortable))      $this->sortable   = FALSE;
        if (!isset($this->span))          $this->span       = 'storm';

        $classParts = explode('\\', get_class($this));
        $className  = end($classParts);
        $this->yamlComment = "$className: $this->yamlComment";

        // TODO: This listEditable should be somewhere else...
        if ($this->listEditable) {
            // json listEditable is not very helpful...
            // So we rely on manual setting
            if (!isset($this->typeEditable)) $this->typeEditable = $this->column->data_type;
            $this->columnType   = 'partial';
            if (!$this->partial) {
                if ($this->jsonable) $this->columnPartial = 'record_list_editable';
                else                 $this->columnPartial = 'list_editable';
            }
        }

        // Views often get their labels from the original tables
        // so labels-from: can be set to indicate which tables to scan
        // for identical columns and auto-copy the labels
        if (!isset($this->labels) && !isset($this->explicitLabelKey)) {
            // Model transforms the labels-from table names in to Table objects
            foreach ($this->model->labelsFrom as $labelsFromTable) {
                // We use the Model because it might not be create-system
                // meaning that labels would not be loaded
                if ($labelsFromModel = $labelsFromTable->model) {
                    if ($labelsFromField = $labelsFromModel->getField($this->name)) {
                        $this->labels           = $labelsFromField->labels;
                        $this->labelsPlural     = $labelsFromField->labelsPlural;
                        $this->explicitLabelKey = $labelsFromField->explicitLabelKey;
                        self::$inheritedLabels[$this->fullyQualifiedName()] = $labelsFromField->fullyQualifiedName();
                    }
                }
            }
        }

        // Standard columns should reference the standard models.general translation arrays
        if (   !isset($this->labels) 
            && !isset($this->explicitLabelKey)
            && get_class($this) == Field::class // Doesn't work with ForeignIdFields
        ) {
            if (isset(Framework::$standardTranslations['en'][$this->name])) {
                $this->explicitLabelKey = $this->translationKey($this->name, self::FORCE_GENERAL_LABEL);
            }
        }

        // All fields can be controlled by a permission
        // permissions are expandable/collapsable in the list screen
        if (!$this->column || $this->column->isCustom()) {
            $permissionNameStub = $this->permissionStub();
            array_push($this->permissions, "{$permissionNameStub}_view");
            array_push($this->permissions, "{$permissionNameStub}_change");

            array_push($this->permissions, $this->model->permissionFQN('view_all_fields'));
            array_push($this->permissions, $this->model->permissionFQN('change_all_fields'));
        }

        // Checks
        if (!$this->name) 
            throw new Exception("Field has no name");
    }

    public function fullyQualifiedName(): string
    {
        return ($this->column 
            ? $this->column->fullyQualifiedName() 
            : $this->model->name . '.' . $this->name
        );
    }

    public static function createFromYamlConfigs(Model &$model, string $fieldName, string|NULL $nameContext, array $fieldConfig, array $columnConfig = NULL, int $tabLocation = NULL): Field
    {
        global $YELLOW, $NC;

        // Loading from non-create-system fields & columns.yaml
        $table           = $model->getTable();
        $relations       = array();
        $tabLocationStr  = ($tabLocation  ? "TabLocation:$tabLocation" : '');
        $columnConfigStr = ($columnConfig ? 'with column config'       : 'without column config');
        $fieldDefinition = array(
            // Create-System specific settings
            '#'           => "From YAML $model->name::$fieldName($tabLocationStr) $columnConfigStr",
            'name'        => $fieldName, // $column->nameWithoutId(), also => fieldKey
            'tabLocation' => $tabLocation,
        );
        if ($nameContext) $fieldDefinition['contexts'] = array($nameContext => TRUE);
        $column = NULL;
        if ($table->hasColumn($fieldName))
            $column = $table->getColumn($fieldName);

        // --------------------------- fields.yaml => Field settings
        foreach ($fieldConfig as $yamlName => $yamlValue) {
            $targetName = $yamlName;
            switch ($yamlName) {
                case 'label':   $targetName = 'explicitLabelKey'; break; // For the translation key
                case 'type':    $targetName = 'fieldType'; break;
                case 'comment': $targetName = 'fieldComment'; break;
                case 'path':    $targetName = 'partial'; break;
                case 'select':  $targetName = 'sqlSelect'; break;
                case 'options': $targetName = 'fieldOptions'; break;
                case 'context': 
                    // Can be context: ['update', 'create'] or a string
                    $targetName = 'contexts';
                    if (is_array($yamlValue)) $yamlValue = array_flip($yamlValue);
                    else                             $yamlValue = array($yamlValue => TRUE);
                    break;
                case 'cssClass': 
                    $targetName = 'cssClasses'; 
                    if (!is_array($yamlValue)) $yamlValue = explode(' ', $yamlValue);
                    break;
                /*
                fieldOptionsModel
                hierarchical
                relatedModel
                */
            }
            if (isset($fieldDefinition[$targetName]) && $fieldDefinition[$targetName] != $yamlValue)
                throw new Exception("[$yamlName => $targetName] already set on Field [$fieldName] to different value [$yamlValue]");
            $fieldDefinition[$targetName] = $yamlValue;
        }

        // --------------------------- columns.yaml => Field settings
        if ($columnConfig) {
            foreach ($columnConfig as $yamlName => $yamlValue) {
                $targetName = $yamlName;
                switch ($yamlName) {
                    case 'label':    $targetName = 'explicitLabelKey'; break;
                    case 'type':     $targetName = 'columnType'; break;
                    case 'select':   $targetName = 'sqlSelect'; break;
                    case 'path':     $targetName = 'columnPartial'; break;
                    case 'cssClass': {
                        $targetName = 'cssClassesColumn'; 
                        if (!is_array($yamlValue)) $yamlValue = explode(' ', $yamlValue);
                        break;
                    }
                    /*
                    multi
                    'hidden'      => $column->isStandard(Column::DATA_COLUMN_ONLY), // Doesn't include name
                    'invisible'   => $column->isStandard(Column::DATA_COLUMN_ONLY),
                    */
                }
                if (isset($fieldDefinition[$targetName]) && $fieldDefinition[$targetName] != $yamlValue)
                    throw new Exception("[$yamlName => $targetName] already set on Field [$fieldName] to different value [$yamlValue]");
                $fieldDefinition[$targetName] = $yamlValue;
            }
        } else {
            print("        {$YELLOW}WARNING{$NC}: No {$YELLOW}columns.yaml{$NC} field config for [$model->name::$fieldName]\n");
            $fieldDefinition['columnType'] = FALSE;
        }

        if (!isset($fieldDefinition['explicitLabelKey'])) {
            print("        {$YELLOW}WARNING{$NC}: Yaml Field [$fieldName] in [$model->name] has no label setting\n");
            $fieldDefinition['explicitLabelKey'] = ''; // Prevent label writing
        }

        // column|field-type are used for fieldExclude, so we always provide a default
        // This is YAML source so it will not be defaulted/altered later
        if (!isset($fieldDefinition['fieldType']))  $fieldDefinition['fieldType']  = 'text';
        if (!isset($fieldDefinition['columnType'])) $fieldDefinition['columnType'] = 'text';

        return self::create($model, $fieldDefinition, $column, $relations);
    }

    protected static function create(Model $model, array $fieldDefinition, Column|NULL $column, array $relations): Field
    {
        if      ($column && $column->isTheIdColumn()) $field = new IdField(       $model, $fieldDefinition, $column, $relations);
        else if ($column && $column->isForeignID())   $field = new ForeignIdField($model, $fieldDefinition, $column, $relations);
        else $field = new Field($model, $fieldDefinition, $column);

        return $field;
    }

    public static function createFromColumn(Model &$model, Column &$column, array &$relations): Field
    {
        $fieldDefinition = array(
            '#'          => "From $column",
            'name'       => $column->name, // Will override with nameWithoutId() if ForeignIdField()
            'hidden'     => $column->isStandard(Column::DATA_COLUMN_ONLY), // Doesn't include name
            'invisible'  => $column->isStandard(Column::DATA_COLUMN_ONLY),
            'sqlSelect'  => $column->sqlSelect,
            'columnType' => $column->columnType,
            'valueFrom'  => $column->valueFrom,
        );

        $fieldDefinition['required'] = ($column->is_nullable == 'NO' && !$column->column_default);
        if (!$fieldDefinition['required']) {
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
            case 'json':
                $fieldDefinition['jsonable'] = true;
                break;
            case 'double precision':
            case 'double':
            case 'int':
            case 'bigint':
            case 'integer':
                $fieldDefinition['fieldType'] = 'number';
                $fieldDefinition['sortable']  = TRUE;
                if (!isset($fieldDefinition['sqlSelect'])) $fieldDefinition['sqlSelect'] = $column->fullyQualifiedName();
                break;
            case 'timestamp(0) with time zone':
            case 'timestamp(0) without time zone':
            case 'timestamp with time zone':
            case 'timestamp without time zone':
            case 'date':
            case 'datetime':
                $fieldDefinition['fieldType']     = 'datepicker';
                $fieldDefinition['filterType']    = 'daterange';
                $fieldDefinition['filterConditions'] = "$column->name >= ':after' AND $column->name <= ':before'";
                $fieldDefinition['columnType']    = 'partial';
                $fieldDefinition['columnPartial'] = 'datetime'; // 2 line with tooltip
                $fieldDefinition['sortable']  = TRUE;
                if (!isset($fieldDefinition['sqlSelect'])) $fieldDefinition['sqlSelect'] = $column->fullyQualifiedName();
                break;
            case 'interval':
                // TODO: Currently intervals are just presented as text
                break;
            case 'boolean':
            case 'bool':
                $fieldDefinition['fieldType']     = 'switch';
                $fieldDefinition['columnType']    = 'partial';
                $fieldDefinition['columnPartial'] = 'tick';
                $fieldDefinition['sortable']  = TRUE;
                if (!isset($fieldDefinition['sqlSelect'])) $fieldDefinition['sqlSelect'] = $column->fullyQualifiedName();
                break;
            case 'char':
                $fieldDefinition['length']     = 1;
                $fieldDefinition['sortable']  = TRUE;
                if (!isset($fieldDefinition['sqlSelect'])) $fieldDefinition['sqlSelect'] = $column->fullyQualifiedName();
                break;
            case 'text':
                $fieldDefinition['fieldType']     = 'richeditor';
                $fieldDefinition['sortable']  = TRUE;
                if (!isset($fieldDefinition['sqlSelect'])) $fieldDefinition['sqlSelect'] = $column->fullyQualifiedName();
                break;
            case 'money':
                $tableName = $column->table->name;
                $fieldDefinition['sortable']  = TRUE;
                if (!isset($fieldDefinition['sqlSelect'])) $fieldDefinition['sqlSelect'] = "$tableName.$column->name::numeric";
                break;
            case 'path':
                // File uploads are NOT stored in the actual column
                if (!$column->is_nullable) throw new Exception("File upload column $column->column_name(path) must be nullable, because it does not store the path");
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
        foreach (Spyc::YAMLLoadString($column->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            $fieldDefinition[$nameCamel] = $value;
        }

        return self::create($model, $fieldDefinition, $column, $relations);
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

        if ($this->model->getTable()->isOurs() && !$this->model->getTable()->isKnownAcornPlugin()) {
            $translationKey = $this->translationKey();
            print("$indentString  label: $translationKey\n");
        }
    }

    // --------------------------------------------- Info
    public function isNestedFieldKey(): bool
    {
        return Model::isNestedFieldKey($this->fieldKey);
    }

    public function isStandard(): bool {
        return ($this->column && $this->column->isStandard());
    }

    public function isSingularUnique(): bool
    {
        return $this->column?->isSingularUnique();
    }

    public function isCustom():   bool {
        return (!$this->column || $this->column->isCustom());
    }

    public function canDisplayAsColumn(): bool
    {
        return (bool) $this->columnType && !$this->columnExclude;
    }

    public function canDisplayAsField(): bool
    {
        return (bool) $this->fieldType && !$this->fieldExclude;
    }

    public function canDisplayAsFilter(): bool
    {
        return (bool) $this->canFilter;
    }

    public function shouldInclude(): bool
    {
        return ($this->includeContext != 'no-include');
    }

    public function devEnTitle(bool $plural = Model::SINGULAR): string
    {
        // Development EN title
        // This is only used in the absence of multi-lingual labels:
        $title = preg_replace('/_+/', ' ', 
            Str::title(
                preg_replace('/__.*/', '', $this->name)
            )
        );
        if ($plural) $title = Str::plural($title);
        return $title;
    }

    public function sqlFullyQualifiedName(): string
    {
        if (!$this->column) throw new Exception("Field [$this->name] is not related to a column");
        return $this->column->fullyQualifiedName();
    }

    public function permissionStub(): string
    {
        $plugin = $this->model->plugin->dotName();
        $model  = $this->model->dirName();
        $field  = $this->name;

        // We only register permissions for this plugin
        // acorn.university...
        // end, local name, must be unique in the plugin
        return "$plugin.{$model}_$field";
    }

    public function cssClassesColumn(): array
    {
        $cssClassesColumn = ($this->cssClassesColumn ?: array());
        if (is_string($cssClassesColumn)) $cssClassesColumn = array($cssClassesColumn);
        return $cssClassesColumn;
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
            if (!is_array($this->bootstraps)) throw new Exception("bootstraps must be an array on [$this]");
            foreach ($this->bootstraps as $size => $columns) {
                array_push($cssClasses, "col-$size-$columns");
            }
        }

        // Popups, including bootstraps
        if ($this->popupClasses) {
            if (!is_array($this->popupClasses)) throw new Exception("popupClasses must be an array on [$this]");
            foreach ($this->popupClasses as $name => $value) {
                if ($name == 'bootstraps') {
                    if (!is_array($value)) throw new Exception("All bootstraps must be YAML arrays of size: columns when processing [$this]");
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
        $permissions    = array();
        $menuitemPlural = Str::plural(Str::title($this->model->name));

        if (!$this->column || $this->column->isCustom()) {
            $permissionNameStub = $this->permissionStub();
            // TODO: Translation of permission names
            $modelTitle         = Str::title($this->model->name);
            $title              = Str::title($this->name);
            
            $actionName         = 'View field';
            $permissions["{$permissionNameStub}_view"] = array(
                'labels' => array('en' => "$actionName $modelTitle $title")
            );
            $actionName         = 'Change field';
            $permissions["{$permissionNameStub}_change"] = array(
                'labels' => array('en' => "$actionName $modelTitle $title")
            );
        }

        if ($this->permissionSettings) {
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
                // acorn.university... will be written to this plugin
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
                // acorn.university... will be written to this plugin
                $permissions[$qualifiedPermissionName] = $config;
            }
        }

        return $permissions;
    }

    public function cssClass(): string
    {
        return implode(' ', $this->cssClasses());
    }

    public function cssClassColumn(): string
    {
        return implode(' ', $this->cssClassesColumn());
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
        $translationKey      = $this->translationKey();
        $translationKeyParts = explode('::', $translationKey);
        if (!isset($translationKeyParts[1]))
            throw new Exception("Malformed translation key [$translationKey]");
        $localTranslationKey = $translationKeyParts[1];
        return preg_replace('/^lang\./', '', $localTranslationKey);
    }

    public function translationKey(string $name = NULL, bool $forceGeneral = FALSE): string
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
        $name     = ($name ?: $this->name);  // amount | id | name
        if ($forceGeneral || $this->isStandard()) $subgroup = 'general';

        return "$domain::lang.$group.$subgroup.$name";
    }

    public function relations1to1(): array
    {
        $relations1to1 = array();
        foreach ($this->relations as $relationName => &$relation) {
            // 1to1, leaf & hasManyDeep(1to1) relations.
            if ($relation->is1to1()) $relations1to1[$relationName] = $relation;
        }
        return $relations1to1;
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
    public $searchable = TRUE;
    public $sortable   = TRUE;
    public $canFilter  = TRUE;


    protected function __construct(Model &$model, array $definition, Column &$column, array &$relations)
    {
        global $YELLOW, $GREEN, $RED, $NC;

        // Unconditionally override the static create setting
        // TODO: This prevents YAML comment setting of the value
        $definition['name'] = $column->nameWithoutId();

        parent::__construct($model, $definition, $column, $relations);

        // Always allow QR code scanning
        $this->dependsOn['_qrscan'] = TRUE;

        // We omit some of our own known plugins
        // because they do not conform yet to our naming requirements
        // And all system plugins which do not have correct FK setup!
        if ($this->model->getTable()->isOurs() && !$this->model->getTable()->isKnownAcornPlugin()) {
            // All foreign ids, e.g. user_group_id, MUST have only 1 Xto1|1to1 FK
            // but also other 1|Xfrom1|X relations are acceptable 
            if (!count($this->relations)) {
                $foreignKeysFromCount = count($column->foreignKeysFrom);
                $foreignKeysToCount   = count($column->foreignKeysTo);
                $foreignKeysFrom1Type = ($foreignKeysFromCount ? end($column->foreignKeysFrom)->type() : '');
                $foreignKeysTo1Type   = ($foreignKeysToCount   ? end($column->foreignKeysTo)->type()   : '');
                throw new Exception("ForeignIdField [$this->name] has no relation. FKs from:$foreignKeysFromCount($foreignKeysFrom1Type), to:$foreignKeysToCount($foreignKeysTo1Type)]");
            }
            foreach ($this->relations as $name => &$relation) {
                if ( $relation instanceof Relation1to1 // includes RelationLeaf
                  || $relation instanceof RelationXto1
                ) {
                    if ($this->relation1) 
                        throw new Exception("Multiple 1to1/X relations on ForeignIdField[$this->name]");
                    $this->relation1 = &$relation;
                }
            }

            // Relation interface management
            // depending on relation type
            // This is a multiple relation: Xto1, XtoX, etc.
            // We only override the default text setting
            // because, for example, created_at_event_id wants to show a datepicker
            // TODO: This morph to a dropdown needs to be rationalised a bit
            if (!isset($this->fieldType) 
                || in_array($this->fieldType, array('text', 'radio', 'dropdown'))
            ) {
                // ----------------------- Columns.yaml ForeignIdField relation
                // We try to use relation & sqlSelect because it can be column sorted and searched
                // whereas 1to1 nested relation[value][value] fields cannot
                // We should only set sqlSelect if the relation table has the column
                // otherwise use [nested] valueFrom
                if (!isset($this->relation)) $this->relation  = $this->column->relationName();
                $relation1ToTable = $this->relation1->to->getTable();
                if ($this->relation1 && $relation1ToTable->hasColumn('name') && !isset($this->sqlSelect)) {
                    // Sortable relation & select
                    $this->sqlSelect  = "$relation1ToTable->name.name";
                    $this->valueFrom  = NULL;
                    $this->sortable   = TRUE;
                    $this->searchable = TRUE;
                } else {
                    // Not sortable, potentially nested valueFrom
                    // Allows 1to1 Models
                    $this->sqlSelect  = NULL;
                    if (!isset($this->valueFrom)) {
                        if ($this->model->hasNameObjectRelation()) {
                            // Still we need to trigger the request for the name objects
                            // otherwise we will get the JSON full object result 
                            $this->valueFrom = 'name';
                        } else {
                            // No name-object, so let's at least try to get a 1-1 name
                            $this->valueFrom = $this->relation1->to->nameFromPath(); // Can be null
                            if (is_null($this->valueFrom)) $this->valueFrom = 'name';
                        }
                    }
                    $this->sortable   = FALSE;
                    $this->searchable = FALSE;
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
                    //           en: Create a Trial
                    $targetModel = &$this->relation1->to;
                    if ($targetModel->permissionSettings) {
                        foreach ($targetModel->permissionSettings as $localPermissionName => $permissionConfig) {
                            $isQualifiedName = (strstr($localPermissionName, '.') !== FALSE);
                            if ($isQualifiedName) {
                                throw new Exception("Model [$targetModel->name] permission [$localPermissionName] cannot be qualified (it has a dot)");
                            }

                            // Add the required permission to the Fields.yaml permissions: directive
                            // These must be local permission names
                            print("      Added permission {$GREEN}$localPermissionName{$NC}\n");
                            array_push($this->permissions, $localPermissionName);
                        }
                    }
                }

                // ----------------------- Fields.yaml Dropdown
                // NOTE: custom handling of embedded nameFrom in AA module
                if (!isset($this->nameFrom) && !$this->model->hasNameObjectRelation()) 
                    $this->nameFrom = $this->relation1->to->nameFromPath();
                if (!isset($this->cssClasses)) $this->cssClasses = array('popup-col-xs-6');
                if (!isset($this->bootstraps)) $this->bootstraps = array('xs' => 5);
                if (!isset($this->readOnly))   $this->readOnly   = $this->relation1->to->readOnly;
                if (!isset($this->fieldType) || $this->fieldType == 'text') $this->fieldType = 'dropdown';
                if ($this->relation1->isSelfReferencing()) $this->hierarchical = TRUE;

                // ----------------------- Filter
                $column = &$this->column;
                if (!isset($this->filterConditions)) $this->filterConditions = "$column->column_name in(:filtered)";
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

    public function translationKey(string $name = NULL, bool $forceGeneral = FALSE): string
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
            $key = parent::translationKey(NULL, $forceGeneral);
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

    public function translationKey(string $name = NULL, bool $forceGeneral = FALSE): string
    {
        // parent::translationKey() will return a local domain key
        // which will use explicit labels if there are any
        $realname = preg_replace('/^_/', '', $this->name);
        return ($this->translationKey && !$this->labels ? $this->translationKey : parent::translationKey($realname, $forceGeneral));
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
        global $YELLOW, $GREEN, $RED, $NC;

        parent::__construct($model, $definition, $relations);

        foreach ($this->relations as $name => &$relation) {
            if (   $relation instanceof Relation1from1 // includes RelationLeaf
                || $relation instanceof RelationXfrom1
                || $relation instanceof Relation1fromX
                || $relation instanceof RelationXfromX
            ) {
                if ($this->relation1) throw new Exception("Multiple X/1from1/X relations on PseudoFromForeignIdField[$this->name]");
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
                        throw new Exception("Model [$targetModel->name] permission [$localPermissionName] cannot be qualified (it has a dot)");
                    }

                    // Add the required permission to the Fields.yaml permissions: directive
                    // These must be local permission names
                    print("      Added permission {$GREEN}$localPermissionName{$NC}\n");
                    array_push($this->permissions, $localPermissionName);
                }
            }
        }

        // ------------------------ Failover FK labels to foreign table labels-plural
        if ($this->relation1 && !$this->labels && !$this->labelsPlural) {
            $targetModel = &$this->relation1->to;
            if ($targetModel->labelsPlural) {
                print("      Failover permission for {$GREEN}$this->name{$NC} => {$GREEN}$targetModel->name{$NC}::labels-plural\n");
                $this->labels = $targetModel->labelsPlural;
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
/*
class ButtonField extends PseudoField {
    // These do not have a column on this table
    // They are extra fields from external from relations
    // and QR code field

    public function __construct(Model &$model, array $definition, array $relations = array())
    {
        parent::__construct($model, $definition, $relations);
    }

    public function isStandard(): bool
    {
        return FALSE;
    }
}
*/