<?php namespace Acorn\CreateSystem;

require_once('Table.php');
require_once('View.php');

class DB {
    public    $nc;
    protected $framework;
    protected $database;
    protected $connection;
    protected $comment;

    public function __construct(DatabaseNamingConvention &$nc, Framework &$framework)
    {
        $this->nc         = &$nc;
        $this->framework  = &$framework;
        $this->database   = &$framework->database;
        $this->connection = new \PDO($framework->connection, $framework->username, $framework->password, [\PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION]);

        $this->comment    = $this->databaseComment();
        foreach (\Spyc::YAMLLoadString($this->comment) as $name => $value) {
            $nameCamel = Str::camel($name);
            if (!property_exists($this, $nameCamel)) throw new \Exception("Property [$nameCamel] does not exist on [$this->name]");
            if (!isset($this->$nameCamel)) $this->$nameCamel = $value;
        }

        $framework->db = &$this;

        $this->setup();
    }

    public function isFrameworkTable(string &$tablename): bool
    {
        return $this->framework->isFrameworkTable($tablename);
    }

    public function isFrameworkModuleTable(string &$tablename): bool
    {
        return $this->framework->isFrameworkModuleTable($tablename);
    }

    // --------------------------------------- General query interface
    public function serverID(bool $quote = FALSE): string
    {
        $results = $this->select("select id from acorn_servers where hostname=:hostname", array(
            'hostname' => gethostname()
        ));
        $serverID = $results[0]->id;
        if ($quote) $serverID = "'$serverID'";
        return $serverID;
    }

    public function disableTriggers(): bool
    {
        $this->select("SET session_replication_role = replica;");
        return TRUE;
    }

    public function enableTriggers(): bool
    {
        $this->select("SET session_replication_role = DEFAULT;");
        return TRUE;
    }

    public function countRows(string $table): int
    {
        $results = $this->select("select count(*) from $table");
        return $results[0]->count;
    }

    public function isEmpty(string $table): bool
    {
        return !$this->countRows($table);
    }

    public function select($sql, $namedParameters = array()): array
    {
        $statement = $this->connection->prepare($sql);
        foreach ($namedParameters as $name => $value) $statement->bindParam(":$name", $value);
        try {
            $statement->execute();
        } catch (\Exception $ex) {
            throw $ex;
        }
        return $statement->fetchAll(\PDO::FETCH_OBJ);
    }

    public function insert($sql, $namedParameters = array()): array
    {
        return $this->select($sql, $namedParameters);
    }

    // --------------------------------------- Database setup
    public function setup()
    {
        $this->setPHPIntervalStyle();
    }

    public function setPHPIntervalStyle()
    {
        $this->set('IntervalStyle', 'iso_8601');
    }

    public function set($parameter, $value)
    {
        $statement = $this->connection->prepare("ALTER DATABASE $this->database SET \"$parameter\" TO '$value';");
        $statement->execute();
    }

    // --------------------------------------- Schema Queries
    // PostGres supports ANSI information_schema and proprietry pg_* information
    // https://www.postgresql.org/docs/current/functions-info.html
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-COMMENT
    public function actionFunctionsForTable(string $table): array
    {
        $tableParts     = explode('_', $table); // acorn_justice_legalcases
        $tableQualifier = implode('_', array_slice($tableParts, 2)); // legalcases_*
        return (isset($tableParts[1]) ? $this->functions($tableParts[0], $tableParts[1], 'action', $tableQualifier) : array());
    }

