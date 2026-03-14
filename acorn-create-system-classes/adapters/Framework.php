<?php namespace Acorn\CreateSystem\Adapters;

use Exception;
use Spyc;
use Acorn\CreateSystem\Semantic\Plugin;
use Acorn\CreateSystem\Semantic\Module;
use Acorn\CreateSystem\Semantic\Model;
use Acorn\CreateSystem\Semantic\Controller;
use Acorn\CreateSystem\Database\MaterializedView;
use Acorn\CreateSystem\Util\Str;

class Framework
{
    use PhpCodeWriterTrait;
    public const AND_FALSES = TRUE;
    public const NOT_FALSES = FALSE;
    public const FIRST_MULTILINE = FALSE;
    public const ALL_MULTILINE = TRUE;
    public const STD_INDENT = 1;
    public const OVERWRITE_EXISTING = TRUE;
    public const NEW_PROPERTY = FALSE;
    public const CACHE = TRUE;
    public const NO_CACHE = FALSE;
    public const NO_THROW = FALSE;
    public const THROW = TRUE;
    public const PLUGIN_ONLY = TRUE;
    public const PLUGIN_OR_MODULE = FALSE;

    protected $cwd;
    protected $script;
    protected $version;
    protected $scriptDirPath;

    public $connection;
    public $database;
    public $username;
    public $password;
    public $db; // DB object

    protected $iconFile;
    protected $iconCurrent;

    // File cache. Flushed in ~destructor
    protected $FILES       = array();
    protected $ARRAY_FILES = array();
    protected $YAML_FILES  = array();
    // For translation work
    // DB Object => Language key, useful for translation work
    // plugin: table|view|function: [column:] en|ku|ar: <text>
    // All translations should be added in to this file
    protected $LANG        = array();

