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

    protected $cubes = array();
    protected $xDatasource;

    protected function __construct(DB &$db, array $olapViews, array $tables, string $tomcatRoot = '/var/lib/tomcat9/webapps')
    {
        $this->db         = $db;
        $this->olapViews  = $olapViews; // schema: olap
        $this->tables     = $tables;
        $this->tomcatRoot = $tomcatRoot;
        $this->name       = $this->db->database;
    }

    public static function createAndDeploy(DB &$db, array $olapViews, array $tables, string $tomcatRoot = '/var/lib/tomcat9/webapps'): void {
        global $GREEN, $YELLOW, $RED, $NC;
        $olap = new static($db, $olapViews, $tables, $tomcatRoot);
        
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
        //         <URL>http://localhost:8080/xmondrian/demo/xmla</URL>
        //         <DataSourceInfo>
        //              Provider=mondrian;
        //              Jdbc=jdbc:postgresql://localhost:5432/universityacceptance;
        //              JdbcDrivers=org.postgresql.Driver;
        //              JdbcUser=universityacceptance;
        //              JdbcPassword=QueenPool1@;
        //              Catalog=/demo/WEB-INF/schema/universityacceptance.xml;
        //              UseSchemaPool=false
        //         </DataSourceInfo>
        //         <ProviderName>Mondrian</ProviderName>
        //         <ProviderType>MDP</ProviderType>
        //         <AuthenticationMode>Unauthenticated</AuthenticationMode>
        //         <Catalogs>
        //             <Catalog name="universityacceptance">
        //                 <Definition>/demo/WEB-INF/schema/universityacceptance.xml</Definition>
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
        $tomcat9Port   = 8080;
        $appUrl        = trim($this->db->framework->appUrl(), '/');
        $url           = "$appUrl:$tomcat9Port/xmondrian/demo/xmla";
        $schemaPath    = '/demo/WEB-INF/schema/cubes.xml';
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

        foreach ($this->olapViews as $viewName => $olapView) {
            print("  OLAP Cube {$GREEN}$viewName{$NC}\n");
            if ($olapView instanceof OLAPMaterializedView) {
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
            }
            $cube = new OLAPCube($viewName, $dimensions, $measures);
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
            $cubesSchemaPath = "$deploymentRoot/demo/WEB-INF/schema/cubes.xml";
            if (file_exists($cubesSchemaPath)) {
                $xCubesDoc = new DOMDocument();
                $xCubesDoc->preserveWhiteSpace = false;
                $xCubesDoc->formatOutput       = true;
                // Schema
                $xSchemaNode = $xCubesDoc->appendChild($xCubesDoc->createElement('Schema'));
                $xSchemaNode->setAttribute('name', $this->name);

                foreach ($this->cubes as $cubeTitle => $cube) {
                    print("  Creating OLAPCube {$YELLOW}$cubeTitle{$NC} for view {$YELLOW}$cube->viewName{$NC}\n");
                    $xCubeDoc  = $cube->document();
                    $xCubeElem = $xCubeDoc->firstElementChild; // Cube
                    $xCubeElem = $xCubesDoc->importNode($xCubeElem, TRUE);
                    $xSchemaNode->appendChild($xCubeElem);
                }
                print("  Writing main {$YELLOW}$cubesSchemaPath{$NC}\n");
                file_put_contents($cubesSchemaPath, $xCubesDoc->saveXML());
                $ret = TRUE;
            } else {
                print("Cubes schema.xml file not found {$RED}$cubesSchemaPath{$NC}). OLAP Cubes not written\n");
            }
        } else {
            print("TomCat9 server root not found {$RED}$this->tomcatRoot{$NC}). OLAP Cube not setup\n");
        }

        // Report cube URI
        $tomcat9Port   = 8080;
        $appUrl        = trim($this->db->framework->appUrl(), '/');
        $url           = "$appUrl:$tomcat9Port/$this->name/demo/xavier/index.html";
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

class OLAPDimension {
    public $name;
    public $column;

    public function __construct(string $name, Column $column) 
    {
        $this->name   = $name;
        $this->column = $column;
    }

    public function node(DOMDocument $xDoc): DOMNode
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

    public function node(DOMDocument $xDoc): DOMNode
    {
        // <Dimension name="Material">
        //   <Hierarchy hasAll="true" primaryKey="id">
        //     <Level name="Material" column="material_id" nameColumn="material_name" uniqueMembers="false"/>
        //   </Hierarchy>
        // </Dimension>
        $columnStub = $this->column->nameWithoutId();
        $columnName = "{$columnStub}_name";

        $xDimension = parent::node($xDoc);
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

    public function node(DOMDocument $xDoc): DOMNode
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
                //     <Level name="Exam Center" table="university_mofadala_exam_centers" column="id" nameColumn="name" uniqueMembers="true" />
                //   </Hierarchy>
                // </Dimension>
                $xDimension = parent::node($xDoc);
                $xDimension->setAttribute('foreignKey', $this->fk->columnFrom->column_name);

                $xHierarchy = $xDimension->appendChild($xDoc->createElement('Hierarchy'));
                $xHierarchy->setAttribute('hasAll', 'true');
                $xHierarchy->setAttribute('primaryKey', 'id');
                $xHierarchy->setAttribute('primaryKeyTable', $this->fk->tableFrom->fullyQualifiedName());

                $xJoin = $xHierarchy->appendChild($xDoc->createElement('Join'));
                $xJoin->setAttribute('leftKey',  $this->fk->columnFrom->column_name);
                $xJoin->setAttribute('rightKey', 'id');
                $xTable = $xJoin->appendChild($xDoc->createElement('Table'));
                $xTable->setAttribute('name',  $this->fk->tableFrom->fullyQualifiedName());
                $xTable = $xJoin->appendChild($xDoc->createElement('Table'));
                $xTable->setAttribute('name',  $this->fk->tableTo->fullyQualifiedName());
                
                $xLevel = $xHierarchy->appendChild($xDoc->createElement('Level'));
                $xLevel->setAttribute('name', $this->name);
                $xLevel->setAttribute('table', $this->fk->tableTo->fullyQualifiedName());
                $xLevel->setAttribute('column', 'id');
                $xLevel->setAttribute('nameColumn', 'name');
                $xLevel->setAttribute('uniqueMembers', 'true');
                
                break;
        }

        return $xDimension;
    }
}

