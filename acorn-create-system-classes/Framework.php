<?php namespace Acorn\CreateSystem;

use Exception;
use Spyc;

class Framework
{
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

    protected function getNextIcon(): string
    {
        $array    = $this->yamlFileLoad($this->iconFile, self::NO_CACHE);
        $fqn      = $array[0]['icons'][$this->iconCurrent++];
        $fqnParts = explode(' ', $fqn);
        return end($fqnParts);
    }

    protected function buildHint(Model $model, string $hintName, array $hintConfig, string|NULL $fieldsPath = NULL) 
    {
        $path = NULL;

        $level = (isset($hintConfig['level']) ? $hintConfig['level'] : 'info');
        $levelEscaped   = e($level);

        if (isset($hintConfig['path'])) {
            // Managed existing partial from other plugin
            // path will flow through
            $path = $hintConfig['path'];
        } else if (isset($hintConfig['content'])) {
            // Custom content => file
            if (!isset($hintConfig['labels']))
                throw new Exception("labels: are required for content hint $hintName");
            if (!isset($hintConfig['content']))
                throw new Exception("Content: is required for content hint $hintName");

            // Labels => Translation keys
            // values are placed in to the lang.php files later
            $modelKey   = $model->translationDomain(); // acorn.university::lang.models.thing
            $labelKey   = "$modelKey.hints.$hintName.label";
            $contentKey = "$modelKey.hints.$hintName.content";
            $hintConfig['label']   = $labelKey;
            $hintConfig['content'] = $contentKey;
            if (isset($hintConfig['labels'])) unset($hintConfig['labels']);
            $callToAction = '';

            if ($fieldsPath) {
                // Make the actual referenced hint file
                // Content to create in a file and reference
                // Relative plugins hint path
                $hintsDir       = dirname($fieldsPath);
                $hintsDir       = preg_replace('/^.*\/plugins\//', 'plugins/', $hintsDir);
                $hintFileName   = preg_replace('/-+/', '_', $hintName);
                $path           = "{$hintsDir}/_$hintFileName.php";
                $contentHtml    = (isset($hintConfig['contentHtml']) && $hintConfig['contentHtml']);
                $e              = ($contentHtml  ? '' : 'e');
                // TODO: Call to action translation and label
                $callToActionA  = ($callToAction ? "<a href='$callToAction'>Resolve</a>" : '');

                file_put_contents($path, <<<HTML
<i class="icon-$levelEscaped"></i>
<h3><?= e(trans('$labelKey')) ?></h3>
<p><?= $e(trans('$contentKey')) ?>$callToActionA</p>
HTML                        
                );
            }
        } else {
            throw new Exception("Hint $hintName has neither path nor content");
        }

        // Some useful translations
        if (isset($hintConfig['contexts'])) $hintConfig['context'] = $hintConfig['contexts'];

        return array_merge(array(
            'type' => 'hint',  // hints can be hidden
            'path' => $path,   // Path to created file above
            'span' => 'storm', // Usually, many are shown side-by-side
            'cssClass' => "col-xs-6 col-md-4 callout-$levelEscaped", // Also will CSS float: right
        ), $hintConfig);
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

    // ---------------------------------------------- Functions & Property control
    protected function writeFileUses(string $path, array &$uses)
    {
        if (!$path) throw new Exception("FileUses path is empty");
        $usesString = '';
        foreach ($uses as $name => $include) {
            if ($include) $usesString .= "use $name;\n";
        }
        $this->replaceInFile($path, '/^(namespace .*$)/m', "\\1\n\n$usesString");
    }

    protected function writeClassTraits(string $path, array &$traits, int $indent = 1)
    {
        if (!$path) throw new Exception("ClassTraits path is empty");
        $indentString = str_repeat(' ', $indent*4);
        $traitsString = '';
        foreach ($traits as $name => $include) {
            if ($include) $traitsString .= "{$indentString}use $name;\n";
        }
        $this->replaceInFile($path, '/^{$/m', "{\n$traitsString\n");
    }

    protected function addStaticMethod(string $path, string $name, string $body, string $scope = 'public', int $indent = 1)
    {
        if (!$path) throw new Exception("StaticMethod path is empty");
        return $this->addMethod($path, $name, $body, 'mixed', $scope, TRUE, $indent);
    }

    protected function replaceMethod(string $path, string $name, string|array $body, string $type = NULL, string $scope = 'public', bool $static = FALSE, int $indent = 1)
    {
        $this->removeMethod($path, $name);
        $this->addMethod($path, $name, $body, $type, $scope, $static, $indent);name: 
    }

    protected function addMethod(string $path, string $name, string|array $body, string $type = NULL, string $scope = 'public', bool $static = FALSE, int $indent = 1)
    {
        if (!$path) 
            throw new Exception("Method path is empty");

        // Parameters will be empty if included in the $name
        $nameHasParameters = (strstr($name, '(') !== FALSE);
        $parameters    = ($nameHasParameters ? '' : '()');
        $indentString  = str_repeat(' ', $indent*4);
        $indentString2 = str_repeat(' ', ($indent+1)*4);
        $staticString  = ($static ? ' static' : '');
        $signature     = "$name$parameters"; 
        if (is_array($body)) $body = implode("\n$indentString2", $body);
        else $body = preg_replace('/\n/', "\n$indentString2", $body);
        if ($type) $signature .= ": $type";

        $contents = &$this->fileLoad($path);
        if (strstr($contents, "function $signature") !== FALSE)
            throw new Exception("Method $signature already exists in $path");

        $this->replaceInFile($path, '/^}$/m', <<<FUNCTION

$indentString$scope$staticString function $signature {
$indentString2# Auto-injected by acorn-create-system
$indentString2$body
$indentString}
}
FUNCTION
        );
    }