    public function functions(string $author = NULL, string $plugin = NULL, string $qualifier1 = NULL, string $qualifier2 = NULL): array
    {
        $like  = 'fn';
        $like .= ($author     ? "_$author"     : '_%');
        $like .= ($plugin     ? "_$plugin"     : '_%');
        $like .= ($qualifier1 ? "_$qualifier1" : '_%');
        $like .= ($qualifier2 ? "_$qualifier2" : '_%');
        $like .= '_%';
        $statement = $this->connection->prepare("select 
            proname as name, proargnames as parameters, proargtypes as types, oid, obj_description(oid) as comment, prorettype as returntype
            from pg_proc
            where proname like(:like)
            ORDER BY proname");
        $statement->bindParam(':like', $like);
        $statement->execute();
        $results = $statement->fetchAll(\PDO::FETCH_OBJ);

        $functions = array();
        foreach ($results as &$result) {
            $parameters = array();
            $types      = explode(' ', $result->types);
            $returnType = 'unknown';

            foreach (explode(',', substr($result->parameters, 1, -1)) as $i => $name) {
                // TODO: Translate type oids
                $typeOID = (int) $types[$i];
                $typeName = 'unknown';
                switch ($typeOID) {
                    case 2950: $typeName = 'uuid';
                }
                $parameters[$name] = $typeName;
            }
            
            switch ($result->returntype) {
                case 2950: $returnType = 'uuid'; break;
                case 2278: $returnType = 'void'; break;
            }
            
            $functions[$result->name] = array(
                'oid'        => $result->oid,
                'parameters' => $parameters,
                'comment'    => $result->comment,
                'returnType' => $returnType,
            );
        }

        return $functions;
    }

    public function databaseComment(): string
    {
        $comment = NULL;

        $statement = $this->connection->prepare("SELECT d.oid, pg_catalog.shobj_description(d.oid, 'pg_database') AS \"comment\"
            FROM   pg_catalog.pg_database d
            WHERE  datname = :database");
        $statement->bindParam(':database', $this->database);
        $statement->execute();
        $results = $statement->fetchAll(\PDO::FETCH_ASSOC);
        if (count($results)) $comment = $results[0]['comment'];

        return ($comment ?: '');
    }

    public function tablesBy(string $author = NULL, string $plugin = NULL): array
    {
        $tableMatch = ($author ? "{$author}_" : '') . ($plugin ? "{$plugin}_" : '') . '%';
        return $this->tables($tableMatch);
    }

    public function tables(string $schemaMatch = '%', string $tableMatch = '%'): array
    {
        $results = array();

        // TODO: oid for comment write-back
        $statement = $this->connection->prepare("select table_schema as schema, table_name as name, table_type as type,
                substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int as order,
                obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class') as comment,
                tableowner as owner
            from information_schema.tables tbs
            inner join pg_tables pgtbs on tbs.table_schema = pgtbs.schemaname and tbs.table_name = pgtbs.tablename
            where table_catalog = current_database()
                and table_schema not like('pg_%') and not table_schema = 'information_schema'
                and table_schema like(:schemaMatch)
                and table_name   like(:tableMatch)
            order by 
                coalesce(substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9-]+)')::int, 10000) asc,
                length(table_name) desc"
        );
        $statement->bindParam(':schemaMatch', $schemaMatch);
        $statement->bindParam(':tableMatch',  $tableMatch);
        $statement->execute();

        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            // print("$row[schema].$row[name]\n");
            switch ($row['type']) {
                case 'BASE TABLE':
                    $object = Table::fromRow($this, $row);
                    break;
                case 'VIEW':
                    $object = View::fromRow($this, $row);
                    break;
                default:
                    throw new \Exception("Unknown object type [$row[type]]");
            }
            if ($object->shouldProcess()) $results[$object->fullyQualifiedName()] = $object;
        }

        return $results;
    }

    public function views(string $schemaMatch = '%', string $tableMatch = '%'): array
    {
        // table-type: report (read-only)
        $results = array();

        // TODO: oid for comment write-back
        $statement = $this->connection->prepare("select table_catalog, table_schema as schema, table_name as name,
                substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int as order,
                obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class') as comment
            from information_schema.views
            where table_catalog = current_database()
                and table_schema not like('pg_%') and not table_schema = 'information_schema'
                and table_schema like(:schemaMatch)
                and table_name   like(:tableMatch)
            order by coalesce(substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int, 10000) asc"
        );
        $statement->bindParam(':schemaMatch', $schemaMatch);
        $statement->bindParam(':tableMatch',  $tableMatch);
        $statement->execute();
        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            $view = View::fromRow($this, $row);
            if ($view->shouldProcess()) $results[$view->fullyQualifiedName()] = $view;
        }

