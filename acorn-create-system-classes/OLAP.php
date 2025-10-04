<?php namespace Acorn\CreateSystem;

use DOMDocument;
use DOMNode;
use Exception;
use \DateTime;
use Spyc;

class OLAP
{
    protected $db;
    protected $name;
    protected $olapViews;
    protected $tables;
    protected $tomcatRoot = '/var/lib/tomcat9/webapps';
    protected $tomcat9Port = 8080;

    protected $cubes = array();
    protected $xDatasource;

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
                    $dimension = new OLAPSimpleIncludedDimension($dimensionName, $fk->columnFrom);
                } else {
                    if (!$fk->tableTo->hasColumn('name'))
                        throw new Exception('OLAPForeignKeyDimension to table does not have a name column');
                    $dimension = new OLAPForeignKeyDimension($dimensionName, $fk);
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

    public function deploy(): bool
    {
        global $GREEN, $YELLOW, $RED, $NC;

        $ret        = FALSE;
        $scriptsDir = dirname(dirname(__FILE__));
        
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
                $imagePath = "$this->tomcatRoot/ROOT/images/$webapp.png";
                if (file_exists($imagePath)) $imageHtml = "<img src='/ROOT/images/$webapp.png'/>";
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

class OLAPEntity {
    public function addTranslateableName(DOMNode &$xElement, Table $tableTo, string $locale): void
    {
        if ($locale == 'en') {
            $xElement->setAttribute('nameColumn', 'name');
        } else {
            // Translation
            //   <NameExpression>
            //      <SQL dialect="postgres">
            //          fn_acorn_translate(
            //              acorn_exam_calculations.name, 
            //              'acorn_exam_calculations', 
            //              acorn_exam_calculations.id, 
            //              'ar'
            //          )
            //      </SQL>
            //   </NameExpression>
            $tableTo = $tableTo->fullyQualifiedName();
            $sql     = "fn_acorn_translate($tableTo.name, '$tableTo', $tableTo.id, '$locale')";
            $xNameExpression = $xElement->appendChild($xElement->ownerDocument->createElement('NameExpression'));
            $xSQL = $xNameExpression->appendChild($xElement->ownerDocument->createElement('SQL', $sql));
            $xSQL->setAttribute('dialect', 'postgres');
        }
    }
}

class OLAPDimension extends OLAPEntity {
    public $name;
    public $column;

    public function __construct(string $name, Column $column) 
    {
        $this->name   = $name;
        $this->column = $column;
    }

    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        $xDimension = $xDoc->createElement('Dimension');
        $xDimension->setAttribute('name', $this->name);
        return $xDimension;
    }
}

class OLAPSimpleIncludedDimension extends OLAPDimension {
    public function __construct(string $name, Column $column) 
    {
        parent::__construct($name, $column);
    }

    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        // <Dimension name="Material">
        //   <Hierarchy hasAll="true" primaryKey="id">
        //     <Level name="Material" column="material_id" nameColumn="material_name" uniqueMembers="false"/>
        //   </Hierarchy>
        // </Dimension>
        $columnStub = $this->column->nameWithoutId();
        $columnName = "{$columnStub}_name";

        $xDimension = parent::node($xDoc, $locale);
        $xHierarchy = $xDimension->appendChild($xDoc->createElement('Hierarchy'));
        $xHierarchy->setAttribute('hasAll', 'true');
        $xHierarchy->setAttribute('primaryKey', 'id');
        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', $this->name);
        $xLevel->setAttribute('column', $this->column->column_name);
        $xLevel->setAttribute('nameColumn', $columnName);
        $xLevel->setAttribute('uniqueMembers', 'true');

        return $xDimension;
    }
}

class OLAPForeignKeyDimension extends OLAPDimension {
    protected $fk;

