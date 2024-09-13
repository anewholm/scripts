<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Validation Language Lines
    |--------------------------------------------------------------------------
    |
    | The following language lines contain the default error messages used by
    | the validator class. Some of these rules have multiple versions such
    | as the size rules. Feel free to tweak each of these messages here.
    |
    */

    'accepted'             => ':attribute divê bibe qebûl kirin.',
    'active_url'           => ':attribute URLa ne xweseri ye.',
    'after'                => ':attribute divê datayek pêşîn ji :date were.',
    'after_or_equal'       => ':attribute divê datayek pêşîn yan wekhev bibe :date.',
    'alpha'                => ':attribute tenê dîjî wergirtinê bibîne.',
    'alpha_dash'           => ':attribute tenê dîjî, hejmara û lêkolînan bibîne.',
    'alpha_num'            => ':attribute tenê dîjî û hejmara bibîne.',
    'array'                => ':attribute divê matrix be.',
    'before'               => ':attribute divê datayek pêşîn ji :date bibe.',
    'before_or_equal'      => ':attribute divê datayek pêşîn yan wekhev bibe :date.',
    'between'              => [
        'numeric' => ':attribute divê di navbera :min û :max de be.',
        'file'    => ':attribute divê di navbera :min û :max kilobytes de be.',
        'string'  => ':attribute divê di navbera :min û :max karakteran de be.',
        'array'   => ':attribute divê di navbera :min û :max tiştan de be.',
    ],
    'boolean'              => ':attribute xanî divê rast yan na be.',
    'confirmed'            => ':attribute pêşwazî nayê kirin.',
    'date'                 => ':attribute datayek ne xweseri ye.',
    'date_equals'          => ':attribute divê datayek wekhev bibe :date.',
    'date_format'          => ':attribute forma nayê wergirtin: :format.',
    'different'            => ':attribute û :other divê bi awayekî din be.',
    'digits'               => ':attribute divê ji :digits numreyan bibe.',
    'digits_between'       => ':attribute divê di navbera :min û :max numreyan de be.',
    'dimensions'           => ':attribute materyalê wêneyan nerazî ye.',
    'distinct'             => ':attribute xanî bawerî nehatîn.',
    'email'                => ':attribute formatê nayê xwestin.',
    'ends_with'            => ':attribute divê bi yek ji van de were seqetkirin: :values.',
    'exists'               => ':attribute hilbijartin ne xweseri ye.',
    'file'                 => ':attribute divê pel be.',
    'filled'               => ':attribute xanê divê bê guhertin.',
    'gt'                   => [
        'numeric' => ':attribute divê mezin be :value.',
        'file'    => ':attribute divê mezin be :value kilobytes.',
        'string'  => ':attribute divê mezin be :value karakteran.',
        'array'   => ':attribute divê zêde bikin :value tiştan.',
    ],
    'gte'                  => [
        'numeric' => ':attribute divê mezin be an wekhev be :value.',
        'file'    => ':attribute divê mezin be an wekhev be :value kilobytes.',
        'string'  => ':attribute divê mezin be an wekhev be :value karakteran.',
        'array'   => ':attribute divê :value tiştan an zêde be.',
    ],
    'image'                => ':attribute divê wêne be.',
    'in'                   => ':attribute hilbijartina ne xweseri ye.',
    'in_array'             => ':attribute xanî di :other de nehatîn dîtin.',
    'integer'              => ':attribute divê hejmari be.',
    'ip'                   => ':attribute divê IP xweser be.',
    'ipv4'                 => ':attribute divê IPv4 xweser be.',
    'ipv6'                 => ':attribute divê IPv6 xweser be.',
    'json'                 => ':attribute divê JSON String be.',
    'lt'                   => [
        'numeric' => ':attribute divê kêmtir be :value.',
        'file'    => ':attribute divê kêmtir be :value kilobytes.',
        'string'  => ':attribute divê kêmtir be :value karakteran.',
        'array'   => ':attribute divê kêmtir be :value tiştan.',
    ],
    'lte'                  => [
        'numeric' => ':attribute divê kêmtir an wekhev be :value.',
        'file'    => ':attribute divê kêmtir an wekhev be :value kilobytes.',
        'string'  => ':attribute divê kêmtir an wekhev be :value karakteran.',
        'array'   => ':attribute may not have more than :value items.',
    ],
    'max'                  => [
        'numeric' => ':attribute may not be greater than :max.',
        'file'    => ':attribute may not be greater than :max kilobytes.',
        'string'  => ':attribute may not be greater than :max characters.',
        'array'   => ':attribute may not have more than :max items.',
    ],
    'mimes'                => ':attribute divê pelê bibe: :values.',
    'mimetypes'            => ':attribute divê pelê bibe: :values.',
    'min'                  => [
        'numeric' => ':attribute must be at least :min.',
        'file'    => ':attribute must be at least :min kilobytes.',
        'string'  => ':attribute must be at least :min characters.',
        'array'   => ':attribute must have at least :min items.',
    ],
    'not_in'               => ':attribute hilbijartina ne xweseri ye.',
    'not_regex'            => ':attribute forma nayê wergirtin.',
    'numeric'              => ':attribute divê hejmari be.',
    'present'              => ':attribute xanê divê heye.',
    'regex'                => ':attribute formatê nayê xwestin.',
    'required'             => ':attribute xanê dê bê bixwînin.',
    'required_if'          => ':attribute xanê divê heye ke :other :value be.',
    'required_unless'      => ':attribute xanê divê heye tenê di nav de :other be.',
    'required_with'        => ':attribute xanê divê heye ke :values heye.',
    'required_with_all'    => ':attribute xanê divê heye ke :values heye.',
    'required_without'     => ':attribute xanê divê heye ke :values heye.',
    'required_without_all' => ':attribute xanê divê heye ke tenê di nav de :values nebe.',
    'same'                 => ':attribute û :other divê hev be.',
    'size'                 => [
        'numeric' => ':attribute divê :size be.',
        'file'    => ':attribute divê :size kilobytes be.',
        'string'  => ':attribute divê :size karakteran be.',
        'array'   => ':attribute divê :size tiştan be.',
    ],
    'starts_with'          => ':attribute divê bi yek ji van de destpê bike: :values.',
    'string'               => ':attribute divê string be.',
    'timezone'             => ':attribute divê be welatê xweseri ye.',
    'unique'               => ':attribute hilbijartinê hebe.',
    'uploaded'             => ':attribute nekarî bibe upload.',
    'url'                  => ':attribute formatê nayê xwestin.',
    'uuid'                 => ':attribute divê UUID xweser be.',

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Language Lines
    |--------------------------------------------------------------------------
    |
    | Here you may specify custom validation messages for attributes using the
    | convention "attribute.rule" to name the lines. This makes it quick to
    | specify a specific custom language line for a given attribute rule.
    |
    */

    'custom' => [
        'attribute-name' => [
            'rule-name' => 'custom-message',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Attributes
    |--------------------------------------------------------------------------
    |
    | The following language lines are used to swap attribute place-holders
    | with something more reader friendly such as E-Mail Address instead
    | of "email". This simply helps us make messages a little cleaner.
    |
    */

    'attributes' => [],

];
