<?php namespace Acorn\CreateSystem;

require_once('bootstrap/autoload.php');

class WinterCMS extends Framework
{
    protected const WINTER_TABLES  = array('cache', 'jobs', 'failed_jobs', 'job_batches', 'migrations', 'sessions', 'deferred_bindings');
    protected const WINTER_MODULES = array('cms', 'backend', 'system');

    protected $DB_CONNECTION;
    protected $DB_HOST;
    protected $DB_PORT;
    protected $DB_DATABASE;
    protected $DB_USERNAME;
    protected $DB_PASSWORD;

    protected $app;
    protected $kernel;
    protected $input;
    protected $output;
    protected $status;

    public function __construct(string $cwd, string $scriptDirPath)
    {
        global $GREEN, $YELLOW, $RED, $NC;

        parent::__construct($cwd, $scriptDirPath);

        // WinterCMS CLI boot
        $this->app    = require_once('bootstrap/app.php');
        $this->kernel = $this->app->make(\Illuminate\Contracts\Console\Kernel::class);
        $this->output = new \Symfony\Component\Console\Output\ConsoleOutput;

        if (!file_exists("$cwd/modules/acorn/Model.php")) throw new \Exception("WinterCMS at [$cwd] does not have the required Acorn module");

        // ---------------------------- DB
        # Get DB connection parameters from Laravel
        if (!$this->DB_HOST) $this->DB_HOST = '127.0.0.1';
        if (!$this->DB_PORT) $this->DB_PORT = 5432;
        if ( $this->DB_CONNECTION != 'pgsql' || $this->DB_HOST != "127.0.0.1" ) {
            throw new \Exception("$this->DB_CONNECTION@$this->DB_HOST:$this->DB_PORT is not local. Aborted");
        }
        $this->connection = "pgsql:host=$this->DB_HOST;dbname=$this->DB_DATABASE;port=$this->DB_PORT;";
        $this->database   = $this->DB_DATABASE;
        $this->username   = $this->DB_USERNAME;
        $this->password   = $this->DB_PASSWORD;

        // ---------------------------- DBAUTH
        if ($this->username == '<DBAUTH>') {
            print("${YELLOW}NOTE${NC}: DBAuth module detected, using winter user instead\n");
            $this->username   = 'winter';
            $this->password   = 'QueenPool1@';
        }

        // ---------------------------- Icons
        $this->iconFile    = "$cwd/modules/backend/formwidgets/iconpicker/meta/libraries.yaml";
        $this->iconCurrent = 7;
        if (!file_exists($this->iconFile)) {
            throw new \Exception("Icon file [$this->iconFile] missing");
        }
    }

    public function __destruct()
    {
        $this->kernel->terminate($this->input, $this->status);
        parent::__destruct();
    }

    protected function environment(): array
    {
        $env = file_get_contents("$this->cwd/.env");
        if (!$env) throw new \Exception("WinterCMS .env file not found or empty at [$this->cwd]");
        return explode("\n", $env);
    }

    public function isFrameworkTable(string &$tablename): bool
    {
        return (array_search($tablename, self::WINTER_TABLES) !== FALSE);
    }

    public function isFrameworkModuleTable(string &$tablename): bool
    {
        $tableNameParts = explode('_', $tablename);
        return (array_search($tableNameParts[0], self::WINTER_MODULES) !== FALSE);
    }

    protected function runWinterCommand(string $command, ...$args): int
    {
        print("artisan $command\n");
        $this->input  = new \Symfony\Component\Console\Input\ArgvInput(array('', $command, ...$args));
        $this->status = $this->kernel->handle($this->input, $this->output);

        return $this->status;
    }

    protected function pluginDirectoryPath(Plugin &$plugin): string
    {
        $dirName = $plugin->dirName();
        return "$this->cwd/plugins/$dirName";
    }

    protected function pluginFile(Plugin &$plugin): string
    {
        return $this->pluginDirectoryPath($plugin) . "/Plugin.php";
    }