    // These have identical keys
    // and should be referenced from columns 
    // with the same name where explicit labels are empty
    // [en] keys should be checked for column names, others assumed correct
    // WinterCMS.php will write the locale array in to each plugin lang.php's
    public static $standardTranslations = array(
        'en' => array(
            'id'     => 'ID',
            'name'   => 'Name',
            'short_name'  => 'Short name',
            'description' => 'Description',
            'type'   => 'Type',
            'image'  => 'Image',
            'select' => 'Select',
            'select_existing' => 'Selected existing',
            'created_at_event' => 'Created At',
            'updated_at_event' => 'Updated At',
            'created_by_user'  => 'Created By',
            'updated_by_user'  => 'Updated By',
            'created_at'   => 'Created At',
            'updated_at'   => 'Updated At',
            'created_by'   => 'Created By',

            // Some fields
            'quantity' => 'Quantity',
            'distance' => 'Distance',
            'parent'   => 'Parent',
            'current' => 'Current',
            'enabled' => 'Enabled',
            'primary' => 'Primary',
            'translation' => 'Translation',
            'sort_order' => 'Order',
            'ordinal' => 'Ordinal',
            'minimum' => 'Minimum',
            'maximum' => 'Maximum',
            'required' => 'Required',
            'code'    => 'Code',

            // Menus
            'actions' => 'Actions',
            'setup'   => 'Setup',
            'reports' => 'Reports',

            // In-built QR codes
            'qrcode'          => 'QR Code',
            'qrcode_scan'     => 'QR Code Scan',
            'find_by_qrcode'  => 'Find by QR code',
            'state_indicator' => 'Status',

            // Standard Buttons
            'create'     => 'Create',
            'new'        => 'New',
            'add'        => 'Add',
            'print'      => 'Print',
            'save_and_print'    => 'Save and Print',
            'correct_and_print' => 'Correct and Print',
            'advanced'   => 'Advanced',

            // System
            'response'                   => 'HTTP call response',
            'replication_debug'          => 'Replication Debug',
            'trigger_http_call_response' => 'Trigger HTTP call response',
            'import_source'              => 'Import Source',
        ),
        'ar' => array(
            'id'     => 'المعرف',
            'name'   => 'الأسم',
            'short_name'  => 'الاسم المختصر',
            'description' => 'التفاصيل',
            'type'   => 'النوع',
            'image'  => 'الصور',
            'select' => 'إختيار',
            'select_existing' => 'حدد عنوانًا موجودًا',
            'created_at_event' => 'تم التسجيل في',
            'updated_at_event' => 'تم التحديث في',
            'created_by_user'  => 'الانشاء بواسطة',
            'updated_by_user'  => 'التحديث بواسطة',
            'created_at'   => 'تم التسجيل في',
            'updated_at'   => 'تم التحديث في',
            'created_by'   => 'الانشاء بواسطة',

            // Some fields
            'quantity' => 'الكمية',
            'distance' => 'المسافة',
            'parent' => 'محتوى المنطقة',
            'current' => 'الحالي',
            'enabled' => 'مُمَكَّن',
            'primary' => 'اساسي',
            'translation' => 'الترجمة',
            'sort_order' => 'ترتيب الفرز',
            'ordinal' => 'ترتيبي',
            'minimum' => 'الحد الأدنى',
            'maximum' => 'الحد الأقصى',
            'required' => 'مطلوب',
            'code'    => 'شفرة',

            // Menus
            'actions' => 'النشاط',
            'setup' => 'تثبيت',
            'reports' => 'التقارير',

            // In-built QR codes
            'qrcode'          => 'رمز QR',
            'qrcode_scan'     => 'مسح الرمز',
            'find_by_qrcode'  => 'البحث بواسطة الرمز',
            'state_indicator' => 'حالة',

            // Standard Buttons
            'create'     => 'نشاء ماركة جديدة',
            'new'        => 'ماركة جديدة',
            'add'        => 'إضافة',
            'print'      => 'مطبعة',
            'save_and_print'    => 'حفظ وطباعة',
            'correct_and_print' => 'حفظ التصحيح وطباعته',
            'advanced'   => 'متقدم',

            // System
            'response'                   => 'HTTP call response',
            'replication_debug'          => 'تصحيح أخطاء التكرار',
            'trigger_http_call_response' => 'تشغيل استجابة اتصال HTTP',
            'import_source'              => 'مصدر الاستيراد',
        ),
        'ku' => array(
            'id'     => 'Hejmara',
            'name'   => 'Nav',
            'short_name'  => 'Nave kin',
            'description' => 'Têbînî',
            'type'   => 'Cure',
            'image'  => 'Wêne',
            'select' => 'Hilbijêre',
            'select_existing' => 'Vebijêrkek heyî hilbijêre',
            'created_at_event' => 'Dîrokê afirandin',
            'updated_at_event' => 'Dîrokê gûherrandin',
            'created_by_user'  => 'Bikaranîvan afirandin',
            'updated_by_user'  => 'Bikaranîvan gûherrandin',
            'created_at'  => 'Dîrokê afirandin',
            'updated_at'  => 'Dîrokê gûherrandin',
            'created_by'  => 'Bikaranîvan afirandin',

            // Some fields
            'quantity' => 'Jimarî',
            'distance' => 'Dûrî',
            'parent'   => 'Pêşî',
            'current' => 'Vêga',
            'enabled' => 'Çalakkirî',
            'primary' => 'Bingehîn',
            'translation' => 'Werger',
            'sort_order' => 'Rêza',
            'ordinal' => 'Rêz',
            'minimum' => 'Herî kêm',
            'maximum' => 'Herî zêde',
            'required' => 'Pêwîst',
            'code'    => 'Kod',

            // Menus
            'actions' => 'Çalakîyên',
            'setup'   => 'Veavakirin',
            'reports' => 'Raporên',

            // In-built QR codes
            'qrcode'        => 'QR Koda',
            'qrcode_scan'   => 'QR Koda Xwendin',
            'find_by_qrcode' => 'Bi koda QR-ê bibînin',
            'state_indicator' => 'Rewş',

            // Standard Buttons
            'create'     => 'Afirandin',
            'new'        => 'Nû',
            'add'        => 'Lêzêdedike',
            'print'      => 'Çap',
            'save_and_print'    => 'Rizgardike û Çap',
            'correct_and_print' => 'Lihevanîn û Çap',
            'advanced'   => 'Pêşveçû',

            // System
            'response'                   => 'HTTP call response', // TODO: Rename "response" to "http_response"
            'replication_debug'          => 'Replication Debug',
            'trigger_http_call_response' => 'Trigger HTTP call response',
            'import_source'              => 'Çavkaniya importkirinê',
        ),
    );

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
        $this->writeOutFiles();
    }

    protected function writeOutFiles(bool $show = FALSE)
    {
        if ($show) {
            $allFiles = array_merge($this->FILES, $this->ARRAY_FILES, $this->YAML_FILES, array(
                'lang.yaml' => TRUE
            ));
            print(implode("\n", array_keys($allFiles)) . "\n");
            exit(0);
        }

        // For translation work
        // DB Object => Language key, useful for translation work
        // plugin: table|view|function: [column:] en|ku|ar: <text>
        // All translations should be added in to this file
        $yamlString = Spyc::YAMLDump($this->LANG, FALSE, 1000, TRUE);
        file_put_contents('lang.yaml', $yamlString);

        // We will get Ghost writing if the same file is cached & changed in multiple places
        $overlap = array_intersect_key($this->FILES, $this->ARRAY_FILES, $this->YAML_FILES);
        if (count($overlap)) {
            $overlapKeys = implode(', ', array_keys($overlap));
            throw new Exception("[$overlapKeys] are present in multiple different file caches");
        }

        foreach ($this->FILES as $path => &$contents) {
            file_put_contents($path, $contents);
        }

        foreach ($this->ARRAY_FILES as $path => &$array) {
            $arrayString = $this->varExport($array, 0);
            file_put_contents($path, "<?php return $arrayString;");
        }

        foreach ($this->YAML_FILES as $path => &$array) {
            $yamlString = Spyc::YAMLDump($array, FALSE, 1000, TRUE);
            file_put_contents($path, $yamlString);
        }
    }

    protected function environment(): array
    {
        return array();
    }

    public function appUrl(): string {return NULL;}
    public function dbHost(): string {return NULL;}
    public function dbPort(): string {return NULL;}
    public function dbDatabase(): string {return NULL;}
    public function dbUsername(): string {return NULL;}
    public function dbPassword(): string {return NULL;}

    // Registry of detector classes. Each subclass registers itself via registerDetector().
    protected static array $detectors = [];

    public static function registerDetector(string $class): void
    {
        self::$detectors[] = $class;
    }

    // 'targeted' adapters fire when run inside a matching project (e.g. WinterCMS, Drupal).
    // 'full' adapters fire based on server environment and always process all plugins (e.g. OLAP).
    public static function scope(): string { return 'targeted'; }

    // Detect the single primary (targeted) adapter for the given cwd.
    public static function detect(string $cwd, string $scriptDirPath, string $script = 'acorn-create-system', string $version = '1.0'): ?self
    {
        foreach (self::$detectors as $detectorClass) {
            if ($detectorClass::scope() !== 'targeted') continue;
            $framework = $detectorClass::tryDetect($cwd, $scriptDirPath, $script, $version);
            if ($framework) return $framework;
        }
        return NULL;
    }

    // Detect all supplementary (full-scope) adapters present in this environment.
    // Returns class names — instances are constructed later with full context.
    public static function detectSupplementary(string $cwd): array
    {
        $classes = [];
        foreach (self::$detectors as $detectorClass) {
            if ($detectorClass::scope() === 'full' && $detectorClass::isPresent($cwd)) {
                $classes[] = $detectorClass;
            }
        }
        return $classes;
    }

    // Override in full-scope adapters to probe the environment.
    public static function isPresent(string $cwd): bool { return false; }

    public static function tryDetect(string $cwd, string $scriptDirPath, string $script, string $version): ?static
    {
        return NULL;
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
    public function pluginDirectoryPath(Plugin &$plugin): string
    {
        // Override this
        return '';
    }

    public function modelFileDirectoryPath(Model &$model, string $file = NULL): string
    {
        // Override this
        return '';
    }

    public function pluginExists(Plugin &$plugin): bool
    {
        return is_file($this->pluginFile($plugin));
    }

    protected function pluginHasGit(Plugin &$plugin): bool
    {
        return is_dir($this->pluginDirectoryPath($plugin) . "/.git");
    }

    public function langPath(Plugin|Module $plugin, string $lang = NULL): string
    {
        // Override this
        return '';
    }

    public function langEnPath(Plugin|Module $plugin): string
    {
        // Override this
        return '';
    }

    protected function whoCreatedBy(Plugin|Module &$plugin): string|NULL
    {
        $createdBy = NULL;
        $path      = $this->pluginFile($plugin);
        // We do not want to cache in FILES and thus overwrite the Plugin files
        // but we do want the LIVE version in case it is this plugin that is being created
        $contents  = $this->fileLoad($path, self::NO_CACHE);
        if (preg_match("#^// Created By (.*) (.*)$#m", $contents, $matches)) {
            $createdBy = $matches[1];
            $version   = $matches[2];
        }

        return $createdBy;
    }

    public function wasCreatedByUs(Plugin|Module &$plugin): bool
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
        print("$indentString$plugin->name {$YELLOW}$exists{$NC} $hasGit {$GREEN}$createdBy{$NC}");
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
    protected function &arrayFileLoad(string $path, bool $cache = self::CACHE): array
    {
        // TODO: We should still check the cache, even if we don't store it
        // because something else may be writing to this file
        if (!$path) 
            throw new Exception("ARRAY_FILE path is empty");
        $content = (file_exists($path) ? include($path) : array());
        if ($cache) {
            if (!isset($this->ARRAY_FILES[$path])) $this->ARRAY_FILES[$path] = $content;
            return $this->ARRAY_FILES[$path];
        }
        return $content;
    }

    protected function arrayFileValueExists(string $path, string $dotPath, bool $cache = self::CACHE): bool
    {
        $array = &$this->arrayFileLoad($path, $cache);
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
            if (!is_array($level)) throw new Exception("Pre-level [$step] in [$dotPath] is not array when trying to set [$name]");
        }

        if (isset($level[$name])) {
            if ($throwIfAlreadySet) 
                throw new Exception("[$dotPath] already set in [$path]");
            if (is_array($level[$name])) $newValue = array_merge($level[$name], $newValue);
        }
        $level[$name] = $newValue;

        // Destructor will write cached arrays
    }

    protected function arrayFileUnSet(string $path, string $dotPath, bool $throwIfNotSet = TRUE)
    {
        $array = &$this->arrayFileLoad($path);
        $keys  = explode('.', $dotPath);
        $name  = array_pop($keys);
        $level = &$array;
        foreach ($keys as $step) {
            if (!isset($level[$step])) $level[$step] = array();
            $level = &$level[$step];
            if (!is_array($level)) 
                throw new Exception("Pre-level [$step] in [$dotPath] is not array when trying to unset [$name]");
        }

        if (isset($level[$name])) {
            unset($level[$name]);
        } else if ($throwIfNotSet) {
            throw new Exception("[$dotPath] not set in [$path]");
        }

        // Destructor will write cached arrays
    }

    protected function langFileSet(string $path, string $dotPath, string|array $text, string $langName, object|NULL $dbObject, bool $throwIfAlreadySet = TRUE, string $comment = NULL)
    {
        if (!$langName) 
            throw new Exception("Lang name required when setting [$dotPath]");

        // Set the ~/lang/<language>/lang.php file
        $this->arrayFileSet($path, $dotPath, $text, $throwIfAlreadySet);

        if ($dbObject) {
            // Contribute to the DB language translation file
            // For ease for someone to translate and feed back in to the DB
            if (!method_exists($dbObject, 'dbLangPath')) throw new Exception("Incompatible DB object when setting [$dotPath]");
            $dbLangPath = $dbObject->dbLangPath();

            if (!is_array($text)) $text = array('' => $text);
            if ($comment) $this->yamlFileSet('lang.yaml', "$dbLangPath.#", $comment, FALSE);
            foreach ($text as $key => $value) {
                $langFileDotPath = ($key ? "$dbLangPath.$key.$langName" : "$dbLangPath.$langName");
                $this->yamlFileSet('lang.yaml', $langFileDotPath, $value, FALSE);
                // Fill out missing values, to be completed
                foreach (array('en', 'ku', 'ar') as $langNameMissing) {
                    $langFileDotPath = ($key ? "$dbLangPath.$key.$langNameMissing" : "$dbLangPath.$langNameMissing");
                    if (!$this->yamlFileValueExists('lang.yaml', $langFileDotPath)) $this->yamlFileSet('lang.yaml', $langFileDotPath, '.');
                }
            }
        }
    }

    // ---------------------------------------------- Filesystem
    public static function copyDir(string $source, string $dest, bool $overwrite = TRUE, int $permissions = 0755): void
    {
        if (file_exists($dest) && $overwrite) self::removeDir($dest);

        mkdir($dest, $permissions);

        foreach (
            $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($source, \RecursiveDirectoryIterator::SKIP_DOTS),
            \RecursiveIteratorIterator::SELF_FIRST) as $item
        ) {
            if ($item->isDir()) mkdir($dest . DIRECTORY_SEPARATOR . $iterator->getSubPathname());
            else                copy($item, $dest . DIRECTORY_SEPARATOR . $iterator->getSubPathname());
        }
    }


    public static function removeDir(string $dirPath, bool $removeTopLevelHidden = TRUE, bool $removeTopLevel = TRUE, bool $throwIfNotFound = TRUE): void
    {
        if (!$dirPath) throw new Exception("removeDir path is empty");
        if (is_dir($dirPath)) {
            if (substr($dirPath, -1) != '/') $dirPath .= '/';

            $files = glob($dirPath . '*', GLOB_MARK);
            foreach($files as $file) {
                $isHidden = (substr($file, 0, 1) == '.');
                if ($removeTopLevelHidden || !$isHidden) {
                    if (is_dir($file)) self::removeDir($file);
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
        if (!$path) throw new Exception("FileContents path is empty");
        $newlineCharacter = ($newline ? "\n" : '');
        $this->FILES[$path] = "$newContent$newlineCharacter";
    }

    // ----------------------------------------- YAML
    public static function camelKeys(array $array, bool $recursive = TRUE): array
    {
        $camelArray = array();
        foreach ($array as $name => $value) {
            $camelName = (is_numeric($name) ? $name : Str::camel($name));
            if ($recursive && is_array($value)) $value = self::camelKeys($value);
            $camelArray[$camelName] = $value;
        }

        return $camelArray;
    }

    public function &yamlFileLoad(string $path, bool $cache = self::CACHE, bool $throwIfNotFound = self::NO_THROW): array
    {
        // TODO: We should still check the cache, even if we don't store it
        // because something else may be writing to this file
        if (!$path) throw new Exception("YAML path is empty");

        if ($cache) {
            if (!isset($this->YAML_FILES[$path])) {
                if ($throwIfNotFound && !file_exists($path)) 
                    throw new Exception("YAML file not found");
                $this->YAML_FILES[$path] = (file_exists($path) ? Spyc::YAMLLoad($path) : array());
            }
            return $this->YAML_FILES[$path];
        } else {
            // We still check the cache, even if we don't store it
            // because something else may be writing to this file
            if (isset($this->YAML_FILES[$path])) return $this->YAML_FILES[$path];
            else {
                $content = (file_exists($path) ? Spyc::YAMLLoad($path) : array());
                return $content;
            }
        }
    }

    protected function yamlFileValueExists(string $path, string $dotPath, bool $cache = self::CACHE): bool
    {
        $array = &$this->yamlFileLoad($path, $cache);
        $keys  = explode('.', $dotPath);
        $name  = array_pop($keys);
        $level = &$array;
        foreach ($keys as $step) {
            if (!isset($level[$step])) $level[$step] = array();
            $level = &$level[$step];
        }
        return isset($level[$name]);
    }

    protected function yamlFileSet(string $path, string|NULL $dotPath, string|array|int|bool $newValue, bool $throwIfAlreadySet = TRUE, string $complexDotName = NULL)
    {
        $array = &$this->yamlFileLoad($path);
        $keys  = explode('.', $dotPath); // Might be blank or NULL
        if ($complexDotName) $name = $complexDotName;
        else                 $name = array_pop($keys);

        $level = &$array;
        if ($name) {
            // Dot path
            foreach ($keys as $step) {
                if (!isset($level[$step])) $level[$step] = array();
                $level = &$level[$step];
                if (!is_array($level)) 
                    throw new Exception("Pre-level [$step] in [$dotPath] is not array when trying to set [$name]");
            }
            if ($throwIfAlreadySet && isset($level[$name])) 
                throw new Exception("[$dotPath] already set in [$path]");
            $level[$name] = $newValue;
        } else {
            // Top level request
            $level = $newValue;
        }

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
        if ($throwIfNotSet && !isset($level[$name])) 
            throw new Exception("[$dotPath] not already set in [$path]");
        unset($level[$name]);

        // Destructor will write cached arrays
    }

    // ----------------------------------------- File
    public function &fileLoad(string $path, bool $cache = self::CACHE, bool $throwIfNotFound = self::NO_THROW): string
    {
        if (!$path) throw new Exception("FILES path is empty");
        
        if ($cache) {
            if (!isset($this->FILES[$path])) {
                if ($throwIfNotFound && !file_exists($path)) 
                    throw new Exception("YAML file not found");
                $this->FILES[$path] = (file_exists($path) ? file_get_contents($path) : '');
            }
            return $this->FILES[$path];
        } else {
            // We still check the cache, even if we don't store it
            // because something else may be writing to this file
            if (isset($this->FILES[$path])) return $this->FILES[$path];
            else {
                $content = (file_exists($path) ? file_get_contents($path) : '');
                return $content;
            }
        }
    }

    protected function appendToFile(string $path, string $newContent, int $indent = 0, bool $newline = TRUE, bool $throwIfContentExists = TRUE, bool $cache = self::CACHE)
    {
        $contents = &$this->fileLoad($path, $cache);
        
        if ($throwIfContentExists && strstr($contents, $newContent)) throw new Exception("[$newContent] already found in [$path]");
        
        $newlineCharacter = ($newline ? "\n" : '');
        $contents .= "$newContent$newlineCharacter";
    }

    protected function replaceInFile(string $path, string $regex, string $replacement = '', bool $throwIfNotFound = TRUE, bool $cache = self::CACHE)
    {
        $contents = &$this->fileLoad($path, $cache);

        if ($throwIfNotFound) {
            $matched = preg_match($regex, $contents);
            if ($matched === 0)          throw new Exception("[$regex] not found in [$path]");
            else if ($matched === FALSE) throw new Exception("Failed to compile [$regex]");
        }

        $contents = preg_replace($regex, $replacement, $contents);

        // Destructor will write cached files
    }

    protected function runBashScript(string $path, bool $chdir = FALSE, string &$output = NULL, bool $throwOnNoZeroReturn = TRUE): int
    {
        if (!$path) throw new Exception("bash path is empty");
        $cwd = getcwd();

        if ($chdir) chdir(dirname($path));
        $lastline = exec($path, $output, $ret);
        if ($ret && $throwOnNoZeroReturn) throw new Exception("Bash script [$path] returned [$ret] with [$lastline]");
        if ($chdir) chdir($cwd);

        return $ret;
    }

    // ---------------------------------------------- Create
    public function create(Plugin &$plugin, bool $writeREADME = FALSE)
    {
        global $YELLOW, $GREEN, $RED, $NC;

        if ($this->pluginExists($plugin)) {
            $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
            print("{$GREEN}REMOVING{$NC} existing plugin sub-directories and files from [$pluginDirectoryPath]...\n");
            self::removeDir($pluginDirectoryPath, FALSE, FALSE);
        }
        if ($writeREADME) ob_start(); // README.md content

        // Abstracted MVC creates
        $this->createPlugin($plugin);
        $this->createMenus($plugin);
        foreach ($plugin->models as $model) {
            if (!$model->getTable() instanceof MaterializedView) {
                $this->createModel($model);
                $this->createFormInterface($model);
                $this->createListInterface($model);
                foreach ($model->controllers as $controller) {
                    $this->createController($controller);
                }
            }
        }
        $this->adornOtherCustomPlugins($plugin);
        // README.md content
        if ($writeREADME) {
            $this->writeReadme($plugin, ob_get_contents());
            ob_end_flush(); 
        }

        $this->writeOutFiles();
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
    protected function createMenus(Plugin &$plugin, bool $overwrite = FALSE) {}
    protected function createModel(Model &$model, bool $overwrite = FALSE) {}
    protected function createFormInterface(Model &$model, bool $overwrite = FALSE) {}
    protected function createController(Controller &$controller, bool $overwrite = FALSE) {}
    protected function createListInterface(Model &$model, bool $overwrite = FALSE) {}
    protected function adornOtherCustomPlugins(Plugin &$plugin, bool $overwrite = FALSE) {}
    protected function runChecks(Plugin &$plugin) {}
    protected function writeReadme(Plugin &$plugin, string $contents) {}
}