    public function __construct(string $name, ForeignKey $fk) 
    {
        parent::__construct($name, $fk->columnFrom);

        $this->fk = $fk;
    }

    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        switch ($this->fk->type()) {
            case 'Xto1':
                // Fact table: something_id => public.something_table.id
                //
                // <Dimension name="Exam Center" foreignKey="exam_center_id">
                //   <Hierarchy hasAll="true" primaryKey="id" primaryKeyTable="university_mofadala_students">
                //     <Join leftKey="exam_center_id" rightKey="id">
                //       <Table name="university_mofadala_students"/>
                //       <Table name="university_mofadala_exam_centers"/>
                //     </Join>
                //     <Level name="Exam Center" table="university_mofadala_exam_centers" column="id" uniqueMembers="true">
                //       <NameExpression>
                //          <SQL dialect="postgres">
                //              fn_acorn_translate(
                //                  acorn_exam_calculations.name, 
                //                  'acorn_exam_calculations', 
                //                  acorn_exam_calculations.id, 
                //                  'ar'
                //              )
                //          </SQL>
                //       </NameExpression>
                //   </Hierarchy>
                // </Dimension>
                $xDimension = parent::node($xDoc, $locale);
                $xDimension->setAttribute('foreignKey', $this->fk->columnFrom->column_name);

                $xHierarchy = $xDimension->appendChild($xDoc->createElement('Hierarchy'));
                $xHierarchy->setAttribute('hasAll', 'true');
                $xHierarchy->setAttribute('primaryKey', 'id');
                // Schema not necessary apparently...
                $xHierarchy->setAttribute('primaryKeyTable', $this->fk->tableFrom->name);

                $xJoin = $xHierarchy->appendChild($xDoc->createElement('Join'));
                $xJoin->setAttribute('leftKey',  $this->fk->columnFrom->column_name);
                $xJoin->setAttribute('rightKey', 'id');
                $xTable = $xJoin->appendChild($xDoc->createElement('Table'));
                $xTable->setAttribute('name',  $this->fk->tableFrom->name);
                if ($this->fk->tableFrom->schema && $this->fk->tableFrom->schema != 'public') 
                    $xTable->setAttribute('schema',  $this->fk->tableFrom->schema);
                $xTable = $xJoin->appendChild($xDoc->createElement('Table'));
                $xTable->setAttribute('name',  $this->fk->tableTo->name);
                if ($this->fk->tableTo->schema && $this->fk->tableTo->schema != 'public') 
                    $xTable->setAttribute('schema',  $this->fk->tableTo->schema);
                
                $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
                $xLevel->setAttribute('name', $this->name);
                $xLevel->setAttribute('table', $this->fk->tableTo->fullyQualifiedName());
                $xLevel->setAttribute('column', 'id');
                $xLevel->setAttribute('uniqueMembers', 'true');

                $tableTo = $this->fk->tableTo;
                $this->addTranslateableName($xLevel, $tableTo, $locale);
                
                break;
        }

        return $xDimension;
    }
}

class OLAPTimeDimension extends OLAPDimension {
    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        // <Dimension name="Time" type="TimeDimension" foreignKey="student_id">
        //     <Hierarchy hasAll="true" primaryKey="id">
        //         <Table name="university_mofadala_students"/>
        //         <Level name="Year" type="Numeric" uniqueMembers="true" levelType="TimeYears">
        //          <KeyExpression><SQL dialect="postgres">extract(year from university_mofadala_students.created_at)</SQL></KeyExpression>
        //         </Level>
        //         <Level name="Month" type="String" uniqueMembers="false" levelType="TimeMonths">
        //          <KeyExpression><SQL dialect="postgres">TO_CHAR(university_mofadala_students.created_at, 'Month')</SQL></KeyExpression>
        //         </Level>
        //         <Level name="Day" type="Numeric" uniqueMembers="false" levelType="TimeDays">
        //          <KeyExpression><SQL dialect="postgres">extract(day from university_mofadala_students.created_at)</SQL></KeyExpression>
        //         </Level>
        //         <Level name="Hour" type="Numeric" uniqueMembers="false" levelType="TimeHours">
        //          <KeyExpression><SQL dialect="postgres">extract(hour from university_mofadala_students.created_at)</SQL></KeyExpression>
        //         </Level>
        //     </Hierarchy>
        // </Dimension>
        $xDimension = parent::node($xDoc, $locale);
        $xDimension->setAttribute('type', 'TimeDimension');
        $columnFQN  = $this->column->fullyQualifiedName(Column::INCLUDE_SCHEMA, Column::NOT_SCHEMA_PUBLIC);

