<?php namespace Acorn\CreateSystem\Adapters;

use DOMDocument;
use DOMNode;
use Exception;
use DateTime;
use Spyc;
use Acorn\CreateSystem\Database\DB;
use Acorn\CreateSystem\Database\Table;
use Acorn\CreateSystem\Database\View;
use Acorn\CreateSystem\Database\Column;
use Acorn\CreateSystem\Database\ForeignKey;
use Acorn\CreateSystem\Util\Str;
use Acorn\CreateSystem\Adapters\Olap\OLAPEntity;
use Acorn\CreateSystem\Adapters\Olap\OLAPDimension;
use Acorn\CreateSystem\Adapters\Olap\OLAPSimpleIncludedDimension;
use Acorn\CreateSystem\Adapters\Olap\OLAPForeignKeyDimension;
use Acorn\CreateSystem\Adapters\Olap\OLAPTimeDimension;
use Acorn\CreateSystem\Adapters\Olap\OLAPMeasure;
use Acorn\CreateSystem\Adapters\Olap\OLAPCube;

class OLAP extends Framework
{
    public $db;
    protected $name;
    protected $olapViews;
    protected $tables;
    protected $tomcatRoot = '/var/lib/tomcat9/webapps';
    protected $tomcat9Port = 8080;

    protected $cubes = array();
    protected $xDatasource;

    // ----------------------------------------- Adapter detection

    public static function scope(): string { return 'full'; }

    public static function isPresent(string $cwd): bool
    {
        // 1. Explicit bash environment variable takes precedence
        if (getenv('OLAP_DEPLOY_PATH') !== false) return true;
        // 2. Standard Ubuntu Tomcat install path probe
        return !empty(glob('/var/lib/tomcat*/webapps'));
    }

    public static function deployPath(): string
    {
        $envPath = getenv('OLAP_DEPLOY_PATH');
        if ($envPath !== false) return $envPath;
        $paths = glob('/var/lib/tomcat*/webapps');
        return $paths[0] ?? null;
    }

    // ----------------------------------------- Construction

    protected function __construct(DB &$db, array $olapViews, array $tables, string $tomcatRoot = '/var/lib/tomcat9/webapps', int $tomcat9Port = 8080)
    {
        $this->db          = $db;
        $this->olapViews   = $olapViews; // schema: olap
        $this->tables      = $tables;
        $this->tomcatRoot  = $tomcatRoot;
        $this->tomcat9Port = $tomcat9Port;
        $this->name        = $this->db->database;
    }

    public static function createAndDeploy(DB &$db, array $olapViews, array $tables, string $tomcatRoot = '/var/lib/tomcat9/webapps', int $tomcat9Port = 8080): void {
        global $GREEN, $YELLOW, $RED, $NC;
        $olap = new static($db, $olapViews, $tables, $tomcatRoot, $tomcat9Port);
        
        print("OLAP report for database {$YELLOW}$olap->name{$NC}\n");
        $olap->createCubes();
        $olap->createDatasource();
        $olap->deploy();
    }