    // -------------------------------------------------- create*()
    protected function createPlugin(Plugin &$plugin, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
        $pluginFilePath      = "$pluginDirectoryPath/Plugin.php";
        $createdBy           = $this->createdByString();

        $this->runWinterCommand('create:plugin', $plugin->dotClassName());

        // --------------------------------------------- Created bys, authors & README.md
        $readmePath = "$pluginDirectoryPath/README.md";
        if (!file_exists($readmePath)) {
            $this->setFileContents($readmePath, "# $plugin->name");
            $this->appendToFile($readmePath, $createdBy);
        }

        // --------------------------------------------- Plugin.php misc
        // Alter the public function pluginDetails(): array function array return
        // and append some comments
        $this->changeArrayReturnFunctionEntry($pluginFilePath, 'pluginDetails', 'author', 'Acorn');
        $this->removeFunction($pluginFilePath, 'registerNavigation');
        $this->replaceInFile( $pluginFilePath, '/Registers backend navigation items for this plugin./', 'Navigation in plugin.yaml.');
        $this->appendTofile(  $pluginFilePath, "\n// $createdBy");

        // Adding cross plugin dependencies
        $requirePlugins = array(
            'Acorn.Calendar'  => TRUE,
            'Acorn.Location'  => TRUE,
            'Acorn.Messaging' => TRUE
        );
        foreach ($plugin->otherPluginRelations() as &$relation) {
            if (!$relation instanceof RelationFrom) {
                // Do not make requires to Modules
                $otherPlugin = &$relation->to->plugin;
                if ($otherPlugin instanceof Plugin) {
                    $fqn         = $otherPlugin->dotClassName();
                    if (!isset($requirePlugins[$fqn])) {
                        print("      Adding Plugin \$require ${YELLOW}$fqn${NC}\n");
                        $requirePlugins[$fqn] = TRUE;
                    }
                }
            }
        }
        $this->setPropertyInClassFile($pluginFilePath, 'require', array_keys($requirePlugins), FALSE);

        // --------------------------------------------- Lang files
        $langDirPath = "$pluginDirectoryPath/lang";
        $langEnPath  = "$langDirPath/en/lang.php";
        $this->arrayFileSet($langEnPath, 'plugin.description', $createdBy, FALSE);

        // Standard langs
        if (!is_dir("$langDirPath/ku/")) mkdir("$langDirPath/ku/", 0775, TRUE);
        if (!is_dir("$langDirPath/ar/")) mkdir("$langDirPath/ar/", 0775, TRUE);
        foreach (scandir($langDirPath) as $langName) {
            if (!in_array($langName, array(".",".."))) {
                $langFilePath = "$langDirPath/$langName/lang.php";

                if (file_exists($langFilePath)) {
                    if ($langName != 'en') print("  ${RED}LANG${NC}: ${YELLOW}$langName${NC} language file already exists\n");
                } else {
                    print("  ${GREEN}LANG${NC}: Created ${YELLOW}$langName${NC} language file\n");
                    copy($langEnPath, $langFilePath);
                }
            }
        }

        // English General
        // TODO: Move these in to Semantic
        $this->arrayFileSet($langEnPath, 'models.general', array(
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

            // System
            'response' => 'HTTP call response',
            'replication_debug' => 'Replication Debug',
            'trigger_http_call_response' => 'Trigger HTTP call response',
        ), FALSE);
        if (isset($plugin->pluginNames['en']))        $this->arrayFileSet("$langDirPath/en/lang.php", 'plugin.name',        $plugin->pluginNames['en'],        FALSE);
        if (isset($plugin->pluginDescriptions['en'])) $this->arrayFileSet("$langDirPath/en/lang.php", 'plugin.description', $plugin->pluginDescriptions['en'], FALSE);

        // Arabic general
        $this->arrayFileSet("$langDirPath/ar/lang.php", 'models.general', array(
            'id'     => 'المعرف',
            'name'   => 'الأسم',
            'short_name'  => 'الاسم المختصر',
            'description' => 'Description',
            'type'   => 'النوع',
            'image'  => 'الصور',
            'select' => 'إختيار',
            'select_existing' => 'حدد عنوانًا موجودًا',
            'created_at_event' => 'تم التسجيل في',
            'updated_at_event' => 'تم التحديث في',
            'created_by_user'  => 'Created By',
            'updated_by_user'  => 'Updated By',
            'created_at'   => 'تم التسجيل في',
            'updated_at'   => 'تم التحديث في',
            'created_by'   => 'Created By',

            // Some fields
            'quantity' => 'الكمية',
            'distance' => 'المسافة',
            'parent' => 'محتوى المنطقة',

            // Menus
            'actions' => 'الخدمات اللوجستية',
            'setup' => 'تثبيت',
            'reports' => 'التقارير',

            // In-built QR codes
            'qrcode'        => 'رمز QR',
            'qrcode_scan'   => 'مسح الرمز',
            'find_by_qrcode' => 'البحث بواسطة الرمز',
            'state_indicator' => 'Status',

            // Standard Buttons
            'create'     => 'نشاء ماركة جديدة',
            'new'        => 'ماركة جديدة',
            'add'        => 'إضافة',
            'print'      => 'Print',
            'save_and_print'    => 'حفظ وطباعة',
            'correct_and_print' => 'حفظ التصحيح وطباعته',

            // System
            'response' => 'HTTP call response',
            'replication_debug' => 'تصحيح أخطاء التكرار',
            'trigger_http_call_response' => 'تشغيل استجابة اتصال HTTP',
        ), FALSE);
        if (isset($plugin->pluginNames['ar']))        $this->arrayFileSet("$langDirPath/ar/lang.php", 'plugin.name',        $plugin->pluginNames['ar'],        FALSE);
        if (isset($plugin->pluginDescriptions['ar'])) $this->arrayFileSet("$langDirPath/ar/lang.php", 'plugin.description', $plugin->pluginDescriptions['ar'], FALSE);

        // Kurdish general
        $this->arrayFileSet("$langDirPath/ku/lang.php", 'models.general', array(
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

            // Menus
            'actions' => 'Çalakîyên',
            'setup'   => 'Veavakirin',
            'reports' => 'Raporên',

            // In-built QR codes
            'qrcode'        => 'QR Koda',
            'qrcode_scan'   => 'QR Koda Xwendin',
            'find_by_qrcode' => 'Bi koda QR-ê bibînin',
            'state_indicator' => 'Status',

            // Standard Buttons
            'create'     => 'Afirandin',
            'new'        => 'Nû',
            'add'        => 'Lêzêdedike',
            'print'      => 'Çap',
            'save_and_print'    => 'Rizgardike û Çap',
            'correct_and_print' => 'Lihevanîn û Çap',

            // System
            'response' => 'HTTP call response', // TODO: Rename "response" to "http_response"
            'replication_debug' => 'Replication Debug',
            'trigger_http_call_response' => 'Trigger HTTP call response',
        ), FALSE);
        if (isset($plugin->pluginNames['ku']))        $this->arrayFileSet("$langDirPath/ku/lang.php", 'plugin.name',        $plugin->pluginNames['ku'],        FALSE);
        if (isset($plugin->pluginDescriptions['ku'])) $this->arrayFileSet("$langDirPath/ku/lang.php", 'plugin.description', $plugin->pluginDescriptions['ku'], FALSE);

        // --------------------------------------------- Permissions
        // 'acorn.criminal.some_permission' => [
        //     'tab' => 'acorn.criminal::lang.plugin.name',
        //     'label' => 'acorn.criminal::lang.permissions.some_permission',
        //     'roles' => [UserRole::CODE_DEVELOPER, UserRole::CODE_PUBLISHER],
        // ],
        $pluginPermissionsArray = array();
        $translationDomain      = $plugin->translationDomain();
        $pluginDotName          = $plugin->dotName();
        $permissions            = $plugin->allPermissionNames(); // Used in lang section below
        if ($permissions) {
            // Check these permissions keys are fully qualified
            foreach ($permissions as $fullyQualifiedKey => &$config) {
                $isQualifiedName = (strstr($fullyQualifiedKey, '.') !== FALSE);
                if (!$isQualifiedName) throw new \Exception("Permission [$fullyQualifiedKey] is not qualified");
            }

            foreach ($permissions as $fullyQualifiedName => &$config) {
                $permissionNameParts     = explode(".", $fullyQualifiedName);
                $permissionPluginDotPath = implode(".", array_slice($permissionNameParts, 0, 2));
                $permissionLocalName     = end($permissionNameParts);
                if ($permissionPluginDotPath == $pluginDotName) {
                    print("    Adding Permission: ${GREEN}$fullyQualifiedName${NC}\n");
                    $pluginPermissionConfig = array(
                        'tab'   => "$translationDomain::lang.plugin.name",
                        'label' => "$translationDomain::lang.permissions.$permissionLocalName",
                    );
                    $pluginPermissionsArray[$permissionLocalName] = $pluginPermissionConfig;
                    // Adorn the main config for the lang updates later
                    $config['plugin'] = $pluginPermissionConfig;
                }
            }
            // Add these to the plugin.php
            $this->setArrayReturnFunction($pluginFilePath, 'registerPermissions', $pluginPermissionsArray);

            // lang.php
            foreach ($permissions as $fullyQualifiedName => &$config) {
                $permissionNameParts     = explode(".", $fullyQualifiedName);
                $permissionPluginDotPath = implode(".", array_slice($permissionNameParts, 0, 2));
                $permissionLocalName     = end($permissionNameParts);
                if ($permissionPluginDotPath == $pluginDotName) {
                    if (isset($config['plugin']['label']) && isset($config['labels'])) {
                        foreach ($config['labels'] as $lang => $label) {
                            $this->arrayFileSet("$langDirPath/$lang/lang.php", "permissions.$permissionLocalName", $label);
                            $this->arrayFileUnSet("$langDirPath/$lang/lang.php", "permissions.some_permission", FALSE);
                        }
                    }
                }
            }
        }
        
        // --------------------------------------------- Standard Migration Updates
        // TODO: Move SQL/updates => winterCms/updates
        $scriptsUpdatesPath = "$this->scriptDirPath/SQL/updates";
        $pluginUpdatePath   = "$pluginDirectoryPath/updates";
        if (!is_dir($scriptsUpdatesPath)) {
            print("  ${RED}WARNING${NC}: No ${YELLOW}$scriptsUpdatesPath{NC} found to populate the plugin /updates/. Creating...\n");
            mkdir($scriptsUpdatesPath, TRUE);
        }

        print("  Syncing ${GREEN}$pluginUpdatePath${NC}\n");
        if (!is_dir($pluginUpdatePath)) {
            echo "  Made ${YELLOW}$pluginUpdatePath${NC}\n";
            mkdir($pluginUpdatePath, 0775, TRUE);
        }
        foreach (scandir($scriptsUpdatesPath) as $file) {
            if (!in_array($file, array(".",".."))) {
                $scriptsFilePath = realpath("$scriptsUpdatesPath/$file");
                $updatesFilePath = "$pluginUpdatePath/$file";
                if (file_exists($updatesFilePath)) {
                    print("    Ommitting ${RED}$file${NC}\n");
                } else {
                    print("    Copied ${YELLOW}$file${NC} => updates/\n");
                    copy($scriptsFilePath, $updatesFilePath);
                    // ReWrite <Plugin> in the namespace(s) for copied files
                    $this->replaceInFile($updatesFilePath, '/<Plugin>/', $plugin->name, FALSE);
                    // Set execute flags
                    $perms = fileperms($scriptsFilePath);
                    chmod($updatesFilePath, $perms);
                }
            }
        }

        // --------------------------------------------- Update commands
        // Re-create up & down.sql
        if (file_exists("$pluginUpdatePath/acorn-winter-update-sqls")) {
            print("  Run ${GREEN}acorn-winter-update-sqls${NC}\n");
            $this->runBashScript("$pluginUpdatePath/acorn-winter-update-sqls", TRUE);
        } else {
            print("${RED}ERROR${NC}: No ${YELLOW}acorn-winter-update-sqls${NC} available\n");
            exit(1);
        }

        // Functions fn_acorn_*_seed_*()
        $seederPath = "$pluginUpdatePath/seed.sql";
        $functions  = $this->db->functions(strtolower($plugin->author), strtolower($plugin->name), 'seed');
        foreach ($functions as $name => $details) {
            // We suppress duplicate warnings as the function may have been specified in the table seeding above
            $this->appendToFile($seederPath, "select $name();", 0, TRUE, FALSE);
        }

        // Create PGSQL extensions and schemas if not present
        // TODO: Why? This is dangerous. Do it manually
        /*
        if (file_exists("$pluginUpdatePath/pre-up.sql")) {
            print("  Run ${GREEN}pre-up.sql${NC} (functions, schemas, extensions)\n");
            $this->db->runSQLFile("$pluginUpdatePath/pre-up.sql");
        }
        */

        // --------------------------------------------- Register plugin manually
        // This can be necessary if winter:up is not run
        // plugin registration is important to enable the plugin control system
        // /backend/system/updates/manage
        $dotClassName  = $plugin->dotClassName();
        $pluginTable   = 'public.system_plugin_versions';
        $registrations = $this->db->select("SELECT * FROM $pluginTable where code = :plugin",
            array('plugin' => $dotClassName)
        );
        if (count($registrations)) {
            print("  Plugin ${GREEN}$dotClassName${NC} is already registered in $pluginTable\n");
        } else {
            print("  Plugin ${GREEN}$dotClassName${NC} registered in $pluginTable\n");
            $this->db->insert("INSERT into $pluginTable(code, version, created_at)
                values(:plugin, '1.0.0', now())",
                array('plugin' => $dotClassName)
            );
        }
    }

