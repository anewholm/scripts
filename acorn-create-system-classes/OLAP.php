<?php namespace Acorn\CreateSystem;

use Exception;
use Spyc;

class OLAP
{
    protected $db;
    protected $schema;
    protected $tables;
    protected static $tomcatRoot = '/var/lib/tomcat9/webapps';

    protected function __construct(DB &$db, Schema $schema, array $tables)
    {
        $this->db     = $db;
        $this->schema = $schema; // Acorn
        $this->tables = $tables; // Lojistiks
    }

    public static function create(DB &$db, Schema $schema, array $tables): void {
        $olap = new static($db, $schema, $tables);
        $olap->createCube();
    }

    protected function createCube(): void {
        global $GREEN, $YELLOW, $RED, $NC;

        $name       = $this->db->database;
        $tomcatRoot = self::$tomcatRoot;
        $scriptsDir = dirname(dirname(__FILE__));
        
        print("OLAP report for database {$YELLOW}$name{$NC}\n");
        if (file_exists($tomcatRoot)) {
            print("Copying scripts {$YELLOW}$scriptsDir/olap/template{$NC} to {$YELLOW}$tomcatRoot/$name{$NC}\n");
            // Always clobber
            Framework::copyDir("$scriptsDir/olap/template", "$tomcatRoot/$name");

            // Discover the measures
            $measureColumns = array();
            foreach ($this->tables as $table) {
                if ($table->isOurs() && !$table->isKnownAcornPlugin()) {
                    foreach ($table->columns as $column) {
                        if ($column->olap == 'measure' 
                            || (is_array($column->olap) && isset($column->olap['type']) && $column->olap['type'] == 'measure')
                        ) {
                            $measureColumns[$column->fullyQualifiedName()] = $column;
                        }
                    }
                }
            }
            print("Measures:\n");
            foreach ($measureColumns as $fqName => $column) {
                print("  $fqName ({$YELLOW}$column->data_type{$NC})\n");
            }

            // Map the dimensions
            foreach ($this->tables as $table) {
                if ($table->isOurs() && !$table->isKnownAcornPlugin()) {
                    $fksTo     = $table->allForeignKeysTo();
                    $fksFrom   = $table->allForeignKeysFrom();
                    $fksToC    = count($fksTo);
                    $fksFromC  = count($fksFrom);
                }
            }
        } else {
            print("TomCat9 server root not found {$RED}$tomcatRoot{$NC}). OLAP Cube not setup\n");
        }
    }
}
