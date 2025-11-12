<?php namespace Acorn\CreateSystem;

use \Symfony\Component\Console\Input\ArgvInput;
use \Symfony\Component\Console\Output\ConsoleOutput;
use \Illuminate\Contracts\Console\Kernel;
use \Exception;

require_once('bootstrap/autoload.php');

class WinterCMS extends Framework
{
    protected const WINTER_TABLES  = array('cache', 'jobs', 'failed_jobs', 'job_batches', 'migrations', 'sessions', 'deferred_bindings');
    protected const WINTER_MODULES = array('cms', 'backend', 'system');

    protected $APP_URL;
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
        $this->kernel = $this->app->make(Kernel::class);
        $this->output = new ConsoleOutput;

        // We run a winter command to indirectly load all classes
        // We may get an error:
        //  System\\Traits\\SecurityController not defined
        // which means that the classes.php class loader has been removed
        $this->runWinterCommand('list');

        // WinterCMS always requires the AA infrastructure to be pre-installed
        $moduleAALocation = "$cwd/modules/acorn/Model.php";
        if (!file_exists($moduleAALocation)) 
            throw new Exception("WinterCMS at [$cwd] does not have the required Acorn module at [$moduleAALocation]");

        // ---------------------------- DB
        // Get DB connection parameters from Laravel
        if (!$this->DB_HOST) $this->DB_HOST = '127.0.0.1';
        if (!$this->DB_PORT) $this->DB_PORT = 5432;
        if ( $this->DB_CONNECTION != 'pgsql' || $this->DB_HOST != "127.0.0.1" ) {
            throw new Exception("$this->DB_CONNECTION@$this->DB_HOST:$this->DB_PORT is not local. Aborted");
        }
        $this->connection = "pgsql:host=$this->DB_HOST;dbname=$this->DB_DATABASE;port=$this->DB_PORT;";
        $this->database   = $this->DB_DATABASE;
        $this->username   = $this->DB_USERNAME;
        $this->password   = $this->DB_PASSWORD;

        // ---------------------------- DBAUTH
        if ($this->username == '<DBAUTH>') {
            $dbAuthCreateSystemUser = 'createsystem';
            print("{$YELLOW}NOTE{$NC}: DBAuth module detected, using assumed {$YELLOW}$dbAuthCreateSystemUser{$NC} user, with standard password, instead\n");
            $this->username   = $dbAuthCreateSystemUser;
            $this->password   = 'QueenPool1@';
        }

        // ---------------------------- Icons
        // This icon library is used for the automatic, sequential assignment of icons to menu-items
        $this->iconFile    = "$cwd/modules/backend/formwidgets/iconpicker/meta/libraries.yaml";
        $this->iconCurrent = 7;
        if (!file_exists($this->iconFile)) {
            throw new Exception("Icon file [$this->iconFile] missing");
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
        if (!$env) throw new Exception("WinterCMS .env file not found or empty at [$this->cwd]");
        return explode("\n", $env);
    }

    public function appUrl(): string {return $this->APP_URL;}
    public function dbHost(): string {return $this->DB_HOST;}
    public function dbPort(): string {return $this->DB_PORT;}
    public function dbDatabase(): string {return $this->DB_DATABASE;}
    public function dbUsername(): string {return $this->DB_USERNAME;}
    public function dbPassword(): string {return $this->DB_PASSWORD;}

    public function isFrameworkTable(string &$tablename): bool
    {
        return (array_search($tablename, self::WINTER_TABLES) !== FALSE);
    }

    public function isFrameworkModuleTable(string &$tablename): bool
    {
        $tableNameParts = explode('_', $tablename);
        return (array_search($tableNameParts[0], self::WINTER_MODULES) !== FALSE);
    }

    protected function runWinterCommand(string $command, int $indent = 2, ...$args): int
    {
        global $YELLOW, $RED, $NC;

        $indentString = str_repeat(' ', $indent);
        print("{$indentString}{$RED}artisan $command{$NC}\n");
        
        $this->input  = new ArgvInput(array('', $command, ...$args));
        $this->status = $this->kernel->handle($this->input, $this->output);

        return $this->status;
    }

    public function pluginDirectoryPath(Plugin|Module &$plugin): string
    {
        $dirName = $plugin->dirName();
        return "$this->cwd/plugins/$dirName";
    }

    public function modelFileDirectoryPath(Model &$model, string $file = NULL): string
    {
        $pluginDirectoryPath = $this->pluginDirectoryPath($model->plugin);
        $dirName             = $model->dirName();
        $modelDirectoryPath  = "$pluginDirectoryPath/models/$dirName";
        if ($file) $modelDirectoryPath .= "/$file";
        return $modelDirectoryPath;
    }

    public function langPath(Plugin|Module $plugin, string $lang = NULL): string
    {
        $domainDirPath = $this->pluginDirectoryPath($plugin);
        $langDir       = "$domainDirPath/lang";
        if ($lang) $langDir .= "/$lang/lang.php";
        return $langDir;
    }

    public function langEnPath(Plugin|Module $plugin): string
    {
        return $this->langPath($plugin, 'en');
    }

    protected function pluginFile(Plugin|Module &$plugin): string
    {
        return $this->pluginDirectoryPath($plugin) . "/Plugin.php";
    }

    // -------------------------------------------------- create*()
    protected function createPlugin(Plugin &$plugin, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
        $pluginFilePath      = "$pluginDirectoryPath/Plugin.php";
        $createdBy           = $this->createdByString();

        print("Plugin: $plugin->name\n");
        $this->runWinterCommand('create:plugin', 2, $plugin->dotClassName());
        // Immediately stamp it as create-system so that 
        // fields() call below recognises this plugin as native
        $this->appendTofile(  $pluginFilePath, "\n// $createdBy");

        // --------------------------------------------- Plugin.php misc
        // Alter the public function pluginDetails(): array function array return
        // and append some comments
        $this->changeArrayReturnFunctionEntry($pluginFilePath, 'pluginDetails', 'author', 'Acorn');
        $this->removeMethod($pluginFilePath, 'registerNavigation');
        $this->replaceInFile( $pluginFilePath, '/Registers backend navigation items for this plugin./', 'Navigation in plugin.yaml.');

        // Adding cross plugin dependencies
        $requirePlugins = array(
            'Acorn.Calendar'  => TRUE,
            'Acorn.Location'  => TRUE,
            'Acorn.Messaging' => TRUE
        );
        foreach ($plugin->pluginRequires() as $fqn => &$otherPlugin) {
            // Check for direct recursion
            $circular = FALSE;
            foreach ($otherPlugin->pluginRequires() as &$otherOtherPlugin) {
                if ($otherOtherPlugin->is($plugin)) {
                    $circular = TRUE;
                    //     {$RED}ERROR{$NC}: [{$YELLOW}$plugin{$NC}] <=> [{$YELLOW}$otherPlugin{$NC}]
                    throw new Exception("Circular plugin dependency $plugin <=> $otherPlugin");
                }
            }

            if (!$circular && !isset($requirePlugins[$fqn])) {
                print("    Adding Plugin \$require {$YELLOW}$fqn{$NC}\n");
                $requirePlugins[$fqn] = TRUE;
            }
        }
        $this->setPropertyInClassFile($pluginFilePath, 'require', array_keys($requirePlugins), FALSE);

        // --------------------------------------------- Lang plugin section lang.php
        $langDirPath = "$pluginDirectoryPath/lang";
        $langEnPath  = "$langDirPath/en/lang.php";

        // Copy standard lang.php files in to position
        if (!is_dir("$langDirPath/ku/")) mkdir("$langDirPath/ku/", 0775, TRUE);
        if (!is_dir("$langDirPath/ar/")) mkdir("$langDirPath/ar/", 0775, TRUE);
        foreach (scandir($langDirPath) as $langName) {
            if (!in_array($langName, array(".",".."))) {
                $langFilePath = "$langDirPath/$langName/lang.php";

                if (file_exists($langFilePath)) {
                    if ($langName != 'en') print("  {$RED}LANG{$NC}: {$YELLOW}$langName{$NC} language file already exists\n");
                } else {
                    print("    {$GREEN}LANG{$NC}: Created {$YELLOW}$langName{$NC} language file\n");
                    copy($langEnPath, $langFilePath);
                }
            }
        }
        // plugin.name
        if (isset($plugin->pluginNames))
            $this->writeLangValues($langDirPath, 'plugin.name', $plugin->pluginNames);
        // plugin.description
        // Created by message is the same across all language files
        if (isset($plugin->pluginDescriptions))
            $this->writeLangValues($langDirPath, 'plugin.description', $plugin->pluginDescriptions);
        else
            $this->writeLangValues($langDirPath, 'plugin.description', $createdBy);
        // models.general.*
        $this->writeLangValues($langDirPath, 'models.general', Framework::$standardTranslations);

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
                if (!$isQualifiedName) 
                    throw new Exception("Permission [$fullyQualifiedKey] is not qualified");
            }

            foreach ($permissions as $fullyQualifiedName => &$config) {
                $permissionNameParts     = explode(".", $fullyQualifiedName);
                $permissionPluginDotPath = implode(".", array_slice($permissionNameParts, 0, 2));
                $permissionLocalName     = end($permissionNameParts);
                // We only register permissions for this plugin
                // acorn.university...
                if ($permissionPluginDotPath == $pluginDotName) {
                    print("    Adding Permission: {$GREEN}$fullyQualifiedName{$NC}\n");
                    $pluginPermissionConfig = array(
                        'tab'   => "$translationDomain::lang.plugin.name",
                        'label' => "$translationDomain::lang.permissions.$permissionLocalName",
                    );
                    $pluginPermissionsArray[$fullyQualifiedName] = $pluginPermissionConfig;
                    // Adorn the main config for the lang updates later
                    $config['plugin'] = $pluginPermissionConfig;
                }
            }
            // Add these to the plugin.php
            $this->setArrayReturnFunction($pluginFilePath, 'registerPermissions', $pluginPermissionsArray);