        $xHierarchy = $xDimension->appendChild($xDoc->createElement('Hierarchy'));
        $xHierarchy->setAttribute('hasAll', 'true');
        $xHierarchy->setAttribute('primaryKey', 'id');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Year');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'true');
        $xLevel->setAttribute('levelType', 'TimeYears');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(year from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Month');
        $xLevel->setAttribute('type', 'String');
        $xLevel->setAttribute('uniqueMembers', 'false');
        $xLevel->setAttribute('levelType', 'TimeMonths');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "TO_CHAR($columnFQN, 'Month')"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Day');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'false');
        $xLevel->setAttribute('levelType', 'TimeDays');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(day from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Hour');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'true');
        $xLevel->setAttribute('levelType', 'TimeHours');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(hour from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        return $xDimension;
    }
}

class OLAPMeasure {
    public $name;
    public $column;

    public function __construct(string $name, Column $column) 
    {
        $this->name   = $name;
        $this->column = $column;
    }

    public function node(DOMDocument $xDoc, string $locale = 'en'): DOMNode
    {
        // <Measure name="Num Students" column="student_id" aggregator="distinct-count" formatString="Standard"/>
        $xMeasure = $xDoc->createElement('Measure');
        $xMeasure->setAttribute('name', $this->name);
        $xMeasure->setAttribute('column', $this->column->column_name);
        $xMeasure->setAttribute('aggregator', 'distinct-count');
        $xMeasure->setAttribute('formatString', 'Standard');

        return $xMeasure;
    }
}

class OLAPCube {
    public $olapView;
    protected $dimensions;
    protected $measures;
    protected $defaultMeasure;

    public function __construct(View $olapView, array $dimensions, array $measures) {
        $this->olapView   = $olapView;
        $this->dimensions = $dimensions;
        $this->measures   = $measures;
        
        $this->defaultMeasure = 'Count';
    }

    public function title(string $locale = 'en'): string
    {
        // [olap.]acorn_enrollment_olapcube => Enrollment
        // [olap.]acorn_enrollment_olapcube_things => Enrollment Things
        $viewNameParts  = explode('_', $this->olapView->name);
        $viewNameParts  = array_filter($viewNameParts, function($value){return $value != 'olapcube';});
        $viewTitleParts = array_slice($viewNameParts, 1);
        $title          = Str::title(implode(' ', $viewTitleParts));
        if ($locale != 'en') $title .= " ($locale)";
        return $title;
    }

    public function document(string $locale = 'en'): DOMDocument
    {
        $xDoc = new DOMDocument();

        // Cube
        $cubeNode = $xDoc->appendChild($xDoc->createElement('Cube'));
        $cubeNode->setAttribute('name', $this->title($locale));
        $cubeNode->setAttribute('for-view', $this->olapView->name);
        if ($this->defaultMeasure) $cubeNode->setAttribute('defaultMeasure', $this->defaultMeasure);

        // ----------------------------- Set Primary table
        // <Table name="university_mofadala_marks" schema="whatever">
        //     <AggName name="agg_c_count_fact">
        //         <AggFactCount column="id"/>
        //         <AggLevel name="[Time].[Year]" column="id" />
        //     </AggName>
        // </Table>
        $xTable   = $cubeNode->appendChild($xDoc->createElement('Table'));
        $xTable->setAttribute('name', $this->olapView->name);
        if ($this->olapView->schema && $this->olapView->schema != 'public') 
            $xTable->setAttribute('schema', $this->olapView->schema);
        $xAggName = $xTable->appendChild($xDoc->createElement('AggName'));
        $xAggName->setAttribute('name', 'agg_c_count_fact');
        $xAggFactCount = $xAggName->appendChild($xDoc->createElement('AggFactCount'));
        $xAggFactCount->setAttribute('column', 'id');

        // ----------------------------- Add dimensions & Measures
        foreach ($this->dimensions as $dimension) {
            $cubeNode->appendChild($dimension->node($xDoc, $locale));
        }
        foreach ($this->measures as $measure) {
            $cubeNode->appendChild($measure->node($xDoc, $locale));
        }

        return $xDoc;
    }
}

