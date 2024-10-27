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

    // --------------------------------------- Schema Queries
    public function actionFunctionsForTable(string $table): array
    {
        $tableParts = explode('_', $table);
        return (isset($tableParts[1]) ? $this->functions($tableParts[0], $tableParts[1], 'action') : array());
    }

    public function functions(string $author = NULL, string $plugin = NULL, string $qualifier = NULL): array
    {
        $like  = 'fn';
        $like .= ($author    ? "_$author"    : '_%');
        $like .= ($plugin    ? "_$plugin"    : '_%');
        $like .= ($qualifier ? "_$qualifier" : '_%');
        $like .= '_%';
        $statement = $this->connection->prepare("SELECT routines.routine_name as name,
                string_agg(concat(parameters.parameter_name, ' ', parameters.data_type), ', ') as parameters
            FROM information_schema.routines
            LEFT JOIN information_schema.parameters ON routines.specific_name = parameters.specific_name
            WHERE routines.specific_schema='public'
            and routines.routine_name like(:like)
            group by routines.routine_name
            ORDER BY routines.routine_name");
        $statement->bindParam(':like', $like);
        $statement->execute();
        $results = $statement->fetchAll(\PDO::FETCH_OBJ);
        $functions = array();
        foreach ($results as &$result) {
            $parameters = array();
            foreach (explode(',', $result->parameters) as $parameter) {
                $nv = explode(' ', trim($parameter));
                $parameters[$nv[0]] = $nv[1];
            }
            $functions[$result->name] = $parameters;
        }

        return $functions;
    }

    public function databaseComment(): string
    {
        $comment = NULL;

        $statement = $this->connection->prepare("SELECT pg_catalog.shobj_description(d.oid, 'pg_database') AS \"comment\"
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

    public function tables(string $schemaMatch = 'public', string $tableMatch = '%'): array
    {
        $results = array();

        $statement = $this->connection->prepare("select table_schema as schema, table_name as name,
                substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int as order,
                obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class') as comment
            from information_schema.tables
            where table_catalog = current_database()
                and table_schema like(:schemaMatch)
                and table_name   like(:tableMatch)
            order by coalesce(substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int, 10000) asc"
        );
        $statement->bindParam(':schemaMatch', $schemaMatch);
        $statement->bindParam(':tableMatch',  $tableMatch);
        $statement->execute();
        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            $object = Table::fromRow($this, $row);
            $results[$object->fullyQualifiedName()] = $object;
        }

        return $results;
    }

    public function views(string $schemaMatch = 'public', string $tableMatch = '%'): array
    {
        // table-type: report (read-only)
        $results = array();

        $statement = $this->connection->prepare("select table_catalog, table_schema as schema, table_name as name,
                substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int as order,
                obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class') as comment
            from information_schema.views
            where table_catalog = current_database()
                and table_schema like(:schemaMatch)
                and table_name   like(:tableMatch)
            order by coalesce(substring(obj_description(concat(table_schema, '.', table_name)::regclass, 'pg_class'), 'order: ([0-9]+)')::int, 10000) asc"
        );
        $statement->bindParam(':schemaMatch', $schemaMatch);
        $statement->bindParam(':tableMatch',  $tableMatch);
        $statement->execute();
        foreach ($statement->fetchAll(\PDO::FETCH_ASSOC) as $row) {
            $view = View::fromRow($this, $row);
            $results[$view->fullyQualifiedName()] = $view;
        }

        return $results;
    }

    public function tableColumns(Table &$table): array
    {
        $results = array();

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
            $results[$column->name] = $column;
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

        $results = array();
        $statement = $this->connection->prepare("select
                    constr.conname           as name,
                    descr.description        as comment,
                    table_from_class.relname as table_from_name,
                    table_from_att.attname   as table_from_column,
                    table_to_class.relname   as table_to_name,
                    table_to_att.attname     as table_to_column
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
            $object = ForeignKey::fromRow($column, $to, $row);
            $results[$object->fullyQualifiedName()] = $object;
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
