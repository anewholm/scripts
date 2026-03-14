<?php namespace Acorn\CreateSystem\Adapters;

/**
 * PhpCodeWriterTrait
 *
 * Pure PHP source-code manipulation methods.
 * Framework-independent: works on any PHP file regardless of target framework.
 *
 * Requires the using class to provide:
 *   $this->fileLoad(string $path, bool $cache): string
 *   $this->replaceInFile(string $path, string $regex, string $replacement, bool $throwIfNotFound, bool $cache): void
 *   $this->FILES[]: array (file content cache)
 */
trait PhpCodeWriterTrait
{
    // ---------------------------------------------- Functions & Property control

    protected function writeFileUses(string $path, array &$uses)
    {
        if (!$path) throw new \Exception("FileUses path is empty");
        $usesString = '';
        foreach ($uses as $name => $include) {
            if ($include) $usesString .= "use $name;\n";
        }
        $this->replaceInFile($path, '/^(namespace .*$)/m', "\\1\n\n$usesString");
    }

    protected function writeClassTraits(string $path, array &$traits, int $indent = 1)
    {
        if (!$path) throw new \Exception("ClassTraits path is empty");
        $indentString = str_repeat(' ', $indent*4);
        $traitsString = '';
        foreach ($traits as $name => $include) {
            if ($include) $traitsString .= "{$indentString}use $name;\n";
        }
        $this->replaceInFile($path, '/^{$/m', "{\n$traitsString\n");
    }

    protected function addStaticMethod(string $path, string $name, string $body, string $scope = 'public', int $indent = 1)
    {
        if (!$path) throw new \Exception("StaticMethod path is empty");
        return $this->addMethod($path, $name, $body, 'mixed', $scope, TRUE, $indent);
    }

    protected function replaceMethod(string $path, string $name, string|array $body, string $type = NULL, string $scope = 'public', bool $static = FALSE, int $indent = 1)
    {
        $this->removeMethod($path, $name);
        $this->addMethod($path, $name, $body, $type, $scope, $static, $indent);
    }

