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
        if (!$env) throw new \Exception("WinterCMS .env file not found or empty at [$cwd]");
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

        if (file_exists($pluginFilePath) && $overwrite) unlink($pluginFilePath);
        if (file_exists($pluginFilePath)) {
            print("  ${RED}WARNING${NC}: Plugin file [$pluginFilePath] already exists. Leaving.\n");
        } else {
            $this->runWinterCommand('create:plugin', $plugin->dotClassName());

            // --------------------------------------------- Created bys, authors & README.md
            $createdBy  = $this->createdByString();
            $readmePath = "$pluginDirectoryPath/README.md";
            if (!file_exists($readmePath)) {
                $this->setFileContents($readmePath, "# $plugin->name");
                $this->appendToFile($readmePath, $createdBy);
            }

            // --------------------------------------------- Plugin.php misc
            // Alter the public function pluginDetails(): array function array return
            // and append some comments
            $this->changeArrayReturnFunction($pluginFilePath, 'pluginDetails', 'author', 'Acorn');
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
                if (!$relation instanceof Relation1from1) {
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
        }

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
        $this->arrayFileSet($langEnPath, 'models.general', array(
            'id'     => 'ID',
            'name'   => 'Name',
            'short_name' => 'Short name',
            'type'   => 'Type',
            'image'  => 'Image',
            'select' => 'Select',
            'select_existing' => 'Selected existing',
            'created_at_event' => 'Created At',
            'updated_at_event' => 'Updated At',
            'created_by_user'  => 'Created By',
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
            '_qrcode'        => 'QR Code',
            '_qrcode_scan'   => 'QR Code Scan',
            'find_by_qrcode' => 'Find by QR code',

            // Standard Buttons
            'create'     => 'Create',
            'new'        => 'New',
            'add'        => 'Add',
            'print'      => 'Print',
            'save_and_print'    => 'Save and Print',
            'correct_and_print' => 'Correct and Print',

            // System
            'replication_debug' => 'Replication Debug',
            'trigger_http_call_response' => 'Trigger HTTP call response',
        ), FALSE);
        if (isset($plugin->pluginNames['en']))        $this->arrayFileSet("$langDirPath/en/lang.php", 'plugin.name',        $plugin->pluginNames['en'],        FALSE);
        if (isset($plugin->pluginDescriptions['en'])) $this->arrayFileSet("$langDirPath/en/lang.php", 'plugin.description', $plugin->pluginDescriptions['en'], FALSE);

        // Arabic general
        $this->arrayFileSet("$langDirPath/ar/lang.php", 'models.general', array(
            'id'     => 'المعرف',
            'name'   => 'الأسم',
            'short_name' => 'الاسم المختصر',
            'type'   => 'النوع',
            'image'  => 'الصور',
            'select' => 'إختيار',
            'select_existing' => 'حدد عنوانًا موجودًا',
            'created_at_event' => 'تم التسجيل في',
            'updated_at_event' => 'تم التحديث في',
            'created_by_user'  => 'Created By',
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
            '_qrcode'        => 'رمز QR',
            '_qrcode_scan'   => 'مسح الرمز',
            'find_by_qrcode' => 'البحث بواسطة الرمز',

            // Standard Buttons
            'create'     => 'نشاء ماركة جديدة',
            'new'        => 'ماركة جديدة',
            'add'        => 'إضافة',
            'print'      => 'Print',
            'save_and_print'    => 'حفظ وطباعة',
            'correct_and_print' => 'حفظ التصحيح وطباعته',

            // System
            'replication_debug' => 'تصحيح أخطاء التكرار',
            'trigger_http_call_response' => 'تشغيل استجابة اتصال HTTP',
        ), FALSE);
        if (isset($plugin->pluginNames['ar']))        $this->arrayFileSet("$langDirPath/ar/lang.php", 'plugin.name',        $plugin->pluginNames['ar'],        FALSE);
        if (isset($plugin->pluginDescriptions['ar'])) $this->arrayFileSet("$langDirPath/ar/lang.php", 'plugin.description', $plugin->pluginDescriptions['ar'], FALSE);

        // Kurdish general
        $this->arrayFileSet("$langDirPath/ku/lang.php", 'models.general', array(
            'id'     => 'ID',
            'name'   => 'Name',
            'short_name' => 'Short name',
            'type'   => 'Type',
            'image'  => 'Image',
            'select' => 'Select',
            'select_existing' => 'Selected existing',
            'created_at_event' => 'Created At',
            'updated_at_event' => 'Updated At',
            'created_by_user'  => 'Created By',
            'created_at'  => 'Created At',
            'updated_at'  => 'Updated At',
            'created_by'  => 'Created By',

            // Some fields
            'quantity' => 'Quantity',
            'distance' => 'Distance',
            'parent'   => 'Parent',

            // Menus
            'actions' => 'Actions',
            'setup'   => 'Setup',
            'reports' => 'Reports',

            // In-built QR codes
            '_qrcode'        => 'QR Code',
            '_qrcode_scan'   => 'QR Code Scan',
            'find_by_qrcode' => 'Find by QR code',

            // Standard Buttons
            'create'     => 'Create',
            'new'        => 'New',
            'add'        => 'Add',
            'print'      => 'Print',
            'save_and_print'    => 'Save and Print',
            'correct_and_print' => 'Correct and Print',

            // System
            'replication_debug' => 'Replication Debug',
            'trigger_http_call_response' => 'Trigger HTTP call response',
        ), FALSE);
        if (isset($plugin->pluginNames['ku']))        $this->arrayFileSet("$langDirPath/ku/lang.php", 'plugin.name',        $plugin->pluginNames['ku'],        FALSE);
        if (isset($plugin->pluginDescriptions['ku'])) $this->arrayFileSet("$langDirPath/ku/lang.php", 'plugin.description', $plugin->pluginDescriptions['ku'], FALSE);

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

        // Create PGSQL extensions and schemas if not present
        // TODO: Why? This is dangerous. Do it manually
        /*
        if (file_exists("$pluginUpdatePath/pre-up.sql")) {
            print("  Run ${GREEN}pre-up.sql${NC} (functions, schemas, extensions)\n");
            $this->db->runSQLFile("$pluginUpdatePath/pre-up.sql");
        }
        */
    }

    protected function createMenus(Plugin &$plugin) {
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

        if (file_exists($modelFilePath) && $overwrite) unlink($modelFilePath);
        if (file_exists($modelFilePath)) {
            print("  ${RED}WARNING${NC}: Model file [$modelFilePath] already exists. Leaving.\n");
        } else {
            $this->runWinterCommand('create:model', $model->plugin->dotClassName(), $model->name);

            // Potentially rewrite $table because create:model will automatically plural it
            $this->setPropertyInClassFile($modelFilePath, 'table', $model->table->name);

            $createdBy  = $this->createdByString();
            $this->appendToFile($modelFilePath, "// $createdBy");

            // Rewrite version.yaml to use create_from_sql.php: The create:model has updated it
            // create:model makes the v1.0.1/ directories also. Remove them
            $scriptsUpdatesPath = "$this->scriptDirPath/SQL/updates";
            $pluginUpdatePath   = "$pluginDirectoryPath/updates";
            copy("$scriptsUpdatesPath/version.yaml", "$pluginUpdatePath/version.yaml");
            $this->removeDir("$pluginDirectoryPath/updates/v1.0.1/", TRUE, TRUE, FALSE);

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
            $this->setPropertyInClassFile($modelFilePath, 'actionFunctions', $model->actionFunctions, FALSE);

            // ---------------------------------------------------------------- Seeding
            // This moves seeding: directives in to updates\seed.sql
            $seederPath = "$pluginDirectoryPath/updates/seed.sql";
            if ($model->table->seeding) {
                $schema = $model->table->schema;
                $table  = $model->table->name;
                print("  ${GREEN}SEEDING${NC} for [$table]\n");
                // TODO: Seeding does not work yet: NULLs and strings. Also not creating NOT NULL associated calendar events. Need function?
                foreach ($model->table->seeding as $row) {
                    $valuesSQL = '';
                    foreach ($row as $value) {
                        if      ($value === 'DEFAULT') $valueSQL = 'DEFAULT';
                        else if (substr($value, 0, 19) === 'fn_acorn_' && substr($value, -1) == ')') $valueSQL = $value;
                        else $valueSQL = var_export($value, TRUE);
                        if ($valuesSQL) $valuesSQL .= ',';
                        $valuesSQL .= $valueSQL;
                    }
                    $insert = "insert into $schema.$table values($valuesSQL);";
                    $this->appendToFile($seederPath, $insert);
                }
            }

            // ----------------------------------------------------------------- Language
            // These non-en files will not have been updated by the create:model command
            $langDirPath      = "$pluginDirectoryPath/lang";
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
                        $this->arrayFileSet($langFilePath, "models.$modelSectionName", array(
                            'label'        => $label,
                            'label_plural' => $labelPlural
                        ), $throwIfAlreadySet);
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
                $relations[$name] = array($relation->to, 'key' => $relation->column->name, 'name' => $relation->nameObject, 'leaf' => $isLeaf, 'type' => $relation->type());
            }
            foreach ($model->relationsXto1() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = array($relation->to, 'key' => $relation->column->name, 'name' => $relation->nameObject, 'type' => $relation->type());
            }
            foreach ($model->relationsSelf() as $name => &$relation) {
                if (isset($relations[$name]))    throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                if (isset($relations['parent'])) throw new \Exception("Only one parent relation allowed on [$model->name]");
                $relations[$name]    = array($relation->to, 'key' => $relation->column->name, 'type' => $relation->type());
                $relations['parent'] = array($relation->to, 'key' => $relation->column->name, 'type' => $relation->type());
            }
            $this->setPropertyInClassFile($modelFilePath, 'belongsTo', $relations);

            // -------- hasMany
            $relations = array();
            foreach ($model->relations1fromX() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = array($relation->to, 'key' => $relation->column->name, 'type' => $relation->type());
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
                $relations[$name] = array(
                    $relation->to,
                    'table'    => $relation->pivot->name,
                    'key'      => $relation->keyColumn->name,  // pivot.legalcase_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'type'     => $relation->type()
                );
            }
            foreach ($model->relationsXfromXSemi() as $name => &$relation) {
                // This is a link to the primary through field
                // For other through fields, the pivot model should be used, $hasMany[*_pivot], from above
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = array(
                    $relation->to,
                    'table'    => $relation->pivot->name,      // Semi-Pivot Model
                    'key'      => $relation->keyColumn->name,  // pivot.legalcase_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'type'     => $relation->type()
                );
            }
            $this->setPropertyInClassFile($modelFilePath, 'belongsToMany', $relations);

            // -------- hasOne
            $relations = array();
            foreach ($model->relations1from1() as $name => &$relation) {
                if (isset($relations[$name])) throw new \Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = array($relation->from, 'key' => $relation->column->name, 'type' => $relation->type());
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
                $funcName   = "get${namePascal}Attribute";
                print("  Injecting public ${YELLOW}$funcName${NC}() into [$model->name]\n");
                $this->addMethod($modelFilePath, $funcName, $body);
            }
            // methods()
            foreach ($model->methods as $funcName => &$body) {
                print("  Injecting public function ${YELLOW}$funcName${NC}() into [$model->name]\n");
                $this->addStaticMethod($modelFilePath, $funcName, $body);
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
            $dotPath = "fields.$field->fieldKey";
            if (!$field->include) {
                if      ($field->tabLocation == 2) $dotPath = "secondaryTabs.$dotPath";
                else if ($field->tabLocation == 3) $dotPath = "tertiaryTabs.$dotPath";
                else if ($field->tab)              $dotPath = "tabs.$dotPath";
            }
            $labelKey = $field->translationKey();

            // Fields.yaml checks
            if ($field->include) throw new \Exception("include: is depreceated on [$field->name]");

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

                'options'      => $field->fieldOptions,      // Function call
                'optionsModel' => $field->fieldOptionsModel, // Model name
                'placeholder'  => $field->placeholder,
                'hierarchical' => $field->hierarchical,
                'nameFrom'     => $field->nameFrom,
                'context'      => array_keys($field->contexts),
                'dependsOn'    => array_keys($field->dependsOn),

                'comment'      => $field->fieldComment,
                'commentHtml'  => ($field->commentHtml && $field->fieldComment),

                'include'      => $field->include,
                'includeModel' => $field->includeModel,
                'includePath'  => $field->includePath,
                'includeContext' => $field->includeContext,
                'tab'          => $fieldTab
            );
            $fieldDefinition = $this->removeEmpty($fieldDefinition, TRUE);
            if ($field->goto) $fieldDefinition['containerAttributes'] = array('goto-form-group-selection' => $field->goto);
            $this->yamlFileSet($fieldsPath, $dotPath, $fieldDefinition);

            // Tabs and icons
            if ($field->tabLocation == 2) $this->yamlFileSet($fieldsPath, 'secondaryTabs.cssClass', 'primary-tabs', FALSE);
            // TODO: Make tab icon configuarble
            if ($icon = $field->icon) {
                if (substr($icon, 0, 5) != 'icon-') $icon = "icon-$icon";
                if      ($field->tabLocation == 2) $this->yamlFileSet($fieldsPath, 'secondaryTabs.icons', $icon, TRUE, $labelKey);
                else if ($field->tabLocation == 3) $this->yamlFileSet($fieldsPath, 'tertiaryTabs.icons', $icon, TRUE, $labelKey);
                else if ($field->tab)              $this->yamlFileSet($fieldsPath, 'tabs.icons',          $icon, TRUE, $labelKey);
            }

            // -------------------------------------------------------- Special ButtonFields
            foreach ($field->buttons as $buttonName => &$buttonField) {
                if ($buttonField) { // Can be FALSE
                    $buttonDefinition = array(
                        'name' => $buttonField->name,
                        'type' => $buttonField->fieldType,
                        'span' => $buttonField->span,
                        'cssClass'     => $buttonField->cssClass(),
                        'context'      => array_keys($buttonField->contexts),
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
        $rules = array();
        foreach ($model->fields() as $name => &$field) {
            $rule = $field->rule;
            if (!$rule && !$field->isStandard()) {
                if ($field->required) $rule .= 'required';
                // TODO: max length (Currency needs this) https://wintercms.com/docs/v1.2/docs/services/validation
            }
            if ($rule) $rules[$name] = $rule;
        }
        $this->setPropertyInClassFile($modelFilePath, 'rules', $rules);

        // ---------------------------------------- Lang
        $langDirPath   = "$pluginDirectoryPath/lang";
        $langEnPath    = "$pluginDirectoryPath/lang/en/lang.php";
        $modelLangName = $model->langSectionName();
        foreach ($model->fields() as $name => &$field) {
            $localTranslationKey = $field->localTranslationKey();
            if ($field->isLocalTranslationKey() && !$field->isStandard() && !$this->arrayFileValueExists($langEnPath, $localTranslationKey)) {
                print("      Add ${YELLOW}$localTranslationKey${NC} to ${YELLOW}lang/*${NC} for ${YELLOW}$name${NC}\n");
                // At least set the english label programmatically
                if (!$field->labels || !isset($field->labels['en'])) $this->arrayFileSet($langEnPath, $localTranslationKey, $field->devEnTitle());
                // Then others, if we have them
                // Leave the interface to show the keys, if the translation has not been added
                if ($field->labels) {
                    foreach ($field->labels as $langName => &$translation) {
                        $langFilePath = "$langDirPath/$langName/lang.php";
                        if (!file_exists($langFilePath)) throw new \Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                        $this->arrayFileSet($langFilePath, $localTranslationKey, $translation);
                    }
                }
            }
        }
    }

    protected function createController(Controller &$controller, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($controller->model->plugin);
        $controllerDirName   = $controller->dirName();
        $controllerFilePath  = "$pluginDirectoryPath/controllers/$controller->name.php";
        $controllerDirPath   = "$pluginDirectoryPath/controllers/$controllerDirName";
        $configFilterPath    = "$controllerDirPath/config_filter.yaml";

        if (file_exists($controllerFilePath) && $overwrite) unlink($controllerFilePath);
        if (file_exists($controllerFilePath)) {
            print("  ${RED}WARNING${NC}: Controller file [$controllerFilePath] already exists. Leaving.\n");
        } else {
            $this->runWinterCommand('create:controller', $controller->model->plugin->dotClassName(), $controller->name);

            // Inheritance
            $author = $controller->author();
            print("  Inheriting ${YELLOW}$controller->name${NC} from $author\n");
            $this->replaceInFile($controllerFilePath, '/^use Backend\\\\Classes\\\\Controller;$/m', "use $author\\\\Controller;");
            $this->replaceInFile($controllerFilePath, '/\\\\Backend\\\\Behaviors\\\\FormController::class/', "\\\\$author\\\\Behaviors\\\\FormController::class");
            $this->replaceInFile($controllerFilePath, '/\\\\Backend\\\\Behaviors\\\\ListController::class/', "\\\\$author\\\\Behaviors\\\\ListController::class");

            // Explicit plural name injection
            // Otherwise PathsHelper will get confused when making URLs and things
            $plural = $controller->model->table->plural;
            if ($plural) $this->setPropertyInClassFile($controllerFilePath, 'namePlural', $plural, FALSE);

            // -------------------------------- Filters
            $indent = 0;
            $this->appendToFile("$controllerDirPath/config_list.yaml", "filter: config_filter.yaml");
            foreach ($controller->model->fields() as $name => &$field) {
                if ($field->canFilter) {
                    // Usually PseudoField ?from? relation filters
                    // The IdField also has all these relations on it
                    if (count($field->relations)) {
                        foreach ($field->relations as $name => &$relation) {
                            // RelationXfromX
                            // RelationXfrom1 does not
                            // Date based fields should have a datarange type filter
                            // Event fields should have a datarange type filter
                            if ($relation->canFilter) {
                                // SQL
                                $pivotTable       = &$relation->pivot;
                                $keyColumn        = &$relation->keyColumn;
                                $otherColumn      = &$relation->column;

                                // Labels
                                $otherModel       = &$relation->to;
                                $otherModelFQN    = $otherModel->fullyQualifiedName();
                                $nameFrom         = 'fully_qualified_name';

                                $filterDefinition = array(
                                    'label'      => $field->translationKey(Model::PLURAL),
                                    'modelClass' => $otherModelFQN,
                                    'nameFrom'   => $nameFrom,
                                    'conditions' => "id in(select $pivotTable->name.$keyColumn->name from $pivotTable->name where $pivotTable->name.$otherColumn->name in(:filtered))",
                                );

                                // TODO: This should be the concern of something else?
                                // TODO: These SQL statements should be elsewhere?
                                if ($otherModelFQN == 'Acorn\\Calendar\\Models\\Event') {
                                    // Created_at_event_id (calendar style) Date Range filter
                                    $filterDefinition = array_merge($filterDefinition, array(
                                        'type' => 'daterange',
                                        'yearRange' => 10,
                                        'conditions' => "((select aacep.start from acorn_calendar_event_part aacep where aacep.event_id = $columnSQLName order by start limit 1) between ':after' and ':before')",
                                    ));
                                }

                                $this->yamlFileSet($configFilterPath, "scopes.$name", $filterDefinition);
                            }
                        }
                    }
                }
            }
        }

        // ----------------------------------------------- Interface variants
        foreach ($controller->model->fields() as $name => &$field) {
            if ($field->tabLocation == 3) {
                // form-with-sidebar layout required
                $this->setPropertyInClassFile($controllerFilePath, 'bodyClass', 'compact-container', FALSE);

                $interfaceVariantsDirPath = "$this->scriptDirPath/acorn-create-system-classes/frameworks/winter/controllers/form-with-sidebar";
                foreach (scandir($interfaceVariantsDirPath) as $controllerFile) {
                    $controllerFilePath = "$interfaceVariantsDirPath/$controllerFile";
                    if (!in_array($controllerFile, array(".",".."))) {
                        print("    Copied ${YELLOW}$controllerFile${NC} => $controllerDirPath/\n");
                        copy($controllerFilePath, "$controllerDirPath/$controllerFile");
                    }
                }

                // Only necessary once
                break;
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
        $indent = 1;
        $this->yamlFileUnSet($columnsPath, 'columns.id');
        if (!$model->hasField('created_at')) $this->yamlFileUnSet($columnsPath, 'columns.created_at');
        if (!$model->hasField('updated_at')) $this->yamlFileUnSet($columnsPath, 'columns.updated_at');

        foreach ($model->fields() as $name => &$field) {
            if ($field->canDisplayAsColumn()) {
                // Columns.yaml checks
                if ($field->sqlSelect && $field->valueFrom)              throw new \Exception("select: and valueFrom: are mutually exclusive on [$field->name]");
                if ($field->relation  && strstr($field->columnKey, '[')) throw new \Exception("relation: and nesting are mutually exclusive on [$field->name]");

                print("      Add ${YELLOW}$name${NC}($field->fieldType/$field->columnType): to ${YELLOW}columns.yaml${NC}\n");
                $columnDefinition = array(
                    '#'          => $field->yamlComment,
                    'label'      => $field->translationKey(),
                    'type'       => $field->columnType,
                    'valueFrom'  => $field->valueFrom,
                    'searchable' => $field->searchable,
                    'sortable'   => $field->sortable,
                    'invisible'  => $field->invisible,
                    'path'       => $field->columnPartial,
                    'relation'   => $field->relation,
                    'select'     => $field->sqlSelect,

                    // TODO: Columns should also include Xto1 relations
                    'include'        => $field->include,
                    'includeModel'   => $field->includeModel,
                    'includePath'    => $field->includePath,
                    'includeContext' => $field->includeContext,
                );
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
                $fields         = $this->yamlFileLoad($fieldsFilePath);
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
                $columns         = $this->yamlFileLoad($columnsFilePath);
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
        $localParts    = explode('.', $keyParts[1]);       // lang, models, general, id
        $localKey      = implode('.', array_slice($localParts, 1)); // models.general.id
        $isModule      = (strstr($domain, '.') === FALSE); // acorn
        $domainRelDir  = str_replace('.', '/', $domain);   // acorn/user | acorn
        $domainDirPath = ($isModule ? "modules/$domainRelDir" : "plugins/$domainRelDir");
        $langFilePath  = realpath("$domainDirPath/lang/en/lang.php");

        return $this->arrayFileValueExists($langFilePath, $localKey);
    }
}