            // ---------------------------------------------------------------- Permissions lang.php
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
            print("  {$RED}WARNING{$NC}: No {$YELLOW}$scriptsUpdatesPath{NC} found to populate the plugin /updates/. Creating...\n");
            mkdir($scriptsUpdatesPath, TRUE);
        }

        print("  Syncing {$GREEN}$pluginUpdatePath{$NC}\n");
        if (!is_dir($pluginUpdatePath)) {
            echo "  Made {$YELLOW}$pluginUpdatePath{$NC}\n";
            mkdir($pluginUpdatePath, 0775, TRUE);
        }
        foreach (scandir($scriptsUpdatesPath) as $file) {
            if (!in_array($file, array(".",".."))) {
                $scriptsFilePath = realpath("$scriptsUpdatesPath/$file");
                $updatesFilePath = "$pluginUpdatePath/$file";
                if (file_exists($updatesFilePath)) {
                    print("    Ommitting {$RED}$file{$NC}\n");
                } else {
                    print("    Copied {$YELLOW}$file{$NC} => updates/\n");
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
            print("  Run {$GREEN}acorn-winter-update-sqls{$NC}\n");
            $this->runBashScript("$pluginUpdatePath/acorn-winter-update-sqls", TRUE);
        } else {
            print("{$RED}ERROR{$NC}: No {$YELLOW}acorn-winter-update-sqls{$NC} available\n");
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
            print("  Run {$GREEN}pre-up.sql{$NC} (functions, schemas, extensions)\n");
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
            print("  Plugin {$GREEN}$dotClassName{$NC} is already registered in $pluginTable\n");
        } else {
            print("  Plugin {$GREEN}$dotClassName{$NC} registered in $pluginTable\n");
            $this->db->insert("INSERT into $pluginTable(code, version, created_at)
                values(:plugin, '1.0.0', now())",
                array('plugin' => $dotClassName)
            );
        }

        // --------------------------------------------- Do Seeding
        // Note that this will seed also table comments that are not Models
        $this->runWinterCommand('acorn:seed', 2, $plugin->dotClassName());
    }

    protected function adornOtherCustomPlugins(Plugin &$thisPlugin, bool $overwrite = FALSE) {
        // Non-create-system plugins can usefully receive extra dynamic relations, fields and columns
        // where create-system plugins are referencing them
        // For example: student 1-1=> (user 1-X=> user_group) <=1-1 entity

        // This happens where $this model has a relation to a custom plugin like user
        // which means that $this->plugin needs to boot() adorn the custom plugin
        // with a relation, field and column
        // For example:
        //   public function boot() {
        //     User::extend(function ($model){
        //         $model->belongsToMany['addresses'] = [Address::class, 'table' => 'acorn_location_user_address'];
        //     });
        //     Users::extendFormFields(function ($form, $model, $context) {
        //       $form->addFields(['addresses' => [...]]);
        //     });
        //     Users::extendListColumns(function ($list, $model) {
        //         $list->addColumns(['addresses' => [...]]);
        //     });
        //   }
        global $GREEN, $YELLOW, $RED, $NC;

        $bootMethodPhp = '';

        foreach ($thisPlugin->models as $thisModel) {
            $thisTable        = $thisModel->getTable();
            $thisLabel        = $thisModel->translationKey();
            $pluginLabel      = $thisPlugin->translationKey();
            $thisOptions      = $thisModel->dropdownOptionsCall();
            $thisRelationName = $thisModel->dirName(); // hierarchies
            $thisClassFQN     = $thisModel->absoluteFullyQualifiedName(Model::WITH_CLASS_STRING);
            $thisTableFQN     = $thisTable->fullyQualifiedName();

            // ------------------------------- belongsTo(1-1) => hasOne
            $relationType = 'hasOne';
            foreach ($thisModel->relations1to1() as $name => &$relation) {
                $isToCustomModel = !$relation->to->isCreateSystem();
                if ($isToCustomModel) {
                    $customModelFQN    = $relation->to->absoluteFullyQualifiedName();
                    $customController  = $relation->to->controller();
                    $listFields        = array(
                        $thisRelationName => [
                            'label'     => $thisLabel,
                            'relation'  => $thisRelationName,
                            'valueFrom' => 'name',
                        ]
                    );
                    if ($relation->fieldsSettingsTo) 
                        $listFields = array_merge($listFields, $relation->fieldsSettingsTo);
                    $listFieldsString = var_export($listFields, TRUE);

                    $bootMethodPhp    .= <<<PHP
// ------------------ $customModelFQN
$customModelFQN::extend(function (\$model){
    \$model->{$relationType}['$thisRelationName'] = [$thisClassFQN, 'table' => '$thisTableFQN'];
});

PHP;
                    if ($customController->exists()) {
                        // We DO NOT add the field for performance reasons
                        // \Acorn\Controller::extendFormFieldsGeneral(function (\$form, \$model, \$context) {
                        //     if (\$model instanceof $customModelFQN) {
                        //         \$form->addTabFields(['$thisRelationName' => [
                        //             'label'    => '$thisLabel',
                        //             'type'     => 'dropdown',
                        //             'options'  => '$thisOptions',
                        //             'emptyOption' => 'acorn::lang.models.general.nothing_linked',
                        //             'tab'      => '$pluginLabel'
                        //         ]]);
                        //     }
                        // });

                        // emptyOption to ensure that it can and does remain NULL
                        $bootMethodPhp    .= <<<PHP
\Acorn\Controller::extendListColumnsGeneral(function (\$list, \$model) {
    if (\$model instanceof $customModelFQN) {
        \$list->addColumns($listFieldsString);
    }
});

PHP;
                    }
                    print("  {$GREEN}INFO{$NC}: Adorned {$YELLOW}$customModelFQN{$NC} with {$YELLOW}$thisRelationName{$NC} relation\n");
                }
            }

            // TODO: ------------------------------- Custom plugin adornment belongsTo(X-1) => hasMany, etc.

            // ------------------------------- Global Scope setting additions to the User plugin
            if ($thisModel->globalScope) {
                // Add field to DB if not present
                // acorn_university_academic_years_global_scope_setting
                $usersTable       = Table::get('acorn_user_users');
                $thisTableSubName = $thisTable->subNameSingular();
                $usersColumnStub  = "global_scope_$thisTableSubName"; 
                $usersColumnName  = "{$usersColumnStub}_id"; 
                if (!$usersTable->hasColumn($usersColumnName)) {
                    // We assume a Lookup table with id (uuid)
                    $this->db->addColumn(
                        $usersTable->fullyQualifiedName(), 
                        $usersColumnName, 
                        'uuid', 
                        NULL, 
                        Column::NULLABLE
                    );
                    $this->db->addForeignKey(
                        $usersTable->fullyQualifiedName(), 
                        $usersColumnName, 
                        $thisTableFQN,
                        'id',
                        DB::SET_NULL
                    );
                }

                // Add field to user field tab and columns
                $bootMethodPhp    .= <<<PHP
// ------------------ Global Scope setting for $thisModel
\Acorn\User\Models\User::extend(function (\$model){
    \$model->belongsTo['$usersColumnStub'] = [$thisClassFQN, 'table' => '$thisTableFQN'];
});
\Acorn\User\Controllers\Users::extendFormFieldsGeneral(function (\$form, \$model, \$context) {
    if (\$model instanceof \Acorn\User\Models\User) {
        \$form->addTabFields(['$usersColumnName' => [
            'label'   => '$thisLabel',
            'type'    => 'dropdown',
            'span'    => 'storm',
            'cssClass' => 'col-xs-6 col-md-3',
            'options' => '$thisOptions',
            'emptyOption' => 'acorn::lang.models.general.no_restriction',
            'tab'     => 'acorn::lang.models.general.global_scopes'
        ]]);
    }
});
\Acorn\User\Controllers\Users::extendListColumnsGeneral(function (\$list, \$model) {
    if (\$model instanceof \Acorn\User\Models\User) {
        \$list->addColumns(['$usersColumnStub' => [
            'label'     => '$thisLabel',
            'relation'  => '$usersColumnStub',
            'valueFrom' => 'name',
        ]]);
    }
});

PHP;
                print("  {$GREEN}INFO{$NC}: Adorned User Model with {$YELLOW}$thisClassFQN{$NC} global scope setting\n");
            }
        }

        // Write boot method of this plugin
        if ($bootMethodPhp) {
            $pluginDirectoryPath = $this->pluginDirectoryPath($thisPlugin);
            $pluginFilePath      = "$pluginDirectoryPath/Plugin.php";
            $this->replaceMethod($pluginFilePath, 'boot', $bootMethodPhp);
        }
    }

    protected function writeReadme(Plugin &$plugin, string $contents) {
        // Created bys, authors & README.md
        $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
        $readmePath = "$pluginDirectoryPath/README.md";

        if (!file_exists($readmePath)) {
            // Lines that are zero-indented are top level headings
            $contents  = preg_replace('/^([^ ].*)/m', "```\n\n# \$1\n\n```", $contents);
            // Remove first code start
            $contents  = preg_replace('/^```\n\n/m', '', $contents, 1);
            // Complete last
            $contents .= '```';
            // Winter doc removes the first # Heading
            $contents  = "# $plugin->name\n\n$contents";
            // Remove terminal colour formatting
            $contents  = preg_replace('/\[[0-9]+;[0-9]+m|\[0m/', '', $contents);
            // Remove accidental commenting
            $contents  = preg_replace('/\/\*/', '/ *', $contents);

            $this->setFileContents($readmePath, $contents);
        }
    }

    public function createMenus(Plugin &$plugin, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($plugin);
        $translationDomain   = $plugin->translationDomain();
        $pluginYamlPath      = "$pluginDirectoryPath/plugin.yaml";
        $pluginMenuName      = strtolower($plugin->name);
        $langDirPath         = "$pluginDirectoryPath/lang";

        if ($plugin->pluginMenu !== FALSE) {
            if ($this->yamlFileValueExists($pluginYamlPath, 'navigation')) {
                print("  {$YELLOW}WARNING{$NC}: Navigation already present for [{$YELLOW}$plugin->name{$NC}]\n");
            } else {
                print("  Adding navigation, setup side-menu\n");

                $sideMenu      = array();
                $firstModelUrl = NULL;
                foreach ($plugin->models as $modelName => &$model) {
                    if ($controller = $model->controller(FALSE)) {
                        if ($controller->menu) {
                            $sideMenuName    = strtolower($controller->name); // educationauthorities
                            $icon            = $controller->icon;
                            $url             = $controller->relativeUrl();
                            $modelFQN        = $model->absoluteFullyQualifiedName();
                            $langSectionName = $model->langSectionName();
                            $permissionFQN   = $model->permissionFQN('view_menu');

                            if ($controller->qrCodeScan) {
                                $qrUrl = "$url/qrcodescan";
                                // Provide an extra Create and Scan button
                                // that comes back to here
                                // TODO: This does not work because the redirect will not include the buttons again
                                $sideMenu['qrcodescan'] = array(
                                    'label'   => 'acorn::lang.models.general.scan_qrcode',
                                    'url'     => $qrUrl,
                                    'icon'    => 'icon-qrcode',
                                    
                                    'permissions' => array($permissionFQN),
                                );
                            }

                            if ($controller->allControllers === TRUE || $controller->allControllers === 'before') {
                                // All controllers item
                                $sideMenu['all'] = array(
                                    'label' => 'acorn::lang.models.general.all_controllers',
                                    'url'   => $controller->relativeUrl('all'),
                                    'icon'  => 'icon-map',
                                    'permissions' => array($model->permissionFQN('all')),
                                );
                                print(", all");
                            }

                            print("    +Side-menu entry [$sideMenuName] @{$YELLOW}$url{$NC}");
                            if ($icon) {
                                if (substr($icon, 0, 5) != 'icon-') $icon = "icon-$icon";
                            } else {
                                $icon = $this->getNextIcon();
                                print(" with auto-selected icon {$YELLOW}$icon{$NC}");
                            }
                            
                            if ($controller->menuSplitter === TRUE || $controller->menuSplitter === 'before') {
                                $sideMenu["_splitter_$sideMenuName"] = array(
                                    'label' => 'splitter',
                                    'url'   => 'splitter',
                                    'icon'  => 'acorn-splitter',
                                );
                                print(", menu-splitter");
                            }
                            
                            if ($controller->menuTaskItems) { 
                                // ---------------------------- Task based menus
                                // For example:
                                //   Register new Student
                                //   Add a student to a course
                                //   Find a student
                                // Allowed formats:
                                //   - create
                                //   create: true
                                //   my_item:
                                //     ...
                                foreach ($controller->menuTaskItems as $tk_menuKey => $tk_menuConfig) {
                                    print("    +Task based menu-item {$YELLOW}$tk_menuKey{$NC}");

                                    if (is_numeric($tk_menuKey)) {
                                        $tk_menuKey    = $tk_menuConfig;
                                        $tk_menuConfig = array();
                                    }
                                    if (is_bool($tk_menuConfig)) $tk_menuConfig = array();

                                    // TODO: Add permissions
                                    $tk_sideMenuName     = "{$sideMenuName}_$tk_menuKey";
                                    $tk_permissionFQN    = $model->permissionFQN("use_task_$tk_menuKey");
                                    $tk_explicitLabelKey = (isset($tk_menuConfig['label']) ? $tk_menuConfig['label'] : NULL);;
                                    $tk_labels  = (isset($tk_menuConfig['labels']) ? $tk_menuConfig['labels'] : NULL);
                                    $tk_url     = (isset($tk_menuConfig['url'])    ? $tk_menuConfig['url']    : NULL);
                                    $tk_icon    = (isset($tk_menuConfig['icon'])   ? $tk_menuConfig['icon']   : NULL);
                                    $tk_counter = NULL;

                                    switch ($tk_menuKey) {
                                        case 'create':
                                            if (is_null($tk_url))    $tk_url    = $controller->relativeUrl('create');
                                            if (is_null($tk_icon))   $tk_icon   = 'plus';
                                            if (is_null($tk_labels)) {
                                                $tk_labels = array();
                                                // TODO: Translate stub Create a new
                                                foreach ($model->labels as $langName => $langModelLabel) {
                                                    $tk_labels[$langName] = "Create a new $langModelLabel";
                                                }
                                            }
                                            break;
                                        case 'find':
                                            if (is_null($tk_url))    $tk_url    = $controller->relativeUrl();
                                            if (is_null($tk_icon))   $tk_icon   = 'search';
                                            if (is_null($tk_labels)) {
                                                $tk_labels = array();
                                                foreach ($model->labels as $langName => $langModelLabel) {
                                                    $tk_labels[$langName] = "Find a $langModelLabel";
                                                }
                                            }
                                            $tk_counter = "$modelFQN::menuitemCount";
                                            break;
                                        case 'list':
                                            // Adopt main list item
                                            if (is_null($tk_url))    $tk_url    = $url;
                                            if (is_null($tk_icon))   $tk_icon   = $icon;
                                            if (is_null($tk_labels)) $tk_explicitLabelKey = "$translationDomain::lang.models.$langSectionName.label_plural";
                                            if (!$firstModelUrl) $firstModelUrl = $tk_url;
                                            $tk_counter = "$modelFQN::menuitemCount";
                                            break;
                                    }

                                    // Auto-provision missing icon
                                    if ($tk_icon) {
                                        if (substr($tk_icon, 0, 5) != 'icon-') $tk_icon = "icon-$tk_icon";
                                    } else {
                                        $tk_icon = $this->getNextIcon();
                                        print(" with auto-selected icon {$YELLOW}$tk_icon{$NC}");
                                    }

                                    // Process labels => explicitLabelKey
                                    if (!$tk_explicitLabelKey) {
                                        $tk_explicitLabelKey = "$translationDomain::lang.models.$langSectionName.menutasks.$tk_menuKey";
                                        $this->writeLangValues($langDirPath, $tk_explicitLabelKey, $tk_labels);
                                    }

                                    $sideMenu[$tk_sideMenuName] = $this->removeEmpty(array(
                                        'label'   => $tk_explicitLabelKey,
                                        'url'     => $tk_url,
                                        'icon'    => $tk_icon,
                                        'permissions' => array($tk_permissionFQN),
                                        'counter' => $tk_counter
                                    ));
                                    print("\n");
                                }
                            }
                            // ---------------------------- Standard List => CRUD Navigation item
                            else { 
                                $sideMenu[$sideMenuName] = array(
                                    'label'   => "$translationDomain::lang.models.$langSectionName.label_plural",
                                    'url'     => $url,
                                    'icon'    => $icon,
                                    'permissions' => array($permissionFQN),
                                );
                                if (!$firstModelUrl) $firstModelUrl = $url;
                                $sideMenu[$sideMenuName]['counter'] = "$modelFQN::menuitemCount";
                            }

                            if ($controller->menuSplitter === 'after') {
                                $sideMenu["_splitter_$sideMenuName"] = array(
                                    'label' => 'splitter',
                                    'url'   => 'splitter',
                                    'icon'  => 'acorn-splitter',
                                );
                                print(", menu-splitter(after)");
                            }

                            if ($controller->allControllers === 'after') {
                                // All controllers item
                                $sideMenu['all'] = array(
                                    'label' => 'acorn::lang.models.general.all_controllers',
                                    'url'   => $controller->relativeUrl('all'),
                                    'icon'  => 'icon-map',
                                    'permissions' => array($model->permissionFQN('all')),
                                );
                                print(", all(after)");
                            }

                            print("\n");
                        }
                    }
                }

                $icon = $plugin->pluginIcon;
                if ($icon) {
                    if (substr($icon, 0, 5) != 'icon-') $icon = "icon-$icon";
                } else {
                    $icon = $this->getNextIcon();
                    print("  Auto-selected plugin icon {$YELLOW}$icon{$NC}\n");
                }
                $permissionFQN = $plugin->permissionFQN();
                $navigationDefinition = array(
                    $pluginMenuName => array(
                        'label'       => "$translationDomain::lang.plugin.name",
                        'url'         => ($plugin->pluginUrl ?: ($firstModelUrl ?: '#')),
                        'icon'        => $icon,
                        'permissions' => array($permissionFQN),
                        'sideMenu'    => $sideMenu,
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
        $modelTranslationKey = $model->translationDomain();
        $langDirPath         = "$pluginDirectoryPath/lang";
        $table               = $model->getTable();

        if (file_exists($modelFilePath) && $overwrite) unlink($modelFilePath);
        if (file_exists($modelFilePath)) {
            print("  {$RED}WARNING{$NC}: Model file [$modelFilePath] already exists. Leaving.\n");
        } else {
            print("Model: $model->name\n");
            $this->runWinterCommand('create:model', 2, $model->plugin->dotClassName(), $model->name);

            // Potentially rewrite $table because create:model will automatically plural it
            $this->setPropertyInClassFile($modelFilePath, 'table', $model->getTable()->fullyQualifiedName());
            if (!is_null($model->order)) $this->setPropertyInClassFile($modelFilePath, 'order', $model->order, Framework::NEW_PROPERTY, 'public static');

            // Views create read-only models
            if ($model->readOnly)
                $this->setPropertyInClassFile($modelFilePath, 'readOnly', TRUE, Framework::NEW_PROPERTY);

            $createdBy  = $this->createdByString();
            $this->appendToFile($modelFilePath, "// $createdBy");

            // Rewrite version.yaml to use create_from_sql.php: The create:model has updated it
            // create:model makes the v1.0.1/ directories also. Remove them
            $scriptsUpdatesPath = "$this->scriptDirPath/SQL/updates";
            $pluginUpdatePath   = "$pluginDirectoryPath/updates";
            copy("$scriptsUpdatesPath/version.yaml", "$pluginUpdatePath/version.yaml");
            self::removeDir("$pluginDirectoryPath/updates/v1.0.1/", TRUE, TRUE, FALSE);

            // Explicit plural name injection
            // Otherwise PathsHelper will get confused when making URLs and things
            $plural = $model->getTable()->plural;
            if ($plural) $this->setPropertyInClassFile($modelFilePath, 'namePlural', $plural, Framework::NEW_PROPERTY);

            // ----------------------------------------------------------------- Behaviours, Uses, Classes & inheritance
            // TODO: SoftDelete
            $dateColumns = array_keys($model->getTable()->dateColumns());
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
                'Carbon\\Carbon' => TRUE,
                'Carbon\\CarbonInterval' => TRUE,
            ));
            print("    Inheriting from Acorn\\\\Model\n");
            // WinterCMS v1.2.7 changed to Winter\Storm\Database\Model
            $this->replaceInFile($modelFilePath, '/^use (Winter\\\Storm\\\Database\\\Model|Model);$/m', 'use Acorn\\Model;');

            // Traits
            $revisionable = array();
            foreach ($model->fields() as $name => &$field) {
                if ($field->revisionable) 
                    array_push($revisionable, $name);
            }
            if ($revisionable) {
                $revisionableList = implode(',', $revisionable);
                print("    Adding Trait Revisionable for $revisionableList\n");
                $model->traits['\\Winter\\Storm\\Database\\Traits\\Revisionable'] = TRUE;
                $this->setPropertyInClassFile($modelFilePath, 'revisionable', $revisionable, FALSE, 'protected');
                $this->setPropertyInClassFile($modelFilePath, 'morphMany', array(
                    'revision_history' => array('System\\Models\\Revision', 'name' => 'revisionable')
                ));
            }

            if ($model->hasSoftDelete()) {
                print("    Adding Trait SoftDelete\n");
                $model->traits['\\Winter\\Storm\\Database\\Traits\\SoftDelete'] = TRUE;
            }
            if ($model->isDistributed()) {
                print("    Adding Trait HasUuids\n");
                $model->traits['\\Illuminate\\Database\\Eloquent\\Concerns\\HasUuids'] = TRUE;
            }
            if ($model->hasSelfReferencingRelations()) 
                $model->traits['\\Winter\\Storm\\Database\\Traits\\NestedTree'] = TRUE;
            if ($model->hasField('sort_order'))
                 $model->traits['\\Winter\\Storm\\Database\\Traits\\Sortable'] = TRUE;

            $this->writeFileUses(   $modelFilePath, $model->uses);
            $this->writeClassTraits($modelFilePath, $model->traits);

            // Relax guarding
            // TODO: SECURITY: Relaxed guarding is ok?
            $this->setPropertyInClassFile($modelFilePath, 'guarded', array(), TRUE, 'protected');

            // ---------------------------------------------------------------- Relations debug
            if ($relations = $model->relations()) {
                print("  Relations:\n");
                foreach ($relations as $name => $relation) {
                    $classParts = explode('\\', get_class($relation));
                    $class      = end($classParts);
                    print("    {$GREEN}$class{$NC}({$YELLOW}$name{$NC}): $relation\n");
                }
            }

            // ---------------------------------------------------------------- Model based functions and links
            // before, after, ales and action functions and links => lang.php
            // Write the labels to lang, and the translationKeys to the YAML
            // All function definitions have a stage before|after|action|link|ales
            // => acorn.<plugin>::lang.models.<model>.functions.<stage>.<fn-name>:
            //   .label|comment
            //   .parameters.<pr-name>.label|comment
            // Some of these model properties are not actually referenced
            // but here for completeness
            if ($model->beforeFunctions) {
                $this->processStageFunctionLang($model, $model->beforeFunctions, $langDirPath);
                $this->setPropertyInClassFile($modelFilePath, 'beforeFunctions', $model->beforeFunctions, FALSE, 'public', self::STD_INDENT, Framework::ALL_MULTILINE);
            }
            if ($model->afterFunctions) {
                $this->processStageFunctionLang($model, $model->afterFunctions, $langDirPath);
                $this->setPropertyInClassFile($modelFilePath, 'afterFunctions', $model->afterFunctions, FALSE, 'public', self::STD_INDENT, Framework::ALL_MULTILINE);
            }
            if ($model->actionFunctions) {
                $this->processStageFunctionLang($model, $model->actionFunctions, $langDirPath);
                $this->setPropertyInClassFile($modelFilePath, 'actionFunctions', $model->actionFunctions, FALSE, 'public', self::STD_INDENT, Framework::ALL_MULTILINE);
            }
            if ($model->actionLinks) {
                $this->processStageFunctionLang($model, $model->actionLinks, $langDirPath);
                $this->setPropertyInClassFile($modelFilePath, 'actionLinks', $model->actionLinks, FALSE, 'public', self::STD_INDENT, Framework::ALL_MULTILINE);
            }
            if ($model->alesFunctions) {
                $this->processStageFunctionLang($model, $model->alesFunctions, $langDirPath);
                $this->setPropertyInClassFile($modelFilePath, 'alesFunctions', $model->alesFunctions, FALSE, 'public', self::STD_INDENT, Framework::ALL_MULTILINE);
            }
    
            // ---------------------------------------------------------------- Global Scope
            // This table restricts ALL related Models to the current selection
            // Relations (Foreign Keys) should be marked as global_scope=<from|to> 
            // to chain to this scope
            if ($model->globalScope) {
                // TODO: $_SESSION[$name] selector
                $scopeName  = "{$model->name}Scope";
                $modelFQN   = $model->fullyQualifiedName();
                $scopeFQN   = "$modelFQN\\$scopeName";
                $path       = "$modelDirPath/$scopeName.php";
                $scopingFunction = (is_string($model->globalScope) 
                    ? "public static \$scopingFunction = '$model->globalScope';"
                    : NULL
                );

                $this->appendToFile($path, <<<PHP
<?php
// Auto-generated by Create-System
namespace $modelFQN;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Acorn\Scopes\GlobalChainScope;

class $scopeName extends GlobalChainScope
{
    $scopingFunction

    public function shouldApply(Model \$model, bool \$isThis = FALSE): bool
    {
        return self::hasSessionFor(\$model, \$isThis);
    }

    public function apply(Builder \$builder, Model \$model): void 
    {
        self::applySession(\$builder, \$model);
    }
}
PHP
                );

                // Instruct this class to use this Scope directly
                $this->setPropertyInClassFile($modelFilePath, 'globalScope', $scopeFQN, FALSE, 'public static');
                if ($model->globalScopeCssTheme) $this->setPropertyInClassFile($modelFilePath, 'globalScopeCssTheme', $model->globalScopeCssTheme, FALSE, 'public static');
            }

            // ---------------------------------------------------------------- Create Seeding
            // This moves seeding: directives in to updates\seed.sql
            // and also appends any fn_acorn_*_seed_*() functions
            $seederPath = "$pluginDirectoryPath/updates/seed.sql";
            if ($seeding = $table->seedingOther) {
                $sqls = $this->seedingToSQLs($seeding);
                $sql  = implode("\n", $sqls);
                $this->appendToFile($seederPath, "-- $table->order: $table->name (other)", 0, TRUE, FALSE);
                $this->appendToFile($seederPath, $sql);
            }
            
            if ($seeding = $table->seeding) {
                $tableFQN     = $table->fullyQualifiedName();
                $seedingTable = array($tableFQN => $seeding);
                $sqls         = $this->seedingToSQLs($seedingTable);
                $sql          = implode("\n", $sqls);
                $this->appendToFile($seederPath, "-- $table->order: $table->name", 0, TRUE, FALSE);
                $this->appendToFile($seederPath, $sql);
            }

            // ---------------------------------------------------------------- Model labels section lang.php
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
            if (isset($model->labels))
                $this->writeLangValues($langDirPath, "models.$modelSectionName.label", $model->labels, $model->dbObject());
            if (isset($model->labelsPlural))
                $this->writeLangValues($langDirPath, "models.$modelSectionName.label_plural", $model->labelsPlural, $model->dbObject());

            // ----------------------------------------------------------------- Relations
            // TODO: Omit 'key' attribute if column name is <model>_id
            // -------- belongsTo
            $relations = array();
            foreach ($model->relations1to1() as $name => &$relation) {
                if (isset($relations[$name])) throw new Exception("Conflicting relations with [$name] on [$model->name]");
                $isLeaf           = ($relation instanceof RelationLeaf);
                $relations[$name] = $this->removeEmpty(array($relation->to,
                    'key'    => $relation->column->name,
                    'name'   => $relation->nameObject,
                    'type'   => $relation->type(),
                    'leaf'   => $isLeaf,
                    'global_scope' => ($relation->globalScope === 'to'),
                    'delete' => $relation->delete,
                    'count'  => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions
                ), Framework::AND_FALSES);
            }
            foreach ($model->relationsXto1() as $name => &$relation) {
                if (isset($relations[$name])) 
                    throw new Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array($relation->to,
                    'key'    => $relation->column->name,
                    'name'   => $relation->nameObject,
                    'type'   => $relation->type(),
                    'global_scope' => ($relation->globalScope === 'to'),
                    'delete' => $relation->delete,
                    'count'  => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions
                ), Framework::AND_FALSES);
            }
            $this->setPropertyInClassFile($modelFilePath, 'belongsTo', $relations);

            // -------- hasManyDeep
            // 1-1 => 1-X && 1-1 => 1-1 => 1-X
            // Important also for form embedding:
            // 1-1 => 1-1 deep form embedding
            $relations = array();
            foreach ($model->relationsHasManyDeep() as $name => $relation) {
                $relations[$name] = $this->removeEmpty(array(
                    $relation->to, 
                    'throughRelations' => array_keys($relation->throughRelations), 
                    'containsLeaf'     => $relation->containsLeaf,
                    'name'             => $relation->nameObject,
                    'key'              => $relation->column->name,
                    'global_scope'     => ($relation->globalScope === 'from'),
                    // Type is important because we can immediately identify 
                    // fully 1to1 deep relations for embedding
                    // 1to1 means all steps are 1to1
                    // because $relation above will only be 1to1 traversal
                    // other (XfromX, etc.) indicates the LAST step only
                    'type'   => $relation->type(), 
                    'count'  => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions
                ), Framework::AND_FALSES);
            }
            $this->setPropertyInClassFile($modelFilePath, 'hasManyDeep', $relations, FALSE);

            // -------- hasMany
            $relations = array();
            foreach ($model->relations1fromX() as $name => &$relation) {
                if (isset($relations[$name])) throw new Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array($relation->to,
                    'key'    => $relation->column->name,
                    'global_scope' => ($relation->globalScope === 'from'),
                    'type'   => $relation->type(),
                    'count'  => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions
                ), Framework::AND_FALSES);
            }
            foreach ($model->relationsXfromXSemi() as $name => &$relation) {
                // For the pivot model only
                $name = "{$name}_pivot";
                if (isset($relations[$name])) throw new Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array(
                    $relation->pivotModel,
                    'key'      => $relation->keyColumn->name,  // pivot.user_group_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'global_scope' => ($relation->globalScope === 'from'),
                    'type'     => $relation->type(),
                    'count'    => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions
                ), Framework::AND_FALSES);
            }
            $this->setPropertyInClassFile($modelFilePath, 'hasMany', $relations);

            // -------- belongsToMany
            $relations = array();
            foreach ($model->relationsXfromX() as $name => &$relation) {
                if (isset($relations[$name])) throw new Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array(
                    $relation->to,
                    'table'    => $relation->pivot->name,
                    'key'      => $relation->keyColumn->name,  // pivot.user_group_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'type'     => $relation->type(),
                    'global_scope' => ($relation->globalScope === 'from'),
                    'delete'   => $relation->delete,
                    'count'    => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions
                ), Framework::AND_FALSES);
            }
            foreach ($model->relationsXfromXSemi() as $name => &$relation) {
                // This is a link to the primary through field
                // For other through fields, the pivot model should be used, $hasMany[*_pivot], from above
                if (isset($relations[$name])) 
                    throw new Exception("Conflicting relations with [$name] on [$model->name]");
                $relations[$name] = $this->removeEmpty(array(
                    $relation->to,
                    'table'    => $relation->pivot->name,      // Semi-Pivot Model
                    'key'      => $relation->keyColumn->name,  // pivot.user_group_id
                    'otherKey' => $relation->column->name,     // pivot.user_id
                    'type'     => $relation->type(),
                    'global_scope' => ($relation->globalScope === 'from'),
                    'delete'   => $relation->delete,
                    'count'    => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions
                ), Framework::AND_FALSES);
            }
            $this->setPropertyInClassFile($modelFilePath, 'belongsToMany', $relations);

            // -------- hasOne
            $relations = array();
            foreach ($model->relations1from1() as $name => &$relation) {
                if (isset($relations[$name])) throw new Exception("Conflicting relations with [$name] on [$model->name]");
                $isLeaf = $relation->isFromLeaf();
                $relations[$name] = $this->removeEmpty(array($relation->to,
                    'key'    => $relation->column->name,
                    'type'   => $relation->type(),
                    'global_scope' => ($relation->globalScope === 'from'),
                    'delete' => $relation->delete, // This can be done by a DELETE CASCADE FK
                    'count'  => $relation->isCount,
                    'flags'  => $relation->flags,
                    'conditions' => $relation->conditions,
                    // 'leaf'   => $isLeaf,
                ), Framework::AND_FALSES);
            }
            $this->setPropertyInClassFile($modelFilePath, 'hasOne', $relations);

            // ----------------------------------------------------------------- File Uploads $attachOne
            // Model needs to state them in public $attachOne
            $attachments = array();
            foreach ($model->fields() as $name => &$field) {
                if ($field->fieldType == 'fileupload') {
                    if (isset($attachments[$name])) {
                        $attachments_name = $attachments[$name];
                        throw new Exception("Field [$name] fileupload already has an attachement class [$attachments_name]");
                    }
                    $attachments[$name] = 'System\Models\File';
                }
            }
            $this->setPropertyInClassFile($modelFilePath, 'attachOne', $attachments);

            // ----------------------------------------------------------------- List Editable
            $listEditable = array();
            foreach ($model->fields() as $name => &$field) {
                // listEditable can be a string or a boolean
                // so we cannot use a switch
                // TODO: Change listEditable settings to all strings to avoid errors
                if      ($field->listEditable === 'delete-on-null') $listEditable[$name] = 2;
                else if ($field->listEditable === 'false-on-null')  $listEditable[$name] = 3;
                else if ($field->listEditable === 'validate')       $listEditable[$name] = TRUE;
                else if ($field->listEditable === TRUE)             $listEditable[$name] = TRUE;
                else if ($field->listEditable)                      $listEditable[$name] = $field->listEditable;
            }
            $this->setPropertyInClassFile($modelFilePath, 'listEditable', $listEditable, FALSE);

            // ----------------------------------------------------------------- JSONable
            $jsonable = array();
            foreach ($model->fields() as $name => &$field) {
                if ($field->jsonable)
                    array_push($jsonable, $name);
            }
            $this->setPropertyInClassFile($modelFilePath, 'jsonable', $jsonable, TRUE, 'protected');

            // ----------------------------------------------------------------- Translatable
            $translatable = array();
            foreach ($model->fields() as $name => &$field) {
                if ($field->canDisplayAsField() && $field->translatable) {
                    array_push($translatable, $name);
                }
            }
            $this->setPropertyInClassFile($modelFilePath, 'translatable', $translatable, FALSE);

            // ----------------------------------------------------------------- Advanced
            $advanced = array();
            foreach ($model->fields() as $name => &$field) {
                if ($field->advanced)
                    array_push($advanced, $name);
            }
            $this->setPropertyInClassFile($modelFilePath, 'advanced', $advanced, Framework::NEW_PROPERTY);

            foreach ($model->fields() as $name => &$field) {
                if ($field->qrcodeObject) {
                    $this->setPropertyInClassFile($modelFilePath, 'qrCodeObject', $name, Framework::NEW_PROPERTY);
                    break;
                }
            }

            // ----------------------------------------------------------------- Methods
            // menuitemCount() for plugins.yaml
            // TODO: menuitemCount() adversely affects performance. Can it be cached?
            // Note that MATERIALIZED VIEWs can throw errors if not populated
            // so we try{}, otherwise we will take down the whole interface
            print("  Adding menuitemCount()\n");
            $this->addStaticMethod($modelFilePath, 'menuitemCount', 'return Model::menuitemCountFor(self::class);');

            // findByCode() static
            if ($model->hasField('code')) {
                print("  Adding findByCode()\n");
                $this->addStaticMethod($modelFilePath, 'findByCode(string|int $code)', 'return self::where("code", "=", $code)->first();');
            }

            // current scope
            if ($model->hasField('current')) {
                // Enable $query->current() calls like $user->languages->current()->first()
                $this->addMethod($modelFilePath, 'scopeCurrent($query)', 'return $query->where(\'current\', true);');
                $this->addMethod($modelFilePath, 'scopePrimary($query)', 'return $query->where(\'current\', true);');
                $this->addStaticMethod($modelFilePath, 'getCurrent()', 'return self::current()->first();');
                $this->addStaticMethod($modelFilePath, 'getPrimary()', 'return self::getCurrent();');
            }

            // get<Something>Attribute()s
            foreach ($model->attributeFunctions() as $funcName => &$body) {
                $funcNamePascal = Str::studly($funcName);
                $type           = ($funcNamePascal == 'name' ? 'string' : 'mixed');
                $signature      = "get{$funcNamePascal}Attribute()";
                print("  Injecting public {$YELLOW}$signature{$NC}() into [$model->name]\n");
                $this->addMethod($modelFilePath, $signature, $body, $type);
            }
            // methods()
            foreach ($model->methods as $funcName => &$body) {
                $type = ($funcName == 'name' ? 'string' : 'mixed');
                print("  Injecting public function {$YELLOW}$funcName(): $type{$NC} into [$model->name]\n");
                $this->addMethod($modelFilePath, $funcName, $body, $type);
            }
            // static methods()
            foreach ($model->staticMethods as $funcName => &$body) {
                print("  Injecting public function {$YELLOW}$funcName{$NC}() into [$model->name]\n");
                $this->addStaticMethod($modelFilePath, $funcName, $body);
            }
            if ($model->printable) {
                $this->setPropertyInClassFile($modelFilePath, 'printable', $model->printable, Framework::NEW_PROPERTY);
            }

            // ----------------------------------------------------------------- Columns commenting in header
            $indent         = str_repeat(' ', 1*4);
            $commentHeader  = "$indent/* Generated Fields:\n";
            foreach ($model->getTable()->columns as $name => &$column) {
                $flags = array();
                if ($column->isSingularUnique()) array_push($flags, 'singular-unique');
                $flagsString = implode(', ', $flags);
                $commentHeader   .= "$indent *   $column $flagsString\n";
            }
            $commentHeader .= "\n";
            $commentHeader .= "$indent * Settings:\n";
            $commentHeader .= "$indent *   noRelationManagerDefault: " . var_export($model->noRelationManagerDefault, TRUE) . "\n";
            $commentHeader .= "$indent */\n";
            $this->replaceInFile($modelFilePath, '/^{$/m', "{\n$commentHeader");
        } // Model exists
    }

    protected function seedingToSQLs(array $seeding, string $type = ''): array
    {
        global $GREEN, $RED, $YELLOW, $NC;

        $sqls       = array();
        $typeString = ($type ? "($type)" : '');

        foreach ($seeding as $table => $rows) {
            $tableParts = explode('.', $table);
            $isFQN      = (count($tableParts) > 1);
            $schema     = ($isFQN ? $tableParts[0] : 'public');
            $table      = ($isFQN ? $tableParts[1] : $tableParts[0]);

            print("  {$GREEN}SEEDING $typeString{$NC} for [$schema.$table]\n");
            foreach ($rows as $row) {
                // $table is a string so we will get raw PDO::FETCH_ASSOC results
                // with ->column_name properties
                $columns = $this->db->tableColumns($table);
                $names   = array();
                $values  = array();
                foreach ($columns as $column) {
                    if (!in_array($column->column_name, Column::SEED_IGNORE_COLUMNS)) {
                        if (!count($row)) break;
                        $value = array_shift($row);

                        if      ($value === 'DEFAULT')   $valueSQL = 'DEFAULT';
                        else if ($value === 'NULL')      $valueSQL = 'NULL';
                        else if (substr($value, 0, 5) === 'EVENT') {
                            // Creation of NOT NULL associated calendar events: 
                            // EVENT(<params>) => $this->db->createCalendarEvent(<params>)
                            $params       = explode(';', trim(substr($value, 6), ')'));
                            $calendarName = addslashes($params[0]);
                            $eventName    = addslashes($params[1]);
                            $typeName     = addslashes(isset($params[2]) ? $params[2] : 'Normal');
                            $statusName   = addslashes(isset($params[3]) ? $params[3] : 'Normal');
                            // TODO: from/to
                            $from         = addslashes(isset($params[4]) ? $params[4] : 'now()');
                            $to           = addslashes(isset($params[5]) ? $params[5] : 'now()');
                            $fn           = 'fn_acorn_calendar_lazy_create_event';
                            $valueSQL     = "$fn('$calendarName', fn_acorn_user_get_seed_user(),'$typeName', '$statusName', '$eventName')";
                        }
                        else if (substr($value, 0, 19) === 'fn_acorn_' && substr($value, -1) == ')') $valueSQL = $value;
                        else $valueSQL = var_export($value, TRUE);

                        array_push($names, $column->column_name);
                        array_push($values, $valueSQL);
                    }
                }

                // created_by_user_id must be sent by the external layer
                if (   isset($columns['created_by_user_id'])
                    && !in_array('created_by_user_id', $names)
                ) {
                    array_push($names, 'created_by_user_id');
                    array_push($values, 'fn_acorn_user_get_seed_user()');
                }
            
                $namesString = implode('","', $names);
                $namesSQL    = "\"$namesString\"";
                $valuesSQL   = implode(',', $values);
                $insertSQL   = "insert into $schema.$table($namesSQL) values($valuesSQL)";
                if ($names[0] == 'id' && $values[0] != 'DEFAULT') $insertSQL .= ' ON CONFLICT(id) DO NOTHING';
                
                $insertSQL .= ';';
                array_push($sqls, $insertSQL);
            }
        }

        return $sqls;
    }

    public function processStageFunctionLang(Model $model, array &$stageFunctions, string $langDirPath) {
        foreach ($stageFunctions as $name => &$defintion) {
            $stage            = (isset($defintion['stage']) ? $defintion['stage'] : 'function');
            $fnTranslationKey = $model->functionsTranslationKey($stage, $name);

            if (isset($defintion['labels'])) {
                $this->writeLangValues($langDirPath, "$fnTranslationKey.label", $defintion['labels']);
                unset($defintion['labels']);
                $defintion['label'] = "$fnTranslationKey.label";
            }
            if (isset($defintion['comment'])) {
                $this->writeLangValues($langDirPath, "$fnTranslationKey.comment", $defintion['comment']);
                $defintion['comment'] = "$fnTranslationKey.comment";
            }

            // Fields
            if (isset($defintion['fields'])) {
                foreach ($defintion['fields'] as $fieldName => &$fieldDefinition) {
                    $prTranslationKey = "$fnTranslationKey.fields.$fieldName";
                    if (isset($fieldDefinition['labels'])) {
                        $this->writeLangValues($langDirPath, "$prTranslationKey.label", $fieldDefinition['labels']);
                        unset($fieldDefinition['labels']);
                        $fieldDefinition['label'] = "$prTranslationKey.label";
                    }

                    if (isset($fieldDefinition['comment'])) {
                        $this->writeLangValues($langDirPath, "$prTranslationKey.comment", $fieldDefinition['comment']);
                        $fieldDefinition['comment'] = "$prTranslationKey.comment";
                    }
                }
            }

            // Parameters
            if (isset($defintion['parameters'])) {
                foreach ($defintion['parameters'] as $paramName => $paramDefinition) {
                    $prTranslationKey = "$fnTranslationKey.parameters.$paramName";
                    if (isset($paramDefinition['labels'])) {
                        $this->writeLangValues($langDirPath, "$prTranslationKey.label", $paramDefinition['labels']);
                        unset($paramDefinition['labels']);
                        $paramDefinition['label'] = "$prTranslationKey.label";
                    }

                    if (isset($paramDefinition['comment'])) {
                        $this->writeLangValues($langDirPath, "$prTranslationKey.comment", $paramDefinition['comment']);
                        $paramDefinition['comment'] = "$prTranslationKey.comment";
                    }
                }
            }
        }
    }

    public function writeLangValues(string $langDirPath, string $translationKey, array|string $texts, object|NULL $dbObject = NULL, bool $throughIfAlreadySet = FALSE, string|NULL $comment = NULL) {
        // $localTranslationKey = 'befores.my_func' but absolute key also accepted
        // $texts = array(
        //   'en' => '...',
        //   'ku' => '...',
        //   'ar' => '...',
        // )
        $localTranslationKey = $translationKey;
        if (strstr($translationKey, '::lang.') !== FALSE) {
            // We have an absolute key like acorn.plugin::lang.models...
            $translationKeyParts = explode('::lang.', $translationKey);
            $localTranslationKey = $translationKeyParts[1];
        }

        foreach (scandir($langDirPath) as $langName) {
            $langFilePath = "$langDirPath/$langName/lang.php";
            if (!in_array($langName, array('.','..')) && file_exists($langFilePath)) {
                $text = NULL; 
                if (is_array($texts) && isset($texts[$langName])) $text = $texts[$langName];
                else if (is_string($texts)) $text = $texts;

                if ($text) {
                    $this->langFileSet(
                        $langFilePath, 
                        $localTranslationKey, 
                        $text, 
                        $langName,
                        $dbObject,
                        $throughIfAlreadySet,
                        $comment
                    );
                } else {
                    // throw new Exception("No [$langName] lang key for [$translationKey]");
                }
            }
        }
    }

    protected function createFormInterface(Model &$model, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($model->plugin);
        $modelDirName        = $model->dirName();
        $modelFilePath       = "$pluginDirectoryPath/models/$model->name.php";
        $modelDirPath        = "$pluginDirectoryPath/models/$modelDirName";
        $fieldsPath          = "$modelDirPath/fields.yaml";
        $createdBy           = $this->createdByString();
        $modelTranslationKey = $model->translationDomain();
        $extraTranslations   = array();

        print("  Fields.yaml: Check/create [$fieldsPath]:\n");
        if (!is_dir($modelDirPath)) mkdir($modelDirPath, TRUE);
        $this->setFileContents($fieldsPath, "# $createdBy");

        // ---------------------------------------- Main fields.yaml
        // TODO: Push this field creation up in to the Model::fields()
        // fields(TRUE) call output
        $this->yamlFileUnSet($fieldsPath, 'fields.id');
        // Model level hints come first
        if ($model->hints) {
            foreach ($model->hints as $hintName => $hintConfig) {
                $this->yamlFileSet($fieldsPath, "fields._$hintName", 
                    $this->buildHint($model, $hintName, $hintConfig, $fieldsPath)
                );
            }
        }

        // Form level comments
        if ($model->formComment) {
            $contexts = $model->formCommentContexts;
            if (is_string($contexts)) $contexts = array($contexts);
            $this->yamlFileSet($fieldsPath, "fields._form_comment", $this->removeEmpty(array(
                'type'     => 'section',
                'span'     => 'full',
                'comment'  => $model->formComment,
                'commentHtml' => $model->commentHtml,
                'context'  => $contexts,
                'cssClass' => 'form-comment',
            )));
        }

        // Main fields
        $fields = $model->fields();
        foreach ($fields as $name => &$field) {
            $indentString = str_repeat(' ', ($field->nestLevel ?: 0) * 2);
            $fieldTypeV   = var_export($field->fieldType, TRUE);
            $columnTypeV  = var_export($field->columnType, TRUE);
            $typeString   = "$fieldTypeV / $columnTypeV";
            if ($field->canDisplayAsField()) { // fieldExclude
                print("    $indentString+{$YELLOW}$name{$NC}($typeString): to {$YELLOW}fields.yaml{$NC}\n");
                $dotPathStub = 'fields';
                if (!$field->include) {
                    if      ($field->tabLocation == 2)             $dotPathStub = "secondaryTabs.$dotPathStub";
                    else if ($field->tabLocation == 3)             $dotPathStub = "tertiaryTabs.$dotPathStub";
                    else if ($field->tab && $field->tab != 'none') $dotPathStub = "tabs.$dotPathStub";
                }
                $fieldKey = "$field->fieldKey$field->fieldKeyQualifier";
                $dotPath  = "$dotPathStub.$fieldKey";

                // -------------------- Explicit dropdown Options
                if (is_array($field->fieldOptions)) {
                    // options: can be in the format of translated codes:
                    // options:
                    //   G:
                    //     en: guilty
                    //     ku: suc
                    foreach ($field->fieldOptions as $code => $labels) {
                        if (!is_numeric($code) 
                            && is_array($labels)
                        ) {
                            // If we are using single letter codes, 
                            // then try to use the english label instead
                            // for the translation key: acorn.university::lang.models.that.options.guilty
                            $localTranslationKey = (strlen($code) == 1 && isset($labels['en']) ? strtolower($labels['en']) : $code);
                            // Add these codes to extraTranslations
                            $extraTranslations[$localTranslationKey] = $labels;
                            $field->fieldOptions[$code] = $field->translationKey($localTranslationKey);
                        }
                    }
                }

                // ---------------------- DependsOn
                // 4 formats are allowed:
                //   qrcode (single string)
                //   qrcode => TRUE|FALSE
                //   0 => qrcode
                //   qrcode => field settings array clause
                // where field settings array clause contains settings for the field
                // TODO: This dependsOn re-organisation should maybe be in Field.php
                $dependsOn         = NULL;
                $dependsOnSettings = NULL;
                if ($field->dependsOn) {
                    $dependsOn         = array();
                    $dependsOnSettings = array();

                    $dependsOnArray    = $field->dependsOn;
                    if (is_string($dependsOnArray)) $dependsOnArray = array($dependsOnArray);

                    // Transform items in to fieldName => clause
                    foreach ($dependsOnArray as $dependsOnKey => $dependsOnClause) {
                        if (is_numeric($dependsOnKey)) {
                            array_push($dependsOn, $dependsOnClause);
                        } else if ($dependsOnClause !== FALSE) {
                            array_push($dependsOn, $dependsOnKey);
                            if (!is_bool($dependsOnClause)) $dependsOnSettings[$dependsOnKey] = $dependsOnClause;
                        }
                    }
                }

                // Convert contexts to a numeric array
                $contexts = array();
                if (is_string($field->contexts)) $contexts = array($field->contexts);
                else if (is_array($field->contexts) && $field->contexts) {
                    if (is_numeric(array_keys($field->contexts)[0])) $contexts = $field->contexts;
                    else $contexts = array_keys($field->contexts);
                }

                // Dropdown defaults do not work
                // The JS will check the attributes and apply the default
                if ($field->fieldType == 'dropdown' && $field->default) {
                    $attributes = ($field->attributes ?: array());
                    $attributes['default'] = $field->default;
                    $field->attributes = $attributes;
                }

                $labelKey = (isset($field->explicitLabelKey) ? $field->explicitLabelKey : $field->translationKey());
                $fieldTab = $field->tab();

                // Lang.php additions also use is_array() & $field->translationKey('_comment')
                $commentKey = (is_array($field->fieldComment) 
                    ? $field->translationKey('_comment') 
                    : $field->fieldComment // Maybe a translation key, from Yaml fields
                );

                // Field hints come first
                if ($field->hints) {
                    foreach ($field->hints as $hintName => $hintConfig) {
                        // Adopt associated field settings
                        if (!isset($hintConfig['tab']) && $fieldTab) $hintConfig['tab'] = $fieldTab;
                        if (!isset($hintConfig['tabLocation']) && $field->tabLocation) $hintConfig['tabLocation'] = $field->tabLocation;
                        if (!isset($hintConfig['advanced']))    $hintConfig['advanced']    = $field->advanced;
                        if (!isset($hintConfig['permissions'])) $hintConfig['permissions'] = $field->permissions;
                        $this->yamlFileSet($fieldsPath, "$dotPathStub._{$fieldKey}_hint", 
                            $this->buildHint($model, $hintName, $hintConfig, $fieldsPath)
                        );
                    }
                }

                $fieldDefinition = array(
                    '#'         => $field->yamlComment,
                    'label'     => $labelKey,
                    'type'      => $field->fieldType,
                    'path'      => $field->partial,
                    'hidden'    => $field->hidden,
                    'required'  => $field->required,
                    'default'   => $field->default,
                    'disabled'  => $field->disabled,
                    'readOnly'  => $field->readOnly,
                    'span'      => $field->span,
                    'cssClass'  => $field->cssClass(),
                    'comment'      => $commentKey,
                    'commentHtml'  => ($field->commentHtml && $commentKey),
                    'context'      => $contexts,
                    'tab'          => $fieldTab,
                    'tabLocation'  => $field->tabLocation, // Pass through for below @context
                    'actions'   => $field->actions,

                    // Pass through
                    'mode'   => $field->mode,
                    'preset' => $field->preset,
                    'width'  => $field->width,
                    'height' => $field->height,
                    'size'   => $field->size,
                    'emptyOption' => $field->emptyOption,
                    // DataTable field type
                    'adding'    => $field->adding,
                    'searching' => $field->searching,
                    'deleting'  => $field->deleting,
                    'columns'   => $field->columns,
                    'keyFrom'   => $field->keyFrom,
                    'recordUrl' => $field->recordUrl,
                    'listEditable' => $field->listEditable,
                
                    'options'      => $field->fieldOptions,      // Function call
                    'optionsModel' => $field->fieldOptionsModel, // Model name
                    'optionsWhere' => $field->optionsWhere,
                    'placeholder'  => $field->placeholder,
                    'hierarchical' => $field->hierarchical,
                    'relatedModel' => $field->relatedModel,      // Model name
                    'nameFrom'     => $field->nameFrom,
                    'attributes'   => $field->attributes,
                    'dependsOn'    => $dependsOn,
                    'dependsOnSettings' => $dependsOnSettings,
                    'deferrable'   => $field->deferrable,
                    
                    // Extended info
                    'nested'       => ($field->nested    ?: NULL),
                    'nestLevel'    => ($field->nestLevel ?: NULL),
                    'advanced'     => $field->advanced,

                    // MorphConfig.php
                    // Complex permissions
                    'permissionSettings' => $field->permissionSettings,
                    'permissions'        => $field->permissions,
                    'setting'            => $field->setting,
                    'settingNot'         => $field->settingNot,
                    // Dynamic include
                    'include'      => $field->include,          // Only include: 1to1
                    'includeModel' => $field->includeModel,     // Required for include
                    'includePath'  => $field->includePath,      // Not used
                    'includeContext' => $field->includeContext, // = exclude for QRCode
                );
                if ($field->fieldConfig) $fieldDefinition = array_merge($fieldDefinition, $field->fieldConfig);
                $fieldDefinition = $this->removeEmpty(
                    $fieldDefinition, 
                    self::AND_FALSES, 
                    ['adding', 'searching', 'deleting', 'height']
                ); // Remove FALSE
                if ($field->goto) $fieldDefinition['containerAttributes'] = array('goto-form-group-selection' => $field->goto);

                // Normal field create
                $this->yamlFileSet($fieldsPath, $dotPath, $fieldDefinition);

                // Setting these contexts causes extra fields to be created
                // Main tabLocation passed through above
                if ($field->contextUpdate) {
                    $fieldContext = array_merge($fieldDefinition, self::camelKeys($field->contextUpdate));
                    if      ($fieldContext['tabLocation'] == 1) $dotPath = "tabs.fields.$fieldKey";
                    else if ($fieldContext['tabLocation'] == 2) $dotPath = "secondaryTabs.fields.$fieldKey";
                    else if ($fieldContext['tabLocation'] == 3) $dotPath = "tertiaryTabs.fields.$fieldKey";
                    $this->yamlFileSet($fieldsPath, "$dotPath@update", $fieldContext);
                }
                if ($field->contextCreate) {
                    $fieldContext = array_merge($fieldDefinition, self::camelKeys($field->contextCreate));
                    if      ($fieldContext['tabLocation'] == 1) $dotPath = "tabs.fields.$fieldKey";
                    else if ($fieldContext['tabLocation'] == 2) $dotPath = "secondaryTabs.fields.$fieldKey";
                    else if ($fieldContext['tabLocation'] == 3) $dotPath = "tertiaryTabs.fields.$fieldKey";
                    $this->yamlFileSet($fieldsPath, "$dotPath@create", $fieldContext);
                }
                if ($field->contextPreview) {
                    $fieldContext = array_merge($fieldDefinition, self::camelKeys($field->contextPreview));
                    if      ($fieldContext['tabLocation'] == 1) $dotPath = "tabs.fields.$fieldKey";
                    else if ($fieldContext['tabLocation'] == 2) $dotPath = "secondaryTabs.fields.$fieldKey";
                    else if ($fieldContext['tabLocation'] == 3) $dotPath = "tertiaryTabs.fields.$fieldKey";
                    $this->yamlFileSet($fieldsPath, "$dotPath@preview", $fieldContext);
                }

                // Tabs and icons
                if ($field->tabLocation == 2) $this->yamlFileSet($fieldsPath, 'secondaryTabs.cssClass', 'primary-tabs', FALSE);
                // TODO: Make tab icon configuarble
                if ($icon = $field->icon) {
                    if (substr($icon, 0, 5) != 'icon-') $icon = "icon-$icon";
                    if      ($field->tabLocation == 2) $this->yamlFileSet($fieldsPath, 'secondaryTabs.icons', $icon, TRUE,  $labelKey);
                    else if ($field->tabLocation == 3) $this->yamlFileSet($fieldsPath, 'tertiaryTabs.icons',  $icon, TRUE,  $labelKey);
                    else if ($field->tab)              $this->yamlFileSet($fieldsPath, 'tabs.icons',          $icon, FALSE, $labelKey);
                }
            } else {
                print("    $indentString{$YELLOW}WARNING{$NC}: Field [$name]($typeString) !canDisplayAs{$YELLOW}Field{$NC}() because fieldType($field->fieldType) is blank or fieldExclude($field->fieldExclude)\n");
            }
        }

        // ---------------------------------------- Fields for afters|befores functions
        // TODO: Push this field creation up in to the Model::fields()
        $stageFunctions = array_merge(
            $model->beforeFunctions ?: array(), 
            $model->afterFunctions ?: array()
        );
        foreach ($stageFunctions as $name => &$functionSpec) {
            // A field for each additional parameter required
            // .parameters.<pr-name>.fields.*
            // Fields can _additionally_ be specified in the fields: array
            // with the same name as the parameter
            // but appear in the main form, not in a action form popup like action functions
            $stage = (isset($functionSpec['stage']) ? $functionSpec['stage'] : 'function');
            if (isset($functionSpec['parameters'])) {
                foreach ($functionSpec['parameters'] as $paramName => $paramSpec) {
                    switch ($paramName) {
                        case 'model_id':
                        case 'p_model_id':
                        case 'user_id':
                        case 'p_user_id':
                            break;
                        default:
                            // Some parameters can come from the new, as yet not created, model
                            $fieldName = preg_replace('/^p_/', '', $paramName);
                            if ($model->hasAttribute($fieldName)) {
                                print("    {$GREEN}INFO{$NC}: Parameter [$paramName] will come from the model $model->name\n");
                            } else {
                                // Add pseudo field, with optional fields settings override in fields.<param-name>
                                $fieldDefinition = array();
                                if (isset($functionSpec['fields'][$paramName])) {
                                    $fieldDefinition = $functionSpec['fields'][$paramName];
                                }

                                // Inherit the label from the function level
                                if (!isset($fieldDefinition['label']) && isset($functionSpec['label'])) {
                                    $fieldDefinition['label'] = $functionSpec['label'];
                                }
                                
                                // Inherit the comment from the function level
                                if (!isset($fieldDefinition['comment']) && isset($functionSpec['comment'])) {
                                    $fieldDefinition['comment'] = $functionSpec['comment'];
                                }

                                // Field key and location
                                $fieldKey = "_{$name}_{$paramName}";
                                $dotPath  = "fields.$fieldKey";
                                if      (isset($fieldDefinition['tabLocation']) && $fieldDefinition['tabLocation'] == 2) $dotPath = "secondaryTabs.fields.$fieldKey";
                                else if (isset($fieldDefinition['tabLocation']) && $fieldDefinition['tabLocation'] == 3) $dotPath = "tertiaryTabs.fields.$fieldKey";
                                else if (isset($fieldDefinition['tab'])) $dotPath = "tabs.fields.$fieldKey";

                                // Condition(s)
                                $condition = 
                                    (isset($fieldDefinition['condition'])  ? $fieldDefinition['condition']  :
                                    (isset($fieldDefinition['conditions']) ? $fieldDefinition['conditions'] :
                                    (isset($functionSpec['condition'])     ? $functionSpec['condition']     :
                                    (isset($functionSpec['conditions'])    ? $functionSpec['conditions']    :
                                    ''
                                ))));

                                // Permissions
                                $permissions = array(
                                    $model->permissionFQN("use_function_{$name}")
                                );
                                
                                // Contexts
                                $contexts = (isset($fieldDefinition['contexts']) 
                                    ? $fieldDefinition['contexts']
                                    : (isset($functionSpec['contexts']) ? $functionSpec['contexts'] : '')
                                );
                                if (isset($fieldDefinition['contexts'])) unset($fieldDefinition['contexts']);

                                print("    {$GREEN}INFO{$NC}: Adding pseudo-field Parameter [$paramName] to the fields.yaml for $model->name\n");
                                $this->yamlFileSet($fieldsPath, $dotPath, 
                                    $this->removeEmpty(array_merge(array(
                                        'type'      => 'switch',
                                        'condition' => $condition,
                                        'context'   => $contexts,
                                        'span'      => 'storm',
                                        'cssClass'  => 'col-xs-12 col-md-6',
                                        'permissions' => $permissions,
                                        'stage'     => $stage,
                                    ), $fieldDefinition))
                                );
                            }
                    }
                }
            }
        }

        // ---------------------------------------- Rules
        // https://wintercms.com/docs/v1.2/docs/services/validation
        $allRules = array();
        foreach ($model->fields() as $name => &$field) {
            $fieldRules = $field->rules;
            if (!$field->isStandard()) {
                if (   $field->required 
                    && !$field->nested 
                    && $field->canDisplayAsField() 
                    && !$field->hidden
                    && !$field->fieldExclude
                ) 
                    array_push($fieldRules, 'required');
                // TODO: max length (Currency needs this)
                if ($field->length) array_push($fieldRules, "max:$field->length");
            }
            if ($fieldRules) $allRules[$name] = implode('|', $fieldRules);
        }
        if ($allRules) {
            print("  Rules:\n");
            foreach ($allRules as $name => $rule) print("    $name => $rule\n");
            $this->setPropertyInClassFile($modelFilePath, 'rules', $allRules);
        }

        // ---------------------------------------- Fields: labels, comments, hints & extraTranslations lang.php
        print("  LANG:\n");
        $langDirPath   = "$pluginDirectoryPath/lang";
        $langEnPath    = "$pluginDirectoryPath/lang/en/lang.php";
        $modelKey      = $model->localTranslationKey();

        if ($model->hints) {
            foreach ($model->hints as $hintName => $hintConfig) {
                // Get the translation keys
                $hintFieldConfig = $this->buildHint($model, $hintName, $hintConfig);
                
                if (isset($hintConfig['labels']) && is_array($hintConfig['labels'])) {
                    $absoluteDomainKey   = $hintFieldConfig['label'];
                    $localTranslationKey = preg_replace('/^.*::lang./', '', $absoluteDomainKey);
                    foreach ($hintConfig['labels'] as $langName => &$translation) {
                        $langFilePath = "$langDirPath/$langName/lang.php";
                        if (!file_exists($langFilePath)) 
                            throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                        $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                    }
                }
                
                if (isset($hintConfig['content']) && is_array($hintConfig['content'])) {
                    $absoluteDomainKey   = $hintFieldConfig['content'];
                    $localTranslationKey = preg_replace('/^.*::lang./', '', $absoluteDomainKey);
                    foreach ($hintConfig['content'] as $langName => &$translation) {
                        $langFilePath = "$langDirPath/$langName/lang.php";
                        if (!file_exists($langFilePath)) 
                            throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                        $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                    }
                }
            }
        }

        foreach ($model->fields() as $name => &$field) {
            $localTranslationKey = $field->localTranslationKey();
            if ($field->isLocalTranslationKey() && !$field->isStandard() && !$this->arrayFileValueExists($langEnPath, $localTranslationKey)) {
                print("    Add {$YELLOW}$localTranslationKey{$NC} to {$YELLOW}lang/*{$NC} for {$YELLOW}$name{$NC}\n");
                // Field label
                // At least set the english label programmatically
                // during development, and translation file generation
                if (!$field->labels || !isset($field->labels['en']))
                    $this->langFileSet($langEnPath, $localTranslationKey, $field->devEnTitle(), 'en', $field->dbObject(), TRUE, $field->yamlComment);
                // Then others, if we have them
                // Leave the interface to show the keys, if the translation has not been added
                if ($field->labels) {
                    foreach ($field->labels as $langName => &$translation) {
                        $langFilePath = "$langDirPath/$langName/lang.php";
                        if (!file_exists($langFilePath)) 
                            throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                        $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                    }
                }
            }

            // Field comments
            if (is_array($field->fieldComment)) {
                $commentTranslationKey = $field->localTranslationKey('_comment'); // As above
                foreach ($field->fieldComment as $langName => &$translation) {
                    $langFilePath = "$langDirPath/$langName/lang.php";
                    if (!file_exists($langFilePath)) 
                        throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                    $this->langFileSet($langFilePath, $commentTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                }
            }

            if ($field->hints) {
                foreach ($field->hints as $hintName => $hintConfig) {
                    // Get the translation keys
                    $hintFieldConfig = $this->buildHint($model, $hintName, $hintConfig);
                    
                    if (isset($hintConfig['labels']) && is_array($hintConfig['labels'])) {
                        $absoluteDomainKey   = $hintFieldConfig['label'];
                        $localTranslationKey = preg_replace('/^.*::lang./', '', $absoluteDomainKey);
                        foreach ($hintConfig['labels'] as $langName => &$translation) {
                            $langFilePath = "$langDirPath/$langName/lang.php";
                            if (!file_exists($langFilePath)) 
                                throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                            $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                        }
                    }
                    
                    if (isset($hintConfig['content']) && is_array($hintConfig['content'])) {
                        $absoluteDomainKey   = $hintFieldConfig['content'];
                        $localTranslationKey = preg_replace('/^.*::lang./', '', $absoluteDomainKey);
                        foreach ($hintConfig['content'] as $langName => &$translation) {
                            $langFilePath = "$langDirPath/$langName/lang.php";
                            if (!file_exists($langFilePath)) 
                                throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                            $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                        }
                    }
                }
            }

            if ($field->extraTranslations) {
                foreach ($field->extraTranslations as $code => $labels) {
                    print("    Add {$YELLOW}$code{$NC} to {$YELLOW}lang/*{$NC} for {$YELLOW}$name{$NC}\n");
                    $localTranslationKey = "$modelKey.$code";
                    if (!is_array($labels)) 
                        throw new Exception("Field $field->fieldKey on $model->name has non-array labels");
                    foreach ($labels as $langName => &$translation) {
                        $langFilePath = "$langDirPath/$langName/lang.php";
                        if (!file_exists($langFilePath)) 
                            throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                        $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
                    }
                }
            }
        }
        foreach ($extraTranslations as $code => $labels) {
            print("    Add {$YELLOW}$code{$NC} to {$YELLOW}lang/*{$NC}\n");
            $localTranslationKey = "$modelKey.$code";
            foreach ($labels as $langName => &$translation) {
                $langFilePath = "$langDirPath/$langName/lang.php";
                if (!file_exists($langFilePath)) 
                    throw new Exception("No translation file found for label.[$langName] in field [$name] on [$model->name]");
                $this->langFileSet($langFilePath, $localTranslationKey, $translation, $langName, $field->dbObject(), TRUE, $field->yamlComment);
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
        $configListPath      = "$controllerDirPath/config_list.yaml";
        $configFilterPath    = "$controllerDirPath/config_filter.yaml";
        $configReorderPath   = "$controllerDirPath/config_reorder.yaml";
        $configReorderView   = "$controllerDirPath/reorder.php";
        $configFormPath      = "$controllerDirPath/config_form.yaml";
        $configRelationPath  = "$controllerDirPath/config_relation.yaml";
        $configImExportPath  = "$controllerDirPath/config_import_export.yaml";

        if (file_exists($controllerFilePath) && $overwrite) unlink($controllerFilePath);
        if (file_exists($controllerFilePath)) {
            print("  {$RED}WARNING{$NC}: Controller file [$controllerFilePath] already exists. Leaving.\n");
        } else {
            print("Controller: $controller->name\n");
            $this->runWinterCommand('create:controller', 2, $controller->model->plugin->dotClassName(), $controller->name);

            // Inheritance
            $author = $controller->author();
            print("  Inheriting {$YELLOW}$controller->name{$NC} from $author\n");
            $this->replaceInFile($controllerFilePath, '/^use Backend\\\\Classes\\\\Controller;$/m', "use $author\\\\Controller;");

            // Implements
            $implements = array(
                "\\\\$author\\\\Behaviors\\\\FormController",
                "\\\\$author\\\\Behaviors\\\\ListController",
                "Backend\\\\Behaviors\\\\RelationController", // Only here to prevent RelationController requirement error
                "\\\\Acorn\\\\Behaviors\\\\RelationController",
            );
            if ($controller->model->export || $controller->model->import)
                array_push($implements, "\Acorn\Behaviors\ImportExportController");
            if ($controller->model->batchPrint) 
                array_push($implements, "\Acorn\Behaviors\BatchPrintController");
            if ($controller->model->hasField('sort_order'))
                array_push($implements, "\Backend\Behaviors\ReorderController");
            $this->setPropertyInClassFile($controllerFilePath, 'implement', $implements, Framework::OVERWRITE_EXISTING);

            // Explicit plural name injection
            // Otherwise PathsHelper will get confused when making URLs and things
            $plural = $controller->model->getTable()->plural;
            if ($plural) $this->setPropertyInClassFile($controllerFilePath, 'namePlural', $plural, Framework::NEW_PROPERTY);

            if ($controller->model->hasSelfReferencingRelations()) 
                $this->yamlFileSet($configListPath, 'showTree', true);
            if ($controller->model->readOnly) {
                $this->yamlFileSet($configListPath, 'showCheckboxes', false, Framework::NO_THROW);
                $this->yamlFileUnSet($configListPath, 'recordUrl');
            }
            if ($controller->model->listRecordUrl) {
                $this->yamlFileSet($configListPath, 'recordUrl', $controller->model->listRecordUrl);
            }
            if ($controller->model->defaultSort) {
                $this->yamlFileSet($configListPath, 'defaultSort', $controller->model->defaultSort);
            }
            if (isset($controller->model->showSorting)) {
                $this->yamlFileSet($configListPath, 'showSorting', $controller->model->showSorting, Framework::NO_THROW);
            }

            // -------------------------------- Import / Export
            $modelsName    = Str::plural($controller->model->name);
            $pluginDirName = $controller->model->plugin->dirName();
            $modelDirName  = $controller->model->dirName();
            $modelDirPath  = "/$pluginDirName/models/$modelDirName";
            if ($controller->model->import) {
                $this->yamlFileSet($configImExportPath, 'import', array(
                    'title'      => "Import $modelsName",
                    'modelClass' => "Acorn\\Models\\Import",
                    'list'       => "\$$modelDirPath/columns.yaml",
                ));
            }
            if ($controller->model->export) {
                $this->yamlFileSet($configImExportPath, 'export', array(
                    'title'      => "Export $modelsName",
                    'modelClass' => "Acorn\\Models\\Export",
                    'list'       => "\$$modelDirPath/columns.yaml",
                    'dataModel'  => $controller->model->fullyQualifiedName(),
                ));
            } else if ($controller->model->batchPrint) {
                $this->yamlFileSet($configImExportPath, 'export', array(
                    'title'      => "Batch print $modelsName",
                    'modelClass' => "Acorn\\Models\\BatchPrint",
                    'list'       => "\$$modelDirPath/columns.yaml",
                    'dataModel'  => $controller->model->fullyQualifiedName(),
                    'useListQuery' => true, // Custom
                    'redirect'   => $controller->relativeUrl(),
                    'form'       => '$/../modules/acorn/behaviors/batchprintcontroller/partials/fields_export.yaml',
                    'fileName'   => 'print.zip',
                ));
                $defaultExtensions = ['avi','bmp','css','doc','docx','eot','flv','gif','ico','ics','jpeg','jpg','js','less','map','mkv','mov','mp3','mp4','mpeg','ods','odt','ogg','pdf','png','ppt','pptx','rar','scss','svg','swf','ttf','txt','wav','webm','webp','wmv','woff','woff2','xls','xlsx','zip'];
                print("  Adding {$YELLOW}Flat XML ODT libre office{$NC} for batch print runs to [{$YELLOW}config/cms.php{$NC}]\n");
                array_push($defaultExtensions, 'fodt');
                // TODO: This is a bit dodgy cause we loose the comments
                // $this->arrayFileSet('config/cms.php', 'fileDefinitions.defaultExtensions', $defaultExtensions, Framework::NEW_PROPERTY);            
            }            

            // -------------------------------- Filters
            $indent = 0;
            print("  Inserting {$YELLOW}config_filter{$NC} to the list [{$YELLOW}$controllerDirPath/config_list.yaml{$NC}]\n");
            $this->yamlFileSet("$controllerDirPath/config_list.yaml", 'filter', 'config_filter.yaml', Framework::NEW_PROPERTY);
            $this->appendToFile($configFilterPath, "# $createdBy");
            foreach ($controller->model->fields() as $fieldName => &$field) {
                $filterDefinition = NULL;

                if ($field->canDisplayAsFilter()) {
                    // Usually PseudoField ?from? relation filters
                    // The IdField also has all these relations on it, but is usually marked as !canFilter
                    // Time fields also have relations
                    $nameFromEmbedded = (strstr($field->nameFrom, '[') !== FALSE);
                    $labelKey         = (isset($field->explicitLabelKey) 
                        ? $field->explicitLabelKey 
                        : $field->translationKey()
                    );
                    $filterDefinition = array(
                        '#'          => $fieldName,
                        'label'      => $labelKey,
                        'type'       => $field->filterType,
                        'conditions' => $field->filterConditions,
                        'nameFrom'   => ($nameFromEmbedded ? FALSE : $field->nameFrom), 
                        'noRelationManager' => $field->noRelationManager,
                        'searchNameSelect'  => $field->filterSearchNameSelect,
                    );

                    if (count($field->relations)) {
                        foreach ($field->relations as $relationName => &$relation) {
                            // RelationXfromX
                            // RelationXfrom1 does not
                            // Date based fields should have a datarange type filter
                            // Event fields should have a datarange type filter
                            $otherModel       = &$relation->to;
                            $otherModelFQN    = $otherModel->fullyQualifiedName();
                            if (!isset($filterDefinition['modelClass'])) $filterDefinition['modelClass'] = $otherModelFQN;

                            if ($relation->canDisplayAsFilter()) {
                                $filterDefinition['# Relation'] = (string) $relation;
                                if ($relation instanceof RelationXfromX || $relation instanceof RelationXfromXSemi) {
                                    // SQL
                                    $pivotTable       = &$relation->pivot;
                                    $keyColumn        = &$relation->keyColumn;
                                    $otherColumn      = &$relation->column;
                                    $pivotTableName   = $pivotTable->name;

                                    // Custom relation scopes based on relations, not SQL
                                    // relationCondition => <the name of the relevant relation>, e.g. belongsTo['language']
                                    // Filters the listed models based on a filtered: of selected related models
                                    // Probably because it is nested
                                    // TODO: This is actually the _un-nested_ relation
                                    // TODO: Write these in to the Model Relations, not here
                                    if ($field->useRelationCondition) {
                                        if (!$field->fieldKey) 
                                            throw new Exception("Field [$fieldName] has no fieldKey for relationCondition");
                                        $filterDefinition['relationCondition'] = $field->fieldKey;
                                    } else {
                                        if (!isset($filterDefinition['conditions']) || is_null($filterDefinition['conditions']))
                                            $filterDefinition['conditions'] = "id in(select $pivotTableName.$keyColumn->name from $pivotTableName where $pivotTableName.$otherColumn->name in(:filtered))";
                                    }
                                } else if ($relation instanceof RelationXto1) {
                                    // Event and User canFilter foreign key fields come here
                                    // conditions already defined
                                }

                                print("    +{$YELLOW}$fieldName{$NC} filter\n");
                                $filterDefinition = $this->removeEmpty($filterDefinition, TRUE);
                                $this->yamlFileSet($configFilterPath, "scopes.$fieldName", $filterDefinition);
                            } else {
                                // Relation !canDisplayAsFilter()
                                $relationClass = preg_replace('/.*\\\\/', '', get_class($relation));
                                $fieldClass    = preg_replace('/.*\\\\/', '', get_class($field));
                                $this->yamlFileSet($configFilterPath, "# $fieldClass($fieldName)::$relationClass($relationName)", 'relation !canDisplayAsFilter()');
                            }
                        }
                    } else {
                        // !relations
                        // Non-relation fields, like dates
                        // Nothing comes here at the moment
                        // because everything is a foreign key: dates, users, etc.
                        // throw new Exception("Un-considered filter [$fieldClass($fieldName)]");
                        $this->yamlFileSet($configFilterPath, "scopes.$fieldName", $filterDefinition);
                    }
                } else { 
                    // !canDisplayAsFilter()
                    $fieldClass = preg_replace('/.*\\\\/', '', get_class($field));
                    $this->yamlFileSet($configFilterPath, "# $fieldClass($fieldName)", 'field !canDisplayAsFilter()');
                }

                // ---------------------------- Custom field filters
                // On the column comment:
                // filters:
                //     expression_type:
                //         label: acorn.exam::lang.models.result.expression_type
                //         conditions: expression_type in(:filtered)
                //         options:
                //           data: Data
                //           expression: Expression
                //           formulae: Formulae
                if ($field->filters) {
                    foreach ($field->filters as $name => $filter) {
                        $comment  = (isset($filter['#']) ? $filter['#'] : '');
                        $comment .= "Custom filter on $field->name field.";
                        $filter['#'] = $comment;
                        $this->yamlFileSet($configFilterPath, "scopes.$name", $filter, Framework::NO_THROW);
                    }
                }                
            }

            if ($controller->model->hasField('sort_order')) {
                // config_reorder.yaml
                $this->yamlFileSet($configReorderPath, '', array(
                    'title'      => 'Reorder',
                    'nameFrom'   => 'name',
                    'modelClass' => $controller->model->fullyQualifiedName(),
                    // 'toolbar'    => array(
                    //     'buttons' => 'reorder_toolbar'
                    // ),
                ));
                $this->appendToFile($configReorderView, '<?= $this->reorderRender() ?>', 0, FALSE, TRUE);
            }

            // ---------------------------- Custom table filters
            // On the table comment:
            // filters:
            //     expression_type:
            //         label: acorn.exam::lang.models.result.expression_type
            //         conditions: expression_type in(:filtered)
            //         options:
            //           data: Data
            //           expression: Expression
            //           formulae: Formulae
            if ($controller->model->filters) {
                foreach ($controller->model->filters as $name => $filter) {
                    $table    = $controller->model->getTable();
                    $comment  = (isset($filter['#']) ? $filter['#'] : '');
                    $comment .= "Custom filter on $table->name table.";
                    $filter['#'] = $comment;
                    $this->yamlFileSet($configFilterPath, "scopes.$name", $filter);
                }
            }                
        }

        // ---------------------------------------- Relation Manager configuration
        // We always need a config_relation.yaml, because all controllers implement the behaviour
        print("  Setting up relations in {$YELLOW}$configRelationPath{$NC}\n");
        $this->yamlFileSet($configRelationPath, '#', $createdBy);
        foreach ($controller->model->fields() as $name => &$field) {
            if ($field->fieldType == 'relationmanager') {
                if (count($field->relations) == 0) throw new Exception("Field $name has no relations for relationmanager configuration");
                if (count($field->relations) > 1)  throw new Exception("Field $name has multiple relations for relationmanager configuration");
                $relation1                 = end($field->relations);
                $relationModel             = $relation1->to;
                $relationPluginDirectory   = $relationModel->plugin->dirName();
                $relationModelDirName      = $relationModel->dirName();
                $relationControllerDirName = $relationModel->controller()->dirName();
                $relationModelDirPath      = "$relationPluginDirectory/models/$relationModelDirName";
                $relationControllerDirPath = "$relationPluginDirectory/controllers/$relationControllerDirName";

                // Relation Manager toolbarButtons can be:
                //   NULL (default buttons), 
                //   false (none), 
                //   an |array or 
                //   an associative array
                // toolbarButtons: create|delete
                // toolbarButtons:
                //     create: Add a line item
                //     delete: Remove line item
                $rlButtonsValue = NULL; // no toolbarButtons value, which sets default for that RM type
                if ($field->rlButtons === FALSE) {
                    $rlButtonsValue = FALSE;
                } else if (is_array($field->rlButtons) && count($field->rlButtons)) {
                    if (is_int(array_keys($field->rlButtons)[0])) {
                        // create, link
                        $rlButtonsValue = implode('|', $field->rlButtons);
                    } else if (array_values($field->rlButtons)[0] === TRUE) {
                        // create: true, link: true
                        $rlButtonsValue = implode('|', array_keys($field->rlButtons));
                    } else {
                        // create: Create this, link: Link this
                        $rlButtonsValue = $field->rlButtons;
                    }
                }

                print("    +{$YELLOW}$field->fieldKey{$NC} filter\n");
                $relationDefinition = NULL;
                if ($field->readOnly) {
                    $relationDefinition = array(
                        'label'    => $field->translationKey(),
                        'readOnly' => TRUE,
                        'view'     => array(
                            'list' => "\$/$relationModelDirPath/columns.yaml",
                            'toolbarButtons' => false,
                            'recordsPerPage' => $field->recordsPerPage, // Can be false
                            'showCheckboxes' => FALSE,
                            'recordOnClick'  => 'return false',
                        ),
                    );
                } else {
                    $relationDefinition = array(
                        'label' => $field->translationKey(),
                        'view' => array(
                            'list' => "\$/$relationModelDirPath/columns.yaml",
                            // TODO: Causes fail at the moment
                            'recordsPerPage' => FALSE, //$field->recordsPerPage, 
                        ),
                        'manage' => array(
                            'form' => "\$/$relationModelDirPath/fields.yaml",
                            // TODO: Causes fail at the moment
                            'recordsPerPage' => FALSE, // $field->recordsPerPage,
                        ),
                    );
                    if (!is_null($relation1->defaultSort)) $relationDefinition['view']['defaultSort'] = $relation1->defaultSort;
                    if (!is_null($rlButtonsValue))         $relationDefinition['view']['toolbarButtons'] = $rlButtonsValue;
                    if ($relationModel->hasField('sort_order'))   $relationDefinition['view']['defaultSort'] = array('column' => 'sort_order', 'direction' => 'asc');
                    if ($relationModel->hasField('ordinal'))      $relationDefinition['view']['defaultSort'] = array('column' => 'ordinal',    'direction' => 'asc');
                }
                
                // WinterCMS lies: The record-url: needs to be on the field.yaml, not the config-relation.yaml");
                // if ($relation1->recordUrl) $relationDefinition['view']['recordUrl']  = $relation1->recordUrl;
                if ($relation1->conditions)   $relationDefinition['view']['conditions'] = $relation1->conditions;
                if ($relation1->deferrable()) $relationDefinition['deferrable']         = $relation1->deferrable();
                if ($relation1->showSearch !== FALSE) {
                    $relationDefinition['view']['showSearch']   = true;
                    $relationDefinition['manage']['showSearch'] = true;
                }
                if ($relation1->showFilter !== FALSE) {
                    $path = "$relationControllerDirPath/config_filter.yaml";
                    if ($relationModel->isCreateSystem() || file_exists("plugins/$path")) {
                        $relationDefinition['view']['filter']   = "\$/$path";
                        $relationDefinition['manage']['filter'] = "\$/$path";
                    }
                }

                $this->yamlFileSet($configRelationPath, $field->fieldKey, $relationDefinition);
            }
        }

        // ---------------------------------------- Controller based Actions
        // config_form.yaml
        // TODO: Write the labels to lang, and the translationKeys to the YAML
        // TODO: These are not used yet, only the Model->actionFunctions set above
        $afCount = count($controller->model->actionFunctions);
        if ($afCount) 
            print("  Setting up [$afCount] {$YELLOW}actionFunctions{$NC}\n");
        else          
            print("  No {$YELLOW}actionFunctions{$NC}\n");
        $this->yamlFileSet($configFormPath, 'actionFunctions', $controller->model->actionFunctions);

        // ---------------------------------------- Controller context AJAX handlers
        // If 1-1 with User
        if ($controller->model->inheritsFrom('Acorn\User\Models\User')) {
            // Allow indirect user activation
            $this->addMethod($controllerFilePath, 'onActivate($code = NULL)', array(
                'if ($student = \Acorn\University\Models\Student::find($code))',
                '    $student->user->attemptActivation($student->user->activation_code);',
                'return \Redirect::refresh();'
            ));
        }
        if ($controller->model->actionAliases) {
            // courseplanner => index
            foreach ($controller->model->actionAliases as $actionAlias) {
                $funcAlias = preg_replace('/[^a-zA-Z0-9]+/', '', strtolower($actionAlias));
                $this->addMethod($controllerFilePath, $funcAlias, 'return $this->runAlias();');
            }
        }


        // ----------------------------------------------- Interface variants
        // TODO: Not used anymore. Superceeded by generic aa/partials/create|update.php
        // Remove standard create|update.php
        print("    Unlink {$YELLOW}$controllerDirPath/update.php{$NC}\n");
        unlink("$controllerDirPath/update.php");
        print("    Unlink {$YELLOW}$controllerDirPath/create.php{$NC}\n");
        unlink("$controllerDirPath/create.php");

        // Body class(es)
        $bodyClasses = array('compact-container');
        if      (is_string($controller->model->bodyClasses)) array_push($bodyClasses, $controller->model->bodyClasses);
        else if (is_array($controller->model->bodyClasses))  $bodyClasses = array_merge($bodyClasses, $controller->model->bodyClasses);
        $this->setPropertyInClassFile($controllerFilePath, 'bodyClass', implode(' ', $bodyClasses), FALSE);

        /* TODO: Old max tab-location interface switcher
        $maxTabLocation = 0;
        foreach ($controller->model->fields() as $name => &$field) {
            if ($field->tabLocation > $maxTabLocation) $maxTabLocation = $field->tabLocation;
        }
        $layout = ($maxTabLocation >= 3 ? 'form-with-sidebar' : 'form');
        $this->setPropertyInClassFile($controllerFilePath, 'bodyClass', 'compact-container', FALSE);
        print("    Tab max {$YELLOW}$maxTabLocation{$NC} template: {$YELLOW}$layout{$NC}\n");

        $interfaceVariantsDirPath = "$this->scriptDirPath/acorn-create-system-classes/frameworks/winter/controllers/$layout";
        foreach (scandir($interfaceVariantsDirPath) as $controllerFile) {
            $controllerFilePath = "$interfaceVariantsDirPath/$controllerFile";
            if (!in_array($controllerFile, array(".",".."))) {
                print("    Copied {$YELLOW}$layout/$controllerFile{$NC} => $controllerDirPath/\n");
                copy($controllerFilePath, "$controllerDirPath/$controllerFile");
            }
        }
        */
    }

    protected function createListInterface(Model &$model, bool $overwrite = FALSE) {
        global $GREEN, $YELLOW, $RED, $NC;

        $pluginDirectoryPath = $this->pluginDirectoryPath($model->plugin);
        $modelDirName        = $model->dirName();
        $modelFilePath       = "$pluginDirectoryPath/models/$model->name.php";
        $modelDirPath        = "$pluginDirectoryPath/models/$modelDirName";
        $columnsPath         = "$modelDirPath/columns.yaml";
        $createdBy           = $this->createdByString();

        print("  Columns.yaml: Check/create [$columnsPath]:\n");
        if (!is_dir($modelDirPath)) mkdir($modelDirPath, TRUE);
        $this->setFileContents($columnsPath, "# $createdBy");

        // -------------------------------- Columns.yaml
        // Remove the standard columns. If the model has them, they will be re-created
        $indent = 1;
        $this->yamlFileUnSet($columnsPath, 'columns.id');
        $this->yamlFileUnSet($columnsPath, 'columns.created_at');
        $this->yamlFileUnSet($columnsPath, 'columns.updated_at');

        foreach ($model->fields() as $name => &$field) {
            $indentString = str_repeat(' ', ($field->nestLevel ?: 0) * 2);
            $typeString   = ($field->fieldType ?: '<no field type>') . ' / ' . ($field->columnType ?: '<no column type>');
            if ($field->canDisplayAsColumn()) {
                print("    $indentString+{$YELLOW}$name{$NC}($typeString): to {$YELLOW}columns.yaml{$NC}\n");
                $labelKey = ($field->explicitLabelKey ?: $field->translationKey());
                $columnDefinition = array(
                    '#'          => $field->yamlComment,
                    '# Debug: '  => str_replace("\n", ' ', $field->debugComment),
                    'label'      => $labelKey,
                    'type'       => $field->columnType,
                    'valueFrom'  => $field->valueFrom,
                    'format'     => $field->format,
                    'bar'        => $field->bar,
                    'searchable' => $field->searchable,
                    'sortable'   => $field->sortable,
                    'invisible'  => $field->invisible,
                    'readOnly'   => $field->readOnly,
                    'path'       => $field->columnPartial,
                    'relation'   => $field->relation,
                    'select'     => $field->sqlSelect,
                    'useRelationCount' => $field->useRelationCount,
                    'cssClass'   => $field->cssClassColumn(),
                    
                    // Extended info
                    'nested'     => ($field->nested    ?: NULL),
                    'nestLevel'  => ($field->nestLevel ?: NULL),
                    // Relation _multi.php and other special directives
                    'multi'      => $field->multi,   
                    'nameObject' => $field->nameObject,
                    'prefix'     => $field->prefix,
                    'suffix'     => $field->suffix,
                    'qrcodeObject' => $field->qrcodeObject,
                    'typeEditable' => $field->typeEditable,

                    // MorphConfig.php
                    // Complex permissions
                    'permissionSettings' => $field->permissionSettings,
                    'permissions'        => $field->permissions,
                    'setting'            => $field->setting,

                    // MorphConfig.php dynamic include
                    'include'      => $field->include,          // Only include: 1to1
                    'includeModel' => $field->includeModel,     // Required for include
                    'includePath'  => $field->includePath,      // Not used
                    'includeContext' => $field->includeContext, // = exclude for QRCode
                );
                if ($field->columnConfig) $columnDefinition = array_merge($columnDefinition, $field->columnConfig);
                $columnDefinition = $this->removeEmpty($columnDefinition); // We do not remove falses
                $this->yamlFileSet($columnsPath, "columns.$field->columnKey", $columnDefinition);
            } else {
                print("    $indentString{$YELLOW}WARNING{$NC}: Field [$name]($typeString) cannot display as {$YELLOW}column{$NC} because columnType is blank\n");
            }
        }
    }

    protected function runChecks(Plugin &$plugin)
    {
        print("Running post install checks for [$plugin]\n");
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
                                throw new Exception("Lang key [$key] in [$fieldsFilePath] not found");
                        }
                    }
                }
                if (isset($fields['tabs']['fields'])) {
                    foreach ($fields['tabs']['fields'] as $name => $config) {
                        if (is_array($config) && isset($config['label'])) {
                            $key = $config['label'];
                            if (!$this->checkTranslationKey($key)) {
                                throw new Exception("Lang key [$key] in [$fieldsFilePath] not found");
                            }
                        }
                        if (is_array($config) && isset($config['tab'])) {
                            $key = $config['tab'];
                            if (!$this->checkTranslationKey($key))
                                throw new Exception("Lang key [$key] in [$fieldsFilePath] not found");
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
                                throw new Exception("Lang key [$key] in [$columnsFilePath] not found");
                        }
                    }
                }
            }
        }
        print(" ✓\n");

        print("  Checking Models PHP syntax");
        foreach (scandir($modelsDirPath) as $fileName) {
            $fileParts = explode('.', $fileName);
            $filePath  = "$modelsDirPath/$fileName";
            $fileType  = (isset($fileParts[1]) ? $fileParts[1] : '');
            if (is_file($filePath) && $fileType == 'php') {
                $modelName     = $fileParts[0];
                $modelFQN      = "$pluginFQN\\Models\\$modelName";
                print('.');
                if (!class_exists($modelFQN)) require_once($filePath);
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

    public function translationKeyPlugin(string $key, bool $pluginOnly = Framework::PLUGIN_ONLY): Plugin|Module|NULL
    {
        // acorn.user::lang.models.user.label
        // acorn::lang.models.general.name
        if (!$pluginOnly) throw new Exception("Module translation search not supported yet");

        $plugin        = NULL;
        $keyParts      = explode('::', $key);
        $domain        = $keyParts[0]; // acorn.user | acorn
        $isModule      = (strstr($domain, '.') === FALSE); // acorn
        if (!$isModule)
            $plugin = Plugin::fromDotName($domain);
        return $plugin;
    }

    public function checkTranslationKey(string $key): bool
    {
        if ($plugin = $this->translationKeyPlugin($key, Framework::PLUGIN_ONLY)) {
            $keyParts      = explode('::', $key);  // backend::lang.models.general.id@create
            $contextParts  = explode('@', $keyParts[1]); // lang.models.general.id, create
            $localParts    = explode('.', $contextParts[0]);       // lang, models, general, id
            $localKey      = implode('.', array_slice($localParts, 1)); // models.general.id

            // TODO: Check all lang files
            // NO_CACHE because we do not want to overwrite other plugins lang files
            $keyExists = $this->arrayFileValueExists($plugin->langEnPath(), $localKey, Framework::NO_CACHE);
        }

        // We do not error if the plugin has not been created
        return (!$plugin || !$plugin->exists() || $keyExists);
    }
}
