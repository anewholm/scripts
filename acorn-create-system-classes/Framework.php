<?php namespace Acorn\CreateSystem;

class Framework
{
    public const AND_FALSES = TRUE;
    public const FIRST_MULTILINE = FALSE;
    public const ALL_MULTILINE = TRUE;
    public const STD_INDENT = 1;
    public const OVERWRITE_EXISTING = TRUE;
    public const NEW_PROPERTY = FALSE;

    protected $cwd;
    protected $script;
    protected $version;

    public $connection;
    public $database;
    public $username;
    public $password;
    public $db; // DB object

    protected $iconFile;
    protected $iconCurrent;

    protected $FILES       = array();
    protected $ARRAY_FILES = array();
    protected $YAML_FILES  = array();

    // ----------------------------------------- Construct
    protected function __construct(string $cwd, string $scriptDirPath, string $script = 'acorn-create-system', string $version = '1.0')
    {
        $this->cwd     = $cwd;
        $this->scriptDirPath = $scriptDirPath;
        $this->script  = $script;
        $this->version = $version;

        foreach ($this->environment() as $line) {
            if (substr($line, 0, 1) != '#') {
                $lineParts = explode('=', $line);
                if (isset($lineParts[1])) {
                    $name  = trim($lineParts[0]);
                    $value = trim(trim(trim($lineParts[1], '"'), "'"));
                    if (property_exists($this, $name)) $this->$name = $value;
                }
            }
        }
    }

    public function __destruct()
    {
        foreach ($this->FILES as $path => &$contents) {
            file_put_contents($path, $contents);
        }

        foreach ($this->ARRAY_FILES as $path => &$array) {
            $arrayString = $this->varExport($array, 0);
            file_put_contents($path, "<?php return $arrayString;");
        }

        foreach ($this->YAML_FILES as $path => &$array) {
            $yamlString = \Spyc::YAMLDump($array, FALSE, 1000, TRUE);
            file_put_contents($path, $yamlString);
        }
    }

    protected function environment(): array
    {
        return array();
    }

    public static function detect(string $cwd, string $scriptDirPath, string $script = 'acorn-create-system', string $version = '1.0')
    {
        $framework = NULL;
        if (file_exists('.env')) $framework = new WinterCMS($cwd, $scriptDirPath, $script, $version);
        return $framework;
    }

    // ----------------------------------------- Display
    public function __toString(): string
    {
        return $this->fullyQualifiedName();
    }

    public function show(int $indent = 0)
    {
        global $GREEN, $YELLOW;

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$this\n");
    }

    public function fullyQualifiedName(): string
    {
        $class = get_class($this);
        return "$class($this->connection)";
    }

    public function createdByString(): string
    {
        return "Created By $this->script v$this->version";
    }

    // ----------------------------------------- Plugin info
    protected function pluginDirectoryPath(Plugin &$plugin): string
    {
        // Override this
        return '';
    }

    protected function pluginExists(Plugin &$plugin): bool
    {
        return is_file($this->pluginFile($plugin));
    }

    protected function pluginHasGit(Plugin &$plugin): bool
    {
        return is_dir($this->pluginDirectoryPath($plugin) . "/.git");
    }

    protected function whoCreatedBy(Plugin &$plugin): string|NULL
    {
        $createdBy = NULL;
        $path      = $this->pluginFile($plugin);
        if (file_exists($path)) {
            if (!isset($this->FILES[$path])) $this->FILES[$path] = file_get_contents($path);
            $contents  = &$this->FILES[$path];

            if (preg_match("#^// Created By (.*) (.*)$#m", $contents, $matches)) {
                $createdBy = $matches[1];
                $version   = $matches[2];
            }
        }

        return $createdBy;
    }

    public function wasCreatedByUs(Plugin &$plugin): bool
    {
        return ($this->whoCreatedBy($plugin) == 'acorn-create-system');
    }

    public function showPluginStatus(Plugin &$plugin, int $indent = 0)
    {
        global $YELLOW, $GREEN, $NC;

        $exists    = ($this->pluginExists($plugin) ? 'exists'   : '');
        $hasGit    = ($this->pluginHasGit($plugin) ? 'with git' : '');
        $createdBy = $this->whoCreatedBy($plugin);

        $indentString = str_repeat(' ', $indent * 2);
        print("$indentString$plugin->name ${YELLOW}$exists${NC} $hasGit ${GREEN}$createdBy${NC}");
    }

    // ----------------------------------------- DB
    public function isFrameworkTable(string &$tablename): bool
    {
        return FALSE;
    }

    public function isFrameworkModuleTable(string &$tablename): bool
    {
        return FALSE;
    }

