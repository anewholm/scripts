<?php namespace Acorn\CreateSystem;

require_once('Table.php');
require_once('View.php');

class DB {
    public    $nc;
    protected $framework;
    protected $database;
    protected $connection;

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
    public function select($sql, $namedParameters = array()): array
    {
        $statement = $this->connection->prepare($sql);
        foreach ($namedParameters as $name => $value) $statement->bindParam(":$name", $value);
        $statement->execute();
        return $statement->fetchAll(\PDO::FETCH_OBJ);
    }

    public function insert($sql, $namedParameters = array()): array
    {
        return $this->select($sql, $namedParameters);
    }

    // --------------------------------------- Schema Queries
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
        $statement = $this->connection->prepare("select proname as name, proargnames as parameters, proargtypes as types, oid, obj_description(oid) as comment
            from pg_proc
            where proname like(:like)
            ORDER BY proname");
        $statement->bindParam(':like', $like);
        $statement->execute();
        $results = $statement->fetchAll(\PDO::FETCH_OBJ);

        $functions = array();
        foreach ($results as &$result) {
            $parameters = array();
            $types      = explode(' ', substr($result->types, 1, -1));
            foreach (explode(',', substr($result->parameters, 1, -1)) as $i => $name) {
                // TODO: Translate type oids
                $parameters[$name] = $types[$i];
            }
            $functions[$result->name] = array(
                'oid'        => $result->oid,
                'parameters' => $parameters,
                'comment'    => $result->comment,
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
        $tableMatch = ($author ? "${author}_" : '') . ($plugin ? "${plugin}_" : '') . '%';
        return $this->tables($tableMatch);
    }

    public function tables(string $schemaMatch = '%', string $tableMatch = '%'): array
    {
        $results = array();

        // TODO: oid for comment write-back
        $statement = $this->connection->prepare("select table_schema as schema, table_name as name, table_type as type,
                substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int as order,
                obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class') as comment
            from information_schema.tables
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

    public function tableColumns(Table &$table): array
    {
        $results = array();

        // TODO: oid for comment write-back
        $statement = $this->connection->prepare("SELECT *, pg_catalog.col_description(concat(table_schema, '.', table_name)::regclass::oid, ordinal_position) as comment
            FROM information_schema.columns
            WHERE   table_schema = :schema
                and table_name   = :table
            order by coalesce(substring(pg_catalog.col_description(concat(table_schema, '.', table_name)::regclass, ordinal_position), 'order: ([0-9]+)')::int, 10000) asc"
        );
        $statement->bindParam(':schema', $table->schema);
        $statement->bindParam(':table',  $table->name);
        $statement->execute();
        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            $column = Column::fromRow($table, $row);
            if ($column->shouldProcess()) $results[$column->name] = $column;
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
                    and table_${toFrom}_schema.nspname = :schema
                    and table_${toFrom}_class.relname  = :table
                    and table_${toFrom}_att.attname    = :column"
        );
        $statement->bindParam(':schema', $column->table->schema);
        $statement->bindParam(':table',  $column->table->name);
        $statement->bindParam(':column', $column->name);
        $statement->execute();

        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            $fk = ForeignKey::fromRow($column, $to, $row);
            if ($fk->shouldProcess()) $results[$fk->fullyQualifiedName()] = $fk;
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

    // --------------------------------------- Actions
    public function addColumn($table, $column, $type, $gen = NULL)
    {
        $sql = 'ALTER TABLE IF EXISTS :table ADD COLUMN :column :type';
        if ($gen) $sql .= ' GENERATED ALWAYS AS (:gen) STORED';
        $this->connection->prepare($sql);
        $statement->bindParam('table',  $table);
        $statement->bindParam('column', $column);
        $statement->bindParam('type',   $type);
        if ($gen) $statement->bindParam('gen', $gen);
        $statement->execute();
    }

    public function runSQLFile(string $filePath, array $prepare = array(), int $indent = 4)
    {
        $indentString = str_repeat(' ', $indent * 2);
        $sql = file_get_contents($filePath);
        if (!$sql) throw new Exception("SQL file [$filePath] is empty");

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
