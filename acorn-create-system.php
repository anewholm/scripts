#!/usr/bin/env php
<?php namespace Acorn\CreateSystem;

$RED="\033[03;31m";
$GREEN="\033[02;31m";
$YELLOW="\033[01;31m";
$NC="\033[0m";
//$TICK="✓"
//$CROSS="✘"
$heading = str_repeat('-', 20);

require_once('acorn-create-system-classes/Spyc.php'); // YAML parser
require_once('acorn-create-system-classes/DatabaseNamingConvention.php');
require_once('acorn-create-system-classes/DB.php');
require_once('acorn-create-system-classes/Module.php');
require_once('acorn-create-system-classes/Plugin.php');
require_once('acorn-create-system-classes/Framework.php');
require_once('acorn-create-system-classes/WinterCMS.php');


// ------------------------------------------- Inputs
$file = basename(__FILE__);
print("Usage: $file [<plugin-name|all> <git command (push|ask|leave)>]\n");
$installPlugins = (isset($argv[1]) ? $argv[1] : NULL);
$gitPolicy      = (isset($argv[2]) ? $argv[2] : NULL);

// ------------------------------------------- Framework
$version       = '1.0';
$cwd           = getcwd();
$scriptPath    = realpath($argv[0]);
$scriptDirPath = dirname($scriptPath);
$framework     = Framework::detect($cwd, $scriptDirPath, __FILE__, $version);
if (!$framework) throw new \Exception("No framework found at [$cwd]");
$framework->show();

// ------------------------------------------- Read DB
$nc     = new AcornNamingConvention();
$db     = new DB($nc, $framework); // TODO: Also db->comment => properties heye
$tables = array_merge($db->tables(), $db->views());
foreach ($tables as &$table) {
    $table->loadForeignKeys();
    $table->loadActionFunctions();
}
//foreach ($tables as &$table) $table->show();

// ------------------------------------------- Generate plugins
$modules = Module::allFromTables($framework, $tables);
$plugins = Plugin::allFromTables($framework, $tables);

print("$heading: Modules\n");
foreach ($modules as $module) $module->show();
print("$heading: Plugins\n");
foreach ($plugins as $plugin) $plugin->show();

// ------------------------------------------- Choose which plugin to create()
if ($installPlugins == '*') {
    $chosenPlugins = &$plugins;
} else if ($installPlugins) {
    $chosenPlugins = array();
    foreach (explode(',', $installPlugins) as $pluginName) {
        $plugin = Plugin::get(ucfirst(trim($pluginName)));
        if (!$plugin) throw new \Exception("Plugin [$pluginName] not found");
        array_push($chosenPlugins, $plugin);
    }
} else {
    print("\n");
    print("${YELLOW}CHOOSE${NC}: No plugin name has been provided\n");
    $i = 1;
    $choices = array();
    print("[${GREEN}0${NC}] all\n");
    foreach ($plugins as $plugin) {
        if ($plugin->isOurs()) {
            print("[${GREEN}$i${NC}] ");
            $framework->showPluginStatus($plugin);
            $choices["$i"] = $plugin;
            print("\n");
            $i++;
        }
    }
    $i = readline("Which plugin would you like to process? ");
    if ($i == '0') $chosenPlugins = &$plugins;
    else {
        if (!isset($choices[$i])) throw new \Exception("Option [$i] not valid");
        $plugin = $choices[$i];
        print("${YELLOW}CHOICE${NC}: $plugin->name\n");
        $chosenPlugins = array($plugin);
    }
}


// ------------------------------------------- Write the plugins
// to the framework
foreach ($chosenPlugins as $plugin) {
    $framework->create($plugin);
}