    // ----------------------------------------- Array files
    protected function &arrayFileLoad(string $path): array
    {
        if (!$path)
            throw new \Exception("ARRAY_FILE path is empty");
        if (!isset($this->ARRAY_FILES[$path])) $this->ARRAY_FILES[$path] = (file_exists($path) ? include($path) : array());
        return $this->ARRAY_FILES[$path];
    }

    protected function arrayFileValueExists(string $path, string $dotPath): bool
    {
        $array = &$this->arrayFileLoad($path);
        $keys  = explode('.', $dotPath);
        $name  = array_pop($keys);
        $level = &$array;
        foreach ($keys as $step) {
            if (!isset($level[$step])) $level[$step] = array();
            $level = &$level[$step];
        }
        return isset($level[$name]);
    }

    protected function arrayFileSet(string $path, string $dotPath, string|array|int $newValue, bool $throwIfAlreadySet = TRUE)
    {
        $array = &$this->arrayFileLoad($path);
        $keys  = explode('.', $dotPath);
        $name  = array_pop($keys);
        $level = &$array;
        foreach ($keys as $step) {
            if (!isset($level[$step])) $level[$step] = array();
            $level = &$level[$step];
            if (!is_array($level)) throw new \Exception("Pre-level [$step] in [$dotPath] is not array when trying to set [$name]");
        }

        if (isset($level[$name])) {
            if ($throwIfAlreadySet) throw new \Exception("[$dotPath] already set in [$path]");
            if (is_array($level[$name])) $newValue = array_merge($level[$name], $newValue);
        }
        $level[$name] = $newValue;

        // Destructor will write cached arrays
    }

    // ---------------------------------------------- Filesystem
    protected function removeDir(string $dirPath, bool $removeTopLevelHidden = TRUE, bool $removeTopLevel = TRUE, bool $throwIfNotFound = TRUE): void
    {
        if (!$dirPath) throw new \Exception("removeDir path is empty");
        if (is_dir($dirPath)) {
            if (substr($dirPath, -1) != '/') $dirPath .= '/';

            $files = glob($dirPath . '*', GLOB_MARK);
            foreach($files as $file) {
                $isHidden = (substr($file, 0, 1) == '.');
                if ($removeTopLevelHidden || !$isHidden) {
                    if (is_dir($file)) $this->removeDir($file);
                    else               unlink($file);
                }
            }
            if ($removeTopLevel) rmdir($dirPath);
        } else if ($throwIfNotFound) {
            throw new \InvalidArgumentException("[$dirPath] must be a directory");
        }
    }

    protected function setFileContents(string $path, string $newContent, bool $newline = TRUE)
    {
        if (!$path) throw new \Exception("FileContents path is empty");
        $newlineCharacter = ($newline ? "\n" : '');
        $this->FILES[$path] = "$newContent$newlineCharacter";
    }

    protected function getNextIcon(): string
    {
        $array    = &$this->yamlFileLoad($this->iconFile);
        $fqn      = $array[0]['icons'][$this->iconCurrent++];
        $fqnParts = explode(' ', $fqn);
        return end($fqnParts);
    }

    // ----------------------------------------- YAML
    protected function &yamlFileLoad(string $path): array
    {
        if (!$path) throw new \Exception("YAML path is empty");
        if (!isset($this->YAML_FILES[$path])) $this->YAML_FILES[$path] = (file_exists($path) ? \Spyc::YAMLLoad($path) : array());
        return $this->YAML_FILES[$path];
    }

    protected function yamlFileValueExists(string $path, string $dotPath): bool
    {
        $array = &$this->yamlFileLoad($path);
        $keys  = explode('.', $dotPath);
        $name  = array_pop($keys);
        $level = &$array;
        foreach ($keys as $step) {
            if (!isset($level[$step])) $level[$step] = array();
            $level = &$level[$step];
        }
        return isset($level[$name]);
    }

    protected function yamlFileSet(string $path, string $dotPath, string|array|int $newValue, bool $throwIfAlreadySet = TRUE, string $complexDotName = NULL)
    {
        $array = &$this->yamlFileLoad($path);
        $keys  = explode('.', $dotPath);
        if ($complexDotName) $name = $complexDotName;
        else                 $name = array_pop($keys);

        $level = &$array;
        foreach ($keys as $step) {
            if (!isset($level[$step])) $level[$step] = array();
            $level = &$level[$step];
            if (!is_array($level)) throw new \Exception("Pre-level [$step] in [$dotPath] is not array when trying to set [$name]");
        }
        if ($throwIfAlreadySet && isset($level[$name])) throw new \Exception("[$dotPath] already set in [$path]");
        $level[$name] = $newValue;

        // Destructor will write cached arrays
    }