    protected function addMethod(string $path, string $name, string|array $body, string $type = NULL, string $scope = 'public', bool $static = FALSE, int $indent = 1)
    {
        if (!$path)
            throw new \Exception("Method path is empty");

        // Parameters will be empty if included in the $name
        $nameHasParameters = (strstr($name, '(') !== FALSE);
        $parameters    = ($nameHasParameters ? '' : '()');
        $indentString  = str_repeat(' ', $indent*4);
        $indentString2 = str_repeat(' ', ($indent+1)*4);
        $staticString  = ($static ? ' static' : '');
        $signature     = "$name$parameters";
        if (is_array($body)) $body = implode("\n$indentString2", $body);
        else $body = preg_replace('/\n/', "\n$indentString2", $body);
        if ($type) $signature .= ": $type";

        $contents = &$this->fileLoad($path);
        if (strstr($contents, "function $signature") !== FALSE)
            throw new \Exception("Method $signature already exists in $path");

        $this->replaceInFile($path, '/^}$/m', <<<FUNCTION

$indentString$scope$staticString function $signature {
$indentString2# Auto-injected by acorn-create-system
$indentString2$body
$indentString}
}
FUNCTION
        );
    }

    protected function setPropertyInClassFile(string $path, string $name, string|int|array $value, bool $overwriteExisting = Framework::OVERWRITE_EXISTING, string $scope = 'public', int $indent = Framework::STD_INDENT, bool $passthrough = Framework::FIRST_MULTILINE)
    {
        if (!$path) throw new \Exception("FILES path is empty");
        if (!isset($this->FILES[$path])) $this->FILES[$path] = file_get_contents($path);
        $contents = &$this->FILES[$path];

        $indentString = str_repeat(' ', $indent*4);
        $valueString  = $value;
        if      (is_array($valueString))  $valueString = $this->varExport($valueString, $indent, TRUE, $passthrough);
        else if (is_string($valueString)) $valueString = "'" . str_replace("'", "\\'", $valueString) . "'";

        if ($overwriteExisting) {
            $regexExistingPropertyLine = "/^$indentString$scope +\\\$$name *=[^;]*;/sm";
            $this->replaceInFile($path, $regexExistingPropertyLine, "$indentString$scope \$$name = $valueString;");
        } else {
            $this->replaceInFile($path, '/^{$/m', "{\n$indentString$scope \$$name = $valueString;");
        }
    }

    protected function varExport(array &$array, int $indent = 1, bool $multiLine = TRUE, bool $passthrough = TRUE): string
    {
        // Clauses
        $valueClauses = array();
        foreach ($array as $name => $value) {
            if      (is_string($value)) $value = "'" . str_replace("'", "\\'", $value) . "'";
            else if (is_bool($value))   $value = ($value ? 'TRUE' : 'FALSE');
            else if (is_array($value))  $value = $this->varExport($value, $indent+1, $passthrough, $passthrough);
            else if (is_object($value) && method_exists($value, 'absoluteFullyQualifiedName'))
                $value = $value->absoluteFullyQualifiedName(TRUE);

            if (is_numeric($name)) array_push($valueClauses, $value);
            else                   array_push($valueClauses, "'$name' => $value");
        }

        // Assembly
        $string = '[';
        if (count($valueClauses)) {
            if ($multiLine) {
                $indentString = str_repeat(' ', ++$indent*4);
                $string .= "\n$indentString";
                $string .= implode(",\n$indentString", $valueClauses);
                $indentString = str_repeat(' ', --$indent*4);
                $string .= "\n$indentString";
            } else {
                $string .= implode(', ', $valueClauses);
            }
        }
        $string .= ']';

        return $string;
    }

    protected function removeEmpty(array $array, bool $andFalses = Framework::NOT_FALSES, array $keepFalses = array()): array
    {
        $cleanedArray = array();
        foreach ($array as $name => $value) {
            $empty = (
                   is_null($value)
                || (is_string($value) && !$value)
                || (is_array($value)  && !count($value))
                || ($andFalses && is_bool($value) && !$value && !in_array($name, $keepFalses))
            );
            if (!$empty) $cleanedArray[$name] = $value;
        }
        return $cleanedArray;
    }

    protected function removeMethod(string $path, string $functionName, string $scope = 'public')
    {
        if (!$path)
            throw new \Exception("Function path is empty");

        $this->replaceInFile($path, "/$scope function $functionName\(/", "$scope function {$functionName}_REMOVED(");
    }

    protected function setArrayReturnFunction(string $path, string $functionName, array $arrayReturn, int $indent = 1)
    {
        if (!$path)         throw new \Exception("File path is empty");
        if (!$functionName) throw new \Exception("Function name is empty");

        $indentString  = str_repeat(' ', $indent*4);
        $indent2string = str_repeat(' ', $indent*8);
        $arrayExport   = $this->varExport($arrayReturn, $indent+2);
        $open   = '{';
        $return = 'return';
        $close  = '}';
        $this->replaceInFile($path,
            "/function $functionName\(([^)]*)\)([^{])*\{[^}]*\}/s",
            "function $functionName(\\1)\\2\n$indentString$open\n$indent2string$return $arrayExport;\n$indentString$close"
        );
    }

    protected function changeArrayReturnFunctionEntry(string $path, string $functionName, string $arrayDotPath, $newValue)
    {
        if (!$path)         throw new \Exception("File path is empty");
        if (!$functionName) throw new \Exception("Function name is empty");
        if (strstr($arrayDotPath, '.') !== FALSE) throw new \Exception("Dot array replacement [$arrayDotPath] not supported yet");

        $escapedValue = str_replace("'", "\\'", $newValue);
        $this->replaceInFile($path, "/'$arrayDotPath' *=>.*/", "'$arrayDotPath' => '$escapedValue',");
    }
}
