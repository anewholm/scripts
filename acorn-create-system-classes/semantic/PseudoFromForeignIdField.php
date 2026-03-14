<?php namespace Acorn\CreateSystem\Semantic;

use Exception;
use Serializable;
use Spyc;
use Acorn\CreateSystem\Adapters\Framework;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;

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
