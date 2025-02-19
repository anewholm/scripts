<?php namespace AcornAssociated\CreateSystem;

require_once('EnglishInflector.php');

class Str
{
    protected static $inflector;

    protected static $pluralExceptions = array(
        'gps' => 'gps'
    );
    protected static $singularExceptions = array(
        'gps' => 'gps',
        'job_batches' => 'job_batch',
        'offices' => 'office', // Fix offices => offix!
    );

    // Copied and commented from Laravel
    // ~/vendor/laravel/framework/src/Illuminate/Support/Str.php

    /**
     * Attempt to match the case on two strings.
     *
     * @param  string  $value
     * @param  string  $comparison
     * @return string
     */
    protected static function matchCase($value, $comparison)
    {
        $functions = ['mb_strtolower', 'mb_strtoupper', 'ucfirst', 'ucwords'];

        foreach ($functions as $function) {
            if ($function($comparison) === $comparison) {
                return $function($value);
            }
        }

        return $value;
    }

    /**
     * The cache of camel-cased words.
     *
     * @var array
     */
    protected static $camelCache = [];

    /**
     * The cache of studly-cased words.
     *
     * @var array
     */
    protected static $studlyCache = [];

    /**
     * Convert a value to camel case.
     *
     * @param  string  $value
     * @return string
     */
    public static function camel($value)
    {
        if (isset(static::$camelCache[$value])) {
            return static::$camelCache[$value];
        }

        return static::$camelCache[$value] = lcfirst(static::studly($value));
    }

    /**
     * Convert a value to studly caps case.
     *
     * @param  string  $value
     * @return string
     */
    public static function studly($value)
    {
        $key = $value;

        if (isset(static::$studlyCache[$key])) {
            return static::$studlyCache[$key];
        }

        $words = explode(' ', str_replace(['-', '_'], ' ', $value));

        $studlyWords = array_map(fn ($word) => ucfirst($word), $words);

        return static::$studlyCache[$key] = implode($studlyWords);
    }

    /**
     * Convert the given string to title case.
     *
     * @param  string  $value
     * @return string
     */
    public static function title($value)
    {
        return mb_convert_case($value, MB_CASE_TITLE, 'UTF-8');
    }

    public static function plural(string $value, $count = 2): string
    {
        if (isset(self::$pluralExceptions[strtolower($value)])) {
            $plurals = array(self::$pluralExceptions[strtolower($value)]);
        } else {
            if (!self::$inflector) self::$inflector = new EnglishInflector();
            $plurals = self::$inflector->pluralize($value);
        }
        return static::matchCase($plurals[0], $value);
    }

    public static function singular(string $value): string
    {
        if (isset(self::$singularExceptions[strtolower($value)])) {
            $singulars = array(self::$singularExceptions[strtolower($value)]);
        } else {
            if (!self::$inflector) self::$inflector = new EnglishInflector();
            $singulars = self::$inflector->singularize($value);
        }
        $option    = (isset($singulars[1]) ? 1 : 0);
        return static::matchCase($singulars[$option], $value);
    }
}