        return $results;
    }

    public function tableColumns(Table|string $table, bool $allColumns = FALSE): array
    {
        $results = array();

        // Can process any table and return raw results
        // or, if it is a table obejct return create-system objects
        $schema = NULL;
        $name   = NULL;
        if ($table instanceof Table) {
            $schema = $table->schema;
            $name   = $table->name;
        } else {
            $tableParts = explode('.', $table);
            $isFQN      = (count($tableParts) > 1);
            $schema     = ($isFQN ? $tableParts[0] : 'public');
            $name       = ($isFQN ? $tableParts[1] : $tableParts[0]);
        }

        // TODO: oid for comment write-back
        $statement = $this->connection->prepare("SELECT *, 
            pg_catalog.col_description(concat(table_schema, '.', table_name)::regclass::oid, ordinal_position) as comment
            FROM information_schema.columns
            WHERE   table_schema = :schema
                and table_name   = :table
            order by 
                coalesce(
                    substring(pg_catalog.col_description(concat(table_schema, '.', table_name)::regclass, 
                    ordinal_position), 'order: ([0-9]+)')::int, 10000) asc"
        );
        $statement->bindParam(':schema', $schema);
        $statement->bindParam(':table',  $name);
        $statement->execute();
        $results = $statement->fetchAll(\PDO::FETCH_ASSOC);

        if ($table instanceof Table) {
            $resultsObjects = array();
            foreach ($results as $row) {
                $column = Column::fromRow($table, $row);
                if ($column->shouldProcess() || $allColumns) $resultsObjects[$column->name] = $column;
            }
            $results = $resultsObjects;
        }

        return $results;
    }

    protected function foreignKeys(Column &$column, bool $to = FALSE): array
    {
        // Foreign tables that this column points to / from
        // For example, column = criminal_legalcase.legalcase_id:
        //   criminal_legalcase.legalcase_id => legalcase.id
        // Or reversed (to this field):
        //   legalcase.id <= criminal_legalcase.legalcase_id, civil_legalcase.legalcase_id, houseofpeace_legalcase.legalcase_id
        $toFrom = ($to ? 'to' : 'from');

        $results   = array();
        $statement = $this->connection->prepare("select
                    constr.oid                as oid,
                    constr.conname            as name,
                    descr.description         as comment,

                    table_from_schema.nspname as table_from_schema,
                    table_from_class.relname  as table_from_name,
                    table_from_att.attname    as table_from_column,

                    table_to_schema.nspname   as table_to_schema,
                    table_to_class.relname    as table_to_name,
                    table_to_att.attname      as table_to_column
                from pg_constraint constr
                    -- From
                    join pg_class     table_from_class  on table_from_class.oid    = constr.conrelid
                    join pg_namespace table_from_schema on table_from_schema.oid   = table_from_class.relnamespace
                    join pg_attribute table_from_att    on table_from_att.attrelid = constr.conrelid

                    -- To (f)
                    join pg_class     table_to_class  on table_to_class.oid    = constr.confrelid
                    join pg_namespace table_to_schema on table_to_schema.oid   = table_to_class.relnamespace
                    join pg_attribute table_to_att    on table_to_att.attrelid = constr.confrelid

                    left outer join pg_description descr on descr.objoid = constr.oid
                where constr.contype = 'f'
                    and table_from_att.attnum = (select unnest(constr.conkey))
                    and table_to_att.attnum   = (select unnest(constr.confkey))
                    and table_{$toFrom}_schema.nspname = :schema
                    and table_{$toFrom}_class.relname  = :table
                    and table_{$toFrom}_att.attname    = :column
                order by coalesce(substring(descr.description, 'order: ([0-9]+)')::int, 10000) asc"
        );
        $statement->bindParam(':schema', $column->table->schema);
        $statement->bindParam(':table',  $column->table->name);
        $statement->bindParam(':column', $column->name);
        $statement->execute();

        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            $fk   = ForeignKey::fromRow($column, $to, $row);
            $name = $fk->fullyQualifiedName();
            if (isset($results[$name]))
                throw new \Exception("Foreign Key $name already exists");
            if ($fk->shouldProcess()) $results[$name] = $fk;
        }

        return $results;
    }

    public function foreignKeysFrom(Column &$column): array
    {
        return $this->foreignKeys($column);
    }

    public function foreignKeysTo(Column &$column): array
    {
        return $this->foreignKeys($column, TRUE);
    }

    public function triggers(Table &$table, string $type = NULL): array
    {
        $results   = array();
        $sql = "SELECT 
                trigger_schema, trigger_name as name, 
                action_timing, event_manipulation, 
                event_object_schema, event_object_table, 
                action_statement, replace(replace(action_statement, 'EXECUTE FUNCTION ', ''), '()', '') as function
            FROM information_schema.triggers
            WHERE event_object_schema = :schema
            AND   event_object_table  = :table
        ";
        if ($type) $sql .= ' AND event_manipulation = :type';
        $statement = $this->connection->prepare($sql);
        $statement->bindParam(':schema', $table->schema);
        $statement->bindParam(':table',  $table->name);
        if ($type) $statement->bindParam(':type',   $type);
        $statement->execute();

        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            $tr = Trigger::fromRow($table, $row);
            $results[$tr->fullyQualifiedName()] = $tr;
        }

        return $results;
    }

    // --------------------------------------- Actions
    public function addColumn(string $table, string $column, string $type, string $gen = NULL, bool $nullable = Column::NOT_NULL)
    {
        global $YELLOW, $RED, $NC;

        if (!$nullable) {
            $sql     = "select count(*) from $table;";
            $reponse = $this->connection->query($sql);
            $results = $reponse->fetchAll(\PDO::FETCH_OBJ);
            if ($results[0]->count) {
                print("{$RED}ERROR$NC: $table has rows, so adding a NOT NULL column will fail\n");
                $yn = readline("Truncate cascade [$table] (y) ?");
                if ($yn != 'n') {
                    $sql     = "TRUNCATE $table CASCADE;";
                    $reponse = $this->connection->query($sql);
                }
            }
        }

        $sql = "ALTER TABLE IF EXISTS $table ADD COLUMN $column $type";
        if (!$nullable) $sql .= " NOT NULL";
        if ($gen)       $sql .= " GENERATED ALWAYS AS ($gen) STORED";
        $statement = $this->connection->prepare($sql);
        $statement->execute();
    }

    public function setDefault(string $table, string $column, string $default, bool $quote = FALSE)
    {
        if ($quote) $default = "'$default'";
        $sql = "ALTER TABLE IF EXISTS $table ALTER COLUMN $column SET DEFAULT $default";
        $statement = $this->connection->prepare($sql);
        $statement->execute();
    }

    public function deleteColumn(string $table, string $column)
    {
        $sql = "ALTER TABLE IF EXISTS $table DROP COLUMN $column";
        $statement = $this->connection->prepare($sql);
        $statement->execute();
    }

    public function addForeignKey(string $table, string $column, string $references_table, string $references_column = 'id')
    {
        $sql = "ALTER TABLE IF EXISTS $table
            ADD CONSTRAINT $column FOREIGN KEY ($column)
            REFERENCES $references_table ($references_column) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
            NOT VALID;";
        $statement = $this->connection->prepare($sql);
        $statement->execute();

        $sql = "CREATE INDEX IF NOT EXISTS fki_$column ON $table($column);";
        $statement = $this->connection->prepare($sql);
        $statement->execute();
    }

    public function addTrigger(string $table, string $function, string $action_timing = 'AFTER', array $event_manipulation = array('INSERT', 'UPDATE'))
    {
        $triggerName = preg_replace('/^fn_/', 'tr_', $function);
        $event_manipulation_string = implode(' OR ', $event_manipulation);
        $sql = "CREATE OR REPLACE TRIGGER $triggerName
            $action_timing $event_manipulation_string 
            ON $table
            FOR EACH ROW
            EXECUTE FUNCTION $function();";
        $statement = $this->connection->prepare($sql);
        $statement->execute();
    }

    public function setCommentValue(string $table, string $column, string $dotPath, mixed $value) {
        // TODO: setCommentValue
    }

    public function appendCommentValue(string $table, string $column, string $dotPath, mixed $value) {
        // TODO: appendCommentValue
    }

    public function runSQLFile(string $filePath, array $prepare = array(), int $indent = 4)
    {
        $indentString = str_repeat(' ', $indent * 2);
        $sql = file_get_contents($filePath);
        if (!$sql) throw new \Exception("SQL file [$filePath] is empty");

        foreach (explode(';', $sql) as $sqlCommand) {
            $sqlCommand = trim($sqlCommand);
            if ($sqlCommand) {
                //print("$indentString$sqlCommand\n");
                $statement = $this->connection->prepare($sqlCommand);
                foreach ($prepare as $name => &$value) $statement->bindParam(":$name", $value);
                $result    = $statement->execute();
            }
        }

        return $result;
    }
}