    public function createDatasource(): void
    {
        // <DataSources>
        //     <DataSource>
        //         <DataSourceName>universityacceptance</DataSourceName>
        //         <DataSourceDescription>University Cubes</DataSourceDescription>
        //         <URL>http://localhost:8080/xmondrian/xmla</URL>
        //         <DataSourceInfo>
        //              Provider=mondrian;
        //              Jdbc=jdbc:postgresql://localhost:5432/universityacceptance;
        //              JdbcDrivers=org.postgresql.Driver;
        //              JdbcUser=universityacceptance;
        //              JdbcPassword=QueenPool1@;
        //              Catalog=/WEB-INF/schema/cubes.xml;
        //              UseSchemaPool=false
        //         </DataSourceInfo>
        //         <ProviderName>Mondrian</ProviderName>
        //         <ProviderType>MDP</ProviderType>
        //         <AuthenticationMode>Unauthenticated</AuthenticationMode>
        //         <Catalogs>
        //             <Catalog name="universityacceptance">
        //                 <Definition>/WEB-INF/schema/cubes.xml</Definition>
        //             </Catalog>
        //         </Catalogs>
        //     </DataSource>
        // </DataSources>
        $xDoc          = new DOMDocument();
        $xDoc->preserveWhiteSpace = false;
        $xDoc->formatOutput       = true;

        $dbHost        = $this->db->dbHost(); // Usually localhost
        $dbName        = $this->db->dbDatabase();
        $dbPort        = $this->db->dbPort();
        $dbUser        = 'olap';
        $dbPassword    = 'QueenPool1@';

        // Assumes the TomCat9 is deployed on the same domain
        // forwarded by Apache from port 8080
        $appUrl        = trim($this->db->framework->appUrl(), '/');
        $url           = "$appUrl:$this->tomcat9Port/xmondrian/xmla";
        $schemaPath    = '/WEB-INF/schema/cubes.xml';
        $useSchemaPool = FALSE; // Cacheing of dimension members
        $useSchemaPoolString = var_export($useSchemaPool, TRUE);

        $xDataSources  = $xDoc->appendChild($xDoc->createElement('DataSources'));
        $xDataSource   = $xDataSources->appendChild($xDoc->createElement('DataSource'));
        $xDataSource->appendChild($xDoc->createElement('DataSourceName', $dbName));
        $xDataSource->appendChild($xDoc->createElement('DataSourceDescription', "$this->name Cubes"));
        $xDataSource->appendChild($xDoc->createElement('URL', $url));
        $xDataSource->appendChild($xDoc->createElement('DataSourceInfo', <<<INFO
            Provider=mondrian;
            Jdbc=jdbc:postgresql://$dbHost:$dbPort/$dbName;
            JdbcDrivers=org.postgresql.Driver;
            JdbcUser=$dbUser;
            JdbcPassword=$dbPassword;
            Catalog=$schemaPath;
            UseSchemaPool=$useSchemaPoolString
INFO
        ));
        $xDataSource->appendChild($xDoc->createElement('ProviderName', 'Mondrian'));
        $xDataSource->appendChild($xDoc->createElement('ProviderType', 'MDP'));
        $xDataSource->appendChild($xDoc->createElement('AuthenticationMode', 'Unauthenticated'));
        $xCatalogs = $xDataSource->appendChild($xDoc->createElement('Catalogs'));
        $xCatalog  = $xCatalogs->appendChild($xDoc->createElement('Catalog'));
        $xCatalog->setAttribute('name', $dbName);
        $xCatalog->appendChild($xDoc->createElement('Definition', $schemaPath));

        $this->xDatasource = $xDoc;
    }

    protected function createCubes(): void {
        global $GREEN, $YELLOW, $RED, $NC;

        foreach ($this->olapViews as $olapView) {
            if ($olapView->menu !== FALSE) {
                $viewName = $olapView->name;
                print("  OLAP Cube {$GREEN}$viewName{$NC}\n");

                // Map the FK dimensions
                $dimensions = array();
                $measures   = array();
                $fks        = $olapView->allForeignKeys();
                foreach ($fks as $fk) {
                    $fkType        = $fk->type();
                    $fkDir         = $fk->directionName();
                    $columnStub    = $fk->columnFrom->nameWithoutId();
                    $columnName    = "{$columnStub}_name";
                    $dimensionName = Str::title(str_replace('_', ' ', $columnStub));
                    print("    +OLAP Dimension {$YELLOW}$dimensionName{$NC} ($fkDir $fkType)\n");
                    if ($olapView->hasColumn($columnName)) {
                        // This does not support translation
                        $dimension = new OLAPSimpleIncludedDimension($dimensionName, $fk->columnFrom);
                    } 
                    else if ($fk->tableTo->hasColumn('name')) {
                        // This _does_ support translation
                        // via the fn_acorn_translate() function => winter_translate_attributes for that table => model name
                        $dimension = new OLAPForeignKeyDimension($dimensionName, $fk);
                    }
                    else {
                        // TODO: Multi-join 1-1 dimensions
                        // e.g. course => entities => user_groups
                        throw new Exception('No OLAPSimpleIncludedDimension name and OLAPForeignKeyDimension to table does not have a name column');
                    }
                    $dimensions[$dimensionName] = $dimension;
                }

                // Map the Time dimensions
                foreach ($olapView->columns as $columnName => $column) {
                    switch ($column->data_type) {
                        case 'timestamp(0) with time zone':
                        case 'timestamp(0) without time zone':
                        case 'timestamp with time zone':
                        case 'timestamp without time zone':
                        case 'date':
                        case 'datetime':
                            $dimensionName = Str::title(str_replace('_', ' ', $columnName));
                            print("    +OLAP Time Dimension {$YELLOW}$dimensionName{$NC}\n");
                            $dimensions[$dimensionName] = new OLAPTimeDimension($dimensionName, $column);
                            break;
                    }
                }

                // Map the Measures
                foreach ($olapView->columns as $columnName => $column) {
                    if ($column->isTheIdColumn()) {
                        $measureName = 'Count';
                        print("    +OLAP Measure {$YELLOW}$measureName{$NC}\n");
                        $measures[$measureName] = new OLAPMeasure($measureName, $column);
                    } else {
                        switch ($column->data_type) {
                            case 'double precision':
                            case 'double':
                            case 'int':
                            case 'bigint':
                            case 'integer':
                                $measureName = Str::title(str_replace('_', ' ', $columnName));
                                print("    +OLAP Measure {$YELLOW}$measureName{$NC}\n");
                                $measures[$measureName] = new OLAPMeasure($measureName, $column);
                                break;
                        }
                    }
                }
                $cube = new OLAPCube($olapView, $dimensions, $measures);
                $this->cubes[$cube->title()] = $cube;
            }
        }
    }

