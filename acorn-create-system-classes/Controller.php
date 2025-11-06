<?php namespace Acorn\CreateSystem;

use Spyc;

class Controller {
    protected static $controllers = array();

    public $model;

    public $name;
    public $role;

    public $comment;
    public $menu = TRUE;
    public $menuSplitter = FALSE;
    public $menuTaskItems; // array
    public $icon;
    public $url;
    public $qrCodeScan;
    public $allControllers;

    // Output arrays
    protected $filters = array();

    public function __construct(Model &$model, string $role = 'CRUD')
    {
        // name is NOT unique
        $this->model   = &$model;
        $this->name    = $model->crudControllerName();
        $this->role    = $role;

        // Adopt some of the models comment statements
        $this->comment = $model->comment;
        foreach (Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (property_exists($this, $nameCamel)) $this->$nameCamel = $value;
        }

        self::$controllers[$this->fullyQualifiedName()] = &$this;
    }

    public function dirName(): string
    {
        return strtolower($this->name);
    }

    public function updateModelUrl(Model $model): string
    {
        return $this->relativeUrl('update', $model->id());
    }

    public function absoluteBackendUrl(string $action = NULL, string $id = NULL): string
    {
        return $this->relativeUrl($action, $id, TRUE);
    }

    public function relativeUrl(string $action = NULL, string $id = NULL, bool $absoluteBackend = FALSE): string
    {
        $url = $this->url;
        if (!$url) {
            $pluginDirName = $this->model->plugin->dirName();
            $thisDirName   = $this->dirName();
            $backendPart   = ($absoluteBackend ? '/backend/' : '');
            $url = "$backendPart$pluginDirName/$thisDirName";
        }

        if ($action) {
            $url .= "/$action";
            if ($id) $url .= "/$id";
        }
        return $url;
    }

    public function exists(): bool
    {
        // Useful for custom plugins
        // Requires the framework to be loaded
        return class_exists($this->absoluteFullyQualifiedName());
    }

    // ----------------------------------------- Display
    public function __toString(): string
    {
        return $this->fullyQualifiedName();
    }

    public function author(): string
    {
        return $this->model->author();
    }

    public function show(int $indent = 0)
    {
        global $GREEN, $NC;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$GREEN$this$NC\n");
    }

    public function fullyQualifiedName(bool $withClassString = FALSE): string
    {
        $classString = ($withClassString ? '::class' : '');
        $pluginFullyQualifiedName = $this->model->plugin->fullyQualifiedName();
        return "$pluginFullyQualifiedName\\Controllers\\$this->name$classString";
    }

    public function absoluteFullyQualifiedName(bool $withClassString = FALSE): string
    {
        return '\\' . $this->fullyQualifiedName($withClassString);
    }
}
