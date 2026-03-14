<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Serializable;
use Spyc;
use Acorn\CreateSystem\Adapters\Framework;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

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
        // This would cause filterFields() to always be called
        // and dropdowns with optionsW* clauses to be double requested
        // if ($this->dependsOn !== FALSE)
        //     $this->dependsOn['_qrscan'] = TRUE;

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
                        // Adding translated links under 1-1 fields
                        $controllerUrl = $controller->absoluteBackendUrl();
                        // View|Add links under dropdowns
                        if (is_null($this->actions)) $this->actions = array();
                        if (!isset($this->actions['view-add-models']))           $this->actions['view-add-models'] = $controllerUrl;
                        if (!isset($this->actions['goto-form-group-selection'])) $this->actions['goto-form-group-selection'] = $controllerUrl;
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

    public function translationKey(string|NULL $name = NULL, bool $forceGeneral = FALSE): string
    {
        /* Translation:
         *  For foreign keys:           acorn.user::lang.models.usergroup.label (pointing TO the user plugin)
         *  For explicit translations:  acorn.finance::lang.models.invoice.user_group: Payee Group
         *  For qualified foreign keys: acorn.finance::lang.models.invoice.payee_user_group (payee_ makes it qualified)
         * is_qualified: Does the field name, [user_group]_id, have the same name as the table it points to, acorn_user_[user_group]s?
         * if not, then it is qualified, and we need a local translation, like [owner]_user_group_id
         */
        $qualifier               = $this->relation1->qualifier();
        $hasExplicitTranslations = ($this->labels && count($this->labels));
        if ($name || $qualifier || $hasExplicitTranslations) {
            // Point to our local plugin translations
            // This will include $this->name with the qualifier
            $key = parent::translationKey($name, $forceGeneral);
        } else {
            // Point to foreign label
            // acorn.user::lang.models.usergroup.label
            // acorn::lang.models.server.label
            $key = $this->relation1->to->translationKey();
        }

        return $key;
    }
}