    public function createMenus(Plugin &$plugin) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
        $translationDomain   = $plugin->translationDomain();
        $pluginYamlPath      = "$pluginDirectoryPath/plugin.yaml";
        $pluginMenuName      = strtolower($plugin->name);

        if ($plugin->pluginMenu !== FALSE) {
            if ($this->yamlFileValueExists($pluginYamlPath, 'navigation')) {
                print("  Navigation already present for [$plugin->name]\n");
            } else {
                print("  Adding navigation\n");
                print("  Adding navigation setup side-menu\n");

                $sideMenu      = array();
                $firstModelUrl = NULL;
                foreach ($plugin->models as $name => &$model) {
                    if ($controller = $model->controller(FALSE)) {
                        if ($controller->menu) {
                            $icon = $controller->icon;
                            $url  = $controller->relativeUrl();
                            $modelFQN = $model->absoluteFullyQualifiedName();
                            $langSectionName = $model->langSectionName();

                            print("  Adding setup side-menu entry for $name\n");
                            print("    @$url\n");
                            if ($icon) {
                                if (substr($icon, 0, 5) != 'icon-') $icon = "icon-$icon";
                            } else {
                                $icon = $this->getNextIcon();
                                print("    Auto-selected controller icon ${YELLOW}$icon${NC}\n");
                            }

                            if ($controller->menuSplitter) {
                                $sideMenu["_splitter_$name"] = array(
                                    'label' => 'splitter',
                                    'url'   => 'splitter',
                                    'icon'  => 'acorn-splitter',
                                );
                            }

                            // CRUD Navigation item
                            $sideMenu[$name] = array(
                                'label'   => "$translationDomain::lang.models.$langSectionName.label_plural",
                                'url'     => $url,
                                'icon'    => $icon,
                                'counter' => "$modelFQN::menuitemCount",
                            );
                            if (!$firstModelUrl) $firstModelUrl = $url;
                        }
                    }
                }

                $icon = $plugin->pluginIcon;
                if ($icon) {
                    if (substr($icon, 0, 5) != 'icon-') $icon = "icon-$icon";
                } else {
                    $icon = $this->getNextIcon();
                    print("  Auto-selected plugin icon ${YELLOW}$icon${NC}\n");
                }
                $navigationDefinition = array(
                    "$pluginMenuName-setup" => array(
                        'label'    => "$translationDomain::lang.plugin.name",
                        'url'      => ($plugin->pluginUrl ?: ($firstModelUrl ?: '#')),
                        'icon'     => $icon,
                        'sideMenu' => $sideMenu,
                    ),
                );

                $this->yamlFileSet($pluginYamlPath, 'navigation', $navigationDefinition);

            }
        }
    }

    protected function createModel(Model &$model, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($model->plugin);
        $modelDirName        = $model->dirName();
        $modelFilePath       = "$pluginDirectoryPath/models/$model->name.php";
        $modelDirPath        = "$pluginDirectoryPath/models/$modelDirName";
        $translationDomain   = $model->plugin->translationDomain();
        $langDirPath         = "$pluginDirectoryPath/lang";

        if (file_exists($modelFilePath) && $overwrite) unlink($modelFilePath);
        if (file_exists($modelFilePath)) {
            print("  ${RED}WARNING${NC}: Model file [$modelFilePath] already exists. Leaving.\n");
        } else {
            $this->runWinterCommand('create:model', $model->plugin->dotClassName(), $model->name);

            // Potentially rewrite $table because create:model will automatically plural it
            $this->setPropertyInClassFile($modelFilePath, 'table', $model->table->fullyQualifiedName());

            $createdBy  = $this->createdByString();
            $this->appendToFile($modelFilePath, "// $createdBy");

            // Rewrite version.yaml to use create_from_sql.php: The create:model has updated it
            // create:model makes the v1.0.1/ directories also. Remove them
            $scriptsUpdatesPath = "$this->scriptDirPath/SQL/updates";
            $pluginUpdatePath   = "$pluginDirectoryPath/updates";
            copy("$scriptsUpdatesPath/version.yaml", "$pluginUpdatePath/version.yaml");
            $this->removeDir("$pluginDirectoryPath/updates/v1.0.1/", TRUE, TRUE, FALSE);

            // Explicit plural name injection
            // Otherwise PathsHelper will get confused when making URLs and things
            $plural = $model->table->plural;
            if ($plural) $this->setPropertyInClassFile($modelFilePath, 'namePlural', $plural, Framework::NEW_PROPERTY);

            // ----------------------------------------------------------------- Behaviours, Uses, Classes & inheritance
            // TODO: SoftDelete
            $dateColumns = array_keys($model->table->dateColumns());
            $this->setPropertyInClassFile($modelFilePath, 'dates', $dateColumns, TRUE, 'protected');
            if (!count($dateColumns)) $this->setPropertyInClassFile($modelFilePath, 'timestamps', FALSE, FALSE);

            $model->uses = array_merge($model->uses, array(
                // Useful AA classes
                "Acorn\\Models\\Server" => TRUE,
                "Acorn\\Collection" => TRUE,
                // Useful
                "BackendAuth" => TRUE,
                '\\Backend\\Models\\User' => TRUE,
                '\\Backend\\Models\\UserGroup' => TRUE,
                'Exception' => TRUE,
                'Flash' => TRUE,
            ));
            print("  Inheriting from Acorn\\\\Model\n");
            $this->replaceInFile($modelFilePath, '/^use Model;$/m', 'use Acorn\\Model;');

            // Traits
            print("  Adding Trait Revisionable\n");
            $model->traits['\\Winter\\Storm\\Database\\Traits\\Revisionable'] = TRUE;
            $this->setPropertyInClassFile($modelFilePath, 'revisionable', array(), FALSE, 'protected');
            $this->setPropertyInClassFile($modelFilePath, 'morphMany', array(
                'revision_history' => array('System\\Models\\Revision', 'name' => 'revisionable')
            ));

            if ($model->hasSoftDelete()) {
                print("  Adding Trait SoftDelete\n");
                $model->traits['\\Winter\\Storm\\Database\\Traits\\SoftDelete'] = TRUE;
            }
            if ($model->isDistributed()) {
                print("  Adding Trait HasUuids\n");
                $model->traits['\\Illuminate\\Database\\Eloquent\\Concerns\\HasUuids'] = TRUE;
            }

            $this->writeFileUses(   $modelFilePath, $model->uses);
            $this->writeClassTraits($modelFilePath, $model->traits);

            // Relax guarding
            // TODO: SECURITY: Relaxed guarding is ok?
            $this->setPropertyInClassFile($modelFilePath, 'guarded', array(), TRUE, 'protected');

            // ---------------------------------------------------------------- Model based action functions
            // Write the labels to lang, and the translationKeys to the YAML
            foreach ($model->actionFunctions as $name => &$defintion) {
                foreach (scandir($langDirPath) as $langName) {
                    $langFilePath = "$langDirPath/$langName/lang.php";
                    if (!in_array($langName, array('.','..')) && file_exists($langFilePath)) {
                        if (isset($defintion['labels'][$langName])) {
                            $label = $defintion['labels'][$langName];
                            $this->arrayFileSet($langFilePath, "actions.$name", $label, FALSE);
                        }
                    }
                }
                unset($defintion['labels']);
                $defintion['label'] = "$translationDomain::lang.actions.$name";
            }
            $this->setPropertyInClassFile($modelFilePath, 'actionFunctions', $model->actionFunctions, FALSE, 'public', self::STD_INDENT, Framework::ALL_MULTILINE);

            // ---------------------------------------------------------------- Seeding
            // This moves seeding: directives in to updates\seed.sql
            // and also appends any fn_acorn_*_seed_*() functions
            $seederPath = "$pluginDirectoryPath/updates/seed.sql";
            if ($model->table->seeding) {
                $schema     = $model->table->schema;
                $table      = $model->table->name;
                $inserts    = array();

                // Table comment seeding directive
                print("  ${GREEN}SEEDING${NC} for [$table]\n");
                foreach ($model->table->seeding as $row) {
                    $names  = array();
                    $values = array();
                    foreach ($model->table->columns as &$column) {
                        if (!count($row)) break;
                        $value = array_shift($row);

                        // TODO: Creation of NOT NULL associated calendar events: EVENT_ID => $this->db->createCalendarEvent('SEEDER')
                        if      ($value === 'DEFAULT')   $valueSQL = 'DEFAULT';
                        else if ($value === 'NULL')      $valueSQL = 'NULL';
                        else if (substr($value, 0, 19) === 'fn_acorn_' && substr($value, -1) == ')') $valueSQL = $value;
                        else $valueSQL = var_export($value, TRUE);

                        array_push($names, $column->name);
                        array_push($values, $valueSQL);
                    }
                    if ($model->table->hasColumn('created_by_user_id')) {
                        array_push($names, 'created_by_user_id');
                        array_push($values, 'fn_acorn_user_get_seed_user()');
                    }
                    $namesSQL  = implode(',', $names);
                    $valuesSQL = implode(',', $values);
                    $insertSQL = "insert into $schema.$table($namesSQL) values($valuesSQL);";
                    array_push($inserts, $insertSQL);
                    $this->appendToFile($seederPath, $insertSQL);
                }
                
                // Run the seeding IF there are no records in the table
                // Because we are not doing a winter:down,up here, but we still want the records
                if ($model->table->isEmpty() && count($inserts)) {
                    print("  Running ${YELLOW}$table${NC} seed inserts because the table is empty: [");
                    // We do not $this->db->disableTriggers(), because we want the created_at_event_id
                    foreach ($inserts as $insert) {
                        print(".");
                        $this->db->insert($insert);
                    }
                    // $this->db->enableTriggers();
                    print("]\n");
                }
            }

            // ----------------------------------------------------------------- Language
            // These non-en files will not have been updated by the create:model command
            $modelSectionName = $model->langSectionName();
            $langEnPath       = "$langDirPath/en/lang.php";

            // At least set the english label programmatically
            // NOTE: They may have already been set, but not cached
            // so we set them again here
            if (!$model->labels || !isset($model->labels['en'])) $this->arrayFileSet($langEnPath, "models.$modelSectionName", array(
                'label'        => $model->devEnTitle(),
                'label_plural' => $model->devEnTitle(Model::PLURAL)
            ), FALSE);

            // Set any explicit ones we have
            foreach (scandir($langDirPath) as $langName) {
                $langFilePath = "$langDirPath/$langName/lang.php";
                if (!in_array($langName, array('.','..')) && file_exists($langFilePath)) {
                    if (isset($model->labels[$langName])) {
                        print("  Added ${YELLOW}$modelSectionName${NC} into ${YELLOW}$langName${NC} lang file\n");
                        $label       = &$model->labels[$langName];
                        $labelPlural = (isset($model->labelsPlural[$langName]) ? $model->labelsPlural[$langName] : $label);
                        $throwIfAlreadySet = ($langName != 'en');
                        $this->langFileSet($langFilePath, "models.$modelSectionName", array(
                            'label'        => $label,
                            'label_plural' => $labelPlural
                        ), $langName, $model->dbObject(), $throwIfAlreadySet);
                    } else {
                        if (!env('APP_DEBUG')) print("  ${RED}ERROR${NC}: No ${YELLOW}$langName${NC} translation label for ${YELLOW}$modelSectionName${NC}\n");
                    }
                }
            }

            // ----------------------------------------------------------------- Relations
            // TODO: Omit 'key' attribute if column name is <model>_id
            // -------- belongsTo
            $relations = array();
            foreach ($model->relations1to1() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $isLeaf           = ($relation instanceof RelationLeaf);
                $relations[$name] = $this->removeEmpty(array($relation->to,
                    'key'    => $relation->column->name,
                    'name'   => $relation->nameObject,
                    'type'   => $relation->type(),
                    'leaf'   => $isLeaf,
                    'delete' => $relation->delete,
                ), Framework::AND_FALSES);
            }
            foreach ($model->relationsXto1() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array($relation->to,
                    'key'    => $relation->column->name,
                    'name'   => $relation->nameObject,
                    'type'   => $relation->type(),
                    'delete' => $relation->delete,
                ), Framework::AND_FALSES);
            }
            foreach ($model->relationsSelf() as $name => &$relation) {
                if (isset($relations[$name]))    throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                if (isset($relations['parent'])) throw new \Exception("Only one parent relation allowed on [$model->name]");
                $relations[$name]    = array($relation->to, 'key' => $relation->column->name, 'type' => $relation->type());
                $relations['parent'] = array($relation->to, 'key' => $relation->column->name, 'type' => $relation->type());
            }
            $this->setPropertyInClassFile($modelFilePath, 'belongsTo', $relations);

            // -------- hasManyDeep
            // 1-1 => 1-X
            $relations = array();
            foreach ($model->relations1to1() as $name => &$relation) {
                $isLeaf       = ($relation instanceof RelationLeaf);
                $subRelations = array_merge(
                    $relation->to->relations1fromX(),
                    $relation->to->relationsXfromX(),
                    $relation->to->relationsXfromXSemi(),
                );
                // Only supporting 1 level at the moment
                foreach ($subRelations as $subName => &$deepRelation) {
                    $deepName = Model::nestedFieldName($subName, array($name));
                    if (isset($relations[$deepName])) throw new \Exception("Conflicting relations with [$deepName] on [$model->name]");
                    $relations[$deepName] = array($deepRelation->to, 'throughRelations' => array($name, $subName));
                }
            }
            $this->setPropertyInClassFile($modelFilePath, 'hasManyDeep', $relations, FALSE);

            // -------- hasMany
            $relations = array();
            foreach ($model->relations1fromX() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = array($relation->to,
                    'key' => $relation->column->name,
                    'type' => $relation->type()
                );
            }
            foreach ($model->relationsXfromXSemi() as $name => &$relation) {
                // For the pivot model only
                $name = "${name}_pivot";
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = array(
                    $relation->pivotModel,
                    'key'      => $relation->keyColumn->name,  // pivot.legalcase_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'type'     => $relation->type()
                );
            }
            foreach ($model->relationsSelf() as $name => &$relation) {
                if (isset($relations['children'])) throw new \Exception("Only one children relation allowed on [$model->name]");
                $relations['children'] = array($relation->to, 'key' => $relation->column->name, 'type' => $relation->type());
            }
            $this->setPropertyInClassFile($modelFilePath, 'hasMany', $relations);

            // -------- belongsToMany
            $relations = array();
            foreach ($model->relationsXfromX() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array(
                    $relation->to,
                    'table'    => $relation->pivot->name,
                    'key'      => $relation->keyColumn->name,  // pivot.legalcase_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'type'     => $relation->type(),
                    'delete'   => $relation->delete,
                ), Framework::AND_FALSES);
            }
            foreach ($model->relationsXfromXSemi() as $name => &$relation) {
                // This is a link to the primary through field
                // For other through fields, the pivot model should be used, $hasMany[*_pivot], from above
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array(
                    $relation->to,
                    'table'    => $relation->pivot->name,      // Semi-Pivot Model
                    'key'      => $relation->keyColumn->name,  // pivot.legalcase_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'type'     => $relation->type(),
                    'delete'   => $relation->delete,
                ), Framework::AND_FALSES);
            }
            $this->setPropertyInClassFile($modelFilePath, 'belongsToMany', $relations);

            // -------- hasOne
            $relations = array();
            foreach ($model->relations1from1() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array($relation->to,
                    'key'    => $relation->column->name,
                    'type'   => $relation->type(),
                    'delete' => $relation->delete, // This can be done by a DELETE CASCADE FK
                ), Framework::AND_FALSES);
            }
            $this->setPropertyInClassFile($modelFilePath, 'hasOne', $relations);

            // ----------------------------------------------------------------- File Uploads
            $attachments = array();
            foreach ($model->fields() as $name => &$field) {
                if ($field->fieldType == 'fileupload') {
                    $attachments[$name] = 'System\Models\File';
                }
            }
            $this->setPropertyInClassFile($modelFilePath, 'attachOne', $attachments);

            // ----------------------------------------------------------------- Methods
            // menuitemCount() for plugins.yaml
            print("  Adding menuitemCount()\n");
            $this->addStaticMethod($modelFilePath, 'menuitemCount', 'return self::all()->count();');

            // get<Something>Attribute()s
            foreach ($model->attributeFunctions as $name => &$body) {
                $namePascal = Str::studly($name);
                $funcName   = "get${namePascal}Attribute"; // Encapsulation...
                print("  Injecting public ${YELLOW}$funcName${NC}() into [$model->name]\n");
                $this->addMethod($modelFilePath, $funcName, $body);
            }
            // methods()
            foreach ($model->methods as $funcName => &$body) {
                print("  Injecting public function ${YELLOW}$funcName${NC} into [$model->name]\n");
                $this->addMethod($modelFilePath, $funcName, $body);
            }
            // static methods()
            foreach ($model->staticMethods as $funcName => &$body) {
                print("  Injecting public function ${YELLOW}$funcName${NC}() into [$model->name]\n");
                $this->addStaticMethod($modelFilePath, $funcName, $body);
            }
            if ($model->printable) {
                $this->setPropertyInClassFile($modelFilePath, 'printable', TRUE, Framework::NEW_PROPERTY);
            }

            // ----------------------------------------------------------------- Columns commenting in header
            $indent         = str_repeat(' ', 1*4);
            $commentHeader  = "$indent/* Generated Fields:\n";
            foreach ($model->table->columns as $name => &$column) $commentHeader .= "$indent * $column\n";
            $commentHeader .= "$indent */\n";
            $this->replaceInFile($modelFilePath, '/^{$/m', "{\n$commentHeader");
        } // Model exists
    }

    protected function createFormInterface(Model &$model, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($model->plugin);
        $modelDirName        = $model->dirName();
        $modelFilePath       = "$pluginDirectoryPath/models/$model->name.php";
        $modelDirPath        = "$pluginDirectoryPath/models/$modelDirName";
        $fieldsPath          = "$modelDirPath/fields.yaml";
        $createdBy           = $this->createdByString();

        print("  Check/create [$fieldsPath], add fields:\n");
        if (!is_dir($modelDirPath)) mkdir($modelDirPath, TRUE);
        $this->setFileContents($fieldsPath, "# $createdBy");

        // ---------------------------------------- Main fields.yaml
        $indent = 1;
        $this->yamlFileUnSet($fieldsPath, 'fields.id');
        foreach ($model->fields() as $name => &$field) {
            print("      Add ${YELLOW}$name${NC}($field->fieldType/$field->columnType): to ${YELLOW}fields.yaml${NC}\n");
            $dotPath = "fields.$field->fieldKey$field->fieldKeyQualifier";
            if (!$field->include) {
                if      ($field->tabLocation == 2) $dotPath = "secondaryTabs.$dotPath";
                else if ($field->tabLocation == 3) $dotPath = "tertiaryTabs.$dotPath";
                else if ($field->tab)              $dotPath = "tabs.$dotPath";
            }
            $labelKey = $field->translationKey();
            $fieldTab = ($field->tab === 'INHERIT' ? $labelKey : $field->tab); // Can be NULL
            $fieldDefinition = array(
                '#'         => $field->yamlComment,
                'label'     => $labelKey,
                'type'      => $field->fieldType,
                'path'      => $field->partial,
                'hidden'    => $field->hidden,
                'required'  => $field->required,
                'disabled'  => $field->disabled,
                'readOnly'  => $field->readOnly,
                'span'      => $field->span,
                'cssClass'  => $field->cssClass(),
                'comment'      => $field->fieldComment,
                'commentHtml'  => ($field->commentHtml && $field->fieldComment),
                'tab'          => $fieldTab,

                'options'      => $field->fieldOptions,      // Function call
                'optionsModel' => $field->fieldOptionsModel, // Model name
                'placeholder'  => $field->placeholder,
                'hierarchical' => $field->hierarchical,
                'relatedModel' => $field->relatedModel,      // Model name
                'nameFrom'     => $field->nameFrom,
                'context'      => array_keys($field->contexts),
                'dependsOn'    => array_keys($field->dependsOn),
                'nested'       => ($field->nested    ?: NULL),
                'nestLevel'    => ($field->nestLevel ?: NULL),

                'permissionSettings' => $field->permissionSettings,
                'permissions'        => $field->permissions,

                'include'      => $field->include,
                'includeModel' => $field->includeModel,
                'includePath'  => $field->includePath,
                'includeContext' => $field->includeContext,
            );
            if ($field->fieldConfig) $fieldDefinition = array_merge($fieldDefinition, $field->fieldConfig);
            $fieldDefinition = $this->removeEmpty($fieldDefinition, TRUE); // Remove FALSE
            if ($field->goto) $fieldDefinition['containerAttributes'] = array('goto-form-group-selection' => $field->goto);
            $this->yamlFileSet($fieldsPath, $dotPath, $fieldDefinition);

            // Tabs and icons
            if ($field->tabLocation == 2) $this->yamlFileSet($fieldsPath, 'secondaryTabs.cssClass', 'primary-tabs', FALSE);
            // TODO: Make tab icon configuarble
            if ($icon = $field->icon) {
                if (substr($icon, 0, 5) != 'icon-') $icon = "icon-$icon";
                if      ($field->tabLocation == 2) $this->yamlFileSet($fieldsPath, 'secondaryTabs.icons', $icon, TRUE,  $labelKey);
                else if ($field->tabLocation == 3) $this->yamlFileSet($fieldsPath, 'tertiaryTabs.icons',  $icon, TRUE,  $labelKey);
                else if ($field->tab)              $this->yamlFileSet($fieldsPath, 'tabs.icons',          $icon, FALSE, $labelKey);
            }

            // -------------------------------------------------------- Special ButtonFields
            foreach ($field->buttons as $buttonName => &$buttonField) {
                if ($buttonField) { // Can be FALSE
                    if ($buttonField->contexts) throw new \Exception("Button field different contexts to main field is not supported yet on [$name]");
                    $buttonDefinition = array(
                        'name'         => $buttonField->name,
                        'type'         => $buttonField->fieldType,
                        'span'         => $buttonField->span,
                        'cssClass'     => $buttonField->cssClass(),
                        'context'      => array_keys($field->contexts),
                        'dependsOn'    => array_keys($buttonField->dependsOn),
                        'options'      => $buttonField->fieldOptions,      // Function call
                        'optionsModel' => $buttonField->fieldOptionsModel, // Model name
                        'path'         => $buttonField->partial,
                        'comment'      => $buttonField->fieldComment,
                        'commentHtml'  => ($buttonField->commentHtml && $buttonField->fieldComment),
                        'controller'   => $buttonField->controller?->fullyQualifiedName(),
                        'tab'          => $fieldTab, // Same tab as parent field
                    );
                    $buttonDefinition = $this->removeEmpty($buttonDefinition, TRUE);

                    $dotPath = "fields.$buttonName";
                    if      ($field->tabLocation == 2) $dotPath = "secondaryTabs.$dotPath";
                    else if ($field->tabLocation == 3) $dotPath = "tertiaryTabs.$dotPath";
                    else if ($field->tab)              $dotPath = "tabs.$dotPath";
                    $this->yamlFileSet($fieldsPath, $dotPath, $buttonDefinition);
                }
            }
        }

        // ---------------------------------------- Rules
        // https://wintercms.com/docs/v1.2/docs/services/validation
        $allRules = array();
        foreach ($model->fields() as $name => &$field) {
            $fieldRules = $field->rules;
            if (!$field->isStandard()) {
                if ($field->required && !$field->nested) array_push($fieldRules, 'required');
                // TODO: max length (Currency needs this)
                if ($field->length) array_push($fieldRules, "max:$field->length");
            }
            if ($fieldRules) $allRules[$name] = implode('|', $fieldRules);
        }
        if ($allRules) $this->setPropertyInClassFile($modelFilePath, 'rules', $allRules);

        // ---------------------------------------- Lang
        $langDirPath   = "$pluginDirectoryPath/lang";
        $langEnPath    = "$pluginDirectoryPath/lang/en/lang.php";
        $modelKey      = $model->localTranslationKey();
        foreach ($model->fields() as $name => &$field) {
            $localTranslationKey = $field->localTranslationKey();
            if ($field->isLocalTranslationKey() && !$field->isStandard() && !$this->arrayFileValueExists($langEnPath, $localTranslationKey)) {
                print("      Add ${YELLOW}$localTranslationKey${NC} to ${YELLOW}lang/*${NC} for ${YELLOW}$name${NC}\n");
                // At least set the english label programmatically
                // during development, and translation file generation
                if (!$field->labels || !isset($field->labels['en']))
                    $this->langFileSet($langEnPath, $localTranslationKey, $field->devEnTitle(), 'en', $field->dbObject(), TRUE, $field->yamlComment);
                // Then others, if we have them
                // Leave the interface to show the keys, if the translation has not been added
                if ($field->labels) {
                    foreach ($field->labels as $langName => &$translation) {
                        $langFilePath = "$langDirPath/$langName/lang.php";
                        if (!file_exists($langFilePath)) throw new \Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                        $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                    }
                }
            }

            if ($field->extraTranslations) {
                foreach ($field->extraTranslations as $code => $labels) {
                    print("      Add ${YELLOW}$code${NC} to ${YELLOW}lang/*${NC} for ${YELLOW}$name${NC}\n");
                    $localTranslationKey = "$modelKey.$code";
                    foreach ($labels as $langName => &$translation) {
                        $langFilePath = "$langDirPath/$langName/lang.php";
                        if (!file_exists($langFilePath)) throw new \Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                        $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                    }
                }
            }
        }
    }

    protected function createController(Controller &$controller, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $createdBy           = $this->createdByString();
        $pluginDirectoryPath = $this->pluginDirectoryPath($controller->model->plugin);
        $controllerDirName   = $controller->dirName();
        $controllerFilePath  = "$pluginDirectoryPath/controllers/$controller->name.php";
        $controllerDirPath   = "$pluginDirectoryPath/controllers/$controllerDirName";
        $configFilterPath    = "$controllerDirPath/config_filter.yaml";
        $configFormPath      = "$controllerDirPath/config_form.yaml";
        $configRelationPath  = "$controllerDirPath/config_relation.yaml";

        if (file_exists($controllerFilePath) && $overwrite) unlink($controllerFilePath);
        if (file_exists($controllerFilePath)) {
            print("  ${RED}WARNING${NC}: Controller file [$controllerFilePath] already exists. Leaving.\n");
        } else {
            $this->runWinterCommand('create:controller', $controller->model->plugin->dotClassName(), $controller->name);

            // Inheritance
            $author = $controller->author();
            print("  Inheriting ${YELLOW}$controller->name${NC} from $author\n");
            $this->replaceInFile($controllerFilePath, '/^use Backend\\\\Classes\\\\Controller;$/m', "use $author\\\\Controller;");

            // Implements
            $this->setPropertyInClassFile($controllerFilePath, 'implement', array(
                "\\\\$author\\\\Behaviors\\\\FormController",
                "\\\\$author\\\\Behaviors\\\\ListController",
                "Backend\\\\Behaviors\\\\RelationController", // Only here to prevent RelationController requirement error
                "\\\\Acorn\\\\Behaviors\\\\RelationController",
            ), Framework::OVERWRITE_EXISTING);

            // Explicit plural name injection
            // Otherwise PathsHelper will get confused when making URLs and things
            $plural = $controller->model->table->plural;
            if ($plural) $this->setPropertyInClassFile($controllerFilePath, 'namePlural', $plural, Framework::NEW_PROPERTY);

            // -------------------------------- Filters
            $indent = 0;
            $this->appendToFile("$controllerDirPath/config_list.yaml", "filter: config_filter.yaml");
            $this->appendToFile($configFilterPath, "# $createdBy");
            foreach ($controller->model->fields() as $name => &$field) {
                $filterDefinition = NULL;

                if ($field->canFilter) {
                    // Usually PseudoField ?from? relation filters
                    // The IdField also has all these relations on it, but is usually marked as !canFilter
                    // Time fields also have relations
                    $filterDefinition = array(
                        '#'          => $name,
                        'label'      => $field->translationKey(Model::PLURAL),
                        'type'       => $field->filterType,
                        'conditions' => $field->conditions,
                        'nameFrom'   => $field->nameFrom, // Often fully_qualified_name
                    );

                    if (count($field->relations)) {
                        foreach ($field->relations as $name => &$relation) {
                            // RelationXfromX
                            // RelationXfrom1 does not
                            // Date based fields should have a datarange type filter
                            // Event fields should have a datarange type filter
                            $otherModel       = &$relation->to;
                            $otherModelFQN    = $otherModel->fullyQualifiedName();
                            if (!isset($filterDefinition['modelClass'])) $filterDefinition['modelClass'] = $otherModelFQN;

                            if ($relation->canFilter) {
                                $filterDefinition['# Relation'] = (string) $relation;
                                if ($relation instanceof RelationXfromX || $relation instanceof RelationXfromXSemi) {
                                    // SQL
                                    $pivotTable       = &$relation->pivot;
                                    $keyColumn        = &$relation->keyColumn;
                                    $otherColumn      = &$relation->column;
                                    $pivotTableName   = $pivotTable->name;

                                    // TODO: Write these in to the Model Relations, not here
                                    if (!isset($filterDefinition['conditions']) || is_null($filterDefinition['conditions']))
                                        $filterDefinition['conditions'] = "id in(select $pivotTableName.$keyColumn->name from $pivotTableName where $pivotTableName.$otherColumn->name in(:filtered))";
                                } else if ($relation instanceof RelationXto1) {
                                    // Event and User canFilter foreign key fields come here
                                    // conditions already defined
                                }

                                $filterDefinition = $this->removeEmpty($filterDefinition, TRUE);
                                $this->yamlFileSet($configFilterPath, "scopes.$name", $filterDefinition);
                            } else {
                                $relationClass = preg_replace('/.*\\\\/', '', get_class($relation));
                                $this->yamlFileSet($configFilterPath, "# ${name}[$relation] ($relationClass)", 'relation !canFilter');
                            }
                        }
                    } else {
                        // TODO: Non-relation fields, like dates
                        // Nothing comes here at the moment
                        // because everything is a foreign key: dates, users, etc.
                        throw new \Exception("Un-considered filter [$name]");
                        // $this->yamlFileSet($configFilterPath, "scopes.$name", $filterDefinition);
                    }
                } else {
                    $fieldClass = preg_replace('/.*\\\\/', '', get_class($field));
                    $this->yamlFileSet($configFilterPath, "# ${name} ($fieldClass)", 'field !canFilter');
                }
            }
        }

        // ---------------------------------------- Relation Manager configuration
        // We always need a config_relation.yaml, because all controllers implement the behaviour
        $this->yamlFileSet($configRelationPath, '#', $createdBy);
        foreach ($controller->model->fields() as $name => &$field) {
            if ($field->fieldType == 'relationmanager') {
                if (count($field->relations) == 0) throw new \Exception("Field $name has no relations for relationmanager configuration");
                if (count($field->relations) > 1)  throw new \Exception("Field $name has multiple relations for relationmanager configuration");
                $relationModel           = end($field->relations)->to;
                $relationPluginDirectory = $relationModel->plugin->dirName();
                $relationModelDirName    = $relationModel->dirName();
                $relationModelDirPath    = "/$relationPluginDirectory/models/$relationModelDirName";
                $rlButtons               = ($field->rlButtons ?: array('create' => TRUE, 'delete' => TRUE));

                $this->yamlFileSet($configRelationPath, $field->fieldKey, array(
                    'label' => $field->translationKey(),
                    'view' => array(
                        'list' => "\$$relationModelDirPath/columns.yaml",
                        'toolbarButtons' => implode('|', array_keys($rlButtons)),
                        'showCheckboxes' => true,
                        'recordsPerPage' => $field->recordsPerPage, // Can be false
                    ),
                    'manage' => array(
                        'form' => "\$$relationModelDirPath/fields.yaml",
                        'recordsPerPage' => $field->recordsPerPage,
                    ),
                ));
            }
        }

        // ---------------------------------------- Controller based Actions
        // config_form.yaml
        // TODO: Write the labels to lang, and the translationKeys to the YAML
        // TODO: These are not used yet, only the Model->actionFunctions set above
        $this->yamlFileSet($configFormPath, 'actionFunctions', $controller->model->actionFunctions);

        // ----------------------------------------------- Interface variants
        $maxTabLocation = 0;
        foreach ($controller->model->fields() as $name => &$field) {
            if ($field->tabLocation > $maxTabLocation) $maxTabLocation = $field->tabLocation;
        }
        $layout = ($maxTabLocation >= 3 ? 'form-with-sidebar' : 'form');
        $this->setPropertyInClassFile($controllerFilePath, 'bodyClass', 'compact-container', FALSE);
        print("    Tab max ${YELLOW}$maxTabLocation${NC} template: ${YELLOW}$layout${NC}\n");

        $interfaceVariantsDirPath = "$this->scriptDirPath/acorn-create-system-classes/frameworks/winter/controllers/$layout";
        foreach (scandir($interfaceVariantsDirPath) as $controllerFile) {
            $controllerFilePath = "$interfaceVariantsDirPath/$controllerFile";
            if (!in_array($controllerFile, array(".",".."))) {
                print("    Copied ${YELLOW}$layout/$controllerFile${NC} => $controllerDirPath/\n");
                copy($controllerFilePath, "$controllerDirPath/$controllerFile");
            }
        }
    }

    protected function createListInterface(Model &$model, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($model->plugin);
        $modelDirName        = $model->dirName();
        $modelFilePath       = "$pluginDirectoryPath/models/$model->name.php";
        $modelDirPath        = "$pluginDirectoryPath/models/$modelDirName";
        $columnsPath         = "$modelDirPath/columns.yaml";
        $createdBy           = $this->createdByString();

        print("  Check/create [$columnsPath], add columns:\n");
        if (!is_dir($modelDirPath)) mkdir($modelDirPath, TRUE);
        $this->setFileContents($columnsPath, "# $createdBy");

        // -------------------------------- Columns.yaml
        // Remove the standard columns. If the model has them, they will be re-created
        $indent = 1;
        $this->yamlFileUnSet($columnsPath, 'columns.id');
        $this->yamlFileUnSet($columnsPath, 'columns.created_at');
        $this->yamlFileUnSet($columnsPath, 'columns.updated_at');

        foreach ($model->fields() as $name => &$field) {
            if ($field->canDisplayAsColumn()) {
                // Columns.yaml checks
                if ($field->sqlSelect && $field->valueFrom)              throw new \Exception("select: and valueFrom: are mutually exclusive on [$field->name]");
                if ($field->relation  && strstr($field->columnKey, '[')) throw new \Exception("relation: and nesting are mutually exclusive on [$field->name]");

                print("      Add ${YELLOW}$name${NC}($field->fieldType/$field->columnType): to ${YELLOW}columns.yaml${NC}\n");
                $columnDefinition = array(
                    '#'          => $field->yamlComment,
                    '# Debug:'   => $field->debugComment,
                    'label'      => $field->translationKey(),
                    'type'       => $field->columnType,
                    'valueFrom'  => $field->valueFrom,
                    'searchable' => $field->searchable,
                    'sortable'   => $field->sortable,
                    'invisible'  => $field->invisible,
                    'path'       => $field->columnPartial,
                    'relation'   => $field->relation,
                    'select'     => $field->sqlSelect,
                    'nested'     => ($field->nested    ?: NULL),
                    'nestLevel'  => ($field->nestLevel ?: NULL),

                    // TODO: Columns should also include Xto1 relations
                    'include'        => $field->include,
                    'includeModel'   => $field->includeModel,
                    'includePath'    => $field->includePath,
                    'includeContext' => $field->includeContext,
                );
                if ($field->columnConfig) $columnDefinition = array_merge($columnDefinition, $field->columnConfig);
                $columnDefinition = $this->removeEmpty($columnDefinition); // We do not remove falses
                $this->yamlFileSet($columnsPath, "columns.$field->columnKey", $columnDefinition);
            }
        }
    }

    protected function runChecks(Plugin &$plugin)
    {
        print("\nRunning post install checks for [$plugin]\n");
        $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
        $modelsDirPath       = "$pluginDirectoryPath/models";
        $controllersDirPath  = "$pluginDirectoryPath/controllers";
        $pluginFQN           = $plugin->fullyQualifiedName();

        print("  Checking all translation keys");
        foreach (scandir($modelsDirPath) as $modelDirName) {
            $modelDirPath = "$modelsDirPath/$modelDirName";
            if (!in_array($modelDirName, array(".","..")) && is_dir($modelDirPath)) {
                print('.');
                $fieldsFilePath = "$modelDirPath/fields.yaml";
                $fields         = $this->yamlFileLoad($fieldsFilePath, Framework::NO_CACHE);
                if (isset($fields['fields'])) {
                    foreach ($fields['fields'] as $name => $config) {
                        if (is_array($config) && isset($config['label'])) {
                            $key = $config['label'];
                            if (!$this->checkTranslationKey($key))
                                throw new \Exception("Lang key [$key] in [$fieldsFilePath] not found");
                        }
                    }
                }
                if (isset($fields['tabs']['fields'])) {
                    foreach ($fields['tabs']['fields'] as $name => $config) {
                        if (is_array($config) && isset($config['label'])) {
                            $key = $config['label'];
                            if (!$this->checkTranslationKey($key))
                                throw new \Exception("Lang key [$key] in [$fieldsFilePath] not found");
                        }
                        if (is_array($config) && isset($config['tab'])) {
                            $key = $config['tab'];
                            if (!$this->checkTranslationKey($key))
                                throw new \Exception("Lang key [$key] in [$fieldsFilePath] not found");
                        }
                    }
                }

                $columnsFilePath = "$modelDirPath/columns.yaml";
                $columns         = $this->yamlFileLoad($columnsFilePath, Framework::NO_CACHE);
                if (isset($columns['columns'])) {
                    foreach ($columns['columns'] as $name => $config) {
                        if (is_array($config) && isset($config['label'])) {
                            $key = $config['label'];
                            if (!$this->checkTranslationKey($key))
                                throw new \Exception("Lang key [$key] in [$columnsFilePath] not found");
                        }
                    }
                }
            }
        }
        print(" ✓\n");

        print("  Checking Models PHP syntax");
        // TODO: Not sure this syntax checking is working...
        foreach (scandir($modelsDirPath) as $fileName) {
            $fileParts = explode('.', $fileName);
            $filePath  = "$modelsDirPath/$fileName";
            $fileType  = (isset($fileParts[1]) ? $fileParts[1] : '');
            if (is_file($filePath) && $fileType == 'php') {
                $modelName     = $fileParts[0];
                $modelFQN      = "$pluginFQN\\Models\\$modelName";
                print('.');
                require($filePath);
                new $modelFQN;
            }
        }
        print(" ✓\n");

        print("  Checking Controllers PHP syntax");
        foreach (scandir($controllersDirPath) as $fileName) {
            $fileParts = explode('.', $fileName);
            $filePath  = "$controllersDirPath/$fileName";
            $fileType  = (isset($fileParts[1]) ? $fileParts[1] : '');
            if (is_file($filePath) && $fileType == 'php') {
                $controllerName     = $fileParts[0];
                $controllerFQN      = "$pluginFQN\\Controllers\\$controllerName";
                print('.');
                require($filePath);
                new $controllerFQN;
            }
        }
        print(" ✓\n");
    }

    public function checkTranslationKey(string $key): bool
    {
        $keyParts      = explode('::', $key);
        $domain        = $keyParts[0];                     // acorn.user | acorn
        if (count($keyParts) < 2) throw new \Exception("Translation key ''$domain' needs 2 dot parts");
        $localParts    = explode('.', $keyParts[1]);       // lang, models, general, id
        $localKey      = implode('.', array_slice($localParts, 1)); // models.general.id
        $isModule      = (strstr($domain, '.') === FALSE); // acorn
        $domainRelDir  = str_replace('.', '/', $domain);   // acorn/user | acorn
        $domainDirPath = ($isModule ? "modules/$domainRelDir" : "plugins/$domainRelDir");
        $langFilePath  = realpath("$domainDirPath/lang/en/lang.php");

        return $this->arrayFileValueExists($langFilePath, $localKey, Framework::NO_CACHE);
    }
}