    protected function yamlFileUnSet(string $path, string $dotPath, bool $throwIfNotSet = FALSE)
    {
        $array = &$this->yamlFileLoad($path);
        $keys  = explode('.', $dotPath);
        $name  = array_pop($keys);
        $level = &$array;
        foreach ($keys as $step) {
            if (!isset($level[$step])) $level[$step] = array();
            $level = &$level[$step];
        }
        if ($throwIfNotSet && !isset($level[$name])) throw new \Exception("[$dotPath] not already set in [$path]");
        unset($level[$name]);

        // Destructor will write cached arrays
    }

    // ----------------------------------------- File
    protected function appendToFile(string $path, string $newContent, int $indent = 0, bool $newline = TRUE, bool $throwIfContentExists = TRUE)
    {
        if (!$path) throw new \Exception("FILES path is empty");
        $newlineCharacter = ($newline ? "\n" : '');
        if (!isset($this->FILES[$path])) $this->FILES[$path] = (file_exists($path) ? file_get_contents($path) : '');
        $contents  = &$this->FILES[$path];

        if ($throwIfContentExists && strstr($contents, $newContent)) throw new \Exception("[$newContent] already found in [$path]");

        $contents .= "$newContent$newlineCharacter";
    }

    protected function replaceInFile(string $path, string $regex, string $replacement = '', bool $throwIfNotFound = TRUE)
    {
        if (!$path) throw new \Exception("FILES path is empty");
        if (!isset($this->FILES[$path])) $this->FILES[$path] = file_get_contents($path);
        $contents = &$this->FILES[$path];

        if ($throwIfNotFound) {
            $matched = preg_match($regex, $contents);
            if ($matched === 0)          throw new \Exception("[$regex] not found in [$path]");
            else if ($matched === FALSE) throw new \Exception("Failed to compile [$regex]");
        }

        $contents = preg_replace($regex, $replacement, $contents);

        // Destructor will write cached files
    }

    protected function runBashScript(string $path, bool $chdir = FALSE, string &$output = NULL, bool $throwOnNoZeroReturn = TRUE): int
    {
        if (!$path) throw new \Exception("bash path is empty");
        $cwd = getcwd();

        if ($chdir) chdir(dirname($path));
        $lastline = exec($path, $output, $ret);
        if ($ret && $throwOnNoZeroReturn) throw new \Exception("Bash script [$path] returned [$ret] with [$lastline]");
        if ($chdir) chdir($cwd);

        return $ret;
    }

    // ---------------------------------------------- Functions & Property control
    protected function writeFileUses(string $path, array &$uses)
    {
        if (!$path) throw new \Exception("FileUses path is empty");
        $usesString = '';
        foreach ($uses as $name => $include) {
            if ($include) $usesString .= "use $name;\n";
        }
        $this->replaceInFile($path, '/^(namespace .*$)/m', "\\1\n\n$usesString");
    }

    protected function writeClassTraits(string $path, array &$traits, int $indent = 1)
    {
        if (!$path) throw new \Exception("ClassTraits path is empty");
        $indentString = str_repeat(' ', $indent*4);
        $traitsString = '';
        foreach ($traits as $name => $include) {
            if ($include) $traitsString .= "${indentString}use $name;\n";
        }
        $this->replaceInFile($path, '/^{$/m', "{\n$traitsString\n");
    }

    protected function addStaticMethod(string $path, string $name, string $body, string $scope = 'public', int $indent = 1)
    {
        if (!$path) throw new \Exception("StaticMethod path is empty");
        return $this->addMethod($path, $name, $body, $scope, TRUE, $indent);
    }