    public function deploy(): bool
    {
        global $GREEN, $YELLOW, $RED, $NC;

        $ret        = FALSE;
        $scriptsDir = dirname(dirname(dirname(__FILE__)));
        
        if (file_exists($this->tomcatRoot)) {
            $deploymentRoot = "$this->tomcatRoot/$this->name";
            print("Copying scripts {$YELLOW}$scriptsDir/olap/template{$NC} to {$YELLOW}$deploymentRoot{$NC}\n");
            // Always clobber
            Framework::copyDir("$scriptsDir/olap/template", $deploymentRoot);

            // Write Datasource
            $datasourcePath = "$deploymentRoot/WEB-INF/datasources.xml";
            if ($this->xDatasource) {
                if (file_exists($datasourcePath)) {
                    print("  Writing main Datasource for database at {$YELLOW}$datasourcePath{$NC}\n");
                    file_put_contents($datasourcePath, $this->xDatasource->saveXML());
                } else {
                    throw new Exception("DataSources path [$datasourcePath] does not exist");
                }
            } else {
                throw new Exception("No DataSources document");
            }

            // TODO: Set the XMLA servlet to UTF-8 
            // in WEB_INF/web.xml
            // <init-param>
            //     <param-name>CharacterEncoding</param-name>
            //     <param-value>UTF-8</param-value>
            // </init-param>


            // Write $cubes => cubes.xml
            $cubesSchemaPath = "$deploymentRoot/WEB-INF/schema/cubes.xml";
            if (file_exists($cubesSchemaPath)) {
                $xCubesDoc = new DOMDocument();
                $xCubesDoc->preserveWhiteSpace = false;
                $xCubesDoc->formatOutput       = true;
                // Schema
                $xSchemaNode = $xCubesDoc->appendChild($xCubesDoc->createElement('Schema'));
                $xSchemaNode->setAttribute('name', $this->name);

                foreach ($this->cubes as $cubeTitle => $cube) {
                    $viewName = $cube->olapView->name;
                    print("  Creating OLAPCube {$YELLOW}$cubeTitle{$NC} for view {$YELLOW}$viewName{$NC}\n");
                    $xCubeDoc  = $cube->document();
                    $xSchemaNode->appendChild($xCubesDoc->importNode($xCubeDoc->firstElementChild, TRUE));
                    $xCubeDoc  = $cube->document('ku');
                    $xSchemaNode->appendChild($xCubesDoc->importNode($xCubeDoc->firstElementChild, TRUE));
                    $xCubeDoc  = $cube->document('ar');
                    $xSchemaNode->appendChild($xCubesDoc->importNode($xCubeDoc->firstElementChild, TRUE));
                }
                print("  Writing main {$YELLOW}$cubesSchemaPath{$NC}\n");
                file_put_contents($cubesSchemaPath, $xCubesDoc->saveXML());
                $ret = TRUE;
            } else {
                throw new Exception("Cubes schema.xml file not found $cubesSchemaPath. OLAP Cubes not written\n");
            }
        } else {
            print("TomCat9 server root not found {$RED}$this->tomcatRoot{$NC}). OLAP Cube not setup\n");
        }

        // TomCat index.html
        $tomcat9IndexPath = "$this->tomcatRoot/ROOT/index.html";
        if (file_exists($tomcat9IndexPath)) {
            // TomCat 9 setup
            $webapps = array();
            foreach (new \DirectoryIterator($this->tomcatRoot) as $item) {
                if ($item->isDir() && !$item->isDot()) {
                    // TODO: Check if there is a schema.xml in the directory
                    switch ($item->getFileName()) {
                        case 'ROOT':
                        case 'xmondrian':
                            break;
                        default:
                            array_push($webapps, $item->getFilename());
                    }
                }
            }
            $linksHtml = '<ul class="webapps">';
            foreach ($webapps as $webapp) {
                $imageHtml = NULL;
                $imageFile = strtolower($webapp);
                $imagePath = "$this->tomcatRoot/ROOT/images/$imageFile.png";
                if (file_exists($imagePath)) $imageHtml = "<img src='/images/$imageFile.png'/>";
                $title = Str::title($webapp);

                $alternateLanguagesHtml = '';
                $cubesHtml = '';
                if ($webapp == $this->name) {
                    // Language list
                    $alternateLanguagesHtml  = '(';
                    $alternateLanguagesHtml .= "<a href='/$webapp/xavier/index.html'>In English</a>, ";
                    $alternateLanguagesHtml .= "<a href='/$webapp/xavier/index-ku.html'>Bi Kurdî</a>, ";
                    $alternateLanguagesHtml .= "<a href='/$webapp/xavier/index-ar.html'>باللغة العربية</a>";
                    $alternateLanguagesHtml .= ')';

                    // Cube list
                    $cubesHtml = '<ul class="cubes">';
                    foreach ($this->cubes as $cube) {
                        $cubeTitle = $cube->title();
                        $cubesHtml .= "<li>$cubeTitle</li>";
                    }
                    $cubesHtml .= '</ul>';
                }

                $linksHtml .= <<<HTML
                    <li>
                        <a href='/$webapp/xavier/index.html'>$title</a>
                        $alternateLanguagesHtml
                        $cubesHtml $imageHtml
                    </li>
HTML
                ;
            }
            $linksHtml .= '</ul>';

            // ROOT/index.html
            file_put_contents($tomcat9IndexPath, <<<HTML
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
                <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
                    <head>
                        <meta http-equiv="Content-Type" content="type=text/html; charset=utf-8" />
                        <title>Acorn OLAP Cubes</title>
                        <link rel="icon" type="image/png" href="/images/favicon.png">
                        <style>
                            body {
                                font: Verdana;
                                background-image: url(/images/olap.png);
                                background-position: right top;
                                background-repeat: no-repeat;
                                color: #555;
                            }
                            img {
                                display: block;
                                height: 100px;
                            }
                            a {
                                text-decoration: none;
                            }
                            a:hover {
                                border-bottom: 1px dotted #d7d7d7;
                            }
                            .webapps > li {
                                font-weight: bold;
                                padding-top:10px;
                            }
                            .cubes > li {
                                display: inline;
                                color: #777;
                                font-weight: normal;
                            }
                            #tech {
                                position: fixed;
                                bottom: 5px;
                                right: 5px;
                                color: #999;
                            }
                        </style>
                    </head>
                    <body>
                        <h1>OLAP Cubes</h1>
                        $linksHtml
                        <a id="tech" href="https://mondrian.pentaho.com/documentation/olap.php">Technical implementation documentation</a>
                    </body>
                </html>
HTML
            );            
        }


        // Report cube URI
        $appUrl        = trim($this->db->framework->appUrl(), '/');
        $url           = "$appUrl:$this->tomcat9Port/$this->name/xavier/index.html";
        print("Cube now available, maybe, on {$YELLOW}$url{$NC}\n");

        $logPath         = '/var/log/tomcat9';
        $ymdDate         = (new DateTime)->format('Y-m-d');
        $catalinaLogPath = "$logPath/catalina.$ymdDate.log";
        $mondrianLogPath = "$logPath/mondrian.log";

        if (file_exists($mondrianLogPath)) {
            print("Logs now available at {$YELLOW}$mondrianLogPath{$NC}\n");
        } else {
            print("Log file not found at {$RED}$mondrianLogPath{$NC}\n");
        }

        return $ret;
    }
}

Framework::registerDetector(OLAP::class);
