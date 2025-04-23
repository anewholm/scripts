<?php

function get_filtered_classes(string $filter = NULL): array
{
    // Maybe a global helper include?
    return array_filter(\get_declared_classes(), function($value) use ($filter): bool 
    {
        return preg_match("/$filter/", $value);
    });
}