class OLAPTimeDimension extends OLAPDimension {
    public function node(DOMDocument $xDoc): DOMNode
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
        $xDimension = parent::node($xDoc);
        $xDimension->setAttribute('type', 'TimeDimension');
        $columnFQN  = $this->column->fullyQualifiedName();

        $xLevel = $xDimension->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Year');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'true');
        $xLevel->setAttribute('levelType', 'TimeYears');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(year from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xDimension->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Month');
        $xLevel->setAttribute('type', 'String');
        $xLevel->setAttribute('uniqueMembers', 'false');
        $xLevel->setAttribute('levelType', 'TimeMonths');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "TO_CHAR($columnFQN, 'Month')"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xDimension->appendChild($xDoc->createElement('Level'));
        $xLevel->setAttribute('name', 'Day');
        $xLevel->setAttribute('type', 'Numeric');
        $xLevel->setAttribute('uniqueMembers', 'false');
        $xLevel->setAttribute('levelType', 'TimeDays');
        $xKeyExpression = $xLevel->appendChild($xDoc->createElement('KeyExpression'));
        $xSQL = $xKeyExpression->appendChild($xDoc->createElement('SQL', "extract(day from $columnFQN)"));
        $xSQL->setAttribute('dialect', 'postgres');

        $xLevel = $xDimension->appendChild($xDoc->createElement('Level'));
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

    public function node(DOMDocument $xDoc): DOMNode
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
    public $viewName;
    protected $dimensions;
    protected $measures;

    public function __construct(string $viewName, array $dimensions, array $measures) {
        $this->viewName   = $viewName;
        $this->dimensions = $dimensions;
        $this->measures   = $measures;
    }

    public function title(): string
    {
        $viewNameParts  = explode('_', $this->viewName);
        $viewNameParts = array_filter($viewNameParts, function($value){return $value != 'olapcube';});
        $viewTitleParts = array_slice($viewNameParts, 1);
        return Str::title(implode(' ', $viewTitleParts));
    }

    public function document(): DOMDocument
    {
        $xDoc = new DOMDocument();

        // Cube
        $xRootNode = $xDoc->appendChild($xDoc->createElement('Cube'));
        $xRootNode->setAttribute('name', $this->title());
        $xRootNode->setAttribute('for-view', $this->viewName);
        // TODO: $cubeNode->setAttribute('defaultMeasure', $this->defaultMeasure);

        // ----------------------------- Set Primary table
        // <Table name="university_mofadala_marks">
        //     <AggName name="agg_c_count_fact">
        //         <AggFactCount column="id"/>
        //         <AggLevel name="[Time].[Year]" column="id" />
        //     </AggName>
        // </Table>
        $xTable   = $xRootNode->appendChild($xDoc->createElement('Table'));
        $xTable->setAttribute('name', $this->viewName);
        $xAggName = $xTable->appendChild($xDoc->createElement('AggName'));
        $xAggName->setAttribute('name', 'agg_c_count_fact');
        $xAggFactCount = $xAggName->appendChild($xDoc->createElement('AggFactCount'));
        $xAggFactCount->setAttribute('column', 'id');

        // ----------------------------- Add dimensions & Measures
        foreach ($this->dimensions as $name => $dimension) {
            $xRootNode->appendChild($dimension->node($xDoc));
        }
        foreach ($this->measures as $name => $measure) {
            $xRootNode->appendChild($measure->node($xDoc));
        }

        return $xDoc;
    }
}