    protected function setPropertyInClassFile(string $path, string $name, string|int|array $value, bool $overwriteExisting = self::OVERWRITE_EXISTING, string $scope = 'public', int $indent = self::STD_INDENT, bool $passthrough = self::FIRST_MULTILINE)
    {
        if (!$path) throw new Exception("FILES path is empty");
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

    protected function removeEmpty(array $array, bool $andFalses = self::NOT_FALSES, array $keepFalses = array()): array
    {
        $cleanedArray = array();
        foreach ($array as $name => $value) {
            $empty = (
                   is_null($value)
                || (is_string($value) && !$value)
                || (is_array($value)  && !count($value))
                || ($andFalses && is_bool($value) && !$value && !in_array($name, $keepFalses))
            );
            if (!$empty) $cleanedArray[$name] = $value;
        }
        return $cleanedArray;
    }

    protected function removeMethod(string $path, string $functionName, string $scope = 'public')
    {
        if (!$path) 
            throw new Exception("Function path is empty");

        $this->replaceInFile($path, "/$scope function $functionName\(/", "$scope function {$functionName}_REMOVED(");
    }

    protected function setArrayReturnFunction(string $path, string $functionName, array $arrayReturn, int $indent = 1)
    {
        // For example: to replace the entire registerPermissions() function below
        // TODO: Support } within the function body
        //   public function registerPermissions(): array
        //   {
        //     return [
        //         'acorn.finance.some_permission' => [
        //             'tab' => 'acorn.finance::lang.plugin.name',
        //             'label' => 'acorn.finance::lang.permissions.some_permission',
        //             'roles' => [UserRole::CODE_DEVELOPER, UserRole::CODE_PUBLISHER],
        //         ],
        //     ];
        //   }
        // /.../s == multiline DOT_ALL: . matches newline, and [^...] also matches newlines
        if (!$path)         throw new Exception("File path is empty");
        if (!$functionName) throw new Exception("Function name is empty");

        $indentString  = str_repeat(' ', $indent*4);
        $indent2string = str_repeat(' ', $indent*8);
        $arrayExport   = $this->varExport($arrayReturn, $indent+2);
        $open   = '{';
        $return = 'return';
        $close  = '}';
        $this->replaceInFile($path, 
            "/function $functionName\(([^)]*)\)([^{])*\{[^}]*\}/s", 
            "function $functionName(\\1)\\2\n$indentString$open\n$indent2string$return $arrayExport;\n$indentString$close"
            
        );
    }

    protected function changeArrayReturnFunctionEntry(string $path, string $functionName, string $arrayDotPath, $newValue)
    {
        // For example: to replace the 'author' value below
        // TODO: Make a read array function so it can be programmatically altered
        // TODO: Support dot path in the array
        //   public function pluginDetails(): array
        //   {
        //     return [
        //         'name'        => 'acorn.finance::lang.plugin.name',
        //         'description' => 'acorn.finance::lang.plugin.description',
        //         'author' => 'Acorn',
        //         'icon'        => 'icon-leaf'
        //     ];
        //   }
        if (!$path)         throw new Exception("File path is empty");
        if (!$functionName) throw new Exception("Function name is empty");
        if (strstr($arrayDotPath, '.') !== FALSE) throw new Exception("Dot array replacement [$arrayDotPath] not supported yet");

        $escapedValue = str_replace("'", "\\'", $newValue);
        $this->replaceInFile($path, "/'$arrayDotPath' *=>.*/", "'$arrayDotPath' => '$escapedValue',");
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
            $this->createModel($model);
            $this->createFormInterface($model);
            $this->createListInterface($model);
            foreach ($model->controllers as $controller) {
                $this->createController($controller);
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
