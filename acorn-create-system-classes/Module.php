<?php namespace Acorn\CreateSystem;

require_once('Model.php');

class Module {
    protected static $modules = array();

    public $framework;
    public $author;
    public $name;

    public $models = array();

    // ----------------------------------------- Construction
    public static function allFromTables(Framework &$framework, array &$tables): array
    {
        foreach ($tables as &$table) {
            if ($table->isModule()) {
                $authorName = $table->authorName();
                $moduleName = $table->moduleName();

                if (isset(self::$modules[$moduleName]))
                    $module = self::$modules[$moduleName];
                else
                    $module = new Module($framework, $authorName, $moduleName);

                $module->addTable($table);
            }
        }
        return self::$modules;
    }

    public static function &get(string $moduleName): Module
    {
        return self::$modules[$moduleName];
    }

    protected function __construct(Framework &$framework, string $authorName, string $moduleName)
    {
        $this->framework = $framework;
        $this->author    = $authorName;
        $this->name      = $moduleName;

        self::$modules[$this->name] = &$this;
    }

    public function addTable(Table &$table)
    {
        if ($table->isContentTable() || $table->isReportTable()) {
            $model = new Model($this, $table);
            $this->models[$model->name] = new Model($this, $table);
        }
    }

    // ----------------------------------------- Info
    public function fullyQualifiedName(): string
    {
        return $this->name;
    }

    public function dotName()
    {
        return strtolower($this->name);
    }

    public function dotClassName(): string
    {
        // Acorn
        return $this->author;
    }

    public function absoluteFullyQualifiedName(): string
    {
        return '\\' . $this->fullyQualifiedName();
    }

    // ----------------------------------------- Semantic Info
    public function otherPluginRelations(): array
    {
        $relations = array();
        foreach ($this->models as &$model) {
            foreach ($model->relations() as $name => &$relation) {
                if ($relation->to->plugin != $this) {
                    $relations[$name] = &$relation;
                }
            }
        }
        return $relations;
    }

    public function isOurs(string $notUsed = NULL): bool
    {
        return ($this->name == 'Acorn');
    }

    public function translationDomain(): string
    {
        return $this->dotName();
    }

    // ----------------------------------------- Display
    public function __toString(): string
    {
        return $this->fullyQualifiedName();
    }

    public function show(int $indent = 0, bool $showModels = TRUE)
    {
        global $YELLOW, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$YELLOW$this$NC\n");
        if ($showModels) foreach ($this->models as $model) $model->show($indent + 1);
        print("\n");
    }
}