    protected function addMethod(string $path, string $name, string $body, string $scope = 'public', bool $static = FALSE, int $indent = 1)
    {
        if (!$path) throw new \Exception("Method path is empty");
        $indentString  = str_repeat(' ', $indent*4);
        $indentString2 = str_repeat(' ', ($indent+1)*4);
        $staticString  = ($static ? ' static' : '');
        $this->replaceInFile($path, '/^}$/m', <<<FUNCTION

$indentString$scope$staticString function $name() {
$indentString2# Auto-injected by acorn-create-system
$indentString2$body
$indentString}
}
FUNCTION
        );
    }

    protected function setPropertyInClassFile(string $path, string $name, string|int|array $value, bool $overwriteExisting = self::OVERWRITE_EXISTING, string $scope = 'public', int $indent = self::STD_INDENT, bool $passthrough = self::FIRST_MULTILINE)
    {
        if (!$path) throw new \Exception("FILES path is empty");
        if (!isset($this->FILES[$path])) $this->FILES[$path] = file_get_contents($path);
        $contents = &$this->FILES[$path];

        $indentString = str_repeat(' ', $indent*4);
        $valueString  = $value;
        if      (is_array($valueString))  $valueString = $this->varExport($valueString, $indent, TRUE, $passthrough);
        else if (is_string($valueString)) $valueString = "'" . str_replace("'", "\\'", $valueString) . "'";

        if ($overwriteExisting) {
            $regexExistingPropertyLine = "/^$indentString$scope +\\\$$name *=[^;]*;/sm";
            $this->replaceInFile($path, $regexExistingPropertyLine, "$indentString$scope \$$name = $valueString;");
        } else {
            $this->replaceInFile($path, '/^{$/m', "{\n$indentString$scope \$$name = $valueString;");
        }
    }

    protected function varExport(array &$array, int $indent = 1, bool $multiLine = TRUE, bool $passthrough = TRUE): string
    {
        // Clauses
        $valueClauses = array();
        foreach ($array as $name => $value) {
            if      (is_string($value)) $value = "'" . str_replace("'", "\\'", $value) . "'";
            else if (is_bool($value))   $value = ($value ? 'TRUE' : 'FALSE');
            else if (is_array($value))  $value = $this->varExport($value, $indent+1, $passthrough, $passthrough);
            else if (is_object($value) && method_exists($value, 'absoluteFullyQualifiedName'))
                $value = $value->absoluteFullyQualifiedName(TRUE);

            if (is_numeric($name)) array_push($valueClauses, $value);
            else                   array_push($valueClauses, "'$name' => $value");
        }

        // Assembly
        $string = '[';
        if (count($valueClauses)) {
            if ($multiLine) {
                $indentString = str_repeat(' ', ++$indent*4);
                $string .= "\n$indentString";
                $string .= implode(",\n$indentString", $valueClauses);
                $indentString = str_repeat(' ', --$indent*4);
                $string .= "\n$indentString";
            } else {
                $string .= implode(', ', $valueClauses);
            }
        }
        $string .= ']';

        return $string;
    }

    protected function removeEmpty(array $array, bool $andFalses = FALSE): array
    {
        $cleanedArray = array();
        foreach ($array as $name => $value) {
            $empty = (
                   is_null($value)
                || (is_string($value) && !$value)
                || (is_array($value)  && !count($value))
                || ($andFalses && is_bool($value) && !$value)
            );
            if (!$empty) $cleanedArray[$name] = $value;
        }
        return $cleanedArray;
    }

    protected function removeFunction(string $path, string $functionName, string $scope = 'public', int $indent = 1)
    {
        if (!$path) throw new \Exception("Function path is empty");
        $indentString = str_repeat(' ', $indent*4);
        $this->replaceInFile($path, "/$scope function $functionName\(/", "$scope function ${functionName}_REMOVED(");
    }

    protected function changeArrayReturnFunction(string $path, string $functionName, string $arrayDotPath, $newValue)
    {
        // TODO: Support the function name searching support and dot path
        if (!$path) throw new \Exception("ArrayReturnFunction path is empty");
        if (strstr($arrayDotPath, '.') !== FALSE) throw new \Exception("Dot array replacement [$arrayDotPath] not supported yet");
        $escapedValue = str_replace("'", "\\'", $newValue);

        $this->replaceInFile($path, "/'$arrayDotPath' *=>.*/", "'$arrayDotPath' => '$escapedValue',");
    }

    // ---------------------------------------------- Create
    public function create(Plugin &$plugin)
    {
        global $YELLOW, $GREEN, $RED, $NC;

        if ($this->pluginExists($plugin)) {
            $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
            print("${GREEN}REMOVING${NC} existing plugin sub-directories and files from [$pluginDirectoryPath]...\n");
            $this->removeDir($pluginDirectoryPath, FALSE, FALSE);
        }

        // Abstracted MVC creates
        $this->createPlugin($plugin);
        $this->createMenus($plugin);
        foreach ($plugin->models as $model) {
            $this->createModel($model);
            $this->createFormInterface($model);
            $this->createListInterface($model);
            foreach ($model->controllers as $controller) {
                $this->createController($controller);
            }
        }

        $this->runChecks($plugin);

        /* TODO: GIT
        if [ -d .git ]; then
            echo "  Git repository found. Leaving un-changed"
        else
            echo "  Init git, without a  push, to assumed repo $git_group/$plugin_lowercase, branch main"
            git init -b main
            git remote add origin git@$git_server:$git_group/$plugin_lowercase.git
            git config --global --add safe.directory "$run_dir/$plugin_dir"
        fi
        */
    }

    // Abstracted framework dependant
    protected function createPlugin(Plugin &$plugin, bool $overwrite = FALSE) {}
    protected function createModel(Model &$model, bool $overwrite = FALSE) {}
    protected function createFormInterface(Model &$model, bool $overwrite = FALSE) {}
    protected function createController(Controller &$controller, bool $overwrite = FALSE) {}
    protected function createListInterface(Model &$model, bool $overwrite = FALSE) {}
    protected function runChecks(Plugin &$plugin) {}
}