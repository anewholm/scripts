<?php namespace Acorn\CreateSystem;

use Exception;

require_once('Model.php');
require_once('Controller.php');

class Plugin {
    protected static $plugins = array();

    public $framework;
    public $author;
    public $name;

    public $comment;
    public $pluginMenu;
    public $pluginIcon;
    public $pluginUrl;
    // Translation arrays
    public $pluginNames;
    public $pluginDescriptions;

    public $models = array();

    // ----------------------------------------- Construction
    public static function allFromTables(Framework &$framework, array &$tables): array
    {
        global $YELLOW, $NC;

        foreach ($tables as &$table) {
            if ($table->isPlugin()) {
                // Modules have NULL plugin name
                $authorName = $table->authorName(); // Acorn
                $pluginName = $table->pluginName(); // Lojistiks
                $pluginFullyQualifiedName = "$authorName\\$pluginName";

                if (isset(self::$plugins[$pluginFullyQualifiedName]))
                    $plugin = self::$plugins[$pluginFullyQualifiedName];
                else
                    $plugin = new Plugin($framework, $authorName, $pluginName);

                $plugin->addTable($table);
            }
        }
        return self::$plugins;
    }

    public static function &get(string $pluginName, string $authorName = 'Acorn'): Plugin
    {
        $pluginFullyQualifiedName = "$authorName\\$pluginName";
        return self::$plugins[$pluginFullyQualifiedName];
    }

    public function exists(): bool
    {
        return $this->framework->pluginExists($this);
    }

    protected function __construct(Framework &$framework, string $authorName, string $pluginName)
    {
        $this->framework = $framework;
        $this->author    = $authorName; // Acorn
        $this->name      = $pluginName; // Lojistiks

        self::$plugins[$this->fullyQualifiedName()] = &$this;
    }

    public function addTable(Table|View &$table)
    {
        // Adopt some of the tables comment statements
        $this->comment = $table->comment;
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) {
                if (isset($this->$name)) throw new Exception("Plugin value for [$name] set twice by [$table->name]");
                $this->$nameCamel = $value;
            }
        }

        // A Model and a Controller represents a content table
        if ($table->isContentTable() || $table->isSemiPivotTable() || $table->isReportTable()) {
            $model      = new Model($this, $table);
            $controller = new Controller($model, 'CRUD');
            $model->addController($controller);

            $this->models[$model->name] = &$model;
        }
        //else if ($table->isPivotTable()) {
            // TODO: hasManyDeep likes intermediate models?
            //$model = new Model($this, $table);
            //$this->models[$model->name] = &$model;
        //}

        if ($table->isCentralTable()) {
            // Leaf system
            if (!isset($this->pluginMenu)) $this->pluginMenu = FALSE;
        }
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

    // ----------------------------------------- Data
    public function dotName(): string
    {
        // acorn.finance
        $authorLower = strtolower($this->author);
        $nameLower   = strtolower($this->name);
        return "$authorLower.$nameLower";
    }

    public function dotClassName(): string
    {
        // Acorn.Finance
        return "$this->author.$this->name";
    }

    public function snakeName(): string
    {
        // acorn_finance
        $authorLower = strtolower($this->author);
        $nameLower   = strtolower($this->name);
        return "{$authorLower}_$nameLower";
    }

    // ----------------------------------------- Semantic info
    public function otherPluginRelations(): array
    {
        $relations = array();
        foreach ($this->models as &$model) {
            foreach ($model->relations() as $name => &$relation) {
                // Exclude Modules
                if ($relation instanceof RelationHasManyDeep) {
                    // These create deep circular relations
                } else {
                    if ($relation->to->plugin instanceof Plugin && $relation->to->plugin != $this) {
                        $relations[$name] = &$relation;
                    }
                }
            }
        }
        return $relations;
    }

    public function pluginRequires(): array
    {
        $pluginRequires = array();

        foreach ($this->otherPluginRelations() as &$relation) {
            if (!$relation instanceof RelationFrom) {
                // Do not make requires to Modules
                $otherPlugin = &$relation->to->plugin;
                if ($otherPlugin instanceof Plugin) {
                    $fqn = $otherPlugin->dotClassName();
                    if (!isset($pluginRequires[$fqn])) {
                        $pluginRequires[$fqn] = $otherPlugin;
                    }
                }
            }
        }

        return $pluginRequires;
    }

    public static function fromDotName(string $domain): Plugin|Module|NULL
    {
        $plugin = NULL;
        foreach (Plugin::$plugins as $searchPlugin) {
            if ($searchPlugin->dotName() == $domain) {
                $plugin = $searchPlugin;
                break;
            }
        }
        return $plugin;
    }

    public function is(Plugin|Module &$otherPlugin): bool
    {
        return ($this->fullyQualifiedName() == $otherPlugin->fullyQualifiedName());
    }

    public function isOurs(string $which = NULL): bool
    {
        return ($this->author == 'Acorn'
            && ($which == NULL || $this->name == $which)
        );
    }

    public function isCreateSystemPlugin(): bool
    {
        return $this->framework->wasCreatedByUs($this);
    }

    public function fullyQualifiedName(): string
    {
        return "$this->author\\$this->name";
    }

    public function translationDomain(): string
    {
        return $this->dotName();
    }

    public function langEnPath(): string
    {
        return $this->framework->langEnPath($this);
    }

    public function dirName(): string
    {
        $authorLower = strtolower($this->author);
        $nameLower   = strtolower($this->name);
        return "$authorLower/$nameLower";
    }

    public function absoluteFullyQualifiedName(): string
    {
        return '\\' . $this->fullyQualifiedName();
    }

    // ----------------------------------------- Permissions
    public function allPermissionNames(): array
    {
        $permissions = array();

        foreach ($this->models as &$model) {
            $permissions = array_merge($permissions, $model->allPermissionNames());
        }

        // Check these permissions keys are fully qualified
        foreach ($permissions as $fullyQualifiedKey => &$config) {
            $isQualifiedName = (strstr($fullyQualifiedKey, '.') !== FALSE);
            if (!$isQualifiedName) throw new Exception("Permission [$fullyQualifiedKey] is not qualified");
        }

        return $permissions;
    }
}
